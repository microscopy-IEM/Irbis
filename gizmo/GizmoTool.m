classdef GizmoTool < handle 
    % Dependencies: 
    %   - MicroMToPixelPosition function for coordinate conversion from micrometers to pixels
    %   - Requires input object to also contain scale point position and vector data if scaling functionality is desired

    properties (Access = private)
        fig
        ax
        origCallbacks = struct();

        originallyPickableObjects = gobjects(0);

        componentHandles = gobjects(0);
        doesRotate = false(0);
        doesScale = false(0);
        isActive = false(0);
        scalesWithGizmoVisual = false(0);

        centrePointHandle
        normalPointHandle
        referencePointHandles = struct('x', gobjects(0), 'y', gobjects(0), 'z', gobjects(0));
        gizmoGroupHandle 
        objectHandle = gobjects(0)

        stickyPoints = [];
        stickyPointNormals = [];

        gizmoVisualScale (1,1) double = 1;
        gizmoVisualScaleMin (1,1) double = 0.4;
        gizmoVisualScaleMax (1,1) double = 3.0;
        gizmoVisualScaleStep (1,1) double = 1.08;
    end


    methods (Access = public)
        %% Input, constructor and destructor methods
        function obj = GizmoTool(ax, fig, positionVector, directionVector, objectStruct)
            % Constructor for the GizmoTool class - initializes the gizmo components, sets up callbacks, and prepares the tool for interaction

            arguments
                ax (1,1)    % axes handle where the gizmo will be plotted, can be both regular axes or uiaxes
                fig (1,1)   % can be both figure or uifigure - needed to access callbacks and pointer manager
                positionVector (1,3) double
                directionVector (1,3) double
                objectStruct struct = []
            end

            obj.fig = fig;
            obj.ax = ax;
            obj.storeOriginalCallbacks();

            % disable pickability for all currently plotted components
            obj.disableExistingObjectPickability();

            % define gizmo components (now returns gizmoGroup)
            obj.defineGizmoComponents(objectStruct);

            % move gizmo to start position
            obj.moveTo(positionVector);
            obj.rotateTo(directionVector);

            % set callbacks for gizmo components
            obj.setCallbacksForActive()

            % set selectivity and highlighting
            obj.setInteractivity()
        end



        function delete(obj)
            % Destructor for the gizmo tool - delete all the graphical objects and destroy the class instance

            % restore original pickability for objects in axes
            obj.restoreOriginalObjectPickability();

            % reset original callbacks
            obj.resetCallbacks();

            if ~isempty(obj.gizmoGroupHandle) && isvalid(obj.gizmoGroupHandle)
                delete(obj.gizmoGroupHandle);
            end
        end



        function setStickyPoints(obj, stickyPoints, stickyPointNormals)
            % Updates sticky-point data and toggles centre-point snapping interactivity.

            arguments
                obj
                stickyPoints (:,3) double
                stickyPointNormals (:,3) double
            end

            % update the sticky points used for snapping during translation
            % also updates the interactivity of the centre point based on whether sticky points are provided

            if isempty(obj.centrePointHandle)
                return;
            end

            if ~isempty(stickyPoints)
                obj.isActive(1) = true;  % assuming centre point is the first component added
                obj.stickyPoints = stickyPoints;
                obj.stickyPointNormals = stickyPointNormals;
                set(obj.centrePointHandle, "ButtonDownFcn", @(src,evt)obj.gizmoClick(src, evt));
                obj.makeObjectInteractive(obj.centrePointHandle);
            else
                obj.isActive(1) = false;
                set(obj.centrePointHandle, "ButtonDownFcn", []);
                obj.disableInteractivityForObject(obj.centrePointHandle);
            end
        end
        %%


        %% Methods for moving and rotating the gizmo to a specific position and direction
        function moveTo(obj, positionVector)
            % Translates the gizmo so its centre matches the requested position.

            % move gizmo to a position defined by the positionVector
            obj.updatePosition(positionVector, obj.componentHandles)         
        end



        function rotateTo(obj, desiredVector)
            % Rotates the gizmo so its normal direction aligns with a target vector.
            % ROTATETO Rotates the object to align with a desired direction vector
            %
            % Description:
            %   Rotates all components marked as rotatable around a calculated pivot point
            %   to align the current rotation vector with the desired vector. Uses Rodrigues'
            %   rotation formula to compute the rotation axis and angle.
            %
            % Input Arguments:
            %   desiredVector (1x3 double) - Target direction vector for rotation alignment
            %
            % Notes:
            %   - Function validates input vector for finiteness and non-zero magnitude
            %   - Handles edge cases where rotation axis is parallel/antiparallel to current vector
            %   - Early returns occur if preconditions are not met
            
            % Validate and normalize desired vector
            centrePos = obj.getCentrePositionUM();
            if ~all(isfinite(desiredVector)) || norm(desiredVector) < 1e-12
                return;
            end
            desiredVector = desiredVector / norm(desiredVector);

            % Get current rotation vector and validate
            currentVector = obj.getRotationVector();
            if norm(currentVector) < 1e-12
                return;
            end

            % Calculate rotation angle
            dotVal = max(min(dot(currentVector, desiredVector), 1), -1);
            rotationAngle = acos(dotVal);
            if rotationAngle < 1e-9
                return;
            end

            % Calculate rotation axis using cross product
            rotationAxis = cross(currentVector, desiredVector);
            axisNorm = norm(rotationAxis);
            if axisNorm < 1e-9
                rotationAxis = fallbackAxis(currentVector);
                axisNorm = norm(rotationAxis);
                if axisNorm < 1e-9
                    return;
                end
            end
            rotationAxis = rotationAxis / axisNorm;

            % Get rotatable components and apply rotation
            rotatingHandles = obj.componentHandles(obj.doesRotate);
            if isempty(rotatingHandles)
                return;
            end

            startPositionRot = obj.getRotationStartPosition(rotatingHandles);
            obj.updateDirection(rotationAxis, rotationAngle, rotatingHandles, centrePos, startPositionRot);

            % Helper function to compute fallback rotation axis
            function axis = fallbackAxis(direction)
                basis = eye(3);
                [~, idx] = min(abs(direction));
                axis = cross(direction, basis(idx, :));
                if norm(axis) < 1e-12
                    axis = cross(direction, basis(mod(idx,3)+1, :));
                end
            end
        end
        %%


        %% Output functions to get current position and rotation vector of the gizmo - used also internally
        function position = getCentrePositionUM(obj)
            % Returns the current centre-point position in micrometer coordinates.
            position = [obj.centrePointHandle.XData, obj.centrePointHandle.YData, obj.centrePointHandle.ZData];
        end


        
        function rotationVector = getRotationVector(obj)
            % Computes the normalized centre-to-normal direction vector.
            if isempty(obj.normalPointHandle) || ~isvalid(obj.normalPointHandle)
                ME = MException('GizmoTool:MissingNormalPoint', ...
                    'Normal-point handle is missing or invalid.');
                throw(ME)
            end
            centre = obj.getCentrePositionUM();
            rotationVector = [obj.normalPointHandle.XData, obj.normalPointHandle.YData, obj.normalPointHandle.ZData] - centre;
            vectorNorm = norm(rotationVector);
            if vectorNorm > 1e-12
                rotationVector = rotationVector / vectorNorm;
            end
        end
        %%


        %% Handle access functions
        function gizmoHandle = getGizmoHandle(obj)
            % Returns the handle of the main gizmo group containing all components, for external manipulation if needed.
            gizmoHandle = obj.gizmoGroupHandle;
        end



        function objectHandle = getObjectHandle(obj)
            % Returns the handle of the optional 3D object patch, if it exists and is valid.
            if isempty(obj.objectHandle)
                objectHandle = [];
            else
                validMask = isvalid(obj.objectHandle);
                objectHandle = obj.objectHandle(validMask);
            end
        end
        %%
    end




    methods (Access = private)
        %% Gizmo component creation functions - creates all the visual components of the gizmo, stores their handles and behavior flags in the class properties, and parents them to a common hggroup for easier manipulation
        function defineGizmoComponents(obj, objectStruct)
            % Creates and registers all gizmo visual components in one group.
            
            % Get configuration with all visual parameters
            config = obj.getGizmoConfig();

            if isfield(objectStruct, 'gizmoCenter')
                config.origin = objectStruct.gizmoCenter;
            end
            
            % Create hggroup to contain all gizmo components
            gizmoGroup = hggroup('Parent', obj.ax, 'Tag', 'gizmoGroup');
            
            % Create gizmo parts (all parented to the hggroup)
            obj.addCentreBall(gizmoGroup, config);
            obj.addNormalIndicator(gizmoGroup, config);
            obj.addDirectionalAxes(gizmoGroup, config);
            obj.objectHandle = obj.add3DObject(gizmoGroup, config, objectStruct);

            obj.gizmoGroupHandle = gizmoGroup;
        end



        function config = getGizmoConfig(~)
            % Returns centralized visual parameters used to build the gizmo.
            
            % Position
            config.origin = [0 0 0];
            
            % Sizes
            config.spacing = 1.2;
            config.ballSize = 12;
            config.lineWidth = 1;
            config.rotLineWidth = 5;
            config.radius = config.spacing * 1.15;  % spacing * 1.15
            
            % Colors
            config.edgeColor = [0.3 0.3 0.3];
            config.normalColor = [0.4 0.4 0.4];
            config.planeEdgeColor = [0.9 0.9 0.9];
            config.scalePointColor = 'b';
            
            % Transparency
            config.planeTransparency = 0.6;
            
            % Direction-specific settings (x, y, z)
            config.directionNames = {'x', 'y', 'z'};
            config.directionColors = {[0.7350 0.0780 0.1840], [0.4660 0.7740 0.1880], [0.3010 0.6450 0.9930]};
            config.directionVectors = {[1 0 0], [0 1 0], [0 0 1]};
        end



        function addComponent(obj, handle, rotates, scales, active, scalesWithVisual)
            % Registers one component handle together with its behavior flags.
            if nargin < 6
                scalesWithVisual = true;
            end
            obj.componentHandles(end+1) = handle;
            obj.doesRotate(end+1) = rotates;
            obj.doesScale(end+1) = scales;
            obj.isActive(end+1) = active;
            obj.scalesWithGizmoVisual(end+1) = scalesWithVisual;
        end



        function addCentreBall(obj, parent, config)
            % Creates the central translation handle at the gizmo origin.
            p0 = config.origin;
            
            cBallPoint = plot3(p0(1), p0(2), p0(3), 'k', ...
                'Parent', parent, ...
                'Marker', 'o', ...
                'MarkerFaceColor', 'k', ...
                'MarkerSize', config.ballSize, ...
                'Tag', 'cBallPoint', ...
                'MarkerEdgeColor', config.edgeColor, ...
                'LineWidth', config.lineWidth);
            
            isActiveCentre = false; % default to inactive, will be set later if sticky points are provided
            obj.addComponent(cBallPoint, false, false, isActiveCentre);

            obj.centrePointHandle = cBallPoint;
        end



        function addNormalIndicator(obj, parent, config)
            % Creates the normal line and normal endpoint drag handle.

            % Create normal direction line and ball point
            p0 = config.origin;
            spacing = config.spacing;
            
            % Normal direction line
            normLine = line('Parent', parent, ...
                'XData', [p0(1), p0(1) + 1.2*spacing], ...
                'YData', [p0(2), p0(2)], ...
                'ZData', [p0(3), p0(3)], ...
                'LineWidth', config.lineWidth, ...
                'Color', 'k', ...
                'Tag', 'normLink');
            obj.addComponent(normLine, true, false, false);
            
            % Normal ball point (rotation handle)
            normBallPoint = plot3(p0(1) + 1.25*spacing, p0(2), p0(3), ...
                'Parent', parent, ...
                'Marker', 'o', ...
                'MarkerFaceColor', config.normalColor, ...
                'MarkerSize', config.ballSize, ...
                'Tag', 'normBallPoint', ...
                'MarkerEdgeColor', config.edgeColor);
            obj.addComponent(normBallPoint, true, false, true);
            obj.normalPointHandle = normBallPoint;
        end



        function addDirectionalAxes(obj, parent, config)
            % Creates x/y/z axis handles, links, reference points, and rotation rings.
            p0 = config.origin;
            spacing = config.spacing;
            theta = -pi:0.1:pi;
            
            dirNames = config.directionNames;
            dirColors = config.directionColors;
            dirVectors = config.directionVectors;
            
            for dirN = 1:numel(dirNames)
                dirName = dirNames{dirN};
                dirColor = dirColors{dirN};
                v = dirVectors{dirN};
                
                % Translation ball point
                ballPoint = plot3(p0(1) + v(1)*spacing, p0(2) + v(2)*spacing, p0(3) + v(3)*spacing, ...
                    'Parent', parent, ...
                    'Marker', 'o', ...
                    'MarkerFaceColor', dirColor, ...
                    'MarkerSize', config.ballSize, ...
                    'Tag', [dirName 'BallPoint'], ...
                    'MarkerEdgeColor', config.edgeColor);
                obj.addComponent(ballPoint, true, false, true);
                
                % Axis line link
                lineLink = line('Parent', parent, ...
                    'XData', [p0(1), p0(1) + v(1)*spacing], ...
                    'YData', [p0(2), p0(2) + v(2)*spacing], ...
                    'ZData', [p0(3), p0(3) + v(3)*spacing], ...
                    'Tag', [dirName 'lineLink'], ...
                    'Color', dirColor, ...
                    'LineWidth', config.lineWidth);
                obj.addComponent(lineLink, true, false, false);
                
                % Hidden reference point for rotation tracking
                referencePoint = plot3(p0(1) + v(1), p0(2) + v(2), p0(3) + v(3), ...
                    'Parent', parent, ...
                    'Tag', [dirName 'referencePoint'], ...
                    'Visible', 'off');
                obj.addComponent(referencePoint, true, false, false);
                obj.referencePointHandles.(dirName) = referencePoint;
                
                % Rotation ring
                vNull = null(v);
                points = repmat(p0', 1, size(theta, 2)) + config.radius * (vNull(:,1)*cos(theta) + vNull(:,2)*sin(theta));
                rotLine = plot3(points(1,:), points(2,:), points(3,:), ...
                    'Parent', parent, ...
                    'Color', dirColor, ...
                    'LineWidth', config.rotLineWidth, ...
                    'Tag', [dirName 'RotLine']);
                obj.addComponent(rotLine, true, false, true);  
            end
        end



        function objectHandle = add3DObject(obj, parent, config, objectStruct)
            % Creates the optional 3D object patch and its scale handles.
            p0 = config.origin;
            
            if ~isstruct(objectStruct) || isempty(fieldnames(objectStruct))
                objectHandle = gobjects(0);
                return;
            end

            objectHandles = obj.resolveObjectHandles(parent, config, objectStruct);
            objectHandle = objectHandles;
            for handleN = 1:numel(objectHandles)
                obj.addComponent(objectHandles(handleN), true, true, false, false);
            end

            if ~isfield(objectStruct, 'scalePointVectors') || ~isfield(objectStruct, 'scalePointPositions')
                return;
            end
            
            % Add scale points
            for scalePointNum = 1:numel(objectStruct.scalePointVectors)
                scalePointVector = objectStruct.scalePointVectors{scalePointNum};
                scalePointPosition = objectStruct.scalePointPositions{scalePointNum};
                
                scalePointHandle = plot3(p0(1) + scalePointPosition(1), ...
                    p0(2) + scalePointPosition(2), ...
                    p0(3) + scalePointPosition(3), ...
                    'Parent', parent, ...
                    'Marker', 'square', ...
                    'MarkerFaceColor', config.scalePointColor, ...
                    'MarkerSize', config.ballSize, ...
                    'Tag', 'scalePoint', ...
                    'MarkerEdgeColor', config.scalePointColor);
                scalePointHandle.UserData = scalePointVector;
                obj.addComponent(scalePointHandle, true, true, true, false);
            end
        end



        function objectHandles = resolveObjectHandles(~, parent, config, objectStruct)
            % Creates/reuses graphics objects from objectStruct
            % If objectStruct.objectForGizmo contains valid graphics handles, those are used directly - persists after gizmo deletion.
            % If it contains a struct with vertices and faces, a patch object is created and added to the gizmo group - it is deleted when gizmo is deleted. 
            if isfield(objectStruct, 'objectForGizmo')
                objectRef = objectStruct.objectForGizmo;

                if isgraphics(objectRef)
                    objectHandles = objectRef;
                    return;
                end

                if iscell(objectRef)
                    if all(cellfun(@isgraphics, objectRef))
                        objectHandles = vertcat(objectRef{:});
                        return;
                    end
                end

                if isstruct(objectRef) && isfield(objectRef, 'vertices') && isfield(objectRef, 'faces')
                    objectHandles = patch('Parent', parent, ...
                        'Vertices', objectRef.vertices, ...
                        'Faces', objectRef.faces, ...
                        'FaceColor', 'cyan', ...
                        'FaceAlpha', config.planeTransparency, ...
                        'EdgeColor', config.planeEdgeColor, ...
                        'Tag', '3Dobject');
                    return;
                end

                ME = MException('GizmoTool:InvalidObjectReference', ...
                    ['objectForGizmo must be graphics handle(s), or a struct with ' ...
                     'fields vertices and faces.']);
                throw(ME)
            else
                objectHandles = gobjects(0);
            end
        end
        %%


        %% Callback and interaction setup functions
        function storeOriginalCallbacks(obj)
            % Stores current figure callbacks for later restoration.
            
            if isprop(obj.fig, 'WindowButtonMotionFcn')
                obj.origCallbacks.WindowButtonMotionFcn = obj.fig.WindowButtonMotionFcn;
            end
            if isprop(obj.fig, 'WindowButtonUpFcn')
                obj.origCallbacks.WindowButtonUpFcn = obj.fig.WindowButtonUpFcn;
            end
            if isprop(obj.fig, 'WindowScrollWheelFcn')
                obj.origCallbacks.WindowScrollWheelFcn = obj.fig.WindowScrollWheelFcn;
            end
        end


        
        function resetCallbacks(obj)
            % callback function called upon button release and when deleting gizmo - resets default callbacks
            % Restores figure callbacks captured before gizmo interaction.
            
            storedCallbacks = fieldnames(obj.origCallbacks);
            for storedFieldIdx = 1:numel(storedCallbacks)
                callbackName = storedCallbacks{storedFieldIdx};
                if isempty(callbackName)
                    % added because in same cases, storedField was empty, which was causing errors
                    continue
                end
                if isprop(obj.fig, callbackName)
                    obj.fig.(callbackName) = obj.origCallbacks.(callbackName);
                else
                    disp("Original callback " + callbackName + " not found on figure properties.");
                end
            end
        end



        function setCallbacksForActive(obj)
            % Assigns click callbacks to all currently active components.

            activeHandles = obj.componentHandles(obj.isActive);
            set(activeHandles, "ButtonDownFcn", @(src,evt)obj.gizmoClick(src, evt));
        end



        function disableExistingObjectPickability(obj)
            % Disables picking for all existing objects in the axes and stores originally pickable objects for later restoration.
            objectHandles = obj.ax.Children;
            for componentN = 1:length(objectHandles)
                if isprop(objectHandles(componentN), 'PickableParts')
                    pickabilityState = get(objectHandles(componentN), 'PickableParts');
                    if ~isequal(pickabilityState, 'none')
                        obj.originallyPickableObjects(end+1) = objectHandles(componentN);
                        set(objectHandles(componentN), 'PickableParts', 'none');
                    end
                end
            end
        end



        function restoreOriginalObjectPickability(obj)
            % Restores pickability for all objects in axes that were originally pickable before gizmo activation.
            % TO OPTIMIZE - the pickability might have been 'all', not 'visible'
            for i = 1:length(obj.originallyPickableObjects)
                if isvalid(obj.originallyPickableObjects(i))
                    set(obj.originallyPickableObjects(i), 'PickableParts', 'visible');
                end
            end
        end



        function setInteractivity(obj)
            % Enables hover/click interactivity and disables picking for passive components.

            passiveHandles = obj.componentHandles(~obj.isActive);
            set(passiveHandles, "PickableParts", "none");

            activeHandles = obj.componentHandles(obj.isActive);
            for handle = activeHandles
                obj.makeObjectInteractive(handle);
            end
                
            % enable pointerManager within figure
            iptPointerManager(obj.fig, 'enable');
        end



        function makeObjectInteractive(obj, handle)
            % Enables pointer behavior that highlights a component on hover.

            behavior = struct();
            behavior.enterFcn = @(~, ~)makeOutlineThickerAndActivateGizmoResizing(obj, handle);
            behavior.traverseFcn = [];
            behavior.exitFcn = @(~, ~)makeOutlineNormal(handle);

            iptSetPointerBehavior(handle, behavior);
            set(handle, "PickableParts", "visible");        


            function makeOutlineThickerAndActivateGizmoResizing(obj, handle)
                % check for validity added because sometimes during deletion, the exitFcn was called on already deleted object
                % this was causing errors
                if isvalid(handle)
                    set(handle, 'LineWidth',4);

                    % set wheel callback for gizmo visual scaling
                    obj.installScrollWheelCallback();
                end
            end

            function makeOutlineNormal(handle)
                if isvalid(handle)
                    set(handle, 'LineWidth',2)
                end
            end
        end



        function disableInteractivityForObject(~, handle)
            % Clears pointer behavior for a component to disable hover interaction.

            set(handle, "PickableParts", "none");
            behavior = [];
            iptSetPointerBehavior(handle, behavior);
        end
        %%



        %% Handling of scrolling for visual scaling of the gizmo - scales the size of the gizmo components without affecting the actual transformation applied to the object, to maintain usability at different zoom levels
        function installScrollWheelCallback(obj)
            % Installs wheel callback used for gizmo visual scaling.

            if isprop(obj.fig, 'WindowScrollWheelFcn')
                obj.fig.WindowScrollWheelFcn = @(src, evt) obj.handleScrollWheel(src, evt);
            end
        end



        function handleScrollWheel(obj, ~, evt)
            % Scales gizmo visuals when Alt is pressed and pointer is on IPT-interactive gizmo handle.

            if ~obj.isAltPressed()
                obj.forwardOriginalScrollWheel(evt);
                return;
            end

            scaleFactor = obj.gizmoVisualScaleStep ^ (-evt.VerticalScrollCount);
            obj.setGizmoVisualScale(obj.gizmoVisualScale * scaleFactor);
        end



        function setGizmoVisualScale(obj, newScale)
            % Scales only gizmo visuals around centre; keeps target object geometry unchanged.

            if ~isfinite(newScale) || newScale <= 0
                return;
            end

            clampedScale = min(max(newScale, obj.gizmoVisualScaleMin), obj.gizmoVisualScaleMax);
            scaleRatio = clampedScale / obj.gizmoVisualScale;
            if abs(scaleRatio - 1) < 1e-12
                return;
            end

            centre = obj.getCentrePositionUM();

            validMask = isvalid(obj.componentHandles);
            scalingMask = validMask & obj.scalesWithGizmoVisual;
            scalingHandles = obj.componentHandles(scalingMask);

            for handleN = 1:numel(scalingHandles)
                handle = scalingHandles(handleN);

                if isprop(handle, 'XData') && isprop(handle, 'YData') && isprop(handle, 'ZData')
                    handle.XData = centre(1) + (handle.XData - centre(1)) * scaleRatio;
                    handle.YData = centre(2) + (handle.YData - centre(2)) * scaleRatio;
                    handle.ZData = centre(3) + (handle.ZData - centre(3)) * scaleRatio;
                end

                if isprop(handle, 'MarkerSize')
                    handle.MarkerSize = max(1, handle.MarkerSize * scaleRatio);
                end

                if isprop(handle, 'LineWidth')
                    handle.LineWidth = max(0.5, handle.LineWidth * scaleRatio);
                end
            end

            obj.gizmoVisualScale = clampedScale;
        end



        function tf = isAltPressed(obj)
            % Returns true when Alt key is pressed.

            tf = false;
            if isprop(obj.fig, 'CurrentModifier')
                modifiers = obj.fig.CurrentModifier;
                tf = iscell(modifiers) && any(strcmpi(modifiers, 'alt'));
            end
        end



        function forwardOriginalScrollWheel(obj, evt)
            % Forwards scroll-wheel event to original figure callback when gizmo scaling is not active.

            if ~isfield(obj.origCallbacks, 'WindowScrollWheelFcn')
                return;
            end

            callback = obj.origCallbacks.WindowScrollWheelFcn;
            if isempty(callback)
                return;
            end

            if isa(callback, 'function_handle')
                callback(obj.fig, evt);
                return;
            end

            if iscell(callback) && ~isempty(callback)
                callbackFcn = callback{1};
                callbackArgs = callback(2:end);
                feval(callbackFcn, obj.fig, evt, callbackArgs{:});
                return;
            end

            if ischar(callback) || (isstring(callback) && isscalar(callback))
                eval(callback);
            end
        end
        %%        



        %% Click callback and subsequent motion handling functions for different interaction types (translation, rotation, scaling, snapping)
        function gizmoClick(obj, src, evt)
            % Handles mouse-down events and installs drag callbacks by component type.

            rotatingHandles = obj.componentHandles(obj.doesRotate);

            centreStartPosUm = obj.getCentrePositionUM();
            centreStartPosPix = MicroMToPixelPosition(centreStartPosUm, obj.ax);

            % get rotation of the axes system
            azimuth = wrapTo360(obj.ax.View(1));
            elevation = obj.ax.View(2);     

            if evt.Button == 1      % activates mouse move callback to translate or rotate gizmo
            
                motionCallback = [];

                switch src.Tag

                    case {'normBallPoint', 'xBallPoint', 'yBallPoint', 'zBallPoint'}

                        handleStartPosUm = [src.XData, src.YData, src.ZData];
                        handleStartPosPix = MicroMToPixelPosition(handleStartPosUm, obj.ax);

                        % calculate micrometer to pixel ratio and movement direction in the 3D space
                        handleVectorUm = handleStartPosUm-centreStartPosUm;
                        handleDistanceUm = norm(handleVectorUm);
                        handleDistancePix = norm(handleStartPosPix-centreStartPosPix);
                        umPerPixel = handleDistanceUm/handleDistancePix;
                        handleDirectionUm = handleVectorUm/handleDistanceUm;

                        % get parameters of line in 2D screen space that determines the direction of translation
                        dragLinePix = handleStartPosPix - centreStartPosPix;
                        dragLineConstant = -dragLinePix(1)*handleStartPosPix(1) - dragLinePix(2)*handleStartPosPix(2);

                        motionCallback = @() obj.handleMove(obj.componentHandles, dragLinePix, dragLineConstant, umPerPixel, handleDirectionUm, centreStartPosUm);

                    case 'cBallPoint'

                        stickyPointsPix = MicroMToPixelPosition(obj.stickyPoints, obj.ax);  % has to be calculated on every click, because the position in pixels changes with rotation
                        motionCallback = @() obj.handleStickToPointsMove(obj.componentHandles, obj.stickyPoints, stickyPointsPix, obj.stickyPointNormals);

                    case 'scalePoint'

                        handleStartPosUm = [src.XData, src.YData, src.ZData];
                        handleStartPosPix = MicroMToPixelPosition(handleStartPosUm, obj.ax);

                        dragLinePix = handleStartPosPix - centreStartPosPix;
                        dragLineConstant = -dragLinePix(1)*handleStartPosPix(1) - dragLinePix(2)*handleStartPosPix(2);

                        initialScaleDistancePix = norm(dragLinePix);

                        dimensionNames = ['x', 'y', 'z'];
                        R = eye(3);

                        for dimensionN = 1:numel(dimensionNames)
                            rotatedVector = obj.getReferenceDirectionUM(dimensionNames(dimensionN), centreStartPosUm);
                            R(1:3,dimensionN) = rotatedVector(:);
                        end

                        if det(R) < 0
                            R(:,2) = -R(:,2);
                        end

                        R = inv(R);

                        translationMatrix4D = eye(4);
                        translationMatrix4D(1:3, 4) = -centreStartPosUm(:);

                        translationMatrix4Dinv = eye(4);
                        translationMatrix4Dinv(1:3, 4) = centreStartPosUm(:);

                        rotationMatrix4D = eye(4);
                        rotationMatrix4D(1:3,1:3) = R;

                        rotationMatrix4Dinv = eye(4);
                        rotationMatrix4Dinv(1:3,1:3) = R';

                        scalingHandles = obj.componentHandles(obj.doesScale);

                        startScaleGeometry = cell(1, length(scalingHandles));
                        for scaleIdx=1:length(scalingHandles)

                            if isequal(scalingHandles(scaleIdx).Type,'patch')
                                startScaleGeometry{scaleIdx} = scalingHandles(scaleIdx).Vertices;
                            else
                                startScaleGeometry{scaleIdx} = [scalingHandles(scaleIdx).XData', scalingHandles(scaleIdx).YData', scalingHandles(scaleIdx).ZData'];
                            end
                        end

                        scaleDirectionVector = src.UserData;

                        motionCallback = @() obj.handleScaling(obj.componentHandles, scaleDirectionVector, translationMatrix4D, translationMatrix4Dinv, rotationMatrix4D, rotationMatrix4Dinv, startScaleGeometry, initialScaleDistancePix, dragLinePix, dragLineConstant, obj.doesScale);

                    case {'xRotLine', 'yRotLine', 'zRotLine'}

                        rotationHandle = src;
                        cursorStartPosPix = get(0,'PointerLocation');
                        rotationGeometryStart = obj.getRotationStartPosition(rotatingHandles);
                        motionCallback = @() obj.handleRotation(rotationHandle, cursorStartPosPix, centreStartPosUm, centreStartPosPix, rotationGeometryStart, azimuth, elevation, rotatingHandles);
                end

                if ~isempty(motionCallback)
                    obj.fig.WindowButtonMotionFcn = @(~, ~) motionCallback();
                    obj.fig.WindowButtonUpFcn = @(~, ~) obj.resetCallbacks();
                end

            end    
        end



        function handleStickToPointsMove(obj, componentHandles, stickyPointsUm, stickyPointsPix, stickyPointNormals)
            % Snaps centre to nearest sticky point and aligns normal direction.

            cursorPosPix = get(0,'Pointerlocation');
            [closestStickyPointIndex,~] = knnsearch(stickyPointsPix, cursorPosPix);

            newCentrePosUm = stickyPointsUm(closestStickyPointIndex,:);
            obj.updatePosition(newCentrePosUm,componentHandles)

            % Get the normal vector for the current sticky point
            normalVectorUm = stickyPointNormals(closestStickyPointIndex,:);

            obj.rotateTo(normalVectorUm)
        end



        function handleMove(obj, componentHandles, dragLinePix, dragLineConstant, umPerPixel, handleDirectionUm, centreStartPosUm)
            % Translates the gizmo along a constrained drag direction.

            cursorPosPix = get(0,'Pointerlocation');     

            signedDistancePix = (dragLinePix(1)*cursorPosPix(1) + dragLinePix(2)*cursorPosPix(2) + dragLineConstant)/sqrt(dragLinePix(1)^2 + dragLinePix(2)^2);

            deltaUm = handleDirectionUm*umPerPixel*signedDistancePix;

            updatedCentrePosUm = [centreStartPosUm(1)+deltaUm(1), centreStartPosUm(2)+deltaUm(2), centreStartPosUm(3)+deltaUm(3)];
            obj.updatePosition(updatedCentrePosUm,componentHandles)
        end



        function handleRotation(obj, rotationHandle, cursorStartPosPix, centreStartPosUm, centreStartPosPix, rotationGeometryStart, azimuth, elevation, rotatingHandles)
            % Rotates all rotatable components around the selected axis ring.

            cursorPosPix = get(0,'Pointerlocation');
            axisLetter = rotationHandle.Tag(1);
            centre = obj.getCentrePositionUM();
            vRot = obj.getReferenceDirectionUM(axisLetter, centre);

            centreProjectionPix = centreStartPosPix;

            dragStartVecPix = - centreProjectionPix + cursorStartPosPix;
            dragCurrentVecPix = cursorPosPix - centreProjectionPix;

            thetaVect = atan2(cross([dragStartVecPix, 0], [dragCurrentVecPix, 0]), dot(dragStartVecPix, dragCurrentVecPix));

            camDir = [sind(azimuth)*cosd(elevation), cosd(azimuth)*cosd(elevation), sind(elevation)];
            theta = -sign(dot(vRot, camDir)) * thetaVect(3);

            obj.updateDirection(vRot, theta, rotatingHandles, centreStartPosUm, rotationGeometryStart)
        end



        function handleScaling(obj, componentHandles, scaleDirectionVector, translationMatrix4D, translationMatrix4Dinv, rotationMatrix4D, rotationMatrix4Dinv, startScaleGeometry, initialScaleDistancePix, dragLinePix, dragLineConstant, doesScale)
            % Computes and applies anisotropic scaling from cursor movement.

            cursorPosPix = get(0,'Pointerlocation');

            signedDistancePix = (dragLinePix(1)*cursorPosPix(1) + dragLinePix(2)*cursorPosPix(2) + dragLineConstant)/sqrt(dragLinePix(1)^2 + dragLinePix(2)^2);
            scaleFactor = 1 + signedDistancePix*scaleDirectionVector/initialScaleDistancePix;

            scaleMatrix4D = eye(4);
            for i = 1:3
                scaleMatrix4D(i,i) = scaleFactor(i);
            end

            transformMatrix4D = translationMatrix4Dinv*rotationMatrix4Dinv*scaleMatrix4D*rotationMatrix4D*translationMatrix4D;

            scalingHandles = componentHandles(doesScale);

            obj.scale(startScaleGeometry, scalingHandles, transformMatrix4D)
        end
        %%


            
        %% Transformation functions
        % function calculating new position via translation
        function updatePosition(obj, newPosition, handles)
            % Applies translational offset to all provided handles.

            currentPosition = obj.getCentrePositionUM();

            dX = newPosition(1) - currentPosition(1);
            dY = newPosition(2) - currentPosition(2);
            dZ = newPosition(3) - currentPosition(3);

            for i = 1:length(handles)

                if isequal(handles(i).Type,'patch')
                    handles(i).Vertices(:,1) = handles(i).Vertices(:,1) + dX;
                    handles(i).Vertices(:,2) = handles(i).Vertices(:,2) + dY;
                    handles(i).Vertices(:,3) = handles(i).Vertices(:,3) + dZ;
                else
                    handles(i).XData = handles(i).XData + dX;
                    handles(i).YData = handles(i).YData + dY;
                    handles(i).ZData = handles(i).ZData + dZ;
                end

            end
        end



        % function calculating new position via rotation
        function updateDirection(~, vRot,theta,handles,startPosition,startPositionRot)
            % Applies axis-angle rotation to handle geometry around a pivot.

            startPosition = startPosition(:);

            % calculate rotational matrix considering the input vector of rotation
            R = [cos(theta) + (vRot(1))^2 * (1 - cos(theta))      (vRot(1)) * (vRot(2)) * (1 - cos(theta)) - (vRot(3)) * sin(theta)    (vRot(1)) * (vRot(3)) * (1 - cos(theta)) + (vRot(2)) * sin(theta);
                (vRot(2)) * (vRot(1)) * (1 - cos(theta)) + (vRot(3)) * sin(theta)    cos(theta) + (vRot(2))^2 * (1 - cos(theta))    (vRot(2)) * (vRot(3)) * (1 - cos(theta)) - (vRot(1)) * sin(theta);
                (vRot(3)) * (vRot(1)) * (1 - cos(theta)) - (vRot(2)) * sin(theta)    (vRot(3)) * (vRot(2)) * (1 - cos(theta)) + (vRot(1)) * sin(theta)    cos(theta) + (vRot(3))^2 * (1 - cos(theta))];

            % adapt position of all elements affected by rotation
            for i=1:(length(handles))

                if isequal(handles(i).Type,'patch')
                    cornerN = round(size(startPositionRot{i},1)/3);
                    for corner=1:cornerN
                        startPosCorner = [startPositionRot{i}(corner);startPositionRot{i}(corner+cornerN);startPositionRot{i}(corner+2*cornerN)];
                        P1_rotated = R*(startPosCorner-startPosition)+startPosition;
                        handles(i).Vertices(corner,1) = P1_rotated(1);
                        handles(i).Vertices(corner,2) = P1_rotated(2);
                        handles(i).Vertices(corner,3) = P1_rotated(3);
                    end
                else % if isequal(handles(i).Type,'line')
                    for n=1:size(startPositionRot{i},2)
                        P1_rotated = R*(startPositionRot{i}(:,n)-startPosition)+startPosition;
                        handles(i).XData(n) = P1_rotated(1);
                        handles(i).YData(n) = P1_rotated(2);
                        handles(i).ZData(n) = P1_rotated(3);
                    end 
                end
            end
        end



        % function calculating scaling in specified dimension
        function scale(~, startPositionScale, handles, transformMatrix4D)
            % Applies a 4D transform matrix to all scalable handle geometry.

            % adapt position of all elements affected by rotation
            for i=1:(length(handles))
                if isequal(handles(i).Type,'patch')

                    data3D = startPositionScale{i};
                    N = size(data3D, 1);
                    data4D = [data3D, ones(N, 1)];
                    scaledData4D = (transformMatrix4D*data4D')';
                    scaledData3D = scaledData4D(:,1:3);
                    handles(i).Vertices = scaledData3D;

                else % this should work at least for line and scatter
                    data3D = startPositionScale{i};
                    N = size(data3D, 1);
                    data4D = [data3D, ones(N, 1)];
                    scaledData4D = (transformMatrix4D*data4D')';
                    scaledData3D = scaledData4D(:,1:3);

                    handles(i).XData = scaledData3D(:, 1)';
                    handles(i).YData = scaledData3D(:, 2)';
                    handles(i).ZData = scaledData3D(:, 3)';
                end
            end
        end
        %%



        function startPositionCell = getRotationStartPosition(~, rotatingHandles)
            % Captures the current geometry of rotatable handles as a rotation baseline.
            startPositionCell = cell(1, length(rotatingHandles));
            for handleN=1:length(rotatingHandles)
                if isequal(rotatingHandles(handleN).Type,'patch')
                    startPositionCell{handleN} = [rotatingHandles(handleN).Vertices(:,1);rotatingHandles(handleN).Vertices(:,2);rotatingHandles(handleN).Vertices(:,3)];
                else
                    startPositionCell{handleN} = [rotatingHandles(handleN).XData;rotatingHandles(handleN).YData;rotatingHandles(handleN).ZData];
                end
            end
        end



        function referenceHandle = getReferencePointHandle(obj, axisLetter)
            % Returns cached reference-point handle for x/y/z axes.

            axisName = lower(char(axisLetter));
            if ~isfield(obj.referencePointHandles, axisName)
                ME = MException('GizmoTool:InvalidAxisReference', ...
                    sprintf('Unknown axis "%s".', axisName));
                throw(ME)
            end

            referenceHandle = obj.referencePointHandles.(axisName);
            if isempty(referenceHandle) || ~isvalid(referenceHandle)
                ME = MException('GizmoTool:MissingReferencePoint', ...
                    sprintf('Reference point handle for axis "%s" is missing or invalid.', axisName));
                throw(ME)
            end
        end



        function positionUm = getReferencePointPositionUM(obj, axisLetter)
            % Returns the xyz position of a cached reference-point handle in micrometers.

            referenceHandle = obj.getReferencePointHandle(axisLetter);
            positionUm = [referenceHandle.XData, referenceHandle.YData, referenceHandle.ZData];
        end



        function directionUm = getReferenceDirectionUM(obj, axisLetter, centrePos)
            % Returns normalized direction vector from centrePos to the cached axis reference point.

            referencePositionUm = obj.getReferencePointPositionUM(axisLetter);
            directionUm = referencePositionUm - centrePos;
            directionNorm = norm(directionUm);

            if directionNorm < 1e-12
                axisName = lower(char(axisLetter));
                ME = MException('GizmoTool:InvalidReferenceDirection', ...
                    sprintf('Reference direction for axis "%s" is near zero length.', axisName));
                throw(ME)
            end

            directionUm = directionUm / directionNorm;
        end
    end
end