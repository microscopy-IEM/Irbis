function [objectHandle, originalCallbacks, gizmoGroup] = gizmoTool(ax, fig, stickyPoints, pointA, pointB, objectStruct)

    % (save original callbacks)
    originalCallbacks = storeOriginalCallbacks(fig);
    % delete old gizmo components
    deleteGizmo(ax);

    normalPosition = [pointB.XData, pointB.YData, pointB.ZData];    % temporary fix, because for some reason, pointB is deleted in the process


    % check pointA and pointB tags and delete other objects with the same tags
    if ~isempty(objectStruct)        % because if objectStruct is empty, we use it for moving basePoints, and there are more of them that we want to keep
        deleteObjectsWithTag(ax, pointA.Tag, pointA);
    end

    if ~isequal(pointA.Tag, 'pointA') 
        deleteObjectsWithTag(ax, 'pointA')
        pointA.Tag = 'pointA';
    end
    if ~isempty(pointB)
        if ~isempty(objectStruct)
            deleteObjectsWithTag(ax, pointB.Tag, pointB);
        end
        if ~isequal(pointB.Tag, 'pointB')
            deleteObjectsWithTag(ax, 'pointB')
            pointB.Tag = 'pointB';
        end
    end
    % disable selectivity for all currently plotted components
    disableExistingObjectSelectivity(ax);
    % define gizmo components (now returns gizmoGroup)
    [componentHandles, doesRotate, doesScale, isActive, objectHandle, gizmoGroup] = defineGizmoComponents(ax, objectStruct, stickyPoints);
    % move gizmo to start position
    [componentHandles, doesRotate, doesScale, isActive] = moveGizmoToStart(componentHandles, doesRotate, doesScale, isActive, pointA, pointB);
    rotateGizmoToStart(componentHandles, doesRotate, pointA, normalPosition);

    % set callbacks for gizmo components
    setCallbacksForActive(componentHandles, isActive, ax, fig, stickyPoints, doesRotate, doesScale, originalCallbacks)
    % set selectivity and highlighting
    setInteractivity(fig, componentHandles, isActive)

end

function originalCallbacks = storeOriginalCallbacks(fig)
    % save original callbacks
    buttonMotionCallback = fig.WindowButtonMotionFcn;
    buttonUpCallback = fig.WindowButtonUpFcn;
    scrollWheelCallback = fig.WindowScrollWheelFcn;
    
    originalCallbacks = {buttonMotionCallback,buttonUpCallback,scrollWheelCallback};

end


function deleteObjectsWithTag(ax, tag, varargin)

    if nargin == 3
        exceptions = varargin{1};
    else
        exceptions = [];
    end

    objectHandles = findobj(ax, 'Tag', tag);
    % Remove the objects corresponding to the two handles
    objectsToDelete = setdiff(objectHandles, exceptions);

    delete(objectsToDelete);

end


function [componentHandles, doesRotate, doesScale, isActive, objectHandle, gizmoGroup] = defineGizmoComponents(ax, objectStruct, stickyPoints)
    % Creates all gizmo visual components and returns their properties
    
    % Get configuration with all visual parameters
    config = getGizmoConfig();
    
    % Create hggroup to contain all gizmo components
    gizmoGroup = hggroup('Parent', ax, 'Tag', 'gizmoGroup');
    
    % Initialize component collector struct
    comp = initComponentCollector();
    
    % Create gizmo parts (all parented to the hggroup)
    comp = addCenterBall(comp, gizmoGroup, config, stickyPoints);
    comp = addNormalIndicator(comp, gizmoGroup, config);
    comp = addDirectionalAxes(comp, gizmoGroup, config);
    [comp, objectHandle] = add3DObject(comp, gizmoGroup, config, objectStruct);
    
    % Extract output arrays from collector
    [componentHandles, doesRotate, doesScale, isActive] = extractComponentArrays(comp);
end


function config = getGizmoConfig()
    % Centralized configuration for all gizmo visual parameters
    
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


