classdef ExtendedBranchGraphicsGroup < BranchGraphicsGroup

    properties
        supportingGraphicsHandles
        supportingGraphicsVisible = "on";
        colorIdentifier = "Color";
        plotType = "line"; % Default plot type for supporting graphics
        supportingGraphicsTag = 'SupportingGraphics';
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

            % We probably want to be able to have the main objects invisible while supporting graphics are visible

            obj.supportingGraphicsVisible = visibility;
            if isempty(obj.supportingGraphicsHandles)
                return; % No supporting graphics to update
            end
            set(obj.supportingGraphicsHandles(~obj.excluded), 'Visible', visibility);
        end


        function setExcluded(obj, excluded)
            arguments
                obj BranchGraphicsGroup
                excluded (1,:) logical
            end
            setExcluded@BranchGraphicsGroup(obj, excluded);

            % Update the visibility of supporting graphics based on exclusion
            % isSupportingVisible = obj.visible && obj.supportingGraphicsVisible;
            isSupportingVisible = obj.supportingGraphicsVisible;
            if ~isempty(obj.supportingGraphicsHandles)
                set(obj.supportingGraphicsHandles(obj.excluded), 'Visible', 'off');
                set(obj.supportingGraphicsHandles(~obj.excluded), 'Visible', isSupportingVisible);
            end
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
                set(obj.supportingGraphicsHandles, obj.colorIdentifier, color);
            elseif iscell(color)
                % Lenght check is already done in the parent method
                for i = 1:length(obj.supportingGraphicsHandles)
                    isSelected = ismember(obj.objectIdArray(i), obj.selectedIds(:));
                    if ~isSelected
                        % Set the color for each supporting graphics handle
                        set(obj.supportingGraphicsHandles(i), obj.colorIdentifier, color{i});
                    end
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
            if ~isempty(obj.supportingGraphicsHandles) 
                set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selectedIds, ...
                    obj.colorIdentifier, obj.selectionColor);   % For Line objects, use 'Color' instead of 'FaceColor'
            end
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
            if ~isempty(obj.supportingGraphicsHandles)
                
                if iscell(obj)
                    objectColor = obj.color{idx}; % Get the color for the specific object
                else
                    objectColor = obj.color; % Use the default color for the group
                end

                set(obj.supportingGraphicsHandles(idx), 'Selected', obj.selectedIds, ...
                    obj.colorIdentifier, objectColor);   % For Line objects, use 'Color' instead of 'FaceColor'
            end
        end


        function toggleIndividualSelection(obj, id)
            % Toggle selection for a specific object by ID
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Implemented like this, because calling toggle on the parent class would skip the parts for supporting graphics

            isSelected = ismember(id, obj.selectedIds);
            if isSelected
                obj.turnIndividualSelectionOff(id); % Turn off selection if it is currently on
            else
                obj.turnIndividualSelectionOn(id); % Turn on selection if it is currently off
            end
        end


        function toggleIndividualSelectionAndDeselectOthers(obj, id)
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            % Deselect all objects and toggle selection for a specific object by ID
            isSelected = ismember(id, obj.selectedIds);
            obj.deselectAll();
            % Toggle selection for a specific object by ID
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Object with ID "%d" not found in the group.', id);
                return
            end
            if isSelected
                obj.turnIndividualSelectionOff(id); % Turn off selection if it is currently on
            else
                obj.turnIndividualSelectionOn(id); % Turn on selection if it is currently off
            end
        end


        function deselectAll(obj)
            % Deselect all objects in the group, including supporting graphics
            obj.selectedIds = []; % Clear the selection array
            obj.setSelected(obj.selectedIds); % Update the selection state of all objects
            obj.idLabel.String = '';
        end


        function setSelected(obj, selectedIndices)
            % Set the selection state for all objects in the group, including supporting graphics
            arguments
                obj BranchGraphicsGroup
                selectedIndices (1,:) {mustBeNumeric}
            end

            setSelected@BranchGraphicsGroup(obj, selectedIndices);
            
            if isempty(obj.supportingGraphicsHandles)
                return % No supporting graphics to update
            end

            % Update the supporting graphics handles
            isSelected = ismember(obj.objectIdArray, selectedIndices(:));

            % Set the selected property for each graphics object
            set(obj.supportingGraphicsHandles(isSelected), 'Selected', "on");
            set(obj.supportingGraphicsHandles(~isSelected), 'Selected', "off");

            % Update the selection color for selected objects
            set(obj.supportingGraphicsHandles(isSelected), obj.colorIdentifier, obj.selectionColor);
            
            % Reset the color for non-selected objects
            if iscell(obj.color)
                for i = 1:length(obj.supportingGraphicsHandles)
                    if ~isSelected(i)
                        set(obj.supportingGraphicsHandles(i), obj.colorIdentifier, obj.color{i});
                    end
                end
            else
                set(obj.supportingGraphicsHandles(~isSelected), obj.colorIdentifier, obj.color);
            end
        end


        function setSelectionColor(obj, color)
            % Set the selection color for all objects in the group, including supporting graphics
            setSelectionColor@BranchGraphicsGroup(obj, color);
            
            isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
            set(obj.supportingGraphicsHandles(isSelected), obj.colorIdentifier, color);
        end


        function hideUnselected(obj)
            % Hide unselected objects in the group, including supporting graphics
            hideUnselected@BranchGraphicsGroup(obj);
            
            if isempty(obj.supportingGraphicsHandles)
                return; % No supporting graphics to update
            end
            
            isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
            set(obj.supportingGraphicsHandles(~isSelected), 'Visible', 'off');
            set(obj.supportingGraphicsHandles(isSelected), 'Visible', obj.supportingGraphicsVisible);
        end


        function resetVisibility(obj)
            % Reset visibility of all objects in the group, including supporting graphics
            resetVisibility@BranchGraphicsGroup(obj);
            
            if isempty(obj.supportingGraphicsHandles)
                return; % No supporting graphics to update
            end
            
            set(obj.supportingGraphicsHandles, 'Visible', obj.supportingGraphicsVisible);
        end


        function visibleIds = getVisibleIds(obj)
            % Get IDs of all visible objects in the group, including supporting graphics
            visibleIds = getVisibleIds@BranchGraphicsGroup(obj);
            
            if isempty(obj.supportingGraphicsHandles) || ~isempty(visibleIds)
                return; % No supporting graphics to check visibility
            end
            
            visibleIds = obj.objectIdArray(~obj.excluded & strcmp({obj.supportingGraphicsHandles.Visible}, 'on'));
        end


        function deleteSupportingGraphics(obj)
            % Delete all supporting graphics handles
            if ~isempty(obj.supportingGraphicsHandles)
                delete(obj.supportingGraphicsHandles);
            end
            obj.supportingGraphicsHandles = matlab.graphics.Graphics.empty();
        end


        function delete(obj)
            % Delete the ExtendedBranchGraphicsGroup object and its supporting graphics
            obj.deleteSupportingGraphics; % Delete supporting graphics handles
            delete@BranchGraphicsGroup(obj); % Call the parent class delete method
        end


        function deleteObjects(obj, objectIds)
            % Delete specific objects by their IDs, including supporting graphics
            arguments
                obj BranchGraphicsGroup
                objectIds (1,:) {mustBeNumeric}
            end

            % Call the parent method to delete main graphics objects
            deleteObjects@BranchGraphicsGroup(obj, objectIds);

            % Find indices of the objects to delete in the supporting graphics handles
            isToDelete = ismember(obj.objectIdArray, objectIds);
            if any(isToDelete) && ~isempty(obj.supportingGraphicsHandles)
                delete(obj.supportingGraphicsHandles(isToDelete)); % Delete supporting graphics handles
                obj.supportingGraphicsHandles(isToDelete) = []; % Remove deleted handles from the array
            end
        end


        function initializeSupportingObjects(obj, dataArray, plotType, idArray, groupIdArray, buttonDownCallback, tag)
            % Initialize supporting graphics objects without including the main graphics
            arguments
                obj BranchGraphicsGroup
                dataArray (:, 1) cell
                plotType string {mustBeMember(plotType, ["line", "scatter"])}
                idArray (1,:) {mustBeNumeric}
                groupIdArray (1,:) {mustBeNumeric}
                buttonDownCallback function_handle
                tag (1, :) char = 'SupportingGraphics'
            end

            obj.deleteSupportingGraphics; % Clear existing supporting graphics handles

            if isempty(dataArray) || isempty(idArray)
                return; % No data to initialize
            end

            % Initialize supporting graphics handles
            obj.supportingGraphicsHandles = matlab.graphics.Graphics.empty();


            nObjects = numel(idArray);
            obj.supportingGraphicsHandles = gobjects(nObjects,1);
            obj.objectIdArray = idArray;
            obj.groupIdArray = groupIdArray;
            obj.selectedIds = []; % Initialize empty selection
            obj.excluded = false(nObjects, 1); % Initialize exclusion status for all objects

            obj.buttonDownCallback = buttonDownCallback; % Set the button down callback for supporting graphics
            obj.plotType = plotType; % Set the plot type for supporting graphics
            if isequal(obj.plotType, "line")
                obj.colorIdentifier = 'Color'; % For Line objects, use 'Color'
            else
                obj.colorIdentifier = 'MarkerFaceColor'; % For Scatter objects, use 'MarkerFaceColor'
            end
            obj.supportingGraphicsTag = tag; % Set the tag for supporting graphics

            % Loop through each object and plot it
            for i = 1:numel(idArray)
                % Extract vertices and faces for the current object
                datapoints = dataArray{i};
                if isempty(datapoints)
                    continue; % Skip empty data points
                end
                id = idArray(i);
        
                % Determine color for this object based on color type
                if iscell(obj.color)
                    objectColor = obj.color{i};
                else
                    objectColor = obj.color;
                end
                objectHandle = obj.plotSupportingObject(datapoints, id, objectColor, obj.visible, "off");
                obj.supportingGraphicsHandles(i) = objectHandle;
            end
        end


        function initializeExtendedGroup(obj, verticesArray, facesArray, dataArray, idArray, groupIdArray, buttonDownCallback)
            arguments
                obj BranchGraphicsGroup
                verticesArray (:, 1) cell
                facesArray (:, 1) cell
                dataArray (:, 1) cell
                idArray (1,:) {mustBeNumeric}
                groupIdArray (1,:) {mustBeNumeric}
                buttonDownCallback function_handle
            end

            obj.initializeGroup(obj, verticesArray, facesArray, idArray, groupIdArray, buttonDownCallback);

            obj.deleteSupportingGraphics; % Clear existing supporting graphics handles

            if isempty(dataArray) || isempty(idArray)
                return; % No data to initialize
            end

            nObjects = numel(idArray);
            obj.supportingGraphicsHandles = gobjects(nObjects,1);

            % Loop through each object and plot it
            for i = 1:numel(idArray)
                % Extract vertices and faces for the current object
                datapoints = dataArray{i};
                id = idArray(i);
        
                % Determine color for this object based on color type
                if iscell(obj.color)
                    objectColor = obj.color{i};
                else
                    objectColor = obj.color;
                end
                objectHandle = obj.plotSupportingObject(datapoints, id, objectColor, obj.visible, "off");
                obj.supportingGraphicsHandles(i) = objectHandle;
            end
        end


        function objectHandle = plotSupportingObject(obj, datapoints, id, color, visibilityStatus, selectionStatus)
            % Plot a supporting object based on the specified type
            arguments
                obj BranchGraphicsGroup
                datapoints (:, :) double
                id {mustBeNumeric}
                color (1,:) double
                visibilityStatus (1,1) string {mustBeMember(visibilityStatus, ["on", "off"])}
                selectionStatus string {mustBeMember(selectionStatus, ["on", "off"])} = "off"
            end

            % Create the graphics object based on the specified type
            if strcmp(obj.plotType, "line")
                objectHandle = plot3(obj.parentAxes, datapoints(:, 1), datapoints(:, 2), datapoints(:, 3), ...
                    'LineWidth', 5, 'Color', color, ...
                    'Visible', visibilityStatus);
            elseif strcmp(obj.plotType, "scatter")
                objectHandle = scatter3(obj.parentAxes, datapoints(:, 1), datapoints(:, 2), datapoints(:, 3), ...
                    'filled', 'MarkerFaceColor', color, ...
                    'Visible', visibilityStatus, 'PickableParts');
            else
                error('Unsupported plot type: %s', obj.plotType);
            end
            
            % Set additional properties
            objectHandle.UserData = id; % Store the ID in UserData for easy access later
            objectHandle.Selected = selectionStatus; % Initialize selection state
            objectHandle.Tag = obj.supportingGraphicsTag; % Tag for identification
            objectHandle.ButtonDownFcn = obj.buttonDownCallback; % Set the button down callback
            objectHandle.PickableParts = obj.pickableParts; % Set pickable parts

            objectHandle.SelectionHighlight = 'off'; % blocked default highlight (we do it by changing color)
        end


        function addSupportingObjects(obj, dataArray, idArray, groupIdArray, color, isExcluded, isSelected)
            % Add supporting objects to the group
            arguments
                obj BranchGraphicsGroup
                dataArray (:, 1) cell
                idArray (1,:) {mustBeNumeric}
                groupIdArray (1,:) {mustBeNumeric}
                color (1,:) double
                isExcluded (1,:) logical = false(1, numel(idArray))
                isSelected (1,:) logical = false(1, numel(idArray))
            end

            if isempty(dataArray) || isempty(idArray)
                return; % No data to add
            end

            % Initialize the supporting graphics objects
            if isempty(obj.supportingGraphicsHandles)
                obj.initializeSupportingObjects(dataArray, obj.plotType, idArray, groupIdArray, obj.buttonDownCallback);
            end
            
            % Handle color input for new objects
            if isempty(color)
                if iscell(obj.color)
                    color = obj.color;  % Use existing cell array of colors
                else
                    color = repmat({obj.color}, numel(idArray), 1);  % Use group's default color
                end
            end

            % Validate color dimensions
            if ~iscell(color)
                % Single color for all objects - convert to cell array
                color = repmat(color, numel(idArray), 1);  % Create cell array of repeated colors
            end

            % Identify which objects to update vs. which to add new
            updateIndices = false(numel(idArray), 1);
            updateIdxMap = zeros(numel(idArray), 1);
            
            for i = 1:numel(idArray)
                existingIdx = find(obj.objectIdArray == idArray(i), 1);
                objectExists = ~isempty(existingIdx) && isvalid(obj.supportingGraphicsHandles(existingIdx)) && ...
                ~isequal(class(obj.supportingGraphicsHandles(existingIdx)), 'matlab.graphics.GraphicsPlaceholder');
                % the object exists if it corresponds to an id, is valid and an actual graphics object, not a placeholder
                if objectExists
                    updateIndices(i) = true;
                    updateIdxMap(i) = existingIdx;
                end
            end
            
            % Update existing objects
            for i = find(updateIndices)'
                existingIdx = updateIdxMap(i);
                originalIdx = i;
                
                % Delete the existing object
                if isvalid(obj.supportingGraphicsHandles(existingIdx))
                    delete(obj.supportingGraphicsHandles(existingIdx));
                end
                
                % Create new object
                objectHandle = obj.plotSupportingObject(dataArray{originalIdx}, idArray(originalIdx), color{originalIdx}, obj.visible, isSelected);
                obj.supportingGraphicsHandles(existingIdx) = objectHandle;
                
                % Maintain exclusion status
                if obj.excluded(existingIdx)
                    set(objectHandle, 'Visible', 'off');
                end
            end
            
            % Add new objects
            newObjIndices = find(~updateIndices);
            
            if ~isempty(newObjIndices)
                % Prepare arrays for new objects
                currentSize = numel(obj.objectIdArray);
                newSize = currentSize + numel(newObjIndices);
                
                % Resize arrays
                oldHandles = obj.supportingGraphicsHandles;
                oldIds = obj.objectIdArray;
                oldExcluded = obj.excluded;
                
                obj.supportingGraphicsHandles = gobjects(newSize, 1);
                obj.objectIdArray = zeros(newSize, 1);
                obj.excluded = false(newSize, 1);
                
                % Copy existing data
                obj.supportingGraphicsHandles(1:currentSize) = oldHandles;
                obj.objectIdArray(1:currentSize) = oldIds;
                obj.excluded(1:currentSize) = oldExcluded;
                obj.excluded(currentSize + 1:end) = isExcluded(newObjIndices);
                
                % Add new objects
                for i = 1:numel(newObjIndices)
                    idx = currentSize + i;
                    originalIdx = newObjIndices(i);
                    
                    objectHandle = obj.plotSupportingObject(dataArray{originalIdx}, idArray(originalIdx), color{originalIdx}, obj.visible, isSelected);
                    obj.supportingGraphicsHandles(idx) = objectHandle;
                    obj.objectIdArray(idx) = idArray(originalIdx);
                    obj.groupIdArray(idx) = groupIdArray(originalIdx);
                end
            end

            obj.setExcluded(obj.excluded); % TO OPTIMIZE - this might be done just for new objects
        end
    end
end