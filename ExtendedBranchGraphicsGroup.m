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

            partiallyVisible = isequal(obj.visible, 'on') || isequal(obj.supportingGraphicsVisible, 'on');
            if partiallyVisible
                set(obj.idLabel, 'Visible', 'on');
            else
                set(obj.idLabel, 'Visible', 'off');
            end
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
            
            % Apply colors to supporting graphics using the same logic as parent
            obj.applySupportingColors();
        end


        function setBranchColor(obj, color)
            arguments
                obj BranchGraphicsGroup
                color (1,3) double {mustBeInRange(color, 0, 1)}
            end
            % Set the branch-wide color
            setBranchColor@BranchGraphicsGroup(obj, color);
            if ~obj.isColorcoded
                obj.applySupportingColors();
            end
        end


        function setColorArray(obj, colorArray)
            arguments
                obj BranchGraphicsGroup
                colorArray (:,1) cell % Cell array of 1x3 doubles
            end
            % Set individual colors for each object
            setColorArray@BranchGraphicsGroup(obj, colorArray);
            if obj.isColorcoded
                obj.applySupportingColors();
            end
        end


        function setColorCoded(obj, isColorcoded)
            arguments
                obj BranchGraphicsGroup
                isColorcoded (1,1) logical
            end
            % Switch between color-coded and branch color modes
            setColorCoded@BranchGraphicsGroup(obj, isColorcoded);
            obj.applySupportingColors();
        end


        function applySupportingColors(obj)
            % Apply colors to supporting graphics objects based on current color mode
            if isempty(obj.supportingGraphicsHandles)
                return; % No supporting graphics handles to update
            end
            
            if obj.isColorcoded && ~isempty(obj.colorArray)
                % Use individual colors
                for i = 1:length(obj.supportingGraphicsHandles)
                    isSelected = ismember(obj.objectIdArray(i), obj.selectedIds(:));
                    if ~isSelected
                        mustBeInRange(obj.colorArray{i}, 0, 1);
                        set(obj.supportingGraphicsHandles(i), obj.colorIdentifier, obj.colorArray{i});
                    end
                end
            else
                % Use branch color
                if ~isempty(obj.branchColor)
                    mustBeInRange(obj.branchColor, 0, 1);
                    isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
                    set(obj.supportingGraphicsHandles(~isSelected), obj.colorIdentifier, obj.branchColor);
                end
            end
        end


        function updateIdLabel(obj, id)
            % Update the ID label for the selected object
            arguments
                obj BranchGraphicsGroup
                id {mustBeNumeric, mustBePositive}
            end

            updateIdLabel@BranchGraphicsGroup(obj, id);
            if isempty(obj.GraphicsHandles) && ~isempty(obj.supportingGraphicsHandles)
                xPos = mean([obj.supportingGraphicsHandles.XData], 2);
                yPos = mean([obj.supportingGraphicsHandles.YData], 2);
                zPos = mean([obj.supportingGraphicsHandles.ZData], 2);

                obj.idLabel.Position = [xPos, yPos, zPos];
            end

            obj.idLabel.Visible = "on";     % TO OPTIMIZE - this might not be necessary if it is switched properly elsewhere
                % the problem at the moment is that setting setVisibility turns label visibility off, even if centreline is still visible
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
                set(obj.supportingGraphicsHandles(idx), 'Selected', "on", ...
                    obj.colorIdentifier, obj.selectionColor);   % For Line objects, use 'Color' instead of 'FaceColor'
                % set(obj.supportingGraphicsHandles(idx), 'ContextMenu', obj.contextMenu);
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
                
                % Use the new color logic based on color mode
                if obj.isColorcoded && ~isempty(obj.colorArray)
                    objectColor = obj.colorArray{idx};
                else
                    objectColor = obj.branchColor;
                end

                set(obj.supportingGraphicsHandles(idx), 'Selected', "off", ...
                    obj.colorIdentifier, objectColor);   % For Line objects, use 'Color' instead of 'FaceColor'
                % set(obj.supportingGraphicsHandles(idx), 'ContextMenu', []);
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
            % set(obj.supportingGraphicsHandles(isSelected), 'ContextMenu', obj.contextMenu);
            set(obj.supportingGraphicsHandles(~isSelected), 'Selected', "off");
            % set(obj.supportingGraphicsHandles(~isSelected), 'ContextMenu', []);

            % Update the selection color for selected objects
            set(obj.supportingGraphicsHandles(isSelected), obj.colorIdentifier, obj.selectionColor);
            
            % Reset the color for non-selected objects based on color mode
            if obj.isColorcoded && ~isempty(obj.colorArray)
                for i = 1:length(obj.supportingGraphicsHandles)
                    if ~isSelected(i)
                        set(obj.supportingGraphicsHandles(i), obj.colorIdentifier, obj.colorArray{i});
                    end
                end
            else
                set(obj.supportingGraphicsHandles(~isSelected), obj.colorIdentifier, obj.branchColor);
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


        function deleteGraphics(obj)
            % disp('Deleting ExtendedBranchGraphicsGroup object and its supporting graphics...');
            obj.deleteSupportingGraphics; % Delete supporting graphics handles
            deleteGraphics@BranchGraphicsGroup(obj); % Call the parent class delete method
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

            % Find indices of the objects to delete in the supporting graphics handles
            isToDelete = ismember(obj.objectIdArray, objectIds);
            if any(isToDelete) && ~isempty(obj.supportingGraphicsHandles)
                delete(obj.supportingGraphicsHandles(isToDelete)); % Delete supporting graphics handles
                obj.supportingGraphicsHandles(isToDelete) = []; % Remove deleted handles from the array
            end

            % Call the parent method to delete main graphics objects
            % Moved after deleting supporting graphics, because otherwise the objectIdArray element is deleted too early
            deleteObjects@BranchGraphicsGroup(obj, objectIds);
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

            % disp('Initializing supporting graphics objects...');

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
            % obj.selectedIds = []; % Initialize empty selection
            % We do not want to initialize selectedIds here, because that way, we would delete the current selection from main objects
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
        
                % Determine color for this object based on color mode
                if obj.isColorcoded && ~isempty(obj.colorArray)
                    objectColor = obj.colorArray{i};
                else
                    objectColor = obj.branchColor;
                end
                objectHandle = obj.plotSupportingObject(datapoints, id, objectColor, obj.visible, "off");
                obj.supportingGraphicsHandles(i) = objectHandle;
            end

            % Activate selection, which might be already set from the parent objects
            selectedIds = intersect(obj.objectIdArray, obj.selectedIds(:));
            obj.setSelected(selectedIds);
        end


        function initializeExtendedGroup(obj, verticesArray, facesArray, dataArray, idArray, groupIdArray, colorArray, isExcluded, buttonDownCallback)
            arguments
                obj BranchGraphicsGroup
                verticesArray (:, 1) cell
                facesArray (:, 1) cell
                dataArray (:, 1) cell
                idArray (1,:) {mustBeNumeric}
                groupIdArray (1,:) {mustBeNumeric}
                colorArray (:,1) cell = {}
                isExcluded (1,:) logical = false(1, numel(idArray))
                buttonDownCallback function_handle = []
            end

            obj.initializeGroup(verticesArray, facesArray, idArray, groupIdArray, colorArray, isExcluded, buttonDownCallback);

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
        
                % Determine color for this object based on color mode
                if obj.isColorcoded && ~isempty(obj.colorArray)
                    objectColor = obj.colorArray{i};
                else
                    objectColor = obj.branchColor;
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

            % disp('Plotting supporting object...');
            % disp(visibilityStatus);

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

            % if isequal(selectionStatus, "on") 
            %     objectHandle.ContextMenu = obj.contextMenu; 
            % else
            %     objectHandle.ContextMenu = []; % Remove context menu if not selected
            % end

            objectHandle.SelectionHighlight = 'off'; % blocked default highlight (we do it by changing color)
        end


        function addSupportingObjects(obj, dataArray, idArray, groupIdArray, colorArray, isExcluded, isSelected)
            % Add supporting objects to the group
            arguments
                obj BranchGraphicsGroup
                dataArray (:, 1) cell
                idArray (1,:) {mustBeNumeric}
                groupIdArray (1,:) {mustBeNumeric}
                colorArray (:,1) cell = {} % Optional cell array of colors for individual objects
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
            if length(colorArray) ~= length(idArray)
                error('Number of colors must match number of objects');
            end
            if isempty(obj.colorArray)
                obj.colorArray = repmat({obj.branchColor}, length(obj.objectIdArray), 1);
            end
            color = colorArray;

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
                obj.colorArray{existingIdx} = color{originalIdx};
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
                    obj.colorArray{idx} = color{originalIdx};
                end
            end

            obj.setExcluded(obj.excluded); % TO OPTIMIZE - this might be done just for new objects
        end
    end
end