function comp = initComponentCollector()
    % Initialize empty collector struct for gizmo components
    comp.handles = gobjects(0);
    comp.doesRotate = false(0);
    comp.doesScale = false(0);
    comp.isActive = false(0);
end


function comp = addComponent(comp, handle, rotates, scales, active)
    % Add a single component to the collector
    comp.handles(end+1) = handle;
    comp.doesRotate(end+1) = rotates;
    comp.doesScale(end+1) = scales;
    comp.isActive(end+1) = active;
end


function comp = addCenterBall(comp, parent, config, stickyPoints)
    % Create the center ball point (translation handle)
    p0 = config.origin;
    
    cBallPoint = plot3(p0(1), p0(2), p0(3), 'k', ...
        'Parent', parent, ...
        'Marker', 'o', ...
        'MarkerFaceColor', 'k', ...
        'MarkerSize', config.ballSize, ...
        'Tag', 'cBallPoint', ...
        'MarkerEdgeColor', config.edgeColor, ...
        'LineWidth', config.lineWidth);
    
    isActiveCenter = ~isempty(stickyPoints);
    comp = addComponent(comp, cBallPoint, false, false, isActiveCenter);
end


function comp = addNormalIndicator(comp, parent, config)
    % Create normal direction line and ball point
    p0 = config.origin;
    spacing = config.spacing;
    
    % Normal direction line
    normLine = line('Parent', parent, ...
        'XData', [0, 1.2*spacing], 'YData', [0, 0], 'ZData', [0, 0], ...
        'LineWidth', config.lineWidth, ...
        'Color', 'k', ...
        'Tag', 'normLink');
    comp = addComponent(comp, normLine, true, false, false);
    
    % Normal ball point (rotation handle)
    normBallPoint = plot3(p0(1) + 1.25*spacing, p0(2), p0(3), ...
        'Parent', parent, ...
        'Marker', 'o', ...
        'MarkerFaceColor', config.normalColor, ...
        'MarkerSize', config.ballSize, ...
        'Tag', 'normBallPoint', ...
        'MarkerEdgeColor', config.edgeColor);
    comp = addComponent(comp, normBallPoint, true, false, true);
end


