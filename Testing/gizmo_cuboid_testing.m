function originalCallbacks = gizmo_cuboid(ax, fig, stickyPoints, pointA, pointB, objectStruct)
            
    % save original callbacks
    buttonMotionCallback = fig.WindowButtonMotionFcn;
    buttonUpCallback = fig.WindowButtonUpFcn;
    scrollWheelCallback = fig.WindowScrollWheelFcn;
    
    originalCallbacks = {buttonMotionCallback,buttonUpCallback,scrollWheelCallback};

    % clear old components
    delete(findobj(ax,'Tag','cBallPoint'))
    delete(findobj(ax,'Tag','xBallPoint'))
    delete(findobj(ax,'Tag','yBallPoint'))
    delete(findobj(ax,'Tag','zBallPoint'))
    
    delete(findobj(ax,'Tag','xlineLink'))
    
    delete(findobj(ax,'Tag','xzRotLine'))
    delete(findobj(ax,'Tag','xyRotLine'))
    delete(findobj(ax,'Tag','normBallPoint'))
    delete(findobj(ax,'Tag','3dPlane'))
    delete(findobj(ax,'Tag','normLink'))    
    
    % disable selectivity for all currently plotted components  
    h = ax.Children;
    for compN = 1:length(h)
        if isprop(h(compN), 'PickableParts')
            set(h(compN), 'PickableParts', 'none');
        end
    end

    %% DEFINE GIZMO PARTS

    % define default position
    x0 = 0;
    y0 = 0;
    z0 = 0;
    p0 = [x0 y0 z0];

    % define gizmo size
    spacing = 1.2;
    ballSize = 12;
    planeEdgeSize = 3;    

    % set default colors and transparency
    edgeCol = [0.3 0.3 0.3];
    % linkCol = [0.3 0.3 0.3];
    % planeCol = [0.3 0.3 0.4];
    planeCol = [0.8 0.8 0.8];
    
    xCol = [0.4660 0.7740 0.1880];
    yCol = [0.7350 0.0780 0.1840];
    zCol = [0.3010 0.6450 0.9930];

    normCol = [0.4 0.4 0.4];

    lineWidth = 1;
    
    planeTansparency = 0.6;
    planeCData = [1 0.6 0.3 0];
    planeEdgeColor = [0.9 0.9 0.9];

    %% Translation elements
    
    lx = line(ax,[x0,x0+spacing],[y0 y0],[z0 z0],'Tag','xlineLink','Color',xCol,'LineWidth',lineWidth);
    ly = line(ax,[x0,x0],[y0 y0+spacing],[z0 z0],'Tag','xlineLink','Color',yCol,'LineWidth',lineWidth);
    lz = line(ax,[x0,x0],[y0 y0],[z0 z0+spacing],'Tag','xlineLink','Color',zCol,'LineWidth',lineWidth);
    
    cBallPoint = plot3(ax,x0,y0,z0,'k','Marker','o','MarkerFaceColor','k','MarkerSize',ballSize,'Tag','cBallPoint','MarkerEdgeColor',edgeCol,'LineWidth',lineWidth);
    
    xBallPoint = plot3(ax,x0+spacing,y0,z0,'Marker','o','MarkerFaceColor',xCol,'MarkerSize',ballSize,'Tag','xBallPoint','MarkerEdgeColor',edgeCol);
    yBallPoint = plot3(ax,x0,y0+spacing,z0,'Marker','o','MarkerFaceColor',yCol,'MarkerSize',ballSize,'Tag','yBallPoint','MarkerEdgeColor',edgeCol);
    zBallPoint = plot3(ax,x0,y0,z0+spacing,'Marker','o','MarkerFaceColor',zCol,'MarkerSize',ballSize,'Tag','zBallPoint','MarkerEdgeColor',edgeCol);

    %% Rotation elements
    
    normal = [0 1 0];
    center = p0;
    radius = spacing*1.15;
    
    % xz rotation element
    % theta=0.85*pi:0.1:1.15*pi;
    theta=-pi:0.1:pi;
    v=null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    xzRot = plot3(ax,points(1,:),points(2,:),points(3,:),'Color',yCol,'LineWidth',5,'Tag','xzRotLine');
    
    % xy rotation element
    normal = [0 0 1];
    % theta=1.35*pi:0.1:1.65*pi;
    v=null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    xyRot = plot3(ax,points(1,:),points(2,:),points(3,:),'Color',zCol,'LineWidth',5,'Tag','xyRotLine');

    % yz rotation element
    normal = [1 0 0];
    v = null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    yzRot = plot3(ax,points(1,:),points(2,:),points(3,:),'Color',xCol,'LineWidth',5,'Tag','yzRotLine');
           
    % plane 
    A = planeEdgeSize/2;
    
    % corner points for plane
    x = [0 0 0 0];
    y = [-A A A -A];
    z = [-A -A A A];

    % normPlane = fill3(ax,x,y,z,planeCol,'CData',planeCData,'FaceColor','interp','FaceAlpha',planeTansparency,'EdgeColor',planeEdgeColor,'Tag','3dPlane');
    normLine = line(ax,[0 1.2*spacing],[0 0],[0 0],'LineWidth',lineWidth,'Color','k','Tag','normLink');
    normBallPoint = plot3(ax,x0+1.25*spacing,y0,z0,'Marker','o','MarkerFaceColor',normCol,'MarkerSize',ballSize,'Tag','normBallPoint','MarkerEdgeColor',edgeCol);

    % save handles of all objects
    moveHandles = [cBallPoint xBallPoint yBallPoint zBallPoint lx ly lz normLine normBallPoint xzRot xyRot yzRot];
    rotHandles = [normLine normBallPoint];
    scaleHandles = [];

    activeHandles = [xBallPoint yBallPoint zBallPoint normBallPoint xzRot xyRot yzRot];
    passiveHandles = [normLine, lx, ly, lz];
    
    % add thin cuboid instead of the plane
    objectHandle = patch(ax,'Vertices',objectStruct.vertices,'Faces',objectStruct.faces,'FaceColor','cyan','FaceAlpha',planeTansparency,'EdgeColor',planeEdgeColor,'Tag','3dPlane');
    moveHandles(end + 1) = objectHandle;
    rotHandles(end + 1) = objectHandle;
    scaleHandles = [objectHandle];  % adding as a first element
    passiveHandles(end + 1) = objectHandle;
    % disp('creation')
    % get(objectHandle)
    % disp(objectHandle.Vertices)
    for scalePointCell = objectStruct.scalePointVectors

        scalePointVector = scalePointCell{1};
        scalePointHandle = plot3(ax,x0 + scalePointVector(1),y0 + scalePointVector(2),z0 + scalePointVector(3),'Marker','square','MarkerFaceColor','b','MarkerSize',ballSize,'Tag','scalePoint','MarkerEdgeColor','b');
        scalePointHandle.UserData = scalePointVector;
        moveHandles(end + 1) = scalePointHandle;
        rotHandles(end + 1) = scalePointHandle;
        scaleHandles(end + 1) = scalePointHandle;
        activeHandles(end + 1) = scalePointHandle;
    end

    % disp(rotHandles)
    % get(scaleHandles)

    %% Interactivity settings

    if isempty(stickyPoints)
        passiveHandles(end + 1) = cBallPoint;
    else
        activeHandles(end + 1) = cBallPoint;
    end

    set(passiveHandles,'PickableParts','none');
       

    
    % Assign ButtonDownFcn to elements
    set(activeHandles, "ButtonDownFcn", @(src,evt)gizmoClick(src,evt));
    
    %% Mouse hover pre-selection highlight 

    for handle = activeHandles
        behavior = struct();
        behavior.enterFcn = @(hfig, cpp)set(handle, 'LineWidth',4);
        behavior.traverseFcn = [];
        behavior.exitFcn = @(hfig, cpp)set(handle, 'LineWidth',2);

        iptSetPointerBehavior(handle, behavior);
    end
           
    % enable Pointmanage within figure
    iptPointerManager(fig, 'enable');
    
    
    %% move gizmo to starting position - defined by pointA (position) and pointB (rotation)
    
    % position
    newPosition = [pointA.XData,pointA.YData,pointA.ZData];
    updatePosition(newPosition,moveHandles)            

    % rotation
    v1 = [normBallPoint.XData;normBallPoint.YData;normBallPoint.ZData] - [pointA.XData;pointA.YData;pointA.ZData];
    v2 = - [pointA.XData;pointA.YData;pointA.ZData] + [pointB.XData;pointB.YData;pointB.ZData];

    v1 = v1/norm(v1);
    v2 = v2/norm(v2);

    vRot = cross(v1,v2);

    theta = acos(dot(v1,v2)/(norm(v1)*norm(v2)));

    pointA.XData = cBallPoint.XData;
    pointA.YData = cBallPoint.YData;
    pointA.ZData = cBallPoint.ZData;

    pointB.XData = normBallPoint.XData;
    pointB.YData = normBallPoint.YData;
    pointB.ZData = normBallPoint.ZData;

    % add them to the handles so that they get tranformed automatically
    moveHandles(end + 1) = pointA;
    moveHandles(end + 1) = pointB;

    rotHandles(end + 1) = pointB;

    %% callback function called when a button press is performed on an active gizmo part
    function gizmoClick(src,evt)
    
        % get rotation of the axes system
        azimuth = wrapTo360(ax.View(1));
        elevation = ax.View(2);    
    
        % get position of the gizmo center in uM world and in pixel world
        startPosition = [moveHandles(1).XData;moveHandles(1).YData;moveHandles(1).ZData];
        cBallPointArray = [moveHandles(1).XData,moveHandles(1).YData,moveHandles(1).ZData];
        startPositionPix = MicroMToPixelPosition(cBallPointArray,ax); 
        normBallPointArray = [normBallPoint.XData, normBallPoint.YData, normBallPoint.ZData];
    
        % get initial position of the selected part in pixel world
        srcArray = [src.XData,src.YData,src.ZData];
        startPositionSrcPix = MicroMToPixelPosition(srcArray,ax); 

        % get initial position of the pointer in pixel world
        startScreenPosition = get(0,'Pointerlocation');
    
        % get starting position of rotational elements
        startPositionRot = cell(1, length(rotHandles));
        for rotN2=1:length(rotHandles)
            if isequal(rotHandles(rotN2).Type,'patch')
                startPositionRot{rotN2} = [rotHandles(rotN2).Vertices(:,1);rotHandles(rotN2).Vertices(:,2);rotHandles(rotN2).Vertices(:,3)];
            else
                startPositionRot{rotN2} = [rotHandles(rotN2).XData;rotHandles(rotN2).YData;rotHandles(rotN2).ZData];
            end
        end

    
        if evt.Button == 3      % rotates the axes into a specific view
           
            switch src.Tag
                case 'xBallPoint'
                    ax.View = [0 89.9];
                case 'yBallPoint'
                    ax.View = [90 0];
                case 'zBallPoint'
                    ax.View = [0 0];
                case 'cBallPoint'
                    ax.View = [-30 30];
            end
        
        elseif evt.Button == 1      % activates mouse move callback to translate or rotate gizmo
    
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
                        XmicMetrPerPix = microM/pix;
                    end
    
                    % precalculate starting line
                    x0 = startScreenPosition(1);
                    y0 = startScreenPosition(2);
    
                    aL = cosd(azimuth);
                    bL = -sind(azimuth)*sind(elevation);
                    cL = -aL*x0 -bL*y0; 
    
                case 'yBallPoint'
    
                    % precalculate microM to pixel conversion for y
                    if isequal(elevation,0) && isequal(mod(azimuth,180),0)
                        return
                    else
                        p1 = MicroMToPixelPosition([0,ax.YLim(1),0],ax);
                        p2 = MicroMToPixelPosition([0,ax.YLim(2),0],ax);
                        pix = norm(p2-p1);                
                        microM = ax.YLim(2) - ax.YLim(1);
                        YmicMetrPerPix = microM/pix;
                    end
    
                    % precalculate starting line
                    x0 = startScreenPosition(1);
                    y0 = startScreenPosition(2);
        
                    aL = sind(azimuth);
                    bL = cosd(azimuth)*sind(elevation);
                    cL = -aL*x0 -bL*y0;
    
                case 'zBallPoint'
    
                    % precalculate microM to pixel conversion for z
                    if isequal(elevation,90) || isequal(elevation,-90)
                        return
                    else
                        p1 = MicroMToPixelPosition([0,0,ax.ZLim(1)],ax);
                        p2 = MicroMToPixelPosition([0,0,ax.ZLim(2)],ax);
                        pix = norm(p2-p1);  
                        microM = ax.ZLim(2) - ax.ZLim(1);
                        ZmicMetrPerPix = microM/pix;   
                    end
    
                case 'normBallPoint'
                    
                    % precalculate microM to pixel conversion for normal direction
                    p1 = startPositionPix;    % central point
                    p2 = startPositionSrcPix;    % point on the normal
                    if isequal(p1,p2)
                        return
                    else
                        pix = norm(p2-p1);  
                        vMicroM = srcArray-cBallPointArray;
                        microM = norm(vMicroM);
                        micMetrPerPix = microM/pix;
                        vMicroMnorm = vMicroM/microM;
                    end
    
                    % precalculate starting line
                    x0 = startPositionSrcPix(1);
                    y0 = startPositionSrcPix(2);
                     
                    vLine = startPositionSrcPix - startPositionPix;
                    cL = -vLine(1)*x0 -vLine(2)*y0;   

                case 'cBallPoint'

                    % get the 2D projection (the code gets here only if sticky points exist)
                    stickyPoints2D = MicroMToPixelPosition(stickyPoints,ax);

                case 'scalePoint'

                    scalePointVector = src.UserData;

                    % precalculate microM to pixel conversion for normal direction
                    p1 = startPositionPix;    % central point
                    p2 = startPositionSrcPix;    % point on the normal
                    if isequal(p1,p2)
                        return
                    else
                        pix = norm(p2-p1);  
                        vMicroM = srcArray-cBallPointArray;
                        microM = norm(vMicroM);
                        micMetrPerPix = microM/pix;
                        vMicroMnorm = vMicroM/microM;
                    end
    
                    % precalculate starting line
                    x0 = startPositionSrcPix(1);
                    y0 = startPositionSrcPix(2);
                     
                    vLine = startPositionSrcPix - startPositionPix;
                    cL = -vLine(1)*x0 -vLine(2)*y0;

                    scaleInitialDistancePix = norm(vLine);

                    % find the axis of rotation
                    % normalVector = (normBallPointArray - cBallPointArray)/norm(normBallPointArray - cBallPointArray);
                    

                    % if isequal(size(normalVector), [1, 3])
                    %     disp(size(normalVector))
                    %     % disp('problem')
                    %     normalVector = normalVector';
                        
                    % end

                    rotatedScalePointVector = (srcArray - cBallPointArray)/norm(srcArray - cBallPointArray)

                    if isequal(size(scalePointVector), [1, 3])
                        disp(size(scalePointVector))
                        % disp('problem')
                        scalePointVector = scalePointVector';
                    end

                    if isequal(size(rotatedScalePointVector), [1, 3])
                        disp(size(rotatedScalePointVector))
                        % disp('problem')
                        rotatedScalePointVector = rotatedScalePointVector';
                    end

                    scalePointVector = scalePointVector/norm(scalePointVector);

                        k = cross(rotatedScalePointVector, scalePointVector);
                        % k = cross([1 0 0], normalVector);
                    if isequal(norm(k), 0)
                        disp('they are parallel')
                        transformedScaleVector = scalePointVector;
                        R = eye(3);
                        Rinv = inv(R);
                    else
                        vRot = k/norm(k);
    
                        % theta = acos(dot([1 0 0], normalVector));
                        dot(rotatedScalePointVector, scalePointVector)
                        theta = acos(dot(rotatedScalePointVector, scalePointVector))
    
                        R = [cos(theta) + (vRot(1))^2 * (1 - cos(theta))      (vRot(1)) * (vRot(2)) * (1 - cos(theta)) - (vRot(3)) * sin(theta)    (vRot(1)) * (vRot(3)) * (1 - cos(theta)) + (vRot(2)) * sin(theta);
                        (vRot(2)) * (vRot(1)) * (1 - cos(theta)) + (vRot(3)) * sin(theta)    cos(theta) + (vRot(2))^2 * (1 - cos(theta))    (vRot(2)) * (vRot(3)) * (1 - cos(theta)) - (vRot(1)) * sin(theta);
                        (vRot(3)) * (vRot(1)) * (1 - cos(theta)) - (vRot(2)) * sin(theta)    (vRot(3)) * (vRot(2)) * (1 - cos(theta)) + (vRot(1)) * sin(theta)    cos(theta) + (vRot(3))^2 * (1 - cos(theta))];
    
                        disp('jere')
                        disp(R)

                        Rinv = inv(R);

                        % transformedScaleVector = (R*scalePointVector)/norm(R*scalePointVector);
                    end

                    startPositionScale = cell(1, length(scaleHandles));
                    % disp('startPositionScale')
                    for scaleN=1:length(scaleHandles)
                        % disp(scaleN)
                        % get(scaleHandles(scaleN))
                        % disp('what was there')
                        % disp(rotHandles(scaleN).Type)
                        % disp(scaleHandles(scaleN).Vertices)
                        if isequal(scaleHandles(scaleN).Type,'patch')
                            disp('this is patch')
                            % disp('this is patch')
                            % startPositionScale{scaleN} = scaleHandles(scaleN).Vertices;
                            startPositionScale{scaleN} = [scaleHandles(scaleN).Vertices(:,1);scaleHandles(scaleN).Vertices(:,2);scaleHandles(scaleN).Vertices(:,3)];
                            % disp('what I got')
                            % startPositionScale{scaleN}
                            % disp('stop')
                        else
                            % disp('I am here')
                            startPositionScale{scaleN} = [scaleHandles(scaleN).XData;scaleHandles(scaleN).YData;scaleHandles(scaleN).ZData];
                            % startPositionScale{scaleN}
                            % disp('this was the result')
                        end
                    end

            end     
        
            fig.WindowButtonMotionFcn = @(src,evt)gizmoMove(src,evt);
            fig.WindowButtonUpFcn = @(src,evt)resetClb(src,evt);
    
        elseif evt.Button == 2      % activates translation or rotation via scrolling
    
            fig.WindowScrollWheelFcn = @(src,evt)scrollwheelMove(src,evt);
            theta = 0;
            dPos = 0;
    
        end

        %% callback function called when left button is used - enables translation or rotation via button motion
        function gizmoMove(~,~)
    
            currentScreenPosition = get(0,'Pointerlocation');
    
             switch src.Tag
                    
                case 'xBallPoint'
    
                    % calculate distance of current point to line
                    x1 = currentScreenPosition(1);
                    y1 = currentScreenPosition(2);                
        
                    D = (aL*x1 + bL*y1 + cL)/sqrt(aL^2 + bL^2);
        
                    dx = D*XmicMetrPerPix;
        
                    newPosition = [startPosition(1)+dx startPosition(2) startPosition(3)];
                    updatePosition(newPosition,moveHandles,pointA,pointB)
        
                    
                case 'yBallPoint'
    
                    % calculate distance of current point to line
                    x1 = currentScreenPosition(1);
                    y1 = currentScreenPosition(2);                          
        
                    D = (aL*x1 + bL*y1 + cL)/sqrt(aL^2 + bL^2);
        
                    % reversed y - added minus sign to dy
                    dy = -D*YmicMetrPerPix;  
        
                    newPosition = [startPosition(1) startPosition(2)+dy  startPosition(3)];
                    updatePosition(newPosition,moveHandles,pointA,pointB)                  
        
                                                            
                case 'zBallPoint'
    
                    % get movement distance in pixels
                    z0 = startScreenPosition(2);
                    zc = currentScreenPosition(2);
                    dz = (z0-zc)*ZmicMetrPerPix;
                      
                    newPosition = [startPosition(1) startPosition(2) startPosition(3) - dz];
                    updatePosition(newPosition,moveHandles,pointA,pointB)

        
                case 'cBallPoint'
                    % stick to points + follow normal
       
                    % find the index in 2D...
                    csp = [currentScreenPosition(1) currentScreenPosition(2)];
                    [spineIndexes,~] = knnsearch(stickyPoints2D,csp);
                    
                    % ...and get the new position in 3D
                    newPosition = stickyPoints(spineIndexes,:);
                    
                    updatePosition(newPosition,moveHandles,pointA,pointB)
                    
                    % rotation:
                    
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
                    pC = [rotHandles(3).XData;rotHandles(3).YData;rotHandles(3).ZData];
                    
                    v1 = (pB - pA)/norm(pB - pA);
                    v2 = (pC - pA)/norm(pC - pA);
                    
                    vRot = cross(v1,v2)/norm(cross(v1,v2));
                    
                    theta = acos(-dot(v1,v2)/(norm(v1)*norm(v2)));
                    
                    startPosition = pA;
            
                    startPositionRot = cell(1, length(rotHandles));
                    for rotN3=1:length(rotHandles)
                        if isequal(rotHandles(rotN3).Type,'patch')
                            startPositionRot{rotN3} = [rotHandles(rotN3).Vertices(:,1);rotHandles(rotN3).Vertices(:,2);rotHandles(rotN3).Vertices(:,3)];
                        else
                            startPositionRot{rotN3} = [rotHandles(rotN3).XData;rotHandles(rotN3).YData;rotHandles(rotN3).ZData];
                        end
                    end
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)
    
                 case 'normBallPoint'
    
                    x1 = currentScreenPosition(1);
                    y1 = currentScreenPosition(2);                
    
                    D = (vLine(1)*x1 + vLine(2)*y1 + cL)/sqrt(vLine(1)^2 + vLine(2)^2);
    
                    dx = vMicroMnorm(1)*micMetrPerPix*D;
                    dy = vMicroMnorm(2)*micMetrPerPix*D;
                    dz = vMicroMnorm(3)*micMetrPerPix*D;
    
                    newPosition = [startPosition(1)+dx startPosition(2)+dy startPosition(3)+dz];
                    updatePosition(newPosition,moveHandles,pointA,pointB)    
    
               case 'xzRotLine'
    
                    vRot = [0 1 0];
                    CPix = startPositionPix;
        
                    v1 = - CPix + startScreenPosition;
                    v2 = currentScreenPosition - CPix;
        
                    thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));
                    theta = sign(-cosd(azimuth))*thetaVect(3);
        
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)
                        
                 case 'xyRotLine'
        
                    vRot = [0 0 1];
                    CPix = startPositionPix;
        
                    v1 = - CPix + startScreenPosition;
                    v2 = currentScreenPosition - CPix;
        
                    thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));
                    % reversed y - added minus to sign(-sind(elevation))
                    theta = sign(-sind(elevation))*thetaVect(3);
        
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)

                case 'yzRotLine'
        
                    vRot = [1 0 0];
                    CPix = startPositionPix;
        
                    v1 = - CPix + startScreenPosition;
                    v2 = currentScreenPosition - CPix;
        
                    thetaVect = atan2(cross([v1, 0], [v2, 0]), dot(v1, v2));

                    theta = sign(-sind(azimuth))*thetaVect(3);
        
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)

                case 'scalePoint'

                    % calculate distance of current point to line
                    x1 = currentScreenPosition(1);
                    y1 = currentScreenPosition(2);                                    
    
                    D = (vLine(1)*x1 + vLine(2)*y1 + cL)/sqrt(vLine(1)^2 + vLine(2)^2);
                    scaleFactor = 1 + D*scalePointVector/scaleInitialDistancePix;

                    scale(startPosition, startPositionScale, scaleHandles, scaleFactor, R, Rinv)
                 
             end        
        end
    
        %% callback function called when scrollwheel is used - enables translation or rotation via scrolling
        function scrollwheelMove(~,evt)
    
            switch src.Tag
    
                case 'xBallPoint'
                    dPos = dPos + evt.VerticalScrollCount*0.1;
                    newPosition = [startPosition(1)+dPos startPosition(2) startPosition(3)];
                    updatePosition(newPosition,moveHandles,pointA,pointB)
                case 'yBallPoint'
                    dPos = dPos + evt.VerticalScrollCount*0.1;
                    newPosition = [startPosition(1) startPosition(2)+dPos startPosition(3)];
                    updatePosition(newPosition,moveHandles,pointA,pointB)             
                case 'zBallPoint'
                    dPos = dPos + evt.VerticalScrollCount*0.1;
                    newPosition = [startPosition(1) startPosition(2) startPosition(3)+dPos];
                    updatePosition(newPosition,moveHandles,pointA,pointB)          
                case 'cBallPoint'
                case 'normBallPoint'
                    dx = rotHandles(3).XData - moveHandles(1).XData;
                    dy = rotHandles(3).YData - moveHandles(1).YData;
                    dz = rotHandles(3).ZData - moveHandles(1).ZData;
    
                    dPos = dPos + evt.VerticalScrollCount*0.1;
                    newPosition = [startPosition(1)+dx*dPos startPosition(2)+dy*dPos startPosition(3)+dz*dPos];
                    updatePosition(newPosition,moveHandles,pointA,pointB)
    
                case 'xzRotLine'
                    vRot = [0 1 0];
                    theta = theta + evt.VerticalScrollCount*0.1;
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)
                case 'xyRotLine'
                    vRot = [0 0 1];
                    theta = theta + evt.VerticalScrollCount*0.1;
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)                
    
            end
        end
    
    end

    %% callback function called upon button release - resets default callbacks
    function resetClb(~,~)
    
        fig.WindowButtonMotionFcn = buttonMotionCallback;
        fig.WindowButtonUpFcn = buttonUpCallback;
        fig.WindowScrollWheelFcn = scrollWheelCallback;

    end

