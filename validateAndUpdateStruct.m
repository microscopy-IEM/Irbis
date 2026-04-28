function updatedStruct = validateAndUpdateStruct(loadedStruct, baseStruct,loadedIrbisVersion)

    %% Old Irbis versions
    if loadedIrbisVersion < 1.1
        presentRootFields = fieldnames(loadedStruct);

        % make sure that if MMPack is on top, the root is moved to the second level
        if isequal(presentRootFields,{"MMpack"})
            disp('there was just MMpack')
            loadedStruct = loadedStruct.MMpack;
            presentRootFields = fieldnames(loadedStruct);
        end

        emptyRootFields = {};
        for i = 1:length(presentRootFields)
            field = presentRootFields{i};
            loadedStruct.(field)
            if isempty(loadedStruct.(field))
                emptyRootFields{end+1} = field;
            elseif isstruct(loadedStruct.(field))
                if isempty(fieldnames(loadedStruct.(field)))
                    emptyRootFields{end+1} = field;
                end
            end
        end

        emptyRootFields

        % info 
        % include also other newly added fields
        if isfield(loadedStruct,'info')
            if ~isfield(loadedStruct.info,'path')
                if isfield(loadedStruct,'results')
                    if isfield(loadedStruct.results,'path')
                        loadedStruct.info.path = loadedStruct.results.path;
                    end
                end
            end
        
            if ~isfield(loadedStruct.info,'filename')
                disp('no filename in loadedStruct.info')
                if isfield(loadedStruct,'results')
                    disp(loadedStruct.results)
                    if isfield(loadedStruct.results,'fileName')
                        disp(['fileName: ' loadedStruct.results.fileName])
                        loadedStruct.info.filename = loadedStruct.results.fileName;
                    end
                end
            end
        end

        % planes
        if isfield(loadedStruct,'planes')
            % back-compatibility
            if isfield(loadedStruct.planes,'channel_names') && ~isfield(loadedStruct.planes,'channelNames')
                disp('there are channel_names but not channelNames')
                loadedStruct.planes.channelNames = loadedStruct.planes.channel_names;
            end
            % /back-compatibility

            loadedStruct.timeline.currentIndex.planes = 1:loadedStruct.planes.nTimePoints;
            loadedStruct.timeline.nTimePoints = loadedStruct.planes.nTimePoints;
        end

        % tracks
        if isfield(loadedStruct,'tracks')
            % back-compatibility
            if iscell(loadedStruct.tracks) % the old structure
                if ~isempty(loadedStruct.tracks)
                    % Get the number of time points
                    numTimePoints = numel(loadedStruct.tracks);
                    
                    % List all variables (assuming all time points have the same structure)
                    fieldNames = fieldnames(loadedStruct.tracks{1});
                    
                    % Initialize the new structure to hold variables across time points
                    cellTracks = loadedStruct.tracks;
                    loadedStruct.tracks = struct();
                    for i = 1:numel(fieldNames)
                        loadedStruct.tracks.(fieldNames{i}) = cell(1, numTimePoints);
                    end
                    
                    % Fill the new structure with the reorganized data
                    for t = 1:numTimePoints
                        for i = 1:numel(fieldNames)
                            variableName = fieldNames{i};
                            loadedStruct.tracks.(variableName){t} = cellTracks{t}.(variableName);
                        end
                    end
                end
                % /back-compatibility
            end

            % back-compatibility
            if ~isfield(loadedStruct.tracks,'tracksList')
                % this is for when there was only loadedStruct.tracks.timePointPresent - generated in planes
                loadedStruct = rmfield(loadedStruct,'tracks');
            else
            % /back-compatibility   
                % back-compatibility
                if isfield(loadedStruct.tracks,'filterRanges')
                    if ~isfield(loadedStruct.tracks,'storedFilters')
                        loadedStruct.tracks.storedFilters = FilteringStorage();
                    end
                    % convert the old filter storage to the new version
                    if ~isempty(loadedStruct.tracks.filterRanges)
                        columnNames = fieldnames(loadedStruct.tracks.filterRanges);
                        storedFilterNames = loadedStruct.tracks.storedFilters.returnGroupingNames;
                        for i = 1:numel(columnNames)
                            columnName = columnNames{i};
                            range = loadedStruct.tracks.filterRanges.(columnName);
        
                            if ismember(columnName,storedFilterNames)
                                loadedStruct.tracks.storedFilters.deleteGrouping(columnName);
                            end
                            loadedStruct.tracks.storedFilters.addRangeFilter(columnName,range);
                        end
                    end
                    loadedStruct.tracks = rmfield(loadedStruct.tracks,'filterRanges');
                end
        
                if isfield(loadedStruct.tracks,'groupThresholds')
                    loadedStruct.tracks = createCategorizationsFromThresholds(loadedStruct.tracks);
                end
                % /back-compatibility
        
                % check missing positions in tracks and remove them
                isValid = cellfun(@(x) istable(x), loadedStruct.tracks.tracksList);
        
                if any(isValid == false)
                    % Get the field names of the tracks structure
                    trackFields = fieldnames(loadedStruct.tracks);
                    
                    % Loop through each field
                    for i = 1:length(trackFields)
                        field = trackFields{i};
                        % Check if the field is a cell array
                        if iscell(loadedStruct.tracks.(field))
                            % Filter the cell array based on valid positions
                            loadedStruct.tracks.(field) = loadedStruct.tracks.(field)(isValid);
                        end
                    end 
                end
                    
                planesPresent = 0;
                if isfield(loadedStruct,'planes')
                    if ~isempty(loadedStruct.planes)
                        prep = zeros(1,loadedStruct.planes.nTimePoints);
                        planesPresent = 1;
                    end
                end
                if ~planesPresent
                    prep = zeros(1,numel(isValid));
                end
                prep(isValid) = 1:sum(isValid);
                loadedStruct.timeline.currentIndex.tracks = prep;

                for tp = 1:numel(loadedStruct.timeline.currentIndex.tracks)
                    tracksId = loadedStruct.timeline.currentIndex.tracks(tp);
                    if ~isequal(tracksId,0)
                        List = loadedStruct.tracks.tracksList{tracksId};
                        if istable(List)
                            if ~ismember('timePoint',List.Properties.VariableNames)
                                loadedStruct.tracks.tracksList{tracksId}.timePoint = categorical(repmat(tp,height(List),1));
                            end
                        end
                    end
                end
            end
        end

        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                if isfield(loadedStruct.model,'timeDrift')
                    loadedStruct.model.timeDrift = cell2mat(loadedStruct.model.timeDrift');
                end
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
        
                    % add positionShift column to the tables if missing
                    disp('there was positionShift missing in a model table')
                    for timePoint = 1:numel(loadedStruct.model.(branch).List)
                        List = loadedStruct.model.(branch).List{timePoint};
                        variableNames = string(List.Properties.VariableNames);
                        if ~ismember('positionShift',variableNames)
                            tableHeight = height(List);
                            loadedStruct.model.(branch).List{timePoint}.positionShift = repmat({[0,0,0]}, tableHeight, 1);
                        end
                    end
        
                    % remove missing fields and adjust currentIndexes
                    % check missing positions in tracks and remove them
                    isValid = cellfun(@(x) ~isempty(x), loadedStruct.model.(branch).List);
            
                    if any(isValid == false)
                        % Get the field names of the tracks structure
                        modelFields = fieldnames(loadedStruct.model.(branch));
                        
                        % Loop through each field
                        for i = 1:length(modelFields)
                            field = modelFields{i};
                            % Check if the field is a cell array
                            if iscell(loadedStruct.model.(branch).(field))
                                % Filter the cell array based on valid positions
                                loadedStruct.model.(branch).(field) = loadedStruct.model.(branch).(field)(isValid);
                            end
                        end 
                    end
                        
                    planesPresent = 0;
                    if isfield(loadedStruct,'planes')
                        if ~isempty(loadedStruct.planes)
                            prep = zeros(1,loadedStruct.planes.nTimePoints);
                            planesPresent = 1;
                        end
                    end
                    if ~planesPresent
                        prep = zeros(1,numel(isValid));
                    end
                    prep(isValid) = 1:sum(isValid);
                    loadedStruct.timeline.currentIndex.model.(branch) = prep;
                end
            end
        end

        assignin('base','loadedStruct',loadedStruct)

        loadedStruct = unifyStruct(loadedStruct,baseStruct);

        % Remove loadable modalities if they are not present in the loadedStruct at the beginning
        loadableStructs = {'planes','tracks','points','model'};
        for i = 1:length(loadableStructs)
            field = loadableStructs{i};
            if ismember(field,emptyRootFields)
                field
                loadedStruct = rmfield(loadedStruct, field);
            end
        end
    end

    if loadedIrbisVersion < 1.11 && loadedIrbisVersion >= 1.1
        if ~isfield('tools',loadedStruct.timeline.currentIndex)
            loadedStruct.timeline.currentIndex.tools.areas = [];
        end
    end

    %% Irbis version 1.11 changes
    if loadedIrbisVersion < 1.12
        % newer changes
        % added the info.dish and info.experimentDate fields
        if isfield(loadedStruct,'info')
            if ~isfield(loadedStruct.info,'experimentDate')
                loadedStruct.info.experimentDate = NaT;
            end
            if ~isfield(loadedStruct.info,'dish')
                loadedStruct.info.dish = NaN;
            end
        end

        % adding column 'color' to the table 
        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
        
                    % add positionShift column to the tables if missing
                    % branchColor = loadedStruct.model.(branch).Color;
                    for timePoint = 1:numel(loadedStruct.model.(branch).List)
                        List = loadedStruct.model.(branch).List{timePoint};
                        if istable(List)
                            variableNames = string(List.Properties.VariableNames);
                            if ~ismember('color',variableNames)
                                tableHeight = height(List);
                                loadedStruct.model.(branch).List{timePoint}.color = mat2cell(rand(tableHeight,3), ones(tableHeight, 1), 3); % repmat({branchColor}, tableHeight, 1);
                            end
                        end
                    end
                end
            end
        end

        % older changes
        if isfield(loadedStruct,'tools')
            if isfield(loadedStruct.tools,'areas')
                if isfield(loadedStruct.tools.areas,'list')
                    loadedStruct.tools.areas.List{1} = loadedStruct.tools.areas.list;
                    loadedStruct.tools.areas = rmfield(loadedStruct.tools.areas,'list');
                    if ~isempty(loadedStruct.tools.areas.List{1})
                        loadedStruct.timeline.currentIndex.tools.areas = 1;
                    end
                end
            end
        end
    end

    if loadedIrbisVersion < 1.13
        % adding column 'excluded' to the table 
        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
        
                    for timePoint = 1:numel(loadedStruct.model.(branch).List)
                        List = loadedStruct.model.(branch).List{timePoint};
                        if istable(List)
                            variableNames = string(List.Properties.VariableNames);
                            if ~ismember('excluded',variableNames)
                                tableHeight = height(List);
                                loadedStruct.model.(branch).List{timePoint}.excluded = false(tableHeight, 1);
                            end
                        end
                    end
                end
            end
        end
    end

    if loadedIrbisVersion < 1.14
        % adding summarizedStorageClass - needed for ResultsViewer
        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
                    loadedStruct.model.(branch).storedSummarizedTables = SummarizedTableStorageClass();
                end
            end
        end

        if isfield(loadedStruct,'tracks')
            if ~isempty(loadedStruct.tracks)
                loadedStruct.tracks.storedSummarizedTables = SummarizedTableStorageClass();
            end
        end

        if isfield(loadedStruct,'points')
            if ~isempty(loadedStruct.points)
                loadedStruct.points.storedSummarizedTables = SummarizedTableStorageClass();
            end
        end
    end

    if loadedIrbisVersion < 1.15
        % adding column 'excluded' to the tracks and points table 
        existingTimePoints = string(1:loadedStruct.timeline.nTimePoints);
        if isfield(loadedStruct,'tracks')
            if ~isempty(loadedStruct.tracks)
                for idx = 1:numel(loadedStruct.tracks.tracksList)
                    List = loadedStruct.tracks.tracksList{idx};
                    if istable(List)
                        % Add 'excluded' column if it does not exist
                        variableNames = string(List.Properties.VariableNames);
                        if ~ismember('excluded',variableNames)
                            tableHeight = height(List);
                            loadedStruct.tracks.tracksList{idx}.excluded = false(tableHeight, 1);
                        end

                        % Add 'timePoint' column if it does not exist
                        if ~ismember('timePoint',variableNames)
                            timePoint = {num2str(loadedStruct.timeline.currentIndex.tracks(idx))}
                            loadedStruct.tracks.tracksList{idx}.timePoint = categorical(repmat(timePoint,height(List),1), existingTimePoints);
                        end
                    end
                end
            end
        end 

        if isfield(loadedStruct,'points')
            if ~isempty(loadedStruct.points)
                for idx = 1:numel(loadedStruct.points.pointsList)
                    List = loadedStruct.points.pointsList{idx};
                    if istable(List)
                        variableNames = string(List.Properties.VariableNames);
                        % Add 'excluded' column if it does not exist
                        if ~ismember('excluded',variableNames)
                            tableHeight = height(List);
                            loadedStruct.points.pointsList{idx}.excluded = false(tableHeight, 1);
                        end

                        % Add 'timePoint' column if it does not exist
                        if ~ismember('timePoint',variableNames)
                            timePoint = {num2str(loadedStruct.timeline.currentIndex.points(idx))}
                            loadedStruct.points.pointsList{idx}.timePoint = categorical(repmat(timePoint,height(List),1), existingTimePoints);
                        end
                    end
                end
            end
        end

        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
        
                    for idx = 1:numel(loadedStruct.model.(branch).List)
                        List = loadedStruct.model.(branch).List{idx};
                        if istable(List)
                            variableNames = string(List.Properties.VariableNames);
                            % Add 'timePoint' column if it does not exist
                            if ~ismember('timePoint',variableNames)
                                timePoint = {num2str(loadedStruct.timeline.currentIndex.model.(branch)(idx))}
                                loadedStruct.model.(branch).List{idx}.timePoint = categorical(repmat(timePoint,height(List),1), existingTimePoints);
                            end
                        end
                    end
                end
            end
        end
    end

    if loadedIrbisVersion < 1.16
        % delete prevTPid column from model tables if it exists - it is not needed anymore
        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
        
                    for idx = 1:numel(loadedStruct.model.(branch).List)
                        List = loadedStruct.model.(branch).List{idx};
                        if istable(List)
                            variableNames = string(List.Properties.VariableNames);
                            % Remove 'prevTPid' column if it does exist
                            if ismember('prevTPid', variableNames)
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'prevTPid');
                            end

                            % Remove 'nextTPid' column if it does exist
                            if ismember('nextTPid', variableNames)
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'nextTPid');
                            end

                            % Remove 'Points' column if it does exist - it was usually just storing vertices from Mesh
                            if ismember('Points', variableNames)
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'Points');
                            end

                            % Convert 'name' column to 'parentId' - remove S at the beginning and convert to number
                            if ismember('name', variableNames) && ~ismember('parentId', variableNames)
                                nameData = loadedStruct.model.(branch).List{idx}.name;
                                parentIdData = str2double(erase(nameData,'S'));
                                loadedStruct.model.(branch).List{idx}.parentId = parentIdData;
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'name');
                            end

                            % Rename 'cuttingPlaneCentre' to 'basePoint' if 'cuttingPlaneCentre' exists and 'basePoint' does not exist
                            % This variable should exist only in the 'spines' table
                            if ismember('cuttingPlaneCentre', variableNames) && ~ismember('basePoint', variableNames)
                                loadedStruct.model.(branch).List{idx}.basePoint = loadedStruct.model.(branch).List{idx}.cuttingPlaneCentre;
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'cuttingPlaneCentre');
                            end

                            % Rename 'cuttingPlaneNormal' to 'basePointNormal' if 'cuttingPlaneNormal' exists and 'basePointNormal' does not exist
                            if ismember('cuttingPlaneNormal', variableNames) && ~ismember('basePointNormal', variableNames)
                                loadedStruct.model.(branch).List{idx}.basePointNormal = loadedStruct.model.(branch).List{idx}.cuttingPlaneNormal;
                                loadedStruct.model.(branch).List{idx} = removevars(loadedStruct.model.(branch).List{idx},'cuttingPlaneNormal');
                            end
                        end
                    end
                end
            end
        end 
    end

    if loadedIrbisVersion < 1.17
        % reorganization of the reconstruction parameters 
        if isfield(loadedStruct,'model')
            if ~isempty(loadedStruct.model)
                branches = loadedStruct.model.branches;
                primaryBranches = {'fullVolume','synapses'};
                fieldsToTransfer = {'bleachCompensation', 'channel', 'minVertexNum', 'scaleFactor','zScaleFactor'};

                uPAINTdata = false;
                % check if there is a reconstruction of fullVolume - if not, those are most likely data for the uPAINT, where synapses were generated differently
                if ismember('fullVolume', branches) && all(cellfun(@(x) isempty(x), loadedStruct.model.fullVolume.List))
                    disp('there is no fullVolume reconstruction, likely uPAINT data - skipping reorganization of the reconstruction parameters')
                    uPAINTdata = true;
                end
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
                    if ismember(branch, primaryBranches)
                        if uPAINTdata && isequal(branch, 'synapses')
                                loadedStruct.model.(branch).reconstructionMethod = 'localMaxima';
                        else
                            loadedStruct.model.(branch).reconstructionMethod = 'isosurface';
                            nTimePoints = loadedStruct.timeline.nTimePoints;
                            for timePoint = 1:nTimePoints
                                modelId = loadedStruct.timeline.currentIndex.model.(branch)(timePoint);
                                if ~isequal(modelId, 0)
                                    loadedStruct.model.(branch).reconstructionParameters{modelId} = IsosurfaceGenerator.getDefaultParameters();
                                    for i = 1:numel(fieldsToTransfer)
                                        field = fieldsToTransfer{i};
                                        if isfield(loadedStruct.model.(branch), field)
                                            loadedStruct.model.(branch).reconstructionParameters{modelId}.(field) = loadedStruct.model.(branch).(field);
                                        end
                                        if isfield(loadedStruct.model.(branch), 'threshold')
                                            loadedStruct.model.(branch).reconstructionParameters{modelId}.thresholds = loadedStruct.model.(branch).threshold;
                                            loadedStruct.model.(branch).reconstructionParameters{modelId}.threshold = loadedStruct.model.(branch).threshold(timePoint);
                                        end
                                    end
                                    % used parameters that were not stored in the old version of parameters
                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.simplificationOn = true;
                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.simplificationMethod = 'quadric-decimation'; 
                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.simplificationTargetReduction = 0.2;
                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.simplificationMaxError = inf;  
                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.simplificationBoundaryWeight = 1;

                                    loadedStruct.model.(branch).reconstructionParameters{modelId}.smoothingOn = false;
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    % change the Irbis version - CHANGE FOR THE NEWEST
    % getBaseStruct('irbisVersion')
    disp(['new irbis version = ' num2str(getBaseStruct('irbisVersion'))])
    % disp(getBaseStruct('irbisVersion'))
    loadedStruct.info.irbisVersion = getBaseStruct('irbisVersion');
    updatedStruct = loadedStruct;

    % assignin("base", "updatedStruct", updatedStruct);