function comp = addDirectionalAxes(comp, parent, config)
    % Create x, y, z axis components (balls, lines, reference points, rotation rings)
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
        comp = addComponent(comp, ballPoint, false, false, true);
        
        % Axis line link
        lineLink = line('Parent', parent, ...
            'XData', [p0(1), p0(1) + v(1)*spacing], ...
            'YData', [p0(2), p0(2) + v(2)*spacing], ...
            'ZData', [p0(3), p0(3) + v(3)*spacing], ...
            'Tag', [dirName 'lineLink'], ...
            'Color', dirColor, ...
            'LineWidth', config.lineWidth);
        comp = addComponent(comp, lineLink, false, false, false);
        
        % Hidden reference point for rotation tracking
        referencePoint = plot3(p0(1) + v(1), p0(2) + v(2), p0(3) + v(3), ...
            'Parent', parent, ...
            'Tag', [dirName 'referencePoint'], ...
            'Visible', 'off');
        comp = addComponent(comp, referencePoint, true, false, false);
        
        % Rotation ring
        vNull = null(v);
        points = repmat(p0', 1, size(theta, 2)) + config.radius * (vNull(:,1)*cos(theta) + vNull(:,2)*sin(theta));
        rotLine = plot3(points(1,:), points(2,:), points(3,:), ...
            'Parent', parent, ...
            'Color', dirColor, ...
            'LineWidth', config.rotLineWidth, ...
            'Tag', [dirName 'RotLine']);
        comp = addComponent(comp, rotLine, false, false, true);
    end
end


function [comp, objectHandle] = add3DObject(comp, parent, config, objectStruct)
    % Add the 3D object patch and scale points if objectStruct is provided
    p0 = config.origin;
    
    if ~isstruct(objectStruct)
        objectHandle = [];
        return;
    end
    
    % Create 3D object patch
    objectHandle = patch('Parent', parent, ...
        'Vertices', objectStruct.vertices, ...
        'Faces', objectStruct.faces, ...
        'FaceColor', 'cyan', ...
        'FaceAlpha', config.planeTransparency, ...
        'EdgeColor', config.planeEdgeColor, ...
        'Tag', '3Dobject');
    comp = addComponent(comp, objectHandle, true, true, false);
    
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
        comp = addComponent(comp, scalePointHandle, true, true, true);
    end
end


function [componentHandles, doesRotate, doesScale, isActive] = extractComponentArrays(comp)
    % Extract arrays from collector struct
    componentHandles = comp.handles;
    doesRotate = comp.doesRotate;
    doesScale = comp.doesScale;
    isActive = comp.isActive;
end


function setCallbacksForActive(componentHandles, isActive, ax, fig, stickyPoints, doesRotate, doesScale, originalCallbacks)

    activeHandles = componentHandles(isActive);
    set(activeHandles, "ButtonDownFcn", @(src,evt)gizmoClick(src, evt, ax, fig, componentHandles, stickyPoints, doesRotate, doesScale, originalCallbacks));

end

function setInteractivity(fig, componentHandles, isActive)

    passiveHandles = componentHandles(~isActive);
    set(passiveHandles, "PickableParts", "none");

    activeHandles = componentHandles(isActive);
    for handle = activeHandles
        behavior = struct();
        behavior.enterFcn = @(~, ~)makeOutlineThicker(handle);
        behavior.traverseFcn = [];
        behavior.exitFcn = @(~, ~)makeOutlineNormal(handle);

        iptSetPointerBehavior(handle, behavior);
    end

    function makeOutlineThicker(handle)
        % check for validity added because sometimes during deletion, the exitFcn was called on already deleted object
        % this was causing errors
        if isvalid(handle)
            set(handle, 'LineWidth',4)
        end
    end

    function makeOutlineNormal(handle)
        if isvalid(handle)
            set(handle, 'LineWidth',2)
        end
    end
           
    % enable pointerManager within figure
    iptPointerManager(fig, 'enable');
end

function [componentHandles, doesRotate, doesScale, isActive] = moveGizmoToStart(componentHandles, doesRotate, doesScale, isActive, pointA, pointB)
    %% move gizmo to starting position - defined by pointA (position) and pointB (rotation)
    
    % position
    newPosition = [pointA.XData,pointA.YData,pointA.ZData];
    updatePosition(newPosition, componentHandles)         
    
    cBallPoint = findobj(componentHandles, 'Tag', 'cBallPoint');
    normBallPoint = findobj(componentHandles, 'Tag', 'normBallPoint');

    % % rotation
    % v1 = [normBallPoint.XData;normBallPoint.YData;normBallPoint.ZData] - [pointA.XData;pointA.YData;pointA.ZData];
    % v2 = - [pointA.XData;pointA.YData;pointA.ZData] + [pointB.XData;pointB.YData;pointB.ZData];

    % v1 = v1/norm(v1);
    % v2 = v2/norm(v2);

    % vRot = cross(v1,v2);

    % theta = acos(dot(v1,v2)/(norm(v1)*norm(v2)));

    pointA.XData = cBallPoint.XData;
    pointA.YData = cBallPoint.YData;
    pointA.ZData = cBallPoint.ZData;

    if ~isempty(pointB)
        disp('normalizing pointB to normBallPoint position')
        pointB.XData = normBallPoint.XData;
        pointB.YData = normBallPoint.YData;
        pointB.ZData = normBallPoint.ZData;
    end

    % add them to the handles so that they get tranformed automatically
    componentHandles(end + 1) = pointA;
    doesRotate(end + 1) = false;
    doesScale(end + 1) = false;
    isActive(end + 1) = false;

    if ~isempty(pointB)
        componentHandles(end + 1) = pointB;
        doesRotate(end + 1) = true;
        doesScale(end + 1) = false;
        isActive(end + 1) = false;
    end
end


function rotateGizmoToStart(componentHandles, doesRotate, pointA, normal)
    if isempty(pointA) || ~isgraphics(pointA) || isempty(normal)
        return;
    end

    center = [pointA.XData, pointA.YData, pointA.ZData];

    desiredVector = normal - center;
    % desiredVector = normal
    if ~all(isfinite(desiredVector)) || norm(desiredVector) < 1e-12
        return;
    end
    desiredVector = desiredVector / norm(desiredVector);

    normBall = findobj(componentHandles, 'Tag', 'normBallPoint');
    if isempty(normBall)
        return;
    end
    currentVector = [normBall.XData, normBall.YData, normBall.ZData] - center;
    if norm(currentVector) < 1e-12
        return;
    end
    currentVector = currentVector / norm(currentVector);

    dotVal = max(min(dot(currentVector, desiredVector), 1), -1);
    rotationAngle = acos(dotVal);
    if rotationAngle < 1e-9
        return;
    end

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

    rotatingHandles = componentHandles(doesRotate);
    if isempty(rotatingHandles)
        return;
    end

    startPositionRot = getRotationStartPosition(rotatingHandles);
    updateDirection(rotationAxis, rotationAngle, rotatingHandles, center, startPositionRot);

    function axis = fallbackAxis(direction)
        basis = eye(3);
        [~, idx] = min(abs(direction));
        axis = cross(direction, basis(idx, :));
        if norm(axis) < 1e-12
            axis = cross(direction, basis(mod(idx,3)+1, :));
        end
    end
end


function gizmoClick(src, evt, ax, fig, componentHandles, stickyPoints, doesRotate, doesScale, originalCallbacks)

    rotatingHandles = componentHandles(doesRotate);
    startPositionRot = getRotationStartPosition(rotatingHandles);

    centerHandle = findobj(componentHandles, 'Tag', 'cBallPoint');
    centerStartPositionUM = [centerHandle.XData, centerHandle.YData, centerHandle.ZData];
    centerStartPositionPix = MicroMToPixelPosition(centerStartPositionUM, ax);

    srcStartPositionUM = [src.XData, src.YData, src.ZData];
    srcStartPositionPix = MicroMToPixelPosition(srcStartPositionUM, ax);

    % get initial position of the pointer in pixel world
    startScreenPosition = get(0,'Pointerlocation');

    % get rotation of the axes system
    azimuth = wrapTo360(ax.View(1));
    elevation = ax.View(2);     

    if evt.Button == 3      % rotates the axes into a specific view
           
        switch src.Tag
            case 'xBallPoint'
                ax.View = [0 89.9];
            case 'yBallPoint'
                ax.View = [89.9 0];
            case 'zBallPoint'
                ax.View = [0 0];
            case 'cBallPoint'
                ax.View = [-30 30];
        end

    elseif evt.Button == 1      % activates mouse move callback to translate or rotate gizmo
    
        parameters = {};

        % precalculate parameters depending just on system rotation
        switch src.Tag

            case 'xBallPoint'

                % precalculate microM to pixel conversion for x
                if isequal(elevation,0) && isequal(mod(azimuth+90,180),0)
                    return
                else
                    p1 = MicroMToPixelPosition([ax.XLim(1),0,0],ax);
                    p2 = MicroMToPixelPosition([ax.XLim(2),0,0],ax);
                    pix = norm(p2-p1);                
                    microM = ax.XLim(2) - ax.XLim(1);
                    umPerPix = microM/pix;
                end

                % precalculate starting line
                x0 = startScreenPosition(1);
                y0 = startScreenPosition(2);

                aL = cosd(azimuth);
                bL = -sind(azimuth)*sind(elevation);
                cL = -aL*x0 -bL*y0; 

                parameters = {aL, bL, cL, umPerPix};

            case 'yBallPoint'

                % precalculate microM to pixel conversion for y
                if isequal(elevation,0) && isequal(mod(azimuth,180),0)
                    return
                else
                    p1 = MicroMToPixelPosition([0,ax.YLim(1),0],ax);
                    p2 = MicroMToPixelPosition([0,ax.YLim(2),0],ax);
                    pix = norm(p2-p1);                
                    microM = ax.YLim(2) - ax.YLim(1);
                    umPerPix = microM/pix;
                end

                % precalculate starting line
                x0 = startScreenPosition(1);
                y0 = startScreenPosition(2);
    
                aL = sind(azimuth);
                bL = cosd(azimuth)*sind(elevation);
                cL = -aL*x0 -bL*y0;

                parameters = {aL, bL, cL, umPerPix};

            case 'zBallPoint'

                % precalculate microM to pixel conversion for z
                if isequal(elevation,90) || isequal(elevation,-90)
                    return
                else
                    p1 = MicroMToPixelPosition([0,0,ax.ZLim(1)],ax);
                    p2 = MicroMToPixelPosition([0,0,ax.ZLim(2)],ax);
                    pix = norm(p2-p1);  
                    microM = ax.ZLim(2) - ax.ZLim(1);
                    umPerPix = microM/pix;   
                end

                parameters = {umPerPix};

            case 'normBallPoint'
                
                % precalculate microM to pixel conversion for normal direction
                p1 = centerStartPositionPix;    % central point
                p2 = srcStartPositionPix;    % point on the normal
                if isequal(p1,p2)
                    return
                else
                    pix = norm(p2-p1);  
                    vMicroM = srcStartPositionUM-centerStartPositionUM;
                    microM = norm(vMicroM);
                    umPerPix = microM/pix;
                    vMicroMnorm = vMicroM/microM;
                end

                % precalculate starting line
                x0 = srcStartPositionPix(1);
                y0 = srcStartPositionPix(2);
                 
                vLine = srcStartPositionPix - centerStartPositionPix;
                cL = -vLine(1)*x0 -vLine(2)*y0;   

                parameters = {vLine, cL, umPerPix, vMicroMnorm};

            case 'cBallPoint'

                % get the 2D projection (the code gets here only if sticky points exist)
                if ~isequal(size(stickyPoints, 2), 3)
                    stickyPoints = stickyPoints';
                end
                stickyPoints2D = MicroMToPixelPosition(stickyPoints,ax);

                parameters = {stickyPoints, stickyPoints2D};

            case 'scalePoint'

                % precalculate starting line
                x0 = srcStartPositionPix(1);
                y0 = srcStartPositionPix(2);
                 
                vLine = srcStartPositionPix - centerStartPositionPix;
                cL = -vLine(1)*x0 -vLine(2)*y0;

                scaleInitialDistancePix = norm(vLine);

                dimensionNames = ['x', 'y', 'z'];
                R = eye(3);

                for dimensionN = 1:numel(dimensionNames)
                    directionHandle = findobj(componentHandles, 'Tag', [dimensionNames(dimensionN) 'referencePoint']);
                    centerHandle = findobj(componentHandles, 'Tag', 'cBallPoint');

                    directionPosition = [directionHandle.XData, directionHandle.YData, directionHandle.ZData];
                    centerPosition = [centerHandle.XData, centerHandle.YData, centerHandle.ZData];

                    rotatedVector = (directionPosition - centerPosition)/norm(directionPosition - centerPosition);
                    R(1:3,dimensionN) = rotatedVector(:);
                end

                % Check determinant => ensure right-handed
                if det(R) < 0
                    % flip one axis to fix left-handed
                    R(:,2) = -R(:,2);
                end

                R = inv(R);


                translationMatrix4D = eye(4);
                translationMatrix4D(1:3, 4) = -centerStartPositionUM(:);

                translationMatrix4Dinv = eye(4);
                translationMatrix4Dinv(1:3, 4) = centerStartPositionUM(:);


                rotationMatrix4D = eye(4);
                rotationMatrix4D(1:3,1:3) = R;

                rotationMatrix4Dinv = eye(4);
                rotationMatrix4Dinv(1:3,1:3) = R';

                scaleHandles = componentHandles(doesScale);

                startPositionScale = cell(1, length(scaleHandles));
                for scaleN=1:length(scaleHandles)

                    if isequal(scaleHandles(scaleN).Type,'patch')
                        startPositionScale{scaleN} = scaleHandles(scaleN).Vertices;
                    else
                        startPositionScale{scaleN} = [scaleHandles(scaleN).XData', scaleHandles(scaleN).YData', scaleHandles(scaleN).ZData'];

                    end
                end

                parameters = {translationMatrix4D, translationMatrix4Dinv, rotationMatrix4D, rotationMatrix4Dinv, startPositionScale, scaleInitialDistancePix, vLine, cL};

        end

        fig.WindowButtonMotionFcn = @(src2,evt)gizmoMove(src, componentHandles, parameters, azimuth, elevation, doesRotate, doesScale, startScreenPosition, centerStartPositionUM, centerStartPositionPix, startPositionRot);
        fig.WindowButtonUpFcn = @(src2,evt)resetClb(fig, originalCallbacks);

    end    
end


%% callback function called when left button is used - enables translation or rotation via button motion
function gizmoMove(src, componentHandles, parameters, azimuth, elevation, doesRotate, doesScale, startScreenPosition, centerStartPositionUM, centerStartPositionPix, startPositionRot)

    rotatingHandles = componentHandles(doesRotate);
    currentScreenPosition = get(0,'Pointerlocation');

        switch src.Tag
            
        case 'xBallPoint'

            aL = parameters{1};
            bL = parameters{2};
            cL = parameters{3};
            umPerPix = parameters{4};

            % calculate distance of current point to line
            x1 = currentScreenPosition(1);
            y1 = currentScreenPosition(2);                

            D = (aL*x1 + bL*y1 + cL)/sqrt(aL^2 + bL^2);

            dx = D*umPerPix;

            newPosition = [centerStartPositionUM(1)+dx centerStartPositionUM(2) centerStartPositionUM(3)];

            updatePosition(newPosition, componentHandles)

            
        case 'yBallPoint'

            aL = parameters{1};
            bL = parameters{2};
            cL = parameters{3};
            umPerPix = parameters{4};

            % calculate distance of current point to line
            x1 = currentScreenPosition(1);
            y1 = currentScreenPosition(2);                          

            D = (aL*x1 + bL*y1 + cL)/sqrt(aL^2 + bL^2);

            % reversed y - added minus sign to dy
            dy = -D*umPerPix;  

            newPosition = [centerStartPositionUM(1) centerStartPositionUM(2)+dy  centerStartPositionUM(3)];
            updatePosition(newPosition,componentHandles)                  

                                                    
        case 'zBallPoint'

            umPerPix = parameters{1};

            % get movement distance in pixels
            z0 = startScreenPosition(2);
            zc = currentScreenPosition(2);
            dz = (z0-zc)*umPerPix;
                
            newPosition = [centerStartPositionUM(1) centerStartPositionUM(2) centerStartPositionUM(3) - dz];
            updatePosition(newPosition,componentHandles)


        case 'cBallPoint'
            % TO OPTIMIZE - avoid complex values by properly normalizing
            % stick to points + follow normal

            stickyPoints = parameters{1};
            stickyPoints2D = parameters{2};

            % find the index in 2D...
            csp = [currentScreenPosition(1) currentScreenPosition(2)];
            [spineIndexes,~] = knnsearch(stickyPoints2D,csp);
            
            % ...and get the new position in 3D
            newPosition = stickyPoints(spineIndexes,:);
            
            updatePosition(newPosition,componentHandles)
            
            % rotation:

            pointA = findobj(componentHandles, 'Tag', 'pointA');
            pointB = findobj(componentHandles, 'Tag', 'pointB');
            normBallPointHandle = findobj(componentHandles, 'Tag', 'normBallPoint');
            
            if spineIndexes+5 < size(stickyPoints2D,1)
            
            pointB.XData = stickyPoints(spineIndexes+5,1);
            pointB.YData = stickyPoints(spineIndexes+5,2);
            pointB.ZData = stickyPoints(spineIndexes+5,3);
            
            else
                pointB.XData = stickyPoints(spineIndexes-5,1);
                pointB.YData = stickyPoints(spineIndexes-5,2);
                pointB.ZData = stickyPoints(spineIndexes-5,3);
            end
            
            pA = [pointA.XData;pointA.YData;pointA.ZData];
            pB = [pointB.XData;pointB.YData;pointB.ZData];
            pC = [normBallPointHandle.XData;normBallPointHandle.YData;normBallPointHandle.ZData];
            
            v1 = (pB - pA)/norm(pB - pA);
            v2 = (pC - pA)/norm(pC - pA);
            
            vRot = cross(v1,v2)/norm(cross(v1,v2));
            
            theta = acos(-dot(v1,v2)/(norm(v1)*norm(v2)));
            
            centerStartPositionUM = pA;
    
            rotationPositionAfterTranslation = getRotationStartPosition(rotatingHandles);
            updateDirection(vRot,theta,rotatingHandles,centerStartPositionUM,rotationPositionAfterTranslation)

            case 'normBallPoint'

            vLine = parameters{1};
            cL = parameters{2};
            umPerPix = parameters{3};
            vMicroMnorm = parameters{4};

            x1 = currentScreenPosition(1);
            y1 = currentScreenPosition(2);                

            D = (vLine(1)*x1 + vLine(2)*y1 + cL)/sqrt(vLine(1)^2 + vLine(2)^2);

            dx = vMicroMnorm(1)*umPerPix*D;
            dy = vMicroMnorm(2)*umPerPix*D;
            dz = vMicroMnorm(3)*umPerPix*D;

            newPosition = [centerStartPositionUM(1)+dx centerStartPositionUM(2)+dy centerStartPositionUM(3)+dz];
            updatePosition(newPosition,componentHandles)    

        case 'yRotLine'

            vRot = [0 1 0];
            CPix = centerStartPositionPix;

            v1 = - CPix + startScreenPosition;
            v2 = currentScreenPosition - CPix;

            thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));
            theta = sign(-cosd(azimuth))*thetaVect(3);

            updateDirection(vRot,theta,rotatingHandles,centerStartPositionUM,startPositionRot)
                
            case 'zRotLine'

            vRot = [0 0 1];
            CPix = centerStartPositionPix;

            v1 = - CPix + startScreenPosition;
            v2 = currentScreenPosition - CPix;

            thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));
            % reversed y - added minus to sign(-sind(elevation))
            theta = sign(-sind(elevation))*thetaVect(3);

            updateDirection(vRot,theta,rotatingHandles,centerStartPositionUM,startPositionRot)

        case 'xRotLine'

            vRot = [1 0 0];
            CPix = centerStartPositionPix;

            v1 = - CPix + startScreenPosition;
            v2 = currentScreenPosition - CPix;

            thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));

            theta = sign(-sind(azimuth))*thetaVect(3);

            updateDirection(vRot,theta,rotatingHandles,centerStartPositionUM,startPositionRot)

        case 'scalePoint'

            scalePointVector = src.UserData;
            translationMatrix4D = parameters{1};
            translationMatrix4Dinv = parameters{2};
            rotationMatrix4D = parameters{3};
            rotationMatrix4Dinv = parameters{4};
            startPositionScale = parameters{5};
            scaleInitialDistancePix = parameters{6};
            vLine = parameters{7};
            cL = parameters{8};

            % calculate distance of current point to line
            x1 = currentScreenPosition(1);
            y1 = currentScreenPosition(2);                                    

            D = (vLine(1)*x1 + vLine(2)*y1 + cL)/sqrt(vLine(1)^2 + vLine(2)^2);
            scaleFactor = 1 + D*scalePointVector/scaleInitialDistancePix;

            scaleMatrix4D = eye(4);
            for i = 1:3
                scaleMatrix4D(i,i) = scaleFactor(i);
            end

            transformMatrix4D = translationMatrix4Dinv*rotationMatrix4Dinv*scaleMatrix4D*rotationMatrix4D*translationMatrix4D;

            scaleHandles = componentHandles(doesScale);

            scale(startPositionScale, scaleHandles, transformMatrix4D)
        end        
