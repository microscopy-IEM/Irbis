classdef GraphicsObjectGroup < handle

    % A class for managing groups of 3D graphics objects in MATLAB
    %
    % The GraphicsObjectGroup class provides functionality to manage collections of
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
    %   GraphicsObjectGroup - Constructor
    %   setVisibility      - Set visibility state of non-excluded objects
    %   setLightingMethod  - Set lighting method for non-excluded objects
    %   setTransparency    - Set transparency level for non-excluded objects
    %   setExcluded        - Set which objects are excluded from group operations
    %   setColor          - Set color for non-excluded objects
    %   deleteGraphics    - Delete all graphics objects in the group
    %   initializeGroup   - Create initial set of graphics objects
    %   addGraphicsObjects - Add or update objects in the group
    %   plotObject        - Create a single graphics object
    %
    % Example:
    %   axes = gca;
    %   group = GraphicsObjectGroup(axes, 'myGroup', 'gouraud', 0.5, [1 0 0]);
    %   group.initializeGroup(vertices, faces, ids, @clickCallback);

    properties
        objectIdArray              % Array of object IDs
        GraphicsHandles % Array of graphics object handles
        excluded
        visible = "on" % Visibility state of the objects

        color
        transparency
        lightingMethod

        parentAxes % Parent axes for the graphics objects
        buttonDownCallback % Callback function for button down press
        callbackEnabled

        tag
    end

    methods
        % Constructor
        function obj = GraphicsObjectGroup(parentAxes, tag, lightingMethod, transparency, color)
            obj.parentAxes = parentAxes;
            obj.tag = tag;
            obj.lightingMethod = lightingMethod;
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
