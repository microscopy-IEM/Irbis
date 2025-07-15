classdef BranchGraphicsGroup < handle

    % A class for managing groups of 3D graphics objects in MATLAB
    %
    % The BranchGraphicsGroup class provides functionality to manage collections of
    % 3D graphics objects (patches) with shared properties and behaviors. It handles
    % object creation, deletion, visibility, appearance, and interactive features.
    %
    % Properties:
    %   objectIdArray      - Cell array containing IDs of graphics objects
    %   GraphicsHandles    - Array of graphics object handles 
    %   excluded           - Logical array marking objects to exclude from operations
    %   visible            - Visibility state of objects ("on"/"off")
    %   color             - Color specification for objects (1x3 or Nx3 RGB values)
    %   transparency      - Alpha value for object transparency (0-1)
    %   lightingMethod    - Lighting method ("gouraud"/"flat")
    %   parentAxes        - Handle to parent axes containing the objects
    %   buttonDownCallback - Function handle for mouse click interactions
    %   callbackEnabled   - Flag indicating if click callback is enabled
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
        excluded          % Logical array indicating which objects are excluded from operations
        selected    % Logical array indicating which objects are selected

        visible = "on" % Visibility state of the objects
        pickableParts = "visible" % Pickable parts of the objects

        color
        transparency
        lightingMethod

        parentAxes % Parent axes for the graphics objects
        buttonDownCallback % Callback function for button down press
        callbackEnabled
        selectionColor
        
        contextMenuHandle % Context menu handle for right-click actions

        tag
    end

    methods
        % Constructor
        function obj = BranchGraphicsGroup(parentAxes, tag, lightingMethod, selectionColor, transparency, color)
            obj.parentAxes = parentAxes;
            obj.tag = tag;
            obj.lightingMethod = lightingMethod;
            obj.selectionColor = selectionColor;
            obj.transparency = transparency;
            obj.color = color;
            obj.visible = "on";
        end

        % Method to update visibility
        function setVisibility(obj, state)
            arguments
                obj
                state {mustBeMember(state, ["on", "off"])}
            end
            set(obj.GraphicsHandles(~obj.excluded), 'Visible', state);
        end

        function setLightingMethod(obj, method)
            arguments
                obj
                method {mustBeMember(method, ["gouraud", "flat"])}
            end
            set(obj.GraphicsHandles(~obj.excluded), 'FaceLighting', method);
        end

        function setTransparency(obj, alpha)
            arguments
                obj
                alpha (1,1) {mustBeInRange(alpha, 0, 1)}
            end
            set(obj.GraphicsHandles(~obj.excluded), 'FaceAlpha', alpha);
        end

        function setExcluded(obj, excluded)
            arguments
                obj
                excluded (1,:) logical
            end
            obj.excluded = excluded;
            set(obj.GraphicsHandles(obj.excluded), 'Visible', 'off');
            set(obj.GraphicsHandles(~obj.excluded), 'Visible', obj.visible);
        end

        function setPickableParts(obj, pickableParts)
            arguments
                obj
                pickableParts {mustBeMember(pickableParts, ["visible", "all", "none"])}
            end
            set(obj.GraphicsHandles(~obj.excluded), 'PickableParts', pickableParts);
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
            set(obj.GraphicsHandles(~obj.excluded), 'FaceColor', color);
            elseif iscell(color)
            % Individual color for each object
            if length(color) ~= length(obj.GraphicsHandles)
                error('Number of colors must match number of graphics objects');
            end
            for i = 1:length(obj.GraphicsHandles)
                if ~obj.excluded(i)
                mustBeInRange(color{i}, 0, 1);
                set(obj.GraphicsHandles(i), 'FaceColor', color{i});
                end
            end
            else
            error('Color must be either a 1x3 double array or cell array of 1x3 doubles');
            end
        end

        function deselectAllAndChangeSelectionForId(obj, id)

            idx = find(strcmp(id, obj.objectIdArray), 1);

            if isempty(idx)
                error('Object with ID "%s" not found in the group.', id);
            end

            selectionState = obj.selected(idx);
            obj.selected(:) = false; % Deselect all objects
            obj.selected(idx) = ~selectionState; % Toggle the selection state of the specified object

            obj.setSelected(obj.selected, obj.contextMenuHandle); % Update the selection state of all objects
        end

        function changeSelectionForId(obj)
            idx = find(strcmp(id, obj.objectIdArray), 1);

            if isempty(idx)
                error('Object with ID "%s" not found in the group.', id);
            end

            selectionState = obj.selected(idx);
            obj.selected(idx) = ~selectionState; % Toggle the selection state of the specified object

            obj.setSelected(obj.selected, obj.contextMenuHandle); % Update the selection state of all objects
        end

        function deselectAll(obj)
            obj.selected(:) = false; % Deselect all objects
            obj.setSelected(obj.selected, obj.contextMenuHandle); % Update the selection state of all objects
        end

        function setSelected(obj, selected, contextMenuHandle)
            arguments
                obj
                selected (1,:) logical
                contextMenuHandle
            end
            obj.selected = selected;
            % Set the selected property for each graphics object
            set(obj.GraphicsHandles(obj.selected), 'Selected', "on");
            set(obj.GraphicsHandles(~obj.selected), 'Selected', "off");

            % Update the selection color for selected objects
            set(obj.GraphicsHandles(obj.selected), 'FaceColor', obj.selectionColor);
            % Reset the color for non-selected objects
            if iscell(obj.color)
                for i = 1:length(obj.GraphicsHandles)
                    if ~obj.selected(i) && ~obj.excluded(i)
                        set(obj.GraphicsHandles(i), 'FaceColor', obj.color{i});
                    end
                end
            else
                set(obj.GraphicsHandles(~obj.selected), 'FaceColor', obj.color);
            end

            % Add contextMenu function to selected objects
            if ~isempty(contextMenuHandle) && isvalid(contextMenuHandle)
                set(obj.GraphicsHandles(obj.selected), 'ContextMenu', contextMenuHandle);
            end
        end

        function setSelectionColor(obj, color)
            arguments
                obj
                color (1,3) double {mustBeInRange(color, 0, 1)}
            end
            obj.selectionColor = color;
            set(obj.GraphicsHandles(obj.selected), 'FaceColor', color);
        end

        % Method to delete graphics objects explicitly
        function deleteGraphics(obj)
            if isvalid(obj.GraphicsHandles)
                delete(obj.GraphicsHandles);
            end
            obj.GraphicsHandles = matlab.graphics.Graphics.empty();
        end

        % Destructor (when class instance is deleted)
        function delete(obj)
            obj.deleteGraphics();
        end

        function deleteObjects(obj, objectIds)
            % Delete objects with specified IDs
            if isempty(objectIds)
                return;
            end

            for i = 1:numel(objectIds)
                idx = find(strcmp(obj.objectIdArray, objectIds{i}), 1);
                if ~isempty(idx) && isvalid(obj.GraphicsHandles(idx))
                    delete(obj.GraphicsHandles(idx));
                    obj.GraphicsHandles(idx) = [];
                    obj.objectIdArray(idx) = [];
                    obj.excluded(idx) = []; % Remove the excluded status for the deleted object
                    obj.selected(idx) = []; % Remove the selected status for the deleted object

                    % Do the same for color, if it is a cell array
                    if iscell(obj.color)
                        obj.color(idx) = []; % Remove the color for the deleted object
                    end
                end
            end
        end

        function initializeGroup(obj, verticesArray, facesArray, idArray, buttonDownCallback)

            % Check if the input is empty
            if isempty(verticesArray) || isempty(facesArray) || isempty(idArray)
                obj.GraphicsHandles = matlab.graphics.Graphics.empty();
                obj.objectIdArray = {};
                return;
            end
        
            if isempty(buttonDownCallback)
                obj.callbackEnabled = false;
                obj.buttonDownCallback = [];
            else
                obj.callbackEnabled = true;
                obj.buttonDownCallback = buttonDownCallback;
            end

            nObjects = numel(idArray);
            obj.GraphicsHandles = gobjects(nObjects,1);
            obj.objectIdArray = idArray;
        
            % Loop through each object and plot it
            for i = 1:numel(idArray)
                % Extract vertices and faces for the current object
                vertices = verticesArray{i};
                faces = facesArray{i};
                id = idArray{i};
        
                % Determine color for this object based on color type
                if iscell(obj.color)
                    objectColor = obj.color{i};
                else
                    objectColor = obj.color;
                end
                objectHandle = obj.plotObject(vertices, faces, id, objectColor, obj.visible, "off");
                obj.GraphicsHandles(i) = objectHandle;
            end
        
        
        end

        function addGraphicsObjects(obj, verticesArray, facesArray, idArray, color)
            % Adds new graphics objects to the group or updates existing ones with the same ID
            
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
            if nargin < 5 || isempty(color)
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
                existingIdx = find(strcmp(obj.objectIdArray, idArray{i}), 1);
                if ~isempty(existingIdx)
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
                objectHandle = obj.plotObject(verticesArray{originalIdx}, facesArray{originalIdx}, idArray{originalIdx}, color{originalIdx}, obj.visible, "off");
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
                obj.objectIdArray = cell(newSize, 1);
                obj.excluded = false(newSize, 1);
                
                % Copy existing data
                obj.GraphicsHandles(1:currentSize) = oldHandles;
                obj.objectIdArray(1:currentSize) = oldIds;
                obj.excluded(1:currentSize) = oldExcluded;
                
                % Add new objects
                for i = 1:numel(newObjIndices)
                    idx = currentSize + i;
                    originalIdx = newObjIndices(i);
                    
                    objectHandle = obj.plotObject(verticesArray{originalIdx}, facesArray{originalIdx}, idArray{originalIdx}, color{originalIdx}, obj.visible, "off");
                    obj.GraphicsHandles(idx) = objectHandle;
                    obj.objectIdArray{idx} = idArray{originalIdx};
                end
            end
        end

        function [verticesArray, facesArray, colorArray] = reorganizeTableData(obj, dataTable, verticesCol, facesCol, colorCol)
            % Reorganizes data from a table to match the order of objectIdArray
            %
            % Parameters:
            %   dataTable   - Table with row names as object IDs
            %   verticesCol - Name of column containing vertices data
            %   facesCol    - Name of column containing faces data
            %   colorCol    - Name of column containing color data (optional)
            %
            % Returns:
            %   verticesArray - Cell array of vertices in objectIdArray order
            %   facesArray    - Cell array of faces in objectIdArray order
            %   colorArray    - Cell array of colors in objectIdArray order (if specified)
            
            % Validate inputs
            arguments
                obj
                dataTable table
                verticesCol string
                facesCol string
                colorCol string = ""
            end
            
            % Check if table has row names
            if ~ismember('RowNames', dataTable.Properties.DimensionNames)
                error('Input table must have row names as object IDs');
            end
            
            % Get row names as IDs
            tableIds = dataTable.Properties.RowNames;
            
            % Initialize output arrays
            n = length(obj.objectIdArray);
            verticesArray = cell(n, 1);
            facesArray = cell(n, 1);
            colorArray = cell(n, 1);
            
            % For each ID in objectIdArray, find corresponding row in table
            for i = 1:n
                currentId = obj.objectIdArray{i};
                rowIdx = find(strcmp(tableIds, currentId));
                
                if isempty(rowIdx)
                    warning('Object ID "%s" not found in table', currentId);
                    verticesArray{i} = [];
                    facesArray{i} = [];
                    colorArray{i} = [];
                else
                    % Extract data for this ID
                    verticesArray{i} = dataTable{rowIdx, verticesCol};
                    facesArray{i} = dataTable{rowIdx, facesCol};
                    
                    % Extract color if specified
                    if ~isempty(colorCol) && ismember(colorCol, dataTable.Properties.VariableNames)
                        colorArray{i} = dataTable{rowIdx, colorCol};
                    else
                        colorArray{i} = [];
                    end
                end
            end
            
            % If color column wasn't specified, return empty
            if isempty(colorCol) || ~ismember(colorCol, dataTable.Properties.VariableNames)
                colorArray = [];
            end
        end

        function objectHandle = plotObject(obj, vertices, faces, id, color, visibilityStatus, selectionStatus)

            % Create a patch object for the current object
            objectHandle = patch(obj.parentAxes, 'Vertices', vertices, 'Faces', faces, 'UserData', id);
        
            % Individually set properties
            objectHandle.Visible = visibilityStatus; % Set visibility

            objectHandle.FaceColor = color; % Set face color
            objectHandle.Selected = selectionStatus; % Set selection state

            obj.excluded = false(size(obj.GraphicsHandles)); % Initialize excluded property
            
            % Properties depending on the group state
            objectHandle.Tag = obj.tag;
            objectHandle.FaceAlpha = obj.transparency;
            objectHandle.FaceLighting = obj.lightingMethod;
            if obj.callbackEnabled
                objectHandle.ButtonDownFcn = obj.buttonDownCallback;
            else    
                objectHandle.ButtonDownFcn = [];
            end
        
            % Constant properties
            objectHandle.LineStyle = 'none';
            objectHandle.SelectionHighlight = 'off'; % blocked default highlight (we do it by changing color)
        end
    end
end

% plotting all objects anew
    % app.plotObjects(branch)
    % connected to initialization of a new instance
% adding new objects to already existing
    % app.plotObjects(branch,'rowIds',objectIds,'selectListed',1);


% does it make sense to instantiate a new group without simultaneously adding objects?
