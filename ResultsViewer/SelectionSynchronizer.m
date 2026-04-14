classdef SelectionSynchronizer < handle
    % SelectionSynchronizer - Synchronizes selections between BranchGraphicsManager and FullTableProcessor
    % Converts branch object selections with IDs and time points to table row selections
    
    properties (Access = ?matlab.unittest.TestCase)
        branchGraphicsManagerHandle  % Handle to the BranchGraphicsManager
        appStateManagerHandle        % Handle to the AppStateManager

        currentTableProcessorHandle % Handle to the current tableProcessor - at the moment only FullTableProcessor

        appStateListener             % For tracking table processor changes
        graphicsSelectionListener            % Event listener for selection changes in BranchGraphicsManager
        tableSelectionListener            % Event listener for table selection changes in ResultsViewer
        isSyncing = false  % Add this flag
        tableUpdateFunctionHandle = {} % Store the function handle for updating selection, to be set based on table processor type
        graphicsUpdateFunctionHandle = @obj.updateGraphicsSelection; % Function handle for updating graphics selection, can be switched to group ID selection if needed
    end
    
    methods
        function obj = SelectionSynchronizer()
        end

        

        function setBranchGraphicsManagerHandle(obj, handle)
            % Set the BranchGraphicsManager handle
            if isempty(handle)
                error('SelectionSynchronizer:InvalidInput', 'BranchGraphicsManager handle cannot be empty');
            end
            obj.branchGraphicsManagerHandle = handle;

            if ~isempty(obj.appStateManagerHandle) && isvalid(obj.appStateManagerHandle)
                % If AppStateManager is already set, enable synchronization
                obj.enableSync(true);
            end
        end

        

        function setAppStateManagerHandle(obj, handle)
            % Set the AppStateManager handle
            if isempty(handle)
                error('SelectionSynchronizer:InvalidInput', 'AppStateManager handle cannot be empty');
            end
            obj.appStateManagerHandle = handle;
            
            % Listen for table type changes to update table processor listener
            if ~isempty(obj.appStateListener) && isvalid(obj.appStateListener)
                delete(obj.appStateListener);
            end
            obj.appStateListener = addlistener(obj.appStateManagerHandle, ...
                'tableTypeChanged', @obj.onTableProcessorChanged);
            
            % Set up initial table processor listener
            obj.setupTableProcessorListener();

            if ~isempty(obj.branchGraphicsManagerHandle) && isvalid(obj.branchGraphicsManagerHandle)
                % If BranchGraphicsManager is already set, enable synchronization
                obj.enableSync(true);
            end
        end

        

        function enableSync(obj, enable)
            % Enable or disable the synchronization
            if nargin < 2
                enable = true; % Default to enabling
            end
            
            if enable
                % Create the graphics selection listener if it doesn't exist or was deleted
                if isempty(obj.graphicsSelectionListener) || ~isvalid(obj.graphicsSelectionListener)
                    obj.graphicsSelectionListener = addlistener(obj.branchGraphicsManagerHandle, ...
                    'selectionChanged', @obj.onGraphicsSelectionChanged);
                end
                
                % Create the table selection listener if it doesn't exist or was deleted
                if isempty(obj.tableSelectionListener) || ~isvalid(obj.tableSelectionListener)
                    % Setup table processor listener
                    obj.setupTableProcessorListener();
                end
                
                % Create the app state listener if it doesn't exist or was deleted
                if isempty(obj.appStateListener) || ~isvalid(obj.appStateListener)
                    obj.appStateListener = addlistener(obj.appStateManagerHandle, ...
                    'tableTypeChanged', @obj.onTableProcessorChanged);
                end
            else
                % Delete the graphics selection listener to disable synchronization
                if ~isempty(obj.graphicsSelectionListener) && isvalid(obj.graphicsSelectionListener)
                    delete(obj.graphicsSelectionListener);
                    obj.graphicsSelectionListener = [];
                end
                
                % Delete the table selection listener to disable synchronization
                if ~isempty(obj.tableSelectionListener) && isvalid(obj.tableSelectionListener)
                    delete(obj.tableSelectionListener);
                    obj.tableSelectionListener = [];
                end
                
                % Delete the app state listener to disable synchronization
                if ~isempty(obj.appStateListener) && isvalid(obj.appStateListener)
                    delete(obj.appStateListener);
                    obj.appStateListener = [];
                end
            end
        end



        function isEnabled = isSyncEnabled(obj)
            % Check if synchronization is currently enabled
            isEnabled = ~isempty(obj.graphicsSelectionListener) && isvalid(obj.graphicsSelectionListener);
        end



        function toggleSync(obj)
            % Toggle synchronization on/off
            obj.enableSync(~obj.isSyncEnabled());
        end

        

        function delete(obj)
            % Destructor - clean up listeners
            if ~isempty(obj.graphicsSelectionListener) && isvalid(obj.graphicsSelectionListener)
                delete(obj.graphicsSelectionListener);
            end
            if ~isempty(obj.tableSelectionListener) && isvalid(obj.tableSelectionListener)
                delete(obj.tableSelectionListener);
            end
            if ~isempty(obj.appStateListener) && isvalid(obj.appStateListener)
                delete(obj.appStateListener);
            end
        end
    end
    



    methods (Access = ?matlab.unittest.TestCase)
        function onGraphicsSelectionChanged(obj, ~, eventData)
            % OBSERVATION: it seems that when holding ctrl and selecting in table, and then moving to select in graphics: 
                % the ctrl is not registered for the graphics - the previous selection is cleard
            % disp('SelectionSynchronizer:onGraphicsSelectionChanged');
            % Handle selection changes from BranchGraphicsManager
            % Happens when objects were selected in Irbis, we want to update the table in ResultsViewer accordingly

            if obj.isSyncing
                % disp('Skipping selection change event due to ongoing sync');
                obj.isSyncing = false; % Clear flag
                return; % Skip if we're already syncing
            end
            
            obj.isSyncing = true; % Set flag
            try
                % Extract information from the selection event
                branch = eventData.branch;
                selectedIds = eventData.selectedIds;
                selectedGroupIds = eventData.selectedGroupIds;
                timePoint = eventData.currentTimePoint;

                % Check if the appropriate modality and branch are selected
                if ~strcmp(obj.appStateManagerHandle.getActiveModality(), 'model') || ...
                    ~strcmp(obj.appStateManagerHandle.getActiveBranch(), branch)
                    return;
                end
                
                % Get the table processor through the state managers
                % tableProcessor = obj.getTableProcessor();
                % this should not be necessary (it checks things and assigns function handles)
                % instead, we should just be able to access it in obj.currentTableProcessorHandle
                tableProcessor = obj.currentTableProcessorHandle;

                % The function handle is set based on which table type is active
                if ~isempty(obj.tableUpdateFunctionHandle)
                    obj.tableUpdateFunctionHandle(tableProcessor, selectedIds, selectedGroupIds, timePoint);
                end
            catch ME
                warning('SelectionSynchronizer:SyncError', 'Error in selection sync: %s', ME.message);
            end
            obj.isSyncing = false; % Clear flag
        end



        function onTableProcessorChanged(obj, ~, ~)
            % Called when table type changes - need to update listener
            obj.setupTableProcessorListener();
        end

        
        
        function setupTableProcessorListener(obj)
            % Clean up existing listener
            if ~isempty(obj.tableSelectionListener) && isvalid(obj.tableSelectionListener)
                delete(obj.tableSelectionListener);
                obj.tableSelectionListener = [];
            end
            
            % Get current table processor
            tableProcessor = obj.getTableProcessor();
            if isempty(tableProcessor)
                return;
            end
            
            obj.currentTableProcessorHandle = tableProcessor;
            
            % Listen for selection changes on the table processor
            obj.tableSelectionListener = addlistener(tableProcessor, ...
                'tableSelectionChanged', @(~, ~) obj.onTableSelectionChanged);
        end
        

        
        function onTableSelectionChanged(obj)
            % Handle selection changes from FullTableProcessor
            % disp('SelectionSynchronizer:onTableSelectionChanged');
            if obj.isSyncing
                % disp('Skipping table selection change event due to ongoing sync');
                return; % Skip if we're already syncing
            end
            
            if isempty(obj.currentTableProcessorHandle) || isempty(obj.branchGraphicsManagerHandle)
                return;
            end
            
            obj.isSyncing = true; % Set flag
            try
                % Get selected row names from the table processor
                selectedCells = obj.currentTableProcessorHandle.getSelectedTableCellsList();
                if isempty(selectedCells)
                    obj.updateGraphicsSelection([]);
                    return;
                end
                
                % Get unique row indices
                selectedRowIndices = unique(selectedCells(:,1), 'stable');
                
                % Convert row indices to row names
                displayedTable = obj.currentTableProcessorHandle.getTableForDisplay();
                if isempty(displayedTable)
                    return;
                end
                
                % Preallocate rowNames array for better performance
                rowNames = cell(length(selectedRowIndices), 1);
                if ~isempty(displayedTable.Properties.RowNames)
                    % Table has row names
                    allRowNames = displayedTable.Properties.RowNames;
                    validCount = 0;
                    for i = 1:length(selectedRowIndices)
                        if selectedRowIndices(i) <= length(allRowNames)
                            validCount = validCount + 1;
                            rowNames{validCount} = allRowNames{selectedRowIndices(i)};
                        end
                    end
                    % Trim to actual size if needed
                    if validCount < length(rowNames)
                        rowNames = rowNames(1:validCount);
                    end
                else
                    % Do not do anything if there are no row names
                    warning('SelectionSynchronizer:NoRowNames', 'Table does not have row names, cannot synchronize selection');
                    return
                end
                
                % This handle is set based on which table type is active
                obj.graphicsUpdateFunctionHandle(rowNames);

                % Update BranchGraphicsManager selection
                % obj.updateGraphicsSelection(selectedIdsByTimePoint);
            catch ME
                warning('SelectionSynchronizer:SyncError', 'Error in table selection sync: %s', ME.message);
            end
            obj.isSyncing = false; % Clear flag
        end



        function selectedIdsByTimePoint = parseRowNames(~, rowNames)
            % Parse row names in format "id_timePoint" to extract IDs and time points
            % Returns a dictionary where keys are time points and values are arrays of IDs
            
            selectedIdsByTimePoint = configureDictionary('double', 'cell');
            
            for i = 1:length(rowNames)
                parts = split(rowNames{i}, '_');
                if length(parts) == 2
                    id = str2double(parts{1});
                    tp = str2double(parts{2});
                    if ~isnan(id) && ~isnan(tp)
                        % Check if the time point already exists in the dictionary
                        if isKey(selectedIdsByTimePoint, tp)
                            % Add ID to existing time point
                            existingIds = selectedIdsByTimePoint(tp);
                            existingIds = existingIds{1}; % It needs to be wrapped in a cell
                            % Convert id to cell if it's not already
                            if iscell(existingIds)
                                % Pre-allocate a larger cell array to avoid growing in the loop
                                newIds = cell(1, length(existingIds) + 1);
                                for j = 1:length(existingIds)
                                    newIds{j} = existingIds{j};
                                end
                                newIds{end} = id;
                                selectedIdsByTimePoint(tp) = {newIds};
                            else
                                % Should not happen, but handle it safely
                                selectedIdsByTimePoint(tp) = {{id}};
                            end
                        else
                            % Create new entry for this time point
                            selectedIdsByTimePoint(tp) = {{id}};
                        end
                    end
                end
            end
        end



        function [isModelMode, currentBranch] = checkModelModeAndGetBranch(obj)
            % Check if the current modality is 'model' and get the current branch if so
            % Returns:
            %   isModelMode - true if current modality is 'model'
            %   currentBranch - current branch name if in model mode, empty string otherwise
            
            isModelMode = false;
            currentBranch = '';
            
            if isempty(obj.appStateManagerHandle) || ~isvalid(obj.appStateManagerHandle)
                return;
            end
            
            try
                % Get the current modality from the app state manager
                currentModality = obj.appStateManagerHandle.getActiveModality();
                
                % Check if it's model modality
                isModelMode = strcmp(currentModality, 'model');
                
                % If we're in model mode, get the active branch
                if isModelMode
                    currentBranch = obj.appStateManagerHandle.getActiveBranch();
                end
            catch ME
                warning('SelectionSynchronizer:ModelCheckError', ...
                    'Error checking model mode: %s', ME.message);
            end
        end
        
        

        function updateGraphicsSelection(obj, rowNames)
            % Update selection in BranchGraphicsManager
            % This method would depend on BranchGraphicsManager's API

            try
                [isModelMode, currentBranch] = checkModelModeAndGetBranch(obj);

                if ~isModelMode || isempty(currentBranch)
                    warning('SelectionSynchronizer:WrongMode', 'Selection sync requires modality "model" and a valid branch');
                    return;
                end

                branch = currentBranch; % Use the current branch from the app state manager
                if isempty(rowNames)
                    % Clear selection
                    obj.branchGraphicsManagerHandle.clearSelection(branch);
                else
                    % Set selection
                    % This moved here to make the onTableSelectionChanged method more generic and to allow for different ways of updating graphics selection based on table type:
                    selectedIdsByTimePoint = obj.parseRowNames(rowNames);
                    obj.branchGraphicsManagerHandle.setSelection(selectedIdsByTimePoint, branch);
                end
            catch ME
                warning('SelectionSynchronizer:BranchSelectionError', ...
                    'Failed to update branch selection: %s', ME.message);
            end
        end



        function updateGraphicsGroupIdSelection(obj, rowNames)
            % Update selection in BranchGraphicsManager based on group IDs
            selectedGroupIds = cellfun(@(x) str2double(x), rowNames); 

            try
                [isModelMode, currentBranch] = checkModelModeAndGetBranch(obj);

                if ~isModelMode || isempty(currentBranch)
                    warning('SelectionSynchronizer:WrongMode', 'Selection sync requires modality "model" and a valid branch');
                    return;
                end

                branch = currentBranch; % Use the current branch from the app state manager
                if isempty(selectedGroupIds)
                    % Clear selection
                    obj.branchGraphicsManagerHandle.clearSelection(branch);
                else
                    % Set selection
                    obj.branchGraphicsManagerHandle.setGroupIdSelection(selectedGroupIds, branch);
                end
            catch ME
                warning('SelectionSynchronizer:BranchSelectionError', ...
                    'Failed to update branch selection: %s', ME.message);
            end
        end

        
        
        function rowNames = convertToRowNames(~, selectedIds, timePoint)
            % Convert selected IDs and time point to row name format
            rowNames = cell(length(selectedIds), 1);
            for i = 1:length(selectedIds)
                rowNames{i} = sprintf('%d_%d', selectedIds(i), timePoint);
            end
        end

        
        
        function tableProcessor = getTableProcessor(obj)
            % Get the active table processor from AppStateManager and ensure it's a FullTableProcessor
            
            % Get all table processor handles using the AppStateManager method
            [processorHandles, tableTypes] = obj.appStateManagerHandle.getTableProcessorHandles();
            
            % If no processors available, return empty
            if isempty(processorHandles)
                tableProcessor = [];
                return;
            end
            
            % First check for a FullTableProcessor
            for i = 1:length(processorHandles)
                if strcmp(tableTypes{i}, 'Full') && isa(processorHandles{i}, 'FullTableProcessor')
                    tableProcessor = processorHandles{i};
                    obj.tableUpdateFunctionHandle = @obj.updateFullTableSelection; % Set the update function for full table processor
                    obj.graphicsUpdateFunctionHandle = @obj.updateGraphicsSelection; % Set the graphics update function for full table processor
                    return  % Valid FullTableProcessor found
                elseif strcmp(tableTypes{i}, 'Pivoted') && isa(processorHandles{i}, 'PivotedTableProcessor')
                    tableProcessor = processorHandles{i};
                    obj.tableUpdateFunctionHandle = @obj.updatePivotedTableSelection; % Set the update function for pivoted table processor
                    obj.graphicsUpdateFunctionHandle = @obj.updateGraphicsGroupIdSelection; % Set the graphics update function for pivoted table processor to update group ID selection
                    return  % Valid PivotedTableProcessor found
                end
                % TO OPTIMIZE - implement also handling when Summarized is used or when two tables are active at the same time
            end
            
            % If no FullTableProcessor found, return empty
            tableProcessor = [];
        end
        
        

        % TO BE DEPRECATED - now specific for table type
        % function updateTableSelection(~, tableProcessor, rowNames)
        %     % Update the table selection in FullTableProcessor
        %     if isempty(tableProcessor)
        %         return;
        %     end
            
        %     % Use the setRowSelection method instead of manually handling selection
        %     try
        %         tableProcessor.setRowSelection(rowNames);
        %     catch ME
        %         warning('SelectionSynchronizer:SelectionError', 'Failed to set row selection: %s', ME.message);
        %     end
        % end



        function updateFullTableSelection(obj, tableProcessor, selectedIds, ~, timePoint)
            % Update the table selection in FullTableProcessor
            if isempty(tableProcessor)
                return;
            end

            if isempty(selectedIds)
                rowNames = {}; % Clear selection if no IDs
            else
                % Convert selection to row names in the format "id_timePoint"
                rowNames = obj.convertToRowNames(selectedIds, timePoint);
                % TO FIX - the second part of rowNames is bound to index, not timePoint -> this does not work if they don't match
            end

            % Use the setRowSelection method instead of manually handling selection
            try
                tableProcessor.setRowSelection(rowNames);
            catch ME
                warning('SelectionSynchronizer:SelectionError', 'Failed to set row selection: %s', ME.message);
            end
        end



        function updatePivotedTableSelection(~, tableProcessor, ~, selectedGroupIds, ~)
            % Update the table selection in PivotedTableProcessor
            % disp("updateTableSelectionPivoted")
            if isempty(tableProcessor)
                return;
            end

            % disp("selectedGroupIds:")
            % disp(selectedGroupIds)
            % class(tableProcessor)
            % class(selectedGroupIds)

            if isempty(selectedGroupIds)
                rowNames = {}; % Clear selection if no IDs
            else
                % Convert selection to row names which are string
                rowNames = cell(length(selectedGroupIds), 1);
                for i = 1:length(selectedGroupIds)
                    rowNames{i} = sprintf('%d', selectedGroupIds(i));
                end
            end

            % disp("pivoted")
            % disp(rowNames)

            % Use the setRowSelection method instead of manually handling selection
            % try
            tableProcessor.setRowSelection(rowNames);
            % catch ME
            %     warning('SelectionSynchronizer:SelectionError', 'Failed to set row selection: %s', ME.message);
            % end
        end
    end
end