end

%% function calculating new position via translation
function updatePosition(newPosition,handles,pointA,pointB)

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

    % % save position of centre of the plane (pointA) and point on the normal (pointB)
    % pointA.XData = handles(1).XData;
    % pointA.YData = handles(1).YData;
    % pointA.ZData = handles(1).ZData;

    % pointB.XData = handles(10).XData;
    % pointB.YData = handles(10).YData;
    % pointB.ZData = handles(10).ZData;
end

%% function calculating new position via rotation
function updateDirection(vRot,theta,handles,startPosition,startPositionRot,~,pointB)

    % calculate rotational matrix considering the input vector of rotation
    R = [cos(theta) + (vRot(1))^2 * (1 - cos(theta))      (vRot(1)) * (vRot(2)) * (1 - cos(theta)) - (vRot(3)) * sin(theta)    (vRot(1)) * (vRot(3)) * (1 - cos(theta)) + (vRot(2)) * sin(theta);
        (vRot(2)) * (vRot(1)) * (1 - cos(theta)) + (vRot(3)) * sin(theta)    cos(theta) + (vRot(2))^2 * (1 - cos(theta))    (vRot(2)) * (vRot(3)) * (1 - cos(theta)) - (vRot(1)) * sin(theta);
        (vRot(3)) * (vRot(1)) * (1 - cos(theta)) - (vRot(2)) * sin(theta)    (vRot(3)) * (vRot(2)) * (1 - cos(theta)) + (vRot(1)) * sin(theta)    cos(theta) + (vRot(3))^2 * (1 - cos(theta))];

    % disp(R)


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

    % % save position of point on the normal (pointB) - centre of the plane (pointA) is not affected by rotation
    % pointB.XData = handles(3).XData;
    % pointB.YData = handles(3).YData;
    % pointB.ZData = handles(3).ZData;    
