classdef (Sealed) AppStateManager < handle
    % AppStateManager - Manages application state and modality data
    %
    % Data Structure:
    %   availableModalities - Cell array of strings containing modality names
    %   availableBranches - Cell array where each element corresponds to a modality
    %                      at the same index in availableModalities. Each element is
    %                      itself a cell array of branch names for that modality.
    %                      For example:
    %                      availableModalities = {'model', 'tracks'}
    %                      availableBranches = {{'branch1', 'branch2'}, {}}
    %                      This means 'model' has two branches, while 'tracks' has none.

    properties (Access = ?matlab.unittest.TestCase) % Test case can access these properties, otherwise private
        appHandle
        
        modality char = ''  % active modality
        branch char = ''  % active branch
        availableModalities cell = {}
        availableBranches cell = {}

        modalityDataStoreHandle     % Holds DataStore objects for each modality/branch
        activeDataStoreHandle    % Current active DataStore

        tableType string = "Full"  % type of the table (Full, Pivoted, Summarized)

        topTableStateManagerHandle
        bottomTableStateManagerHandle

        multitableSynchronizer

        filteringMenuStateManagerHandle

        columnDefinitionBridge  % Bridge for syncing user column definitions between the app and ResultsViewer
    end

    events
        availableModalitiesChanged  % implicitly counts with the fact that branches are also changed
        availableBranchesChanged    % this needs to be called when modality changes, as each modality has its own branches
        modalityChangedProgrammatically  % called when active modality and branch are set programmatically (eg by applying a stored view)
        newModalityLoaded
        tableTypeChanged
    end

    methods (Access = public)
        function obj = AppStateManager(appHandle)
            obj.appHandle = appHandle;

            % instantiate the modalityDataStoreHandle for storing DataStore objects
            obj.modalityDataStoreHandle = ModalityDataStore();
            
            % Set default empty objects
            obj.activeDataStoreHandle = DataStore();    % TO OPTIMIZE - DataStore has arguments and sets properties in constructor

            obj.registerListeners();
        end


        function delete(obj)
            % Destructor for AppStateManager
            % Clean up listeners and handles
            if ~isempty(obj.columnDefinitionBridge) && isvalid(obj.columnDefinitionBridge)
                delete(obj.columnDefinitionBridge);
            end
        end


        function registerListeners(obj)       % TO OPTIMIZE - it might be safer not to register listeners from the constructor, as the object is not yet fully finished
            addlistener(obj.appHandle, 'modalityChangedByUser', @(~,~) obj.changeModalityForUserSelected());
            addlistener(obj.appHandle, 'branchChangedByUser', @(~,~) obj.changeBranchForUserSelected());
        end


        function availableModalities = getAvailableModalities(obj)
            availableModalities = obj.availableModalities;
        end


        function availableBranches = getAvailableBranches(obj, modality)
            assert(any(ismember(obj.availableModalities, modality)), 'Modality does not exist: %s', modality);
            % get the id of the modality
            correspondsToModality = ismember(obj.availableModalities, modality);
            availableBranches = obj.availableBranches{correspondsToModality};
        end


        function activeModality = getActiveModality(obj)
            % get the active modality from the app state manager
            activeModality = obj.modality;
        end


        function activeBranch = getActiveBranch(obj)
            % get the active branch from the app state manager
            activeBranch = obj.branch;
        end


        function generateTopTableStateManager(obj)
            % Generate the top table state manager
            gridLayoutRowNum = 1;
            obj.topTableStateManagerHandle = TableStateManager(obj, obj.appHandle, obj.activeDataStoreHandle, obj.tableType, gridLayoutRowNum);
        end


        function generateBottomTableStateManager(obj, tableType)
            % Generate the bottom table state manager
            gridLayoutRowNum = 2;
            obj.bottomTableStateManagerHandle = TableStateManager(obj, obj.appHandle, obj.activeDataStoreHandle, tableType, gridLayoutRowNum);
        end


        function changeTopTableType(obj, newTableType)
            % Change the table type of the top table state manager
            obj.tableType = newTableType;
            if isa(obj.topTableStateManagerHandle, 'TableStateManager') && isvalid(obj.topTableStateManagerHandle)
                % disp('AppStateManager: changeTopTableType - Changing table type.');
                obj.topTableStateManagerHandle.changeTableType(newTableType);
            else
                % disp('AppStateManager: changeTopTableType - Generating new top table state manager.');
                obj.generateTopTableStateManager();
            end

            % disp('notifying tableTypeChanged');
            notify(obj, 'tableTypeChanged'); % Notify that the table type has changed

            obj.generateFilteringMenuStateManager();
        end


        function changeBottomTableType(obj, newTableType)
            % Change the table type of the bottom table state manager
            if isa(obj.bottomTableStateManagerHandle, 'TableStateManager') && isvalid(obj.bottomTableStateManagerHandle)
                % disp('AppStateManager: changeBottomTableType - Changing table type.');
                obj.bottomTableStateManagerHandle.changeTableType(newTableType);
            else
                % disp('AppStateManager: changeBottomTableType - Generating new bottom table state manager.');
                obj.generateBottomTableStateManager();
            end
            notify(obj, 'tableTypeChanged'); % Notify that the table type has changed

            obj.generateFilteringMenuStateManager();
        end


        function generateFilteringMenuStateManager(obj)
            [processorHandles, tableTypes] = obj.getTableProcessorHandles();
            if any(strcmp(tableTypes, 'Summarized'))
                summarizedIndex = find(strcmp(tableTypes, 'Summarized'), 1);
                processorHandle = processorHandles{summarizedIndex};
                usedTableType = 'Summarized';       % named as usedTableType instead of just tableType, because tableType is a property
            else
                processorHandle = processorHandles{1};
                usedTableType = obj.tableType;
            end

            % I need to delete the filtering menu state manager if it already exists
            if isa(obj.filteringMenuStateManagerHandle, 'FilteringMenuStateManager') && isvalid(obj.filteringMenuStateManagerHandle)
                delete(obj.filteringMenuStateManagerHandle);
            end

            obj.filteringMenuStateManagerHandle = FilteringMenuStateManager(obj, obj.appHandle, obj.activeDataStoreHandle, ...
                usedTableType, processorHandle);
        end


        function [processorHandles, tableTypes] = getTableProcessorHandles(obj)

            processorHandles = {};
            tableTypes = {};

            if isa(obj.topTableStateManagerHandle, 'TableStateManager') && isvalid(obj.topTableStateManagerHandle)
                localTableType = obj.topTableStateManagerHandle.getTableType();
                tableTypes{end + 1} = localTableType;
                processorHandle = obj.topTableStateManagerHandle.getTableProcessorHandle();
                processorHandles{end + 1} = processorHandle;
            end

            if isa(obj.bottomTableStateManagerHandle, 'TableStateManager') && isvalid(obj.bottomTableStateManagerHandle)
                localTableType = obj.bottomTableStateManagerHandle.getTableType();
                tableTypes{end + 1} = localTableType;
                processorHandle = obj.bottomTableStateManagerHandle.getTableProcessorHandle();
                processorHandles{end + 1} = processorHandle;
            end
        end


        function isShown = showSummarizedAndIndicateSuccess(obj)

            isShown = false;

            if isa(obj.topTableStateManagerHandle, 'TableStateManager') && isvalid(obj.topTableStateManagerHandle)
                topTableType = obj.topTableStateManagerHandle.getTableType();
                topProcessorHandle = obj.topTableStateManagerHandle.getTableProcessorHandle();
            else
                % disp('something did not work')
            end

            if ~isequal(topTableType, 'Pivoted')
                % disp('not pivoted')
                return
            end

            [name, type] = topProcessorHandle.getRowParameterNameAndType();
            if ~isequal(type, 'categorical')
                % disp('not categorical')
                return
            end	

            obj.generateBottomTableStateManager('Summarized');
            bottomProcessorHandle = obj.bottomTableStateManagerHandle.getTableProcessorHandle();

            obj.multitableSynchronizer = MultitableSynchronizer(name, topProcessorHandle, bottomProcessorHandle);
            isShown = true;

            obj.generateFilteringMenuStateManager();

            notify(obj, 'tableTypeChanged')
        end

        
        function destroySummarized(obj)
            if isa(obj.bottomTableStateManagerHandle, 'handle') && isvalid(obj.bottomTableStateManagerHandle)
                delete(obj.bottomTableStateManagerHandle)
            end

            % destroy also the multitable synchronizer, so that the outdated ones are not getting accummulated
            if isa(obj.multitableSynchronizer, 'MultitableSynchronizer') && isvalid(obj.multitableSynchronizer)
                delete(obj.multitableSynchronizer);
            end

            obj.generateFilteringMenuStateManager();

            notify(obj, 'tableTypeChanged')
        end


        function storeLoadedData(obj, batchLoaderHandle)
            % Store data loaded via BatchLoader

            % TO OPTIMIZE - if tracks are loaded and I add model, the tracks are not deleted 
            newDataStruct = batchLoaderHandle.storeLoadedData();
            
            obj.storeDataFromStruct(newDataStruct);
        end


        function storeDataFromStruct(obj, structToLoad)
            % assignin("base", "structToLoad", structToLoad); % for debugging purposes

            obj.loadData(structToLoad);
            
            % Set initial modality and branch if not set
            if (isempty(obj.modality) || isequal(strlength(obj.modality), 0)) && ~isempty(obj.availableModalities)
                obj.modality = obj.availableModalities{1};
                if ~isempty(obj.availableBranches{1})
                    obj.branch = obj.availableBranches{1}{1};
                end
            else
                disp('AppStateManager: storeLoadedData - Modality and branch already set.');
            end
            obj.getAndStoreActiveData();
        end

        
        function appendLoadedData(obj, batchLoaderHandle)
            % Add new data to existing data store
            existingDataStruct = struct();
            modalityPaths = obj.modalityDataStoreHandle.getAvailableModalityPaths();

            if isempty(modalityPaths)
                % If there are no existing modalities, simply store the new data
                obj.storeDataFromStruct(batchLoaderHandle.storeLoadedData());
                return
            end
            
            for i = 1:length(modalityPaths)
                currentPath = modalityPaths{i};
                currentDataStore = obj.modalityDataStoreHandle.getModalityData(currentPath);
                
                % Extract the table from the DataStore
                currentTableStore = currentDataStore.getTableStore();
                currentFilteringStorage = currentDataStore.getFilteringStorage();
                currentData = struct('combinedList', currentTableStore.getTableData());
                
                if length(currentPath) == 2
                    if ~isfield(existingDataStruct, 'model')
                        existingDataStruct.model = struct();
                    end
                    existingDataStruct.model.(currentPath{2}) = currentData;
                    existingDataStruct.model.(currentPath{2}).storedFilters = currentFilteringStorage;
                    existingDataStruct.model.(currentPath{2}).storedCategorizations = CategorizationStorage();  % TO OPTIMIZE - this will be replaced

                elseif strcmp(currentPath{1}, 'tracks')
                    existingDataStruct.tracks = currentData;
                    existingDataStruct.tracks.storedFilters = currentFilteringStorage;
                    existingDataStruct.tracks.storedCategorizations = CategorizationStorage(); % TO OPTIMIZE - this will be replaced
                end
            end
            
            updatedDataStruct = batchLoaderHandle.appendLoadedData(existingDataStruct);
            obj.loadData(updatedDataStruct);
        end


        function storeModalityDataStore(obj, modalityDataStoreHandle)
            obj.modalityDataStoreHandle = modalityDataStoreHandle;

            % Store the info about the available modalities and branches
            availablePaths = obj.modalityDataStoreHandle.getAvailableModalityPaths();
            for i = 1:length(availablePaths)
                path = availablePaths{i};
                obj.addModalityPath(path);
            end
            obj.setInitialModality();  % Set the initial modality and branch if not set
            notify(obj, 'availableModalitiesChanged');
        end


        function modalityDataStoreHandle = getModalityDataStore(obj)
            modalityDataStoreHandle = obj.modalityDataStoreHandle;
        end


        function dataStoreHandle = getActiveDataStore(obj)
            dataStoreHandle = obj.activeDataStoreHandle;
        end


        function state = getState(obj)
            % Get the current state of the AppStateManager
            state = struct();
            state.modality = obj.modality;
            state.branch = obj.branch;
            [processorHandles, tableTypes] = obj.getTableProcessorHandles();
            if ~isempty(processorHandles)
                state.topTable.type = tableTypes{1};
                state.topTable.processorState = processorHandles{1}.getState();

                if length(processorHandles) > 1
                    state.bottomTable.type = tableTypes{2};
                    state.bottomTable.processorState = processorHandles{2}.getState();
                end
            end
        end


        function setState(obj, state)
            obj.modality = state.modality;
            obj.branch = state.branch;

            try
                obj.getAndStoreActiveDataWithoutNotification(); % otherwise, the changes are happening multiple times
            catch ME
                if strcmp(ME.identifier, 'AppStateManager:InvalidModalityPath')
                    % this will happen if the modality used in the view state is not available in the current data
                    newME = MException('AppStateManager:InvalidState', ME.message);
                    throw(newME);
                else
                    rethrow(ME);
                end
            end

            notify(obj, 'modalityChangedProgrammatically');

            % TO OPTIMIZE - table type changes even if not needed

            if isfield(state, 'topTable')
                if isfield(state.topTable, 'type')
                    obj.topTableStateManagerHandle.silentlyLoadNewDataStore();  % load data store before the components are swapped
                    obj.changeTopTableType(state.topTable.type);
                        % this notifies PlotManager about change in tableProcessor
                end
                if isfield(state.topTable, 'processorState')
                    try
                        obj.topTableStateManagerHandle.setState(state.topTable.processorState);
                    catch ME
                        if strcmp(ME.identifier, 'TableStateManager:InvalidState')
                            newME = MException('AppStateManager:InvalidState', ME.message);
                            throw(newME);
                        else
                            rethrow(ME);
                        end
                    end
                end
            end

            if isfield(state, 'bottomTable')
                if isfield(state.bottomTable, 'type')
                    obj.showSummarizedAndIndicateSuccess();
                end
                if isfield(state.bottomTable, 'processorState')
                    try
                        obj.bottomTableStateManagerHandle.setState(state.bottomTable.processorState);
                    catch ME
                        if strcmp(ME.identifier, 'TableStateManager:InvalidState')
                            newME = MException('AppStateManager:InvalidState', ME.message);
                            throw(newME);
                        else
                            rethrow(ME);
                        end
                    end
                end
            end

            % obj.generateFilteringMenuStateManager();  % this is not needed, as it is already done in the changeTableType method

            % notify(obj, 'newModalityLoaded');   % added to ensure proper setup of the plotManager
        end



        function establishBridgeForColumnDefinitions(obj, mainAppHandle)
            % Establish a bridge for column definitions between the app and ResultsViewer
            % This allows the app to listen to changes in column definitions (and vice versa - TO IMPLEMENT)

            obj.columnDefinitionBridge = ColumnDefinitionBridge(obj.modalityDataStoreHandle, mainAppHandle);
        end



        function burnBridgeForColumnDefinitions(obj)
            % Burn the bridge for column definitions
            % This is used when batch loading data, which causes the connection with main app to be lost
            if ~isempty(obj.columnDefinitionBridge) && isvalid(obj.columnDefinitionBridge)
                delete(obj.columnDefinitionBridge);
                obj.columnDefinitionBridge = [];
            end
        end
    end




    methods (Access = ?matlab.unittest.TestCase)
        function changeModalityForUserSelected(obj)

            newModality = obj.appHandle.getActiveModality();
            obj.modality = newModality;

            % Find the branches for the new modality
            modalityIdx = find(strcmp(obj.availableModalities, newModality));
            if ~isempty(modalityIdx) && ~isempty(obj.availableBranches{modalityIdx})
                % Set the first available branch for this modality
                obj.branch = obj.availableBranches{modalityIdx}{1};
            else
                % If no branches available, set empty branch
                obj.branch = '';
            end
            % if modality changes, it automatically also changes the branch (as the branches are specific to the modality)

            obj.getAndStoreActiveData();

            % changing modality leads to change in the branch as well, so notify that the branches have changed
            notify(obj, 'availableBranchesChanged');    % the app needs to listen to this event to update the UI
        end



        function changeBranchForUserSelected(obj)
            newBranch = obj.appHandle.getActiveBranch();
            obj.branch = newBranch;

            obj.getAndStoreActiveData();

            % at the moment, app does not need to be notified (no changes in the UI), and the rest is notified via getAndStoreActiveData by newModalityLoaded event
        end



        function loadData(obj, newDataStruct)
            % Handle data loading from the main app

            % assignin("base", "newDataStruct", newDataStruct); % for debugging purposes
            if isfield(newDataStruct, 'model')
                branches = fieldnames(newDataStruct.model);
                for i = 1:length(branches)
                    currentBranch = branches{i};
                    modalityPath = {'model', currentBranch};
                    
                    % Create a TableStore for the combinedList
                    tableStore = TableStore();
                    if isfield(newDataStruct.model.(currentBranch), 'combinedList')
                        tableStore.setTableData(newDataStruct.model.(currentBranch).combinedList);
                        % add the stored column definitions
                        if isfield(newDataStruct.model.(currentBranch), 'storedCategorizations')
                            [definitionList, namesToRecalculate] = ColumnDefinitionCombiner.combineStorage(newDataStruct.model.(currentBranch).storedCategorizations);
                            obj.addStoredColumnDefinitionsToTableStore(tableStore, definitionList, namesToRecalculate);
                        end
                    else
                        % disp('no combinedList')    
                    end
                    % disp(currentBranch)
                    loadedFilteringStorages = newDataStruct.model.(currentBranch).storedFilters;    % this should be a cell containing FilteringStorage objects
                    filteringStorage = FilteringStorageCombiner.combineStorage(loadedFilteringStorages);
                    % filteringStorage = FilteringStorage();  % TO IMPLEMENT - be able to load and combine filters
                    dataStore = DataStore(tableStore, filteringStorage);
                    
                    % Store the DataStore in the ModalityDataStore
                    obj.modalityDataStoreHandle.setModalityData(modalityPath, dataStore);
                    obj.addModalityPath(modalityPath);
                end
            end
            
            if isfield(newDataStruct, 'tracks')
                modalityPath = {'tracks'};
                
                % Create a TableStore for the tracks combinedList
                tableStore = TableStore();
                if isfield(newDataStruct.tracks, 'combinedList')
                    tableStore.setTableData(newDataStruct.tracks.combinedList);
                    if isfield(newDataStruct.tracks, 'storedCategorizations')
                        [definitionList, namesToRecalculate] = ColumnDefinitionCombiner.combineStorage(newDataStruct.tracks.storedCategorizations);
                        obj.addStoredColumnDefinitionsToTableStore(tableStore, definitionList, namesToRecalculate);
                    end
                end
                
                % Create a DataStore that holds both TableStore and FilteringStorage
                loadedFilteringStorages = newDataStruct.tracks.storedFilters;    % this should be a cell containing FilteringStorage objects
                filteringStorage = FilteringStorageCombiner.combineStorage(loadedFilteringStorages);
                dataStore = DataStore(tableStore, filteringStorage);
                
                % Store the DataStore in the ModalityDataStore
                obj.modalityDataStoreHandle.setModalityData(modalityPath, dataStore);
                obj.addModalityPath(modalityPath);
            end

            if (isempty(obj.modality) || isequal(strlength(obj.modality), 0)) && ~isempty(obj.availableModalities)
                obj.modality = obj.availableModalities{1};
                if ~isempty(obj.availableBranches{1})
                    obj.branch = obj.availableBranches{1}{1};
                end
            end

            % disp(obj.availableModalities)
            % disp(obj.availableBranches)
            
            notify(obj, 'availableModalitiesChanged');
        end



        function addStoredColumnDefinitionsToTableStore(~, tableStore, definitionList, namesToRecalculate)
            % Add stored categorizations to the table store
            if ~isempty(definitionList)
                if ~isempty(namesToRecalculate)
                    namesToRecalculate = unique(namesToRecalculate);
                    % Let user decide whether one definition should be kept and reapplied to the whole column, 
                    % or whether all definitions should be discarded and only data kept
                    [namesToRecalculate, namesToFreeze] = selectNamesToRecalculate(namesToRecalculate);
                else
                    disp('No conflicting column definitions found.');
                    namesToFreeze = {};
                end
                tableStore.addExistingUserColumnDefinitions(definitionList, namesToRecalculate, namesToFreeze);
            end
        end

        

        function addModalityPath(obj, modalityPath)
                assert(isequal(length(modalityPath), 1) || isequal(length(modalityPath), 2), 'Invalid path length: %d', length(modalityPath));

                currentModality = modalityPath{1};
                modalityId = find(ismember(obj.availableModalities, currentModality));

                % If modality doesn't exist, add it
                if isempty(modalityId)
                    obj.availableModalities{end + 1} = currentModality;
                    modalityId = length(obj.availableModalities);
                    obj.availableBranches{modalityId} = {};
                end

                % If path includes a branch, add it to the corresponding modality
                if length(modalityPath) == 2
                    currentBranch = modalityPath{2};
                    if ~ismember(currentBranch, obj.availableBranches{modalityId})
                        obj.availableBranches{modalityId}{end + 1} = currentBranch;
                    end
                end
        end



        function setInitialModality(obj)
            % Set the initial modality and branch if not set
            if (isempty(obj.modality) || isequal(strlength(obj.modality), 0)) && ~isempty(obj.availableModalities)
                obj.modality = obj.availableModalities{1};
                if ~isempty(obj.availableBranches{1})
                    obj.branch = obj.availableBranches{1}{1};
                end
            end

            obj.getAndStoreActiveData();
        end
        % function changeAvailableModalities(obj)

        %     disp('AppStateManager: changeAvailableModalities');
            
        %     availablePaths = obj.modalityDataStoreHandle.getAvailableModalityPaths();

        %     for i = 1:length(availablePaths)

        %         path = availablePaths{i};

        %         assert(isequal(length(path), 1) || isequal(length(path), 2), 'Invalid path length: %d', length(path));

        %         currentModality = path{1};

        %         if !ismember(currentModality, obj.availableModalities)
        %             obj.availableModalities{end + 1} = currentModality;
        %             modalityId = 0;
        %         else % modality already exists in the list
        %             modalityId = find(ismember(obj.availableModalities, currentModality));
        %         end

        %         if isequal(length(path), 2)
        %             currentBranch = path{2};
        %             if isequal(modalityId, 0)
        %                 obj.availableBranches{end + 1} = {currentBranch};
        %             else 
        %                 obj.availableBranches{modalityId}{end + 1} = currentBranch;
        %             end
        %         else
        %             obj.availableBranches{end + 1} = {};
        %         end
        %     end

        %     % notify that available modalities have changed
        %     obj.eventBusHandle.notify(EventTypes.AVAILABLE_MODALITIES_CHANGED);
        % end

        function getAndStoreActiveData(obj)
            if isempty(obj.modality)
                % If modality is empty, do nothing
                return
            end

            if isempty(obj.branch)  % happens for modalities that do not have branches (like tracks)
                modalityPath = {obj.modality};
            else
                modalityPath = {obj.modality, obj.branch};
            end

            % Get the DataStore from ModalityDataStore
            obj.activeDataStoreHandle = obj.modalityDataStoreHandle.getModalityData(modalityPath);

            notify(obj, 'newModalityLoaded');
            % TO OPTIMIZE - it might happen that processor might get updated after other things that depend on it
        end



        function getAndStoreActiveDataWithoutNotification(obj)
            if isempty(obj.branch)  % happens for modalities that do not have branches (like tracks)
                modalityPath = {obj.modality};
            else
                modalityPath = {obj.modality, obj.branch};
            end

            % Get the DataStore from ModalityDataStore
            try
                obj.activeDataStoreHandle = obj.modalityDataStoreHandle.getModalityData(modalityPath);
            catch ME
                if strcmp(ME.identifier, 'ModalityDataStore:InvalidModalityPath')
                    newME = MException('AppStateManager:InvalidModalityPath', ME.message);
                    throw(newME);
                else
                    rethrow(ME);
                end
            end
        end
    end
end


% IMPORTANT - "" this is not empty