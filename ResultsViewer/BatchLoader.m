classdef BatchLoader < handle
    properties
        fileNamesAll = {}
        pathNamesAll = {}
        modalities
        combinedTablesModel = struct()
        combinedFilteringsModel = struct()
        combinedColumnDefinitionsModel = struct()
        combinedTablesTracks = {}
        combinedFilteringsTracks = {}
        combinedColumnDefinitionsTracks = {}
    end
    
    methods
        function obj = BatchLoader()
        end

        function runLoadFromApp(obj, irbisStruct)
            obj.modalities = {'model', 'tracks'};

            fileIdx = 0;  % 0 ensures that metadata are not added when loading from the app - set in proessModelData and processTrackData
            [tempStructModel, tempStructTracks] = processSingleFile(obj, irbisStruct, '', fileIdx);

            obj.mergeModelData({tempStructModel});  % this loads the structure into obj properties
            obj.mergeTrackData({tempStructTracks});

            % Clean up empty modalities
            obj.cleanEmptyModalities();
        end

        function newDataStruct = storeSingleLoadedData(obj)
            newDataStruct = struct();
            if ismember('model', obj.modalities)
                branches = fieldnames(obj.combinedTablesModel);
                for i = 1:length(branches)
                    branch = branches{i};
                    combinedList = obj.combinedTablesModel.(branch);
                    if ~isempty(combinedList)    % store only non-empty branches
                        if iscell(combinedList)
                            combinedList = combinedList{1};
                        end
                        newDataStruct.model.(branch).combinedList = combinedList;
                        newDataStruct.model.(branch).storedCategorizations = obj.combinedColumnDefinitionsModel.(branch);
                        newDataStruct.model.(branch).storedFilters = obj.combinedFilteringsModel.(branch);
                    end
                end
                % newDataStruct.model.branches = reshape(usedBranches, 1, []);

            end
            if ismember('tracks', obj.modalities)
                combinedList = obj.combinedTablesTracks;
                if iscell(combinedList)
                    combinedList = combinedList{1};
                end
                newDataStruct.tracks.combinedList = combinedList;
                newDataStruct.tracks.storedCategorizations = obj.combinedColumnDefinitionsTracks;
                newDataStruct.tracks.storedFilters = obj.combinedFilteringsTracks;
            end
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
            [workerCellModel, workerCellTracks] = obj.processFilesInParallel();
            
            wb.Message = 'Storing data...';
            
            % Merge results
            obj.mergeModelData(workerCellModel);
            obj.mergeTrackData(workerCellTracks);

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
                % usedBranches = {};
                for i = 1:length(branches)
                    branch = branches{i};
                    combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesModel.(branch));
                    if ~isempty(combinedList)    % store only non-empty branches
                        % usedBranches{end+1} = branch;
                        newDataStruct.model.(branch).combinedList = combinedList;
                        newDataStruct.model.(branch).storedCategorizations = obj.combinedColumnDefinitionsModel.(branch);
                        newDataStruct.model.(branch).storedFilters = obj.combinedFilteringsModel.(branch);
                    end
                end
                % newDataStruct.model.branches = reshape(usedBranches, 1, []);

            end
            if ismember('tracks', obj.modalities)
                newDataStruct.tracks.combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesTracks);
                newDataStruct.tracks.storedCategorizations = obj.combinedColumnDefinitionsTracks;
                newDataStruct.tracks.storedFilters = obj.combinedFilteringsTracks;
            end
        end

        function updatedDataStruct = appendLoadedData(obj, existingDataStruct)
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
                            existingDataStruct.model.(branch).combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesModel.(branch));
                            existingDataStruct.model.(branch).storedCategorizations = [{existingDataStruct.model.(branch).storedCategorizations}; obj.combinedColumnDefinitionsModel.(branch)];
                            existingDataStruct.model.(branch).storedFilters = [{existingDataStruct.model.(branch).storedFilters}; obj.combinedFilteringsModel.(branch)];
                        else
                            existingDataStruct.model.(branch).combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesModel.(branch));
                            % existingDataStruct.model.branches{end+1} = branch;
                            existingDataStruct.model.(branch).storedCategorizations = obj.combinedColumnDefinitionsModel.(branch);
                            existingDataStruct.model.(branch).storedFilters = obj.combinedFilteringsModel.(branch);
                        end
                    end
                else
                    branches = fieldnames(obj.combinedTablesModel);
                    for i = 1:length(branches)
                        branch = branches{i};
                        existingDataStruct.model.(branch).combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesModel.(branch));
                        existingDataStruct.model.(branch).storedCategorizations = obj.combinedColumnDefinitionsModel;
                        existingDataStruct.model.(branch).storedFilters = obj.combinedFilteringsModel;
                    end
                    % existingDataStruct.model.branches = reshape(branches, 1, []);
                end
            end
            if ismember('tracks', obj.modalities)
                if isfield(existingDataStruct, 'tracks')
                    obj.combinedTablesTracks{end+1} = existingDataStruct.tracks.combinedList;
                    existingDataStruct.tracks.combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesTracks);
                    existingDataStruct.tracks.storedCategorizations = [{existingDataStruct.tracks.storedCategorizations}; obj.combinedColumnDefinitionsTracks];
                    existingDataStruct.tracks.storedFilters = [{existingDataStruct.tracks.storedFilters}; obj.combinedFilteringsTracks];
                else
                    existingDataStruct.tracks.combinedList = TableCombiner.mergeCombinedTables(obj.combinedTablesTracks);
                    existingDataStruct.tracks.storedCategorizations = obj.combinedColumnDefinitionsTracks;
                    existingDataStruct.tracks.storedFilters = obj.combinedFilteringsTracks;
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

        function [workerCellModel, workerCellTracks] = processFilesInParallel(obj)
            numFiles = length(obj.fileNamesAll);
            workerCellModel = cell(1, numFiles);
            workerCellTracks = cell(1, numFiles);

            pathNames = obj.pathNamesAll;   % added, because it was complaining about obj passing to parfor causing overhead
            fileNames = obj.fileNamesAll;

            parfor i = 1:numFiles
                filePath = fullfile(pathNames{i}, fileNames{i});
                matf = matfile(filePath);

                [tempStructModel, tempStructTracks] = obj.processSingleFile(matf, obj.fileNamesAll{i}, i);

                workerCellModel{i} = tempStructModel;
                workerCellTracks{i} = tempStructTracks;
            end
        end

        function [tempStructModel, tempStructTracks] = processSingleFile(obj, matf, fileName, fileIdx)
            tempStructModel = struct('tables', configureDictionary("string", "cell"), 'filterings', configureDictionary("string", "cell"), 'columnDefinitions', configureDictionary("string", "cell"));
            tempStructTracks = struct('tables', {}, 'filterings', {}, 'columnDefinitions', {});
            % tempCombinedTablesModel = configureDictionary("string", "cell");
            % tempCombinedTablesTracks = {};
            
            if ismember('model', obj.modalities) && isprop(matf, 'model')
                tempStructModel = obj.processModelData(matf, fileName, fileIdx);
            end
            
            if ismember('tracks', obj.modalities) && isprop(matf, 'tracks')
                tempStructTracks = obj.processTrackData(matf, fileName, fileIdx);
            end
        end

        function tempStructModel = processModelData(obj, matf, fileName, fileIdx)
            tempStructModel = struct();
            infoToLoad = matf.info;
            modelToLoad = matf.model;
            timelineToLoad = matf.timeline;
            % tempStructModel = struct('tables', {}, 'filterings', {}, 'columnDefinitions', {});
            combinedTablesModel = configureDictionary("string", "cell");
            filterings = configureDictionary("string", "cell");
            columnDefinitions = configureDictionary("string", "cell");

            for branch = string(modelToLoad.branches)
                if isfield(modelToLoad.(branch), 'List')
                    currentIndex = timelineToLoad.currentIndex.model.(branch);
                    %   where each index corresponds to a timepoint and value corresponds to the position of the timepoint in the List
                    if isequal(fileIdx, 0)  % makes sure that metadata are not added when loading from the app
                        cellList = modelToLoad.(branch).List;
                    else
                        cellList = obj.enrichTablesWithMetadata(modelToLoad.(branch).List, infoToLoad, fileName, fileIdx);
                    end
                    combinedTablesModel(branch) = {TableCombiner.combineAcrossTimepoints(cellList, currentIndex)};
                    if isfield(modelToLoad.(branch), 'storedFilters')
                        filterings(branch) = {modelToLoad.(branch).storedFilters};
                    else
                        filterings(branch) = {FilteringStorage()};
                    end
                    if isfield(modelToLoad.(branch), 'storedCategorizations')
                        columnDefinitions(branch) = {modelToLoad.(branch).storedCategorizations};
                    else
                        columnDefinitions(branch) = {CategorizationStorage()};
                    end
                end
            end

            tempStructModel.tables = combinedTablesModel;
            tempStructModel.filterings = filterings;
            tempStructModel.columnDefinitions = columnDefinitions;
        end

        function tempStruct = processTrackData(obj, matf, fileName, fileIdx)
            tempStruct = struct('tables', {}, 'filterings', {}, 'columnDefinitions', {});
            infoToLoad = matf.info;
            tracksToLoad = matf.tracks;
            timelineToLoad = matf.timeline;
            % tempStruct = {};


            if isfield(tracksToLoad, 'tracksList')
                currentIndex = timelineToLoad.currentIndex.tracks;
                if isequal(fileIdx, 0)  % makes sure that metadata are not added when loading from the app
                    cellList = tracksToLoad.tracksList;
                else
                    cellList = obj.enrichTablesWithMetadata(tracksToLoad.tracksList, infoToLoad, fileName, fileIdx);
                end
                tempStruct.tables = {TableCombiner.combineAcrossTimepoints(cellList, currentIndex)};
                if isfield(tracksToLoad, 'storedFilters')
                    filterings = {tracksToLoad.storedFilters};
                else
                    filterings = {FilteringStorage()};
                end
                if isfield(tracksToLoad, 'storedCategorizations')
                    columnDefinitions = {tracksToLoad.storedCategorizations};
                else
                    columnDefinitions = {CategorizationStorage()};
                end
                tempStruct.filterings = filterings;
                tempStruct.columnDefinitions = columnDefinitions;
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

        function mergeModelData(obj, workerCell)
            for i = 1:length(workerCell)
                tempCell = workerCell{i};
                if ~isempty(fieldnames(tempCell))
                    tableDict = tempCell.tables;
                    branches = keys(tableDict);
                    for j = 1:length(branches)
                        branch = string(branches{j});
                        if isfield(obj.combinedTablesModel, branch)
                            obj.combinedTablesModel.(branch) = [obj.combinedTablesModel.(branch); tableDict(branch)];
                            obj.combinedFilteringsModel.(branch) = [obj.combinedFilteringsModel.(branch); tempCell.filterings(branch)];
                            obj.combinedColumnDefinitionsModel.(branch) = [obj.combinedColumnDefinitionsModel.(branch); tempCell.columnDefinitions(branch)];
                        else
                            obj.combinedTablesModel.(branch) = tableDict(branch);
                            obj.combinedFilteringsModel.(branch) = tempCell.filterings(branch);
                            obj.combinedColumnDefinitionsModel.(branch) = tempCell.columnDefinitions(branch);
                        end
                    end
                end
            end
        end

        function mergeTrackData(obj, workerCell)
            for i = 1:length(workerCell)
                if ~isempty(workerCell{i})
                    obj.combinedTablesTracks = [obj.combinedTablesTracks, workerCell{i}.tables];
                    obj.combinedFilteringsTracks = [obj.combinedFilteringsTracks, workerCell{i}.filterings];
                    obj.combinedColumnDefinitionsTracks = [obj.combinedColumnDefinitionsTracks, workerCell{i}.columnDefinitions];
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