end


%% function calculating scaling in specified dimension
function scale(startPosition, startPositionScale, handles, scaleFactor, R, Rinv)

    % startPositionScale{1}

    % disp(size(Rinv))
    % disp(size(R))
    disp(R)
    % disp(size(scaleFactor'))
    % disp(size(startPosition))

    % adapt position of all elements affected by rotation
    for i=1:(length(handles))
        % disp(['i: ', num2str(i)])

        if isequal(handles(i).Type,'line')
            % for n=1:size(startPositionScale{i},2)
            %     % disp(size(Rinv))
            %     % disp(size(R))
            %     % disp(size(scaleFactor))
            %     disp(size(startPositionScale{i}(:,n)))
            %     P1_rotated = R*(scaleFactor.*(Rinv*(startPositionScale{i}(:,n)-startPosition)))+startPosition;
            %     handles(i).XData(n) = P1_rotated(1);
            %     handles(i).YData(n) = P1_rotated(2);
            %     handles(i).ZData(n) = P1_rotated(3);
            % end 

            % disp(size(startPositionScale{i}))
            % P1_rotated = Rinv*(scaleFactor.*(R*(startPositionScale{i}-startPosition)))+startPosition;
            P1_rotated = ((R*(startPositionScale{i}-startPosition)))+startPosition;

            % P1_rotated = Rinv*(scaleFactor.*(R*(startPositionScale{i}-startPosition)))+startPosition;
            handles(i).XData = P1_rotated(1);
            handles(i).YData = P1_rotated(2);
            handles(i).ZData = P1_rotated(3);         

            % handles(i).XData = scaleFactor(1) * (startPositionScale{i}(1) - startPosition(1)) + startPosition(1);
            % handles(i).YData = scaleFactor(2) * (startPositionScale{i}(2) - startPosition(2)) + startPosition(2);
            % handles(i).ZData = scaleFactor(3) * (startPositionScale{i}(3) - startPosition(3)) + startPosition(3);

            % handles(i).XData
            % handles(i).YData
            % handles(i).ZData

        elseif isequal(handles(i).Type,'patch')
            % disp('here')
            cornerN = round(size(startPositionScale{i},1)/3);
            % scaleFactor
            % R
            % Rinv
            % startPositionScale{i}
            for corner=1:cornerN
                startPosCorner = [startPositionScale{i}(corner);startPositionScale{i}(corner+cornerN);startPositionScale{i}(corner+2*cornerN)];
                % disp('new')
                % disp(size((R*(startPosCorner-startPosition))))
                % multiplied = R*(startPosCorner-startPosition)
                % scaleFactor 
                % disp(size(scaleFactor.*multiplied))
                
                % disp(size(scaleFactor))
                % disp(size((scaleFactor.*(R*(startPosCorner-startPosition)))))
                % P1_rotated = Rinv*(scaleFactor.*(R*(startPosCorner-startPosition)))+startPosition;
                P1_rotated = ((R*(startPosCorner-startPosition)))+startPosition;

                % P1_rotated = Rinv*(scaleFactor.*(R*(startPosCorner-startPosition)))+startPosition;
                % P1_rotated = Rinv*(scaleFactor.*(R*(startPosCorner-startPosition)))+startPosition;
                % disp('new')
                % disp(size((R*(startPosCorner-startPosition))))
                % disp(size(scaleFactor))
                % disp(size(startPosCorner))
                handles(i).Vertices(corner,1) = P1_rotated(1);
                handles(i).Vertices(corner,2) = P1_rotated(2);
                handles(i).Vertices(corner,3) = P1_rotated(3);
            end

            % handles(i).Vertices
        end
    end

end

% %% function calculating scaling in specified dimension
% function scale(startPosition, startPositionScale, handles, vector, scaleFactor)

%     % startPositionScale{1}

%     for i = 1:length(handles)

%         % disp(handles(i).Type)


%         if isequal(handles(i).Type,'patch')

%             % disp(size(handles(i).Vertices))
%             % disp(size(startPositionScale{i}))

%             handles(i).Vertices(:,1) = scaleFactor(1) * (startPositionScale{i}(:,1) - startPosition(1)) + startPosition(1);
%             handles(i).Vertices(:,2) = scaleFactor(2) * (startPositionScale{i}(:,2) - startPosition(2)) + startPosition(2);
%             handles(i).Vertices(:,3) = scaleFactor(3) * (startPositionScale{i}(:,3) - startPosition(3)) + startPosition(3);


%             % handles(i).Vertices(:,1) = vector(1)*scaleFactor * (startPositionScale{i}(:,1) - startPosition(1)) + startPosition(1);
%             % handles(i).Vertices(:,2) = vector(2)*scaleFactor * (startPositionScale{i}(:,2) - startPosition(2)) + startPosition(2);
%             % handles(i).Vertices(:,3) = vector(3)*scaleFactor * (startPositionScale{i}(:,3) - startPosition(3)) + startPosition(3);
%         else

%             handles(i).XData = scaleFactor(1) * (startPositionScale{i}(1) - startPosition(1)) + startPosition(1);
%             handles(i).YData = scaleFactor(2) * (startPositionScale{i}(2) - startPosition(2)) + startPosition(2);
%             handles(i).ZData = scaleFactor(3) * (startPositionScale{i}(3) - startPosition(3)) + startPosition(3);

%             % handles(i).XData = vector(1)*scaleFactor * (startPositionScale{i}(1) - startPosition(1)) + startPosition(1);
%             % handles(i).YData = vector(2)*scaleFactor * (startPositionScale{i}(2) - startPosition(2)) + startPosition(2);
%             % handles(i).ZData = vector(3)*scaleFactor * (startPositionScale{i}(3) - startPosition(3)) + startPosition(3);
%         end

%     end

% end