end



function loadedStruct = unifyStruct(loadedStruct,baseStruct)
    % Add missing fields from baseStruct to loadedStruct
    baseFields = fieldnames(baseStruct);
    for i = 1:length(baseFields)
        field = baseFields{i};
        if ~isfield(loadedStruct, field)
            disp([field '    missing in:'])
            disp(loadedStruct)
            loadedStruct.(field) = baseStruct.(field);
        elseif isstruct(baseStruct.(field)) && isstruct(loadedStruct.(field))
            % Recursively validate and update sub-structures
            loadedStruct.(field) = unifyStruct(loadedStruct.(field), baseStruct.(field));
        end
    end

    % Remove extra fields from loadedStruct that are not in baseStruct
    loadedFields = fieldnames(loadedStruct);
    for i = 1:length(loadedFields)
        field = loadedFields{i};
        if ~isfield(baseStruct, field)
            disp([field '    surplus in:'])
            disp(loadedStruct)
            loadedStruct = rmfield(loadedStruct, field);
        end
    end

end



function tracks = createCategorizationsFromThresholds(tracks)
    % back-compatibility function

    % Initialize the CategorizationStorage if it does not exist
    if ~isfield(tracks, 'storedCategorizations') || isempty(tracks.storedCategorizations)
        tracks.storedCategorizations = CategorizationStorage();
    else
        % Check whether the column names in storedCategorizations correspond to groupThresholds
        storedCategorizationNames = tracks.storedCategorizations.returnCategorizationNames;
        groupThresholdFields = fieldnames(tracks.groupThresholds);
        groupThresholdNames = cellfun(@(x) [x, 'Groups'], groupThresholdFields, 'UniformOutput', false);

        if all(ismember(groupThresholdNames,storedCategorizationNames))
            tracks = rmfield(tracks,"groupThresholds");
            return
        end

    end

    % Iterate over each column in groupThresholds
    groupThresholdFields = fieldnames(tracks.groupThresholds);
    for i = 1:numel(groupThresholdFields)
        columnName = groupThresholdFields{i};
        thresholds = tracks.groupThresholds.(columnName);
        
        % Determine group names from the categorical column
        tracksList = tracks.tracksList{1};
        if ismember([columnName 'Groups'], tracksList.Properties.VariableNames)
            categoriesInColumn = categories(tracksList.([columnName 'Groups']));
        else
            error('Categorical column %sGroups not found in tracksList.', columnName);
        end

        % Create conditions dictionary
        conditions = struct();
        for j = 1:length(thresholds) + 1
            groupName = categoriesInColumn{j};
            groupConditions = dictionary();

            if j == 1
                % Handle values less than the first threshold
                operatorValueDict = dictionary('lessThan', thresholds(1));
            elseif j == length(thresholds) + 1
                % Handle values greater than or equal to the last threshold
                operatorValueDict = dictionary('greaterThan', thresholds(end));
            else
                % Values between current and previous threshold
                operatorValueDict = dictionary(...
                    'greaterThan', thresholds(j-1), ...
                    'lessThan', thresholds(j));
            end

            groupConditions(columnName) = {operatorValueDict};
            conditions.(['group' num2str(j-1)]) = struct('name', groupName, 'conditions', groupConditions);
        end

        % Create the Categorization object
        categorizationName = [columnName 'Groups'];
        categorizationObj = Categorization(categorizationName, conditions);

        % Add the Categorization object to the CategorizationStorage
        tracks.storedCategorizations.addCategorization(categorizationObj);
    end
    tracks = rmfield(tracks,"groupThresholds");
end
