classdef BranchGraphicsManager < handle

    properties
        dataStruct struct

        parentAxes % Parent axes for the graphics objects
        lightingMethod
        selectionColor
    end

    methods 
        function obj = BranchGraphicsManager(branches, parentAxes, lightingMethod, selectionColor)
            % Constructor for the BranchGraphicsManager class
            for branchId = 1:numel(branches)
                branch = branches{branchId};
                obj.dataStruct.(branch) = [];
            end

            obj.parentAxes = parentAxes;
            obj.lightingMethod = lightingMethod;
            obj.selectionColor = selectionColor;
        end

        function groupHandle = createNewGroup(obj, branch, transparency, color)
            % Create a new group handle for the specified branch
            obj.validateBranchExistence(branch);
            if ~isempty(obj.dataStruct.(branch))
                delete(obj.dataStruct.(branch)); % Delete existing group handle if it exists
                    % This will also delete the objects in the group
            end
            
            tag = [branch 'MeshPlot'];
            groupHandle = BranchGraphicsGroup(obj.parentAxes, tag, obj.lightingMethod, obj.selectionColor, transparency, color);
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
    end
end