classdef ExtendedBranchGraphicsGroup < BranchGraphicsGroup

    properties
        supportingGraphicsHandles
        supportingGraphicsVisible = "on";
        % I assume that I will be using the same color as is for the main graphics
        % What about transparency?
    end

    methods
        function obj = ExtendedBranchGraphicsGroup(parentAxes, branch, lightingMethod, selectionColor, transparency, color, contextMenuGenerator)
            % Constructor for the ExtendedBranchGraphicsGroup class
            obj@BranchGraphicsGroup(parentAxes, branch, lightingMethod, selectionColor, transparency, color, contextMenuGenerator);
            obj.supportingGraphicsHandles = matlab.graphics.Graphics.empty();
        end

        function setSupportingGraphicsVisibility(obj, visibility)
            arguments
                obj BranchGraphicsGroup
                visibility {mustBeMember(visibility, ["on", "off"])}
            end

            obj.supportingGraphicsVisible = visibility;
            set(obj.supportingGraphicsHandles, 'Visible', visibility);
        end

        function setExcluded(obj, excluded)
            arguments
                obj BranchGraphicsGroup
                excluded logical
            end
            setExcluded@BranchGraphicsGroup(obj, excluded);

            % Update the visibility of supporting graphics based on exclusion
            isSupportingVisible = obj.visible & obj.supportingGraphicsVisible;
            set(obj.supportingGraphicsHandles(obj.excluded), 'Visible', 'off');
            set(obj.supportingGraphicsHandles(~obj.excluded), 'Visible', isSupportingVisible);
        end


        function setPickableParts(obj, pickableParts)
            arguments
                obj BranchGraphicsGroup
                pickableParts {mustBeMember(pickableParts, ["none", "visible", "all"])}
            end

            setPickableParts@BranchGraphicsGroup(obj, pickableParts);
            
            set(obj.supportingGraphicsHandles, 'PickableParts', pickableParts);
        end


        function setColor(obj, color)
            arguments
                obj BranchGraphicsGroup
                color
            end

            setColor@BranchGraphicsGroup(obj, color);
            
            % Set the same color for supporting graphics
            if isa(color, 'double')
                set(obj.supportingGraphicsHandles, 'FaceColor', color);
            elseif iscell(color)
                if length(color) ~= length(obj.supportingGraphicsHandles)
                    error('Color cell array must match the number of supporting graphics handles.');
                end
                for i = 1:length(obj.supportingGraphicsHandles)
                    set(obj.supportingGraphicsHandles(i), 'FaceColor', color{i});
                end
            else
                error('Unsupported color format. Use a double or a cell array of colors.');
            end
        end


        function turnIndividualSelectionOn(obj, id)
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Call the parent method to handle individual selection
            turnIndividualSelectionOn@BranchGraphicsGroup(obj, id);

            % Ensure that supporting graphics are also updated
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Supporting object with ID "%d" not found in the group.', id);
                return
            end
            set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selected);
        end


        function turnIndividualSelectionOff(obj, id)
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Call the parent method to handle individual deselection
            turnIndividualSelectionOff@BranchGraphicsGroup(obj, id);

            % Ensure that supporting graphics are also updated
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Supporting object with ID "%d" not found in the group.', id);
                return
            end
            set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selected);
        end


        function toggleIndividualSelection(obj, id)
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Call the parent method to toggle individual selection
            toggleIndividualSelection@BranchGraphicsGroup(obj, id);

            % Ensure that supporting graphics are also updated
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Supporting object with ID "%d" not found in the group.', id);
                return
            end
            set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selected);
        end


        function toggleIndividualSelectionAndDeselectOthers(obj, id)
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Call the parent method to toggle individual selection and deselect others
            toggleIndividualSelectionAndDeselectOthers@BranchGraphicsGroup(obj, id);

            % Ensure that supporting graphics are also updated
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Supporting object with ID "%d" not found in the group.', id);
                return
            end
            set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selected);
        end


        function deselectAll(obj)
            % Deselect all objects in the group, including supporting graphics
            deselectAll@BranchGraphicsGroup(obj);
            
            % Update the supporting graphics handles
            set(obj.supportingGraphicsHandles, 'Selected', "off", 'FaceColor', obj.color);
        end


        function setSelected(obj, selected)
            % Set the selection state for all objects in the group, including supporting graphics
            setSelected@BranchGraphicsGroup(obj, selected);
            
            % Update the supporting graphics handles

            set(obj.supportingGraphicsHandles(selected), 'Selected', 'on', 'FaceColor', obj.color);
            set(obj.supportingGraphicsHandles(~selected), 'Selected', 'off', 'FaceColor', obj.color);
        end


        function setSelectionColor(obj, color)
            % Set the selection color for all objects in the group, including supporting graphics
            setSelectionColor@BranchGraphicsGroup(obj, color);
            
            % Update the selection color for supporting graphics
            set(obj.supportingGraphicsHandles, 'FaceColor', obj.selectionColor);
        end
    end
end