end


%% callback function called upon button release - resets default callbacks
function resetClb(fig, originalCallbacks)

    fig.WindowButtonMotionFcn = originalCallbacks{1};
    fig.WindowButtonUpFcn = originalCallbacks{2};
    fig.WindowScrollWheelFcn = originalCallbacks{3};

end
    

%% function calculating new position via translation
function updatePosition(newPosition,handles)

    dX = newPosition(1) - handles(1).XData(1);
    dY = newPosition(2) - handles(1).YData(1);
    dZ = newPosition(3) - handles(1).ZData(1);

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

%% function calculating new position via rotation
function updateDirection(vRot,theta,handles,startPosition,startPositionRot)

    startPosition = startPosition(:);

    % calculate rotational matrix considering the input vector of rotation
    R = [cos(theta) + (vRot(1))^2 * (1 - cos(theta))      (vRot(1)) * (vRot(2)) * (1 - cos(theta)) - (vRot(3)) * sin(theta)    (vRot(1)) * (vRot(3)) * (1 - cos(theta)) + (vRot(2)) * sin(theta);
        (vRot(2)) * (vRot(1)) * (1 - cos(theta)) + (vRot(3)) * sin(theta)    cos(theta) + (vRot(2))^2 * (1 - cos(theta))    (vRot(2)) * (vRot(3)) * (1 - cos(theta)) - (vRot(1)) * sin(theta);
        (vRot(3)) * (vRot(1)) * (1 - cos(theta)) - (vRot(2)) * sin(theta)    (vRot(3)) * (vRot(2)) * (1 - cos(theta)) + (vRot(1)) * sin(theta)    cos(theta) + (vRot(3))^2 * (1 - cos(theta))];

    % adapt position of all elements affected by rotation
    for i=1:(length(handles))

        if isequal(handles(i).Type,'line')
            for n=1:size(startPositionRot{i},2)
                P1_rotated = R*(startPositionRot{i}(:,n)-startPosition)+startPosition;
                handles(i).XData(n) = P1_rotated(1);
                handles(i).YData(n) = P1_rotated(2);
                handles(i).ZData(n) = P1_rotated(3);
            end 

        elseif isequal(handles(i).Type,'patch')
            cornerN = round(size(startPositionRot{i},1)/3);
            for corner=1:cornerN
                startPosCorner = [startPositionRot{i}(corner);startPositionRot{i}(corner+cornerN);startPositionRot{i}(corner+2*cornerN)];
                P1_rotated = R*(startPosCorner-startPosition)+startPosition;
                handles(i).Vertices(corner,1) = P1_rotated(1);
                handles(i).Vertices(corner,2) = P1_rotated(2);
                handles(i).Vertices(corner,3) = P1_rotated(3);
            end
        end
    end
