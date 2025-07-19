classdef BranchGraphicsGroup < handle

    % A class for managing groups of 3D graphics objects in MATLAB
    %
    % The BranchGraphicsGroup class provides functionality to manage collections of
    % 3D graphics objects (patches) with shared properties and behaviors. It handles
    % object creation, deletion, visibility, appearance, and interactive features.
    %
    % Properties:
    %   objectIdArray      - Numeric array containing IDs of graphics objects
    %   GraphicsHandles    - Array of graphics object handles 
    %   excluded           - Logical array marking objects to exclude from operations
    %   visible            - Visibility state of objects ("on"/"off")
    %   color             - Color specification for objects (1x3 or Nx3 RGB values)
    %   transparency      - Alpha value for object transparency (0-1)
    %   lightingMethod    - Lighting method ("gouraud"/"flat")
    %   parentAxes        - Handle to parent axes containing the objects
    %   buttonDownCallback - Function handle for mouse click interactions
    %   tag              - String identifier for the group
    %
    % Methods:
    %   BranchGraphicsGroup - Constructor
    %   setVisibility      - Set visibility state of non-excluded objects
    %   setLightingMethod  - Set lighting method for non-excluded objects
    %   setTransparency    - Set transparency level for non-excluded objects
    %   setExcluded        - Set which objects are excluded from group operations
    %   setColor          - Set color for non-excluded objects
    %   deleteGraphics    - Delete all graphics objects in the group
    %   initializeGroup   - Create initial set of graphics objects
    %   addGraphicsObjects - Add or update objects in the group
    %   plotObject        - Create a single graphics object
    %   reorganizeTableData - Reorganize table data to match objectIdArray order
    %
    % Example:
    %   axes = gca;
    %   group = BranchGraphicsGroup(axes, 'myGroup', 'gouraud', 0.5, [1 0 0]);
    %   group.initializeGroup(vertices, faces, ids, @clickCallback);

    properties
        GraphicsHandles % Array of graphics object handles
        objectIdArray              % Array of object IDs
        groupIdArray
        excluded          % Logical array indicating which objects are excluded from operations

        visible = "on" % Visibility state of the objects
        pickableParts = "visible" % Pickable parts of the objects

        color
        transparency
        lightingMethod

        parentAxes % Parent axes for the graphics objects
        buttonDownCallback % Callback function for button down press
        selectionColor
        
        contextMenu % Context menu handle that needs to be assigned to selected graphics objects

        currentId = []  % Id of the last right-clicked object, used for context menu actions
        
        tag

        branch % Reference to the branch this group belongs to

        boundingBoxShown = false % Flag to show bounding box around the object

        idLabel

        updateGraphicsInfotext
    end


    properties (SetObservable, AbortSet) % Properties that can be set and observed for changes
        % These properties can be set and will trigger updates in the graphics objects
        selectedIds = [] % Numerical array containing indices of selected objects from objectIdArray
    end


    methods
        % Constructor
        function obj = BranchGraphicsGroup(parentAxes, branch, lightingMethod, selectionColor, transparency, color, contextMenuGenerator)
            arguments
                parentAxes matlab.graphics.axis.Axes
                branch char
                lightingMethod {mustBeMember(lightingMethod, ["gouraud", "flat"])}
                selectionColor (1,3) double {mustBeInRange(selectionColor, 0, 1)}
                transparency (1,1) double {mustBeInRange(transparency, 0, 1)}
                color % Can be either (1,3) double or cell array of (1,3) doubles
                contextMenuGenerator function_handle % Function to generate context menu
            end
            obj.parentAxes = parentAxes;
            obj.branch = branch;
            obj.tag = [branch 'MeshPlot'];
            obj.lightingMethod = lightingMethod;
            obj.selectionColor = selectionColor;
            obj.transparency = transparency;
            obj.color = color;
            obj.visible = "on";
            obj.contextMenu = contextMenuGenerator(obj); % Store the generated context menu

            obj.idLabel = text(parentAxes,'FontSize', 20, 'Color', [1,1,1], 'PickableParts', 'none');   %'Tag','objectIDText',
        end


        function setInfotextFunction(obj, updateFunction)
            % Set the function handle to update the graphics infotext
            arguments
                obj
                updateFunction function_handle
            end
            obj.updateGraphicsInfotext = updateFunction; % Store the function handle
        end


        function branch = getBranch(obj)
            % Method to get the branch name
            branch = obj.branch;
        end


        function rightClickedId = getRightClickedId(obj)
            % Method to get the ID of the last right-clicked object
            rightClickedId = obj.currentId;
        end


        function setRightClickedId(obj, id)
            % Method to set the ID of the last right-clicked object
            obj.currentId = id;
        end


        function resetRightClickedId(obj)
            % Method to reset the ID of the last right-clicked object
            obj.currentId = [];
        end


        function useNonstandardCallback(obj, nonstandardCallbackFunction)
            % The stored callback still remains the default one
            set(obj.GraphicsHandles, 'ButtonDownFcn', nonstandardCallbackFunction);
        end


        function resetCallback(obj)
            set(obj.GraphicsHandles, 'ButtonDownFcn', obj.buttonDownCallback);
        end


        % Method to update visibility
        function setVisibility(obj, state)
            arguments
                obj
                state {mustBeMember(state, ["on", "off"])}
            end
            set(obj.idLabel, 'Visible', state); % Update visibility of the ID label
            obj.visible = state; % Store the visibility state
            if isempty(obj.GraphicsHandles)
                return; % No graphics handles to update
            end
            set(obj.GraphicsHandles(~obj.excluded), 'Visible', state);
        end


        function setIdLabelVisibility(obj, state)
            % Set visibility of the ID label
            arguments
                obj
                state {mustBeMember(state, ["on", "off"])}
            end
            set(obj.idLabel, 'Visible', state);
        end


        function setLightingMethod(obj, method)
            arguments
                obj
                method {mustBeMember(method, ["gouraud", "flat"])}
            end
            obj.lightingMethod = method; % Store the lighting method
            set(obj.GraphicsHandles, 'FaceLighting', method);
        end


        function setTransparency(obj, alpha)
            arguments
                obj
                alpha (1,1) {mustBeInRange(alpha, 0, 1)}
            end
            obj.transparency = alpha; % Store the transparency property
            set(obj.GraphicsHandles, 'FaceAlpha', alpha);
        end


        function setExcluded(obj, excluded)
            arguments
                obj
                excluded (1,:) logical
            end
            % passing the logical array counts with having the objects up to date with the table
            % this is probably reasonable, because the ids also require this
            obj.excluded = excluded;
            set(obj.GraphicsHandles(obj.excluded), 'Visible', 'off');
            set(obj.GraphicsHandles(~obj.excluded), 'Visible', obj.visible);
        end


        function setPickableParts(obj, pickableParts)
            arguments
                obj
                pickableParts {mustBeMember(pickableParts, ["visible", "all", "none"])}
            end
            obj.pickableParts = pickableParts; % Store the pickable parts property
            set(obj.GraphicsHandles, 'PickableParts', pickableParts);
        end


        function setColor(obj, color)
            arguments
                obj
                color % Can be either a 1x3 double array or cell array of 1x3 doubles
            end
            
            % Store the color property
            obj.color = color;
            
            if isa(color, 'double')
                % Single color for all non-excluded objects
                mustBeInRange(color, 0, 1);
                set(obj.GraphicsHandles, 'FaceColor', color);
            elseif iscell(color)
                % Individual color for each object
                if (length(color) ~= length(obj.objectIdArray)) % Graphics handles can be empty, if extended wrapper is used
                    error('Number of colors must match number of graphics objects');
                end
                for i = 1:length(obj.GraphicsHandles)
                    isSelected = ismember(obj.objectIdArray(i), obj.selectedIds(:));
                    if ~isSelected
                        mustBeInRange(color{i}, 0, 1);
                        set(obj.GraphicsHandles(i), 'FaceColor', color{i});
                    end
                end
            else
                error('Color must be either a 1x3 double array or cell array of 1x3 doubles');
            end
        end


        function updateIdLabel(obj, id)
            % Update the ID label
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Object with ID "%d" not found in the group.', id);
                return
            end
            groupId = obj.groupIdArray(idx);
            if groupId == 0
                groupId = '-'; % Handle case where groupId is zero
            end
            obj.idLabel.String = [num2str(id) ' (' num2str(groupId) ')'];
            obj.idLabel.Position = mean(obj.GraphicsHandles(idx).Vertices(), 1);
        end


        function turnIndividualSelectionOn(obj, id)
            % Turn on selection for a specific object by ID
            % disp(class(id))
            % disp(['Turning on selection for object with ID: ' num2str(id)]);
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Object with ID "%d" not found in the group.', id);
                return
            end
            if ~ismember(id, obj.selectedIds)
                obj.selectedIds = [obj.selectedIds id]; % Add to selected indices
            end
            if ~isempty(obj.GraphicsHandles)
                set(obj.GraphicsHandles(idx), 'Selected', "on", 'FaceColor', obj.selectionColor); % Update the graphics object
            end
            obj.updateIdLabel(id); % Update the ID label position and text

            if ~isempty(obj.updateGraphicsInfotext)
                % Call the infotext update function if it is set
                obj.updateGraphicsInfotext(obj.branch, id, obj.selectedIds);
            end

            obj.plotBoundingBox();
        end


        function turnIndividualSelectionOff(obj, id)
            % Turn off selection for a specific object by ID
            idx = find(id == obj.objectIdArray, 1);
            if isempty(idx)
                warning('Object with ID "%d" not found in the group.', id);
                return
            end
            % Remove index from selected array
            obj.selectedIds = obj.selectedIds(obj.selectedIds ~= id);
            % Update the graphics object
            if iscell(obj.color)
                objectColor = obj.color{idx};
            else
                objectColor = obj.color;
            end
            if ~isempty(obj.GraphicsHandles)
                set(obj.GraphicsHandles(idx), 'Selected', "off", 'FaceColor', objectColor);
            end
            obj.idLabel.String = '';

            if ~isempty(obj.updateGraphicsInfotext)
                % Call the infotext update function if it is set
                obj.updateGraphicsInfotext(obj.branch, [], obj.selectedIds);
            end

            obj.hideBoundingBox();
        end


        function toggleIndividualSelection(obj, id)
            % Toggle selection for a specific object by ID
            isSelected = ismember(id, obj.selectedIds);    % If id is not in objectIdArray, the process will be stopped anyway
            if isSelected
                obj.turnIndividualSelectionOff(id); % Turn off selection if it is currently on
            else
                obj.turnIndividualSelectionOn(id); % Turn on selection if it is currently off
            end
        end


        function toggleIndividualSelectionAndDeselectOthers(obj, id)
            % Deselect all objects and toggle selection for a specific object by ID
            isSelected = ismember(id, obj.selectedIds);
            obj.deselectAll();
            % Toggle selection for a specific object by ID
            if isSelected
                obj.turnIndividualSelectionOff(id); % Turn off selection if it is currently on
            else
                obj.turnIndividualSelectionOn(id); % Turn on selection if it is currently off
            end
        end


        function deselectAll(obj)
            obj.selectedIds = []; % Clear the selection array
            obj.setSelected(obj.selectedIds); % Update the selection state of all objects
            obj.idLabel.String = '';
        end


        function setSelected(obj, selectedIndices)
            arguments
                obj
                selectedIndices (1,:) {mustBeNumeric}
            end
            obj.selectedIds = selectedIndices;
            
            % Create a logical mask for all objects
            isSelected = ismember(obj.objectIdArray, selectedIndices(:));

            % infotext is updated before checking GraphicsHandles, because there might be just supporting graphics
            if ~isempty(obj.updateGraphicsInfotext)
                % Call the infotext update function if it is set
                obj.updateGraphicsInfotext(obj.branch, [], obj.selectedIds);
            end
            
            % Set the selected property for each graphics object
            if isempty(obj.GraphicsHandles)
                return; % This might happen for extended class - only supporting graphics exists
            end
            set(obj.GraphicsHandles(isSelected), 'Selected', "on");
            set(obj.GraphicsHandles(~isSelected), 'Selected', "off");

            % Update the selection color for selected objects
            set(obj.GraphicsHandles(isSelected), 'FaceColor', obj.selectionColor);
            
            % Reset the color for non-selected objects
            if iscell(obj.color)
                for i = 1:length(obj.GraphicsHandles)
                    if ~isSelected(i)
                        set(obj.GraphicsHandles(i), 'FaceColor', obj.color{i});
                    end
                end
            else
                set(obj.GraphicsHandles(~isSelected), 'FaceColor', obj.color);
            end

            obj.hideBoundingBox();
        end


        function selectedIds = getSelectedIds(obj)
            % Get IDs of all selected objects
            selectedIds = obj.selectedIds;
        end


        function selectedGroupIds = getSelectedGroupIds(obj)
            % Get group IDs of all selected objects
            isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
            selectedGroupIds = obj.groupIdArray(isSelected);
        end


        function groupId = getGroupIdForObjectId(obj, objectId)
            % Get the group ID for a specific object ID
            idx = find(obj.objectIdArray == objectId, 1);
            if isempty(idx)
                error('Object with ID "%d" not found in the group.', objectId);
            end
            groupId = obj.groupIdArray(idx);
        end


        function setSelectionColor(obj, color)
            arguments
                obj
                color (1,3) double {mustBeInRange(color, 0, 1)}
            end

            obj.selectionColor = color;
            if isempty(obj.GraphicsHandles)
                return; % No graphics handles to update
            end
            isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
            if ~isempty(obj.GraphicsHandles)
                set(obj.GraphicsHandles(isSelected), 'FaceColor', color);
            end
        end


        function hideUnselected(obj)
            % Hide all unselected objects
            if isempty(obj.GraphicsHandles)
                return; % No graphics handles to hide
            end
            isSelected = ismember(obj.objectIdArray, obj.selectedIds(:));
            set(obj.GraphicsHandles(~isSelected), 'Visible', 'off');
            set(obj.GraphicsHandles(isSelected), 'Visible', obj.visible);
        end

        
        function resetVisibility(obj)
            % Cancel hiding of unselected objects
            set(obj.GraphicsHandles, 'Visible', obj.visible);
        end


        function visibleIds = getVisibleIds(obj)
            % Get IDs of all visible objects
            if isempty(obj.GraphicsHandles)
                visibleIds = []; % No graphics handles to check visibility
                return;
            end
            visibleIds = obj.objectIdArray(~obj.excluded & strcmp({obj.GraphicsHandles.Visible}, 'on'));
        end


        % Method to delete graphics objects explicitly
        function deleteGraphics(obj)
            if ~isempty(obj.GraphicsHandles) & isvalid(obj.GraphicsHandles)
                delete(obj.GraphicsHandles);
            end
            obj.GraphicsHandles = matlab.graphics.Graphics.empty();
        end


        % Destructor (when class instance is deleted)
        function delete(obj)
            obj.deleteGraphics();
            if ~isempty(obj.idLabel) && isvalid(obj.idLabel)
                delete(obj.idLabel); % Delete the ID label if it exists
            end
            if ~isempty(obj.contextMenu) && isvalid(obj.contextMenu)
                % disp('Deleting context menu');
                delete(obj.contextMenu); % Delete the context menu if it exists
            end
        end


        function deleteObjects(obj, objectIds)
            arguments
                obj
                objectIds (:,1) {mustBeNumeric}  % Column vector of object IDs to delete
            end
            % Delete objects with specified IDs in a vectorized way
            if isempty(objectIds) || isempty(obj.objectIdArray)
                return;
            end
            
            % Find indices of objects to delete
            isToDelete = ismember(obj.objectIdArray, objectIds);
            
            if any(isToDelete)
                % Delete valid graphics handles
                if ~isempty(objectIds)
                    validHandles = isvalid(obj.GraphicsHandles);
                    isValidForDeletion = isToDelete & validHandles; % Only delete handles that are for deletion and valid
                        % & performs element-wise logical AND operation, while && compares scalar logical values
                    if any(isValidForDeletion)
                        delete(obj.GraphicsHandles(isValidForDeletion));
                    end
                    obj.GraphicsHandles(isToDelete) = [];
                end
                
                % Remove corresponding entries from all arrays
                obj.objectIdArray(isToDelete) = [];
                obj.groupIdArray(isToDelete) = [];
                obj.excluded(isToDelete) = [];
                
                % Update selected array - remove IDs that were deleted
                obj.selectedIds = setdiff(obj.selectedIds, objectIds);
                
                % Update colors if it's a cell array
                if iscell(obj.color)
                    obj.color(isToDelete) = [];
                end
            end
        end


        function initializeGroup(obj, verticesArray, facesArray, idArray, groupIdArray, isExcluded, buttonDownCallback)
            arguments
                obj
                verticesArray (:,1) cell % Cell array of vertex matrices
                facesArray (:,1) cell    % Cell array of face matrices
                idArray (:,1) double     % Column vector of object IDs
                groupIdArray (:,1) double % Column vector of group IDs
                isExcluded (:,1) logical = false % Logical array indicating which objects are excluded
                buttonDownCallback function_handle = [] % Optional callback for button press
            end

            obj.deleteGraphics(); % Clear existing graphics handles

            % Check if the input is empty
            if isempty(verticesArray) || isempty(facesArray) || isempty(idArray)
                obj.objectIdArray = [];
                obj.selectedIds = []; % Initialize empty selection
                return;
            end
        
            if isempty(buttonDownCallback)
                obj.buttonDownCallback = [];
            else
                obj.buttonDownCallback = buttonDownCallback;
            end

            nObjects = numel(idArray);
            obj.GraphicsHandles = gobjects(nObjects,1);
            obj.objectIdArray = idArray;
            obj.groupIdArray = groupIdArray;
            obj.selectedIds = []; % Initialize empty selection
            obj.excluded = isExcluded; % Initialize exclusion status for all objects
        
            % Loop through each object and plot it
            for i = 1:numel(idArray)
                % Extract vertices and faces for the current object
                vertices = verticesArray{i};
                faces = facesArray{i};
                id = idArray(i);
        
                % Determine color for this object based on color type
                if iscell(obj.color)
                    objectColor = obj.color{i};
                else
                    objectColor = obj.color;
                end
                objectHandle = obj.plotObject(vertices, faces, id, objectColor, obj.visible, "off", obj.excluded(i));
                obj.GraphicsHandles(i) = objectHandle;
            end
        end

        function addGraphicsObjects(obj, verticesArray, facesArray, idArray, groupIdArray, color, isExcluded, isSelected)
            % Adds new graphics objects to the group or updates existing ones with the same ID
            
            arguments
                obj
                verticesArray (:,1) cell    % Cell array of vertex matrices
                facesArray (:,1) cell       % Cell array of face matrices
                idArray (:,1) double        % Column vector of object IDs
                groupIdArray (:,1) double = [] % Column vector of group IDs (optional)
                color = []                  % Optional color specification
                isExcluded (:,1) logical = [] % Optional exclusion flags (keep for later implementation)
                isSelected string {mustBeMember(isSelected, ["on", "off"])} = "off" % Selection state
            end
            
            % Check for empty inputs
            if isempty(verticesArray) || isempty(facesArray) || isempty(idArray)
                return;
            end

            % If group is empty, initialize it instead
            if isempty(obj.objectIdArray)
                obj.initializeGroup(verticesArray, facesArray, idArray, obj.buttonDownCallback);
                return;
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
                objectExists = ~isempty(existingIdx) && isvalid(obj.GraphicsHandles(existingIdx)) && ...
                ~isequal(class(obj.GraphicsHandles(existingIdx)), 'matlab.graphics.GraphicsPlaceholder');
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
                if isvalid(obj.GraphicsHandles(existingIdx))
                    delete(obj.GraphicsHandles(existingIdx));
                end
                
                % Create new object
                objectHandle = obj.plotObject(verticesArray{originalIdx}, facesArray{originalIdx}, idArray(originalIdx), color{originalIdx}, obj.visible, isSelected, obj.excluded(originalIdx));
                obj.GraphicsHandles(existingIdx) = objectHandle;
                
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
                oldHandles = obj.GraphicsHandles;
                oldIds = obj.objectIdArray;
                oldExcluded = obj.excluded;
                
                obj.GraphicsHandles = gobjects(newSize, 1);
                obj.objectIdArray = zeros(newSize, 1);
                obj.excluded = false(newSize, 1);   % TO FIX
                
                % Copy existing data
                obj.GraphicsHandles(1:currentSize) = oldHandles;
                obj.objectIdArray(1:currentSize) = oldIds;
                obj.excluded(1:currentSize) = oldExcluded;
                obj.excluded(currentSize+1:end) = isExcluded(newObjIndices); % Set exclusion status for new objects
                
                % Add new objects
                for i = 1:numel(newObjIndices)
                    idx = currentSize + i;
                    originalIdx = newObjIndices(i);
                    
                    objectHandle = obj.plotObject(verticesArray{originalIdx}, facesArray{originalIdx}, idArray(originalIdx), color{originalIdx}, obj.visible, isSelected, obj.excluded(originalIdx));
                    obj.GraphicsHandles(idx) = objectHandle;
                    obj.objectIdArray(idx) = idArray(originalIdx);
                    obj.groupIdArray(idx) = groupIdArray(originalIdx);
                end
            end

            obj.setExcluded(obj.excluded); % Update visibility based on exclusion status
        end


        function updateGroupIdArray(obj, newGroupIdArray)
            arguments
                obj
                newGroupIdArray (:,1) double  % Column vector of new group IDs
            end
            % Update the groupIdArray with a new array
            if length(newGroupIdArray) ~= length(obj.groupIdArray)
                error('New group ID array must have the same length as the existing one.');
            end
            obj.groupIdArray = newGroupIdArray;

            lastSelectedId = obj.selectedIds(end);
            % Update the ID label for the last selected object
            if ~isempty(lastSelectedId)
                obj.updateIdLabel(lastSelectedId);
            end
        end


        function objectHandle = plotObject(obj, vertices, faces, id, color, visibilityStatus, selectionStatus, isExcluded)
            arguments
                obj
                vertices (:,3) double     % Nx3 matrix of vertex coordinates
                faces (:,:) double        % Face connectivity matrix
                id (1,1) double          % Object ID
                color                    % Either (1,3) double for RGB or cell containing RGB
                visibilityStatus string {mustBeMember(visibilityStatus, ["on", "off"])}
                selectionStatus string {mustBeMember(selectionStatus, ["on", "off"])}
                isExcluded (1,1) logical = false % Exclusion status for the object
            end

            % Create a patch object for the current object
            objectHandle = patch(obj.parentAxes, 'Vertices', vertices, 'Faces', faces, 'UserData', id);
        
            % Individually set properties
            if isExcluded
                visibilityStatus = "off"; % If excluded, set visibility to off
            end
            objectHandle.Visible = visibilityStatus; % Set visibility

            objectHandle.FaceColor = color; % Set face color
            objectHandle.Selected = selectionStatus; % Set selection state

            % Properties depending on the group state
            objectHandle.Tag = obj.tag;
            objectHandle.UserData = id; % Store ID in UserData
            objectHandle.PickableParts = obj.pickableParts; % Set pickable parts
            objectHandle.FaceAlpha = obj.transparency;
            objectHandle.FaceLighting = obj.lightingMethod;
            objectHandle.ButtonDownFcn = obj.buttonDownCallback;
        
            % Constant properties
            objectHandle.LineStyle = 'none';
            objectHandle.SelectionHighlight = 'off'; % blocked default highlight (we do it by changing color)

            objectHandle.ContextMenu = obj.contextMenu; % Obj passed to be able to call getSelectedIds method from context menu functions

            obj.idLabel.String = '';
        end


        function plotBoundingBox(obj)
            % Plot bounding boxes around selected objects or all objects if none selected
            
            if ~obj.boundingBoxShown
                % Delete existing bounding boxes if they exist
                delete(findobj(obj.parentAxes, 'Tag', [obj.tag '_BoundingBox']));
                return;
            end
            
            % Delete existing bounding boxes first
            delete(findobj(obj.parentAxes, 'Tag', [obj.tag '_BoundingBox']));
            
            % Determine which objects to show bounding boxes for
            if isempty(obj.selectedIds)
                return
            end

            % for id = obj.selectedIds
            %     obj.plotSingleBoundingBox(id);
            % end

            obj.plotSingleBoundingBox(obj.selectedIds(end)); % Plot bounding boxes for the last selected object
        end


        function hideBoundingBox(obj)
            % Hide bounding boxes around objects
            % This method deletes the bounding boxes without changing the visibility of the objects themselves
            delete(findobj(obj.parentAxes, 'Tag', [obj.tag '_BoundingBox']));
        end


        function plotSingleBoundingBox(obj, id)
            idx = find(obj.objectIdArray == id, 1);
            
            % Plot bounding box
            if isempty(obj.GraphicsHandles) || ~isvalid(obj.GraphicsHandles(idx))
                return
            end
            
            % Get vertices of the object
            vertices = obj.GraphicsHandles(idx).Vertices;
            
            % Calculate min and max for each dimension
            minX = min(vertices(:,1));
            maxX = max(vertices(:,1));
            minY = min(vertices(:,2));
            maxY = max(vertices(:,2));
            minZ = min(vertices(:,3));
            maxZ = max(vertices(:,3));
            
            % Calculate position and size for drawcuboid
            position = [minX, minY, minZ, maxX-minX, maxY-minY, maxZ-minZ];
            
            % Create cuboid for the bounding box
            h = drawcuboid('Position', position, 'Parent', obj.parentAxes, ...
                            'Color', [0.2, 0.6, 1.0], ... % Light blue color
                            'FaceAlpha', 0.1, ...        % Mostly transparent
                            'SelectedColor', [0.2, 0.6, 1.0], ...
                            'Tag', [obj.tag '_BoundingBox'], ...
                            'InteractionsAllowed', 'none', ...    % Make it non-interactive
                            'Label', '');                 % No label
                            
            % Store object ID in UserData
            h.UserData = obj.objectIdArray(idx);
        end


        function setBoundingBoxVisibility(obj, isShown)
            % Set visibility of bounding boxes
            arguments
                obj
                isShown logical
            end
            if isShown
                obj.boundingBoxShown = true;
            else
                obj.boundingBoxShown = false;
            end
            obj.plotBoundingBox(); % Update bounding boxes based on the new visibility state
        end
    end
end

% plotting all objects anew
    % app.plotObjects(branch)
    % connected to initialization of a new instance
% adding new objects to already existing
    % app.plotObjects(branch,'rowIds',objectIds,'selectListed',1);


% does it make sense to instantiate a new group without simultaneously adding objects?
