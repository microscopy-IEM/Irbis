classdef SelectionSynchronizer < handle
    % SelectionSynchronizer - Synchronizes selections between BranchGraphicsManager and FullTableProcessor
    % Converts branch object selections with IDs and time points to table row selections
    
    properties (Access = ?matlab.unittest.TestCase)
        branchGraphicsManagerHandle  % Handle to the BranchGraphicsManager
        appStateManagerHandle        % Handle to the AppStateManager
        selectionListener            % Event listener for selection changes
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
                if isempty(obj.selectionListener) || ~isvalid(obj.selectionListener)
                    % Create the listener if it doesn't exist or was deleted
                    obj.selectionListener = addlistener(obj.branchGraphicsManagerHandle, ...
                        'selectionChanged', @obj.onSelectionChanged);
                end
            else
                % Delete the listener to disable synchronization
                if ~isempty(obj.selectionListener) && isvalid(obj.selectionListener)
                    delete(obj.selectionListener);
                    obj.selectionListener = [];
                end
            end
        end


        function isEnabled = isSyncEnabled(obj)
            % Check if synchronization is currently enabled
            isEnabled = ~isempty(obj.selectionListener) && isvalid(obj.selectionListener);
        end


        function toggleSync(obj)
            % Toggle synchronization on/off
            obj.enableSync(~obj.isSyncEnabled());
        end

        
        function delete(obj)
            % Destructor - clean up listeners
            if ~isempty(obj.selectionListener) && isvalid(obj.selectionListener)
                delete(obj.selectionListener);
            end
        end
    end
    
    methods (Access = ?matlab.unittest.TestCase)
        function onSelectionChanged(obj, ~, eventData)
            % Handle selection changes from BranchGraphicsManager
            
            % Extract information from the selection event
            branch = eventData.branch;
            selectedIds = eventData.selectedIds;
            timePoint = eventData.currentTimePoint;

            % Check if the appropriate modality and branch are selected
            if ~strcmp(obj.appStateManagerHandle.getActiveModality(), 'model') || ...
                ~strcmp(obj.appStateManagerHandle.getActiveBranch(), branch)
                % Don't proceed if we're not in model mode or with the correct branch
                warning('SelectionSynchronizer:WrongMode', 'Selection sync requires modality "model" and matching branch');
                return;
            end
            
            % Get the table processor through the state managers
            tableProcessor = obj.getTableProcessor();
            if isempty(tableProcessor)
                warning('SelectionSynchronizer:NoTableProcessor', 'Could not find a valid table processor');
                return;
            end

            if isempty(selectedIds)
                % No selection, clear the table selection
                obj.updateTableSelection(tableProcessor, {});
                return;
            end

            % Convert selection to row names in the format "id_timePoint"
            rowNames = obj.convertToRowNames(selectedIds, timePoint);
            
            % Update the table selection
            obj.updateTableSelection(tableProcessor, rowNames);
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
                    return;  % Valid FullTableProcessor found
                end
            end
            
            % If no FullTableProcessor found, return empty
            tableProcessor = [];
        end
        
        
        function updateTableSelection(~, tableProcessor, rowNames)
            % Update the table selection in FullTableProcessor
            if isempty(tableProcessor)
                return;
            end
            
            % Use the setRowSelection method instead of manually handling selection
            try
                tableProcessor.setRowSelection(rowNames);
            catch ME
                warning('SelectionSynchronizer:SelectionError', 'Failed to set row selection: %s', ME.message);
            end
        end
    end
end