end

%% function calculating scaling in specified dimension
function scale(startPositionScale, handles, transformMatrix4D)

    % adapt position of all elements affected by rotation
    for i=1:(length(handles))

        if isequal(handles(i).Type,'line')
            data3D = startPositionScale{i};
            N = size(data3D, 1);
            data4D = [data3D, ones(N, 1)];
            scaledData4D = (transformMatrix4D*data4D')';
            scaledData3D = scaledData4D(:,1:3);

            handles(i).XData = scaledData3D(1);
            handles(i).YData = scaledData3D(2);
            handles(i).ZData = scaledData3D(3);         


        elseif isequal(handles(i).Type,'patch')

            data3D = startPositionScale{i};
            N = size(data3D, 1);
            data4D = [data3D, ones(N, 1)];
            scaledData4D = (transformMatrix4D*data4D')';
            scaledData3D = scaledData4D(:,1:3);
            handles(i).Vertices = scaledData3D;
        end
    end
end


function startPositionCell = getRotationStartPosition(rotatingHandles)
    startPositionCell = cell(1, length(rotatingHandles));
    for handleN=1:length(rotatingHandles)
        if isequal(rotatingHandles(handleN).Type,'patch')
            startPositionCell{handleN} = [rotatingHandles(handleN).Vertices(:,1);rotatingHandles(handleN).Vertices(:,2);rotatingHandles(handleN).Vertices(:,3)];
        else
            startPositionCell{handleN} = [rotatingHandles(handleN).XData;rotatingHandles(handleN).YData;rotatingHandles(handleN).ZData];
        end
    end
end
