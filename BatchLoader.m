classdef BatchLoader < handle
    properties
        fileNamesAll = {}
        pathNamesAll = {}
        modalities
        combinedTablesModel = {}
        combinedTablesTracks = {}
    end
    
    methods
        function obj = BatchLoader()
        end
        
        function runBatchLoad(obj, varargin)
            if nargin == 2
                figureHandle = varargin{1};
                wb = BatchLoader.initializeProgressDialog(figureHandle, "Selecting files...");  % I cannot refer static functions inside other functions without the prefix, apparently
            else
                figureHandle = [];
                wb = struct();
            end
            
            obj.selectFiles();
            
            if isempty(obj.fileNamesAll)
                disp('No files selected.');
                return;
            end
            
            obj.selectModalities();
            if isempty(obj.modalities)
                return;
            end

            wb.Message = "Starting parallel processing...";
            obj.ensureParallelPool();

            tic
            wb.Message = "Looping through the files...";
            
            % Process files in parallel
            [workerTablesModel, workerTablesTracks] = obj.processFilesInParallel();
            
            wb.Message = 'Storing data...';
            
            % Merge results
            obj.mergeModelData(workerTablesModel);
            obj.mergeTrackData(workerTablesTracks);

            % Clean up empty modalities
            obj.cleanEmptyModalities();
            
            % Store in app structure
            % obj.storeLoadedData();
            % obj.updateUI();


            if ~isempty(figureHandle)
                BatchLoader.finalizeBatchLoad(wb);
            end
            toc
        end

        function newDataStruct = storeLoadedData(obj)
            newDataStruct = struct();
            if ismember('model', obj.modalities)
                branches = fieldnames(obj.combinedTablesModel);
                usedBranches = {};
                for i = 1:length(branches)
                    branch = branches{i};
                    combinedList = combineTableAcrossTimepoints(obj.combinedTablesModel.(branch));
                    if ~isempty(combinedList)    % store only non-empty branches
                        usedBranches{end+1} = branch;
                        newDataStruct.model.(branch).combinedList = combinedList;
                        newDataStruct.model.(branch).storedCategorizations = CategorizationStorage();
                        newDataStruct.model.(branch).storedFilters = FilteringStorage();
                    end
                end
                newDataStruct.model.branches = reshape(usedBranches, 1, []);

            end
            if ismember('tracks', obj.modalities)
                newDataStruct.tracks.combinedList = combineTableAcrossTimepoints(obj.combinedTablesTracks);
                newDataStruct.tracks.storedCategorizations = CategorizationStorage();
                newDataStruct.tracks.storedFilters = FilteringStorage();
            end
        end

        function updatedDataStruct = appendLoadedData(obj, existingDataStruct)
            % TO FIX - fileId not added properly
            if ~isstruct(existingDataStruct)
                existingDataStruct = struct();
            end
            if ismember('model', obj.modalities)
                if isfield(existingDataStruct, 'model')
                    branches = fieldnames(obj.combinedTablesModel);
                    for i = 1:length(branches)
                        branch = branches{i};
                        if isfield(existingDataStruct.model, branch)
                            obj.combinedTablesModel.(branch){end+1} = existingDataStruct.model.(branch).combinedList;
                            existingDataStruct.model.(branch).combinedList = combineTableAcrossTimepoints(obj.combinedTablesModel.(branch));
                        else
                            existingDataStruct.model.(branch).combinedList = combineTableAcrossTimepoints(obj.combinedTablesModel.(branch));
                            existingDataStruct.model.(branch).storedCategorizations = CategorizationStorage();
                            existingDataStruct.model.(branch).storedFilters = FilteringStorage();
                            existingDataStruct.model.branches{end+1} = branch;
                        end
                    end
                else
                    branches = fieldnames(obj.combinedTablesModel);
                    for i = 1:length(branches)
                        branch = branches{i};
                        existingDataStruct.model.(branch).combinedList = combineTableAcrossTimepoints(obj.combinedTablesModel.(branch));
                        existingDataStruct.model.(branch).storedCategorizations = CategorizationStorage();
                        existingDataStruct.model.(branch).storedFilters = FilteringStorage();
                    end
                    existingDataStruct.model.branches = reshape(branches, 1, []);
                end
            end
            if ismember('tracks', obj.modalities)
                if isfield(existingDataStruct, 'tracks')
                    obj.combinedTablesTracks{end+1} = existingDataStruct.tracks.combinedList;
                    existingDataStruct.tracks.combinedList = combineTableAcrossTimepoints(obj.combinedTablesTracks);
                else
                    existingDataStruct.tracks.combinedList = combineTableAcrossTimepoints(obj.combinedTablesTracks);
                    existingDataStruct.tracks.storedCategorizations = CategorizationStorage();
                    existingDataStruct.tracks.storedFilters = FilteringStorage();
                end
            end
            updatedDataStruct = existingDataStruct;
        end
    end

    %% Private Methods
    methods (Access = private)
        function selectFiles(obj)
            while true
                [fileNames, pathName] = uigetfile('*.irbis', 'Select .irbis files (Select "Cancel" when done)', 'MultiSelect', 'on');
                
                if isequal(fileNames, 0)
                    break;
                end
                
                if ischar(fileNames)
                    fileNames = {fileNames};
                end
                
                obj.fileNamesAll = [obj.fileNamesAll, fileNames];
                obj.pathNamesAll = [obj.pathNamesAll, repmat({pathName}, 1, length(fileNames))];
            end
        end

        function selectModalities(obj)
            choice = questdlg('Select what you want to load:', ...
                'Load Options', 'Model', 'Tracks', 'Both', 'Model');

            switch choice
                case 'Model'
                    obj.modalities = {'model'};
                case 'Tracks'
                    obj.modalities = {'tracks'};
                case 'Both'
                    obj.modalities = {'model', 'tracks'};
                otherwise
                    obj.modalities = {};
            end
        end

        function [workerTablesModel, workerTablesTracks] = processFilesInParallel(obj)
            numFiles = length(obj.fileNamesAll);
            workerTablesModel = cell(1, numFiles);
            workerTablesTracks = cell(1, numFiles);

            parfor i = 1:numFiles
                filePath = fullfile(obj.pathNamesAll{i}, obj.fileNamesAll{i});
                matf = matfile(filePath);

                [tempCombinedTablesModel, tempCombinedTablesTracks] = obj.processSingleFile(matf, obj.fileNamesAll{i}, i);

                workerTablesModel{i} = tempCombinedTablesModel;
                workerTablesTracks{i} = tempCombinedTablesTracks;
            end
        end

        function [tempCombinedTablesModel, tempCombinedTablesTracks] = processSingleFile(obj, matf, fileName, fileIdx)
            tempCombinedTablesModel = configureDictionary("string", "cell");
            tempCombinedTablesTracks = {};
            
            if ismember('model', obj.modalities) && isprop(matf, 'model')
                tempCombinedTablesModel = obj.processModelData(matf, fileName, fileIdx);
            end
            
            if ismember('tracks', obj.modalities) && isprop(matf, 'tracks')
                tempCombinedTablesTracks = obj.processTrackData(matf, fileName, fileIdx);
            end
        end

        function combinedTablesModel = processModelData(obj, matf, fileName, fileIdx)
            infoToLoad = matf.info;
            modelToLoad = matf.model;
            combinedTablesModel = configureDictionary("string", "cell");

            for branch = string(modelToLoad.branches)
                if isfield(modelToLoad.(branch), 'List')
                    cellList = obj.enrichTablesWithMetadata(modelToLoad.(branch).List, infoToLoad, fileName, fileIdx);
                    combinedTablesModel(branch) = {combineTableAcrossTimepoints(cellList)};
                end
            end
        end

        function combinedTablesTracks = processTrackData(obj, matf, fileName, fileIdx)
            infoToLoad = matf.info;
            tracksToLoad = matf.tracks;
            combinedTablesTracks = {};

            if isfield(tracksToLoad, 'tracksList')
                cellList = obj.enrichTablesWithMetadata(tracksToLoad.tracksList, infoToLoad, fileName, fileIdx);
                combinedTablesTracks = {combineTableAcrossTimepoints(cellList)};
            end
        end

        function cellList = enrichTablesWithMetadata(~, cellList, infoToLoad, fileName, fileIdx)
            for k = 1:length(cellList)
                table = cellList{k};
                table.fileName = categorical(repmat(string(fileName), height(table), 1));
                table.groupName = categorical(repmat(string(infoToLoad.groupName), height(table), 1));
                table.round = categorical(repmat(string(infoToLoad.round), height(table), 1));
                table.cell = categorical(repmat(string(infoToLoad.cell), height(table), 1));
                table.description = categorical(repmat(string(infoToLoad.description), height(table), 1));
                table.fileId = categorical(repmat(fileIdx, height(table), 1));
                cellList{k} = table;
            end
        end

        function mergeModelData(obj, workerTablesModel)
            for i = 1:length(workerTablesModel)
                tempModel = workerTablesModel{i};
                if ~isempty(tempModel)
                    branches = keys(tempModel);
                    for j = 1:length(branches)
                        branch = string(branches{j});
                        if isfield(obj.combinedTablesModel, branch)
                            obj.combinedTablesModel.(branch) = [obj.combinedTablesModel.(branch); tempModel(branch)];
                        else
                            obj.combinedTablesModel.(branch) = tempModel(branch);
                        end
                    end
                end
            end
        end

        function mergeTrackData(obj, workerTablesTracks)
            for i = 1:length(workerTablesTracks)
                if ~isempty(workerTablesTracks{i})
                    obj.combinedTablesTracks = [obj.combinedTablesTracks, workerTablesTracks{i}];
                end
            end
        end

        function cleanEmptyModalities(obj)
            if ismember('model', obj.modalities) && isempty(obj.combinedTablesModel)
                obj.modalities = setdiff(obj.modalities, 'model');
                % clean also unused branches

            end
            if ismember('tracks', obj.modalities) && isempty(obj.combinedTablesTracks)
                obj.modalities = setdiff(obj.modalities, 'tracks');
            end
        end


    end

    methods (Static)
        function wb = initializeProgressDialog(figureHandle, message)
            disp(message);
            wb = uiprogressdlg(figureHandle, ...
                'Title', 'Loading data', ...
                'Message', message, ...
                'Cancelable', 'off', ...
                'Indeterminate', 'on');
        end
        
        function ensureParallelPool(~)
            if isempty(gcp('nocreate'))
                parpool;
            end
        end

        function finalizeBatchLoad(wb)
            close(wb);
        end
    end
end
