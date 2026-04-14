classdef BranchGraphicsManager < handle

    properties
        dataStruct

        parentAxes % Parent axes for the graphics objects
        lightingMethod
        selectionColor

        lastSelectedBranch

        selectionListenerStruct % Structure to hold selection listeners for each branch

        getCurrentTimePoint % Function handle to get the current time point

        graphicsInfotextHandle % Handle for the graphics infotext in the upper left corner
        updateGraphicsInfotext  % Function handle to update the graphics infotext
    end


    events
        selectionChanged % Event triggered when selection changes, information is passed as SelectionSyncData
    end


    methods 
        function obj = BranchGraphicsManager(branches, parentAxes, lightingMethod, selectionColor, getCurrentTimePoint)
            % Constructor for the BranchGraphicsManager class
            for branchId = 1:numel(branches)
                branch = branches{branchId};
                obj.dataStruct.(branch) = [];
            end

            obj.parentAxes = parentAxes;
            obj.lightingMethod = lightingMethod;
            obj.selectionColor = selectionColor;

            obj.getCurrentTimePoint = getCurrentTimePoint; % Store the function handle to get the current time point
        end


        function setInfotextProperties(obj, infotextHandle, updateInfotextFunction)
            % Set the infotext properties for the graphics manager
            obj.graphicsInfotextHandle = infotextHandle;
            obj.updateGraphicsInfotext = updateInfotextFunction;
        end


        function delete(obj)
            % Destructor for the BranchGraphicsManager class
            fields = fieldnames(obj.dataStruct);
            for i = 1:numel(fields)
                branch = fields{i};
                if ~isempty(obj.dataStruct.(branch)) && isvalid(obj.dataStruct.(branch))
                    delete(obj.dataStruct.(branch)); % Delete the group handle
                end
            end
        end

        
        function groupHandle = createNewGroup(obj, branch, transparency, color, contextMenuGenerator)
            % Create a new group handle for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                delete(obj.dataStruct.(branch)); % Delete existing group handle if it exists
                    % This will also delete the objects in the group
            end
            
            groupHandle = BranchGraphicsGroup(obj.parentAxes, branch, obj.lightingMethod, obj.selectionColor, transparency, color, contextMenuGenerator);
             % Create a new BranchGraphicsGroup object
            obj.dataStruct.(branch) = groupHandle; % Store the new group handle in the data structure
            groupHandle.setInfotextFunction(obj.updateGraphicsInfotext); % Set the infotext update function for the group

            % Create a selection listener for the new group
            if ~isfield(obj.selectionListenerStruct, branch)
                obj.selectionListenerStruct.(branch) = addlistener(groupHandle, 'selectedIds', 'PostSet', @(~, ~) obj.handleSelectionChange(branch));
            end
        end


        function groupHandle = createNewExtendedGroup(obj, branch, transparency, color, contextMenuGenerator)
            % Create a new group handle for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                delete(obj.dataStruct.(branch)); % Delete existing group handle if it exists
                    % This will also delete the objects in the group
            end
            
            groupHandle = ExtendedBranchGraphicsGroup(obj.parentAxes, branch, obj.lightingMethod, obj.selectionColor, transparency, color, contextMenuGenerator);
             % Create a new ExtendedBranchGraphicsGroup object
            obj.dataStruct.(branch) = groupHandle; % Store the new group handle in the data structure
            groupHandle.setInfotextFunction(obj.updateGraphicsInfotext); % Set the infotext update function for the group

            % Create a selection listener for the new group
            if ~isfield(obj.selectionListenerStruct, branch)
                obj.selectionListenerStruct.(branch) = addlistener(groupHandle, 'selectedIds', 'PostSet', @(~, ~) obj.handleSelectionChange(branch));
            end
        end


        function groupHandle = getExistingGroup(obj, branch)
            % Get the existing group handle for the specified branch
            obj.validateBranchExistence(branch);
            assert(~isempty(obj.dataStruct.(branch)), 'Group handle for branch "%s" is empty.', branch);
            groupHandle = obj.dataStruct.(branch);
        end


        function validateBranchExistence(obj, branch)
            % Validate if the branch exists in the data structure
            assert(isfield(obj.dataStruct, branch), 'Branch "%s" does not exist in the data structure.', branch);
            if ~isfield(obj.dataStruct, branch)
                obj.dataStruct.(branch) = [];
            end
        end


        function deleteGroup(obj, branch)
            % Delete the group handle for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                delete(obj.dataStruct.(branch)); % Delete the group handle
                obj.dataStruct.(branch) = []; % Clear the reference in the data structure
            end
        end


        function changeSelectionColor(obj, selectionColor)
            % Change the selection color for all groups
            obj.selectionColor = selectionColor;
            fields = fieldnames(obj.dataStruct);
            for i = 1:numel(fields)
                groupHandle = obj.dataStruct.(fields{i});
                if ~isempty(groupHandle)
                    groupHandle.setSelectionColor(selectionColor); % Update the selection color in the group handle
                end
            end
        end


        function changeLightingMethod(obj, lightingMethod)
            % Change the lighting method for all groups
            obj.lightingMethod = lightingMethod;
            fields = fieldnames(obj.dataStruct);
            for i = 1:numel(fields)
                groupHandle = obj.dataStruct.(fields{i});
                if ~isempty(groupHandle)
                    groupHandle.setLightingMethod(lightingMethod); % Update the lighting method in the group handle
                end
            end
        end


        function setSelectableBranches(obj, branches)
            % Set the selectable branches for all groups
            fields = fieldnames(obj.dataStruct);
            for i = 1:numel(fields)
                branch = fields{i};
                groupHandle = obj.dataStruct.(branch);
                if ~isempty(groupHandle)
                    if ismember(branch, branches)
                        % set pickableParts to 'visible'
                        groupHandle.setPickableParts('visible'); % Make the group selectable
                    else
                        % set pickableParts to 'none'
                        groupHandle.setPickableParts('none'); % Make the group non-selectable
                        groupHandle.deselectAll(); % Deselect the group if it is not selectable
                    end
                end
            end
        end


        function handleSelectionChange(obj, branch)
            % Handle selection change event for the specified branch
            if isfield(obj.dataStruct, branch) && ~isempty(obj.dataStruct.(branch))
                groupHandle = obj.dataStruct.(branch);
                selectedIds = groupHandle.getSelectedIds();
                selectedGroupIds = groupHandle.getSelectedGroupIds();
                currentTimePoint = obj.getCurrentTimePoint(); % Get the current time point using the function handle
                % disp(['Selection changed for branch "' branch '": ' num2str(selectedIds) ' in time point ' num2str(obj.getCurrentTimePoint()) '.']);
                % Additional logic can be added here to handle selection changes
            else
                % disp(['No group handle found for branch "' branch '" in time point ' num2str(obj.getCurrentTimePoint()) '.']);
            end

            obj.lastSelectedBranch = branch; % Update the last selected branch

            notify(obj, 'selectionChanged', SelectionSyncData(branch, selectedIds, selectedGroupIds, currentTimePoint));

            % disp(src)
            % disp(event)
        end


        function clearSelection(obj, branch)
            % Clear the selection for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                obj.dataStruct.(branch).setSelected([]); % Clear the selection in the group handle
            end
        end


        function setSelection(obj, selectedIdsByTimePoint, branch)
            % Set the selection for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                currentTimePoint = obj.getCurrentTimePoint(); % Get the current time point using the function handle
                if isKey(selectedIdsByTimePoint, currentTimePoint)
                    selectedIds = selectedIdsByTimePoint(currentTimePoint); % Get the selected IDs for the current time point
                    selectedIds = cell2mat(selectedIds{1}); % Get the selected IDs for the current time point
                    obj.dataStruct.(branch).setSelected(selectedIds); % Set the selection in the group handle
                else
                    obj.dataStruct.(branch).setSelected([]); % Clear the selection if no IDs are provided for the current time point
                end
            end
        end



        function setGroupIdSelection(obj, selectedGroupIds, branch)
            % Set the group ID selection for the specified branch
            % As groupId is not time point specific, we can set it directly without checking the time point
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                obj.dataStruct.(branch).setSelectedGroupIds(selectedGroupIds);
            else
                obj.dataStruct.(branch).setSelected([]);
            end
        end


        
        function lastSelectedBranch = getLastSelectedBranch(obj)
            % Get the last selected branch
            lastSelectedBranch = obj.lastSelectedBranch;
        end
    end
end