function originalCallbacks = gizmo_app(ax,fig,stickyPoints,pointA,pointB)
            
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
    theta=0.85*pi:0.1:1.15*pi;
    v=null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    xzRot = plot3(ax,points(1,:),points(2,:),points(3,:),'Color',yCol,'LineWidth',5,'Tag','xzRotLine');
    
    % xy rotation element
    normal = [0 0 1];
    theta=1.35*pi:0.1:1.65*pi;
    v=null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    xyRot = plot3(ax,points(1,:),points(2,:),points(3,:),'Color',zCol,'LineWidth',5,'Tag','xyRotLine');
           
    % plane 
    A = planeEdgeSize/2;
    
    % corner points for plane
    x = [0 0 0 0];
    y = [-A A A -A];
    z = [-A -A A A];

    
    normPlane = fill3(ax,x,y,z,planeCol,'CData',planeCData,'FaceColor','interp','FaceAlpha',planeTansparency,'EdgeColor',planeEdgeColor,'Tag','3dPlane');
    normLine = line(ax,[0 1.2*spacing],[0 0],[0 0],'LineWidth',lineWidth,'Color','k','Tag','normLink');
    normBallPoint = plot3(ax,x0+1.25*spacing,y0,z0,'Marker','o','MarkerFaceColor',normCol,'MarkerSize',ballSize,'Tag','normBallPoint','MarkerEdgeColor',edgeCol);
    
    %% Interactivity settings
    
    % disable selectivity for passive elements
    normPlane.PickableParts = "none";
    normLine.PickableParts = "none";
    lx.PickableParts = "none";
    ly.PickableParts = "none";
    lz.PickableParts = "none";
       
    % save handles of all objects
    moveHandles = [cBallPoint xBallPoint yBallPoint zBallPoint lx ly lz normLine normPlane normBallPoint xzRot xyRot];
    rotHandles = [normLine normPlane normBallPoint xzRot xyRot];
    
    % Assign ButtonDownFcn to elements
    % for central element only if there are sticky points
    if ~isempty(stickyPoints)
        cBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    end
    
    xBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    yBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    zBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    
    normBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    xyRot.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    xzRot.ButtonDownFcn = @(src,evt)gizmoClick(src,evt);
    
    %% Mouse hover pre-selection highlight 
    
    cPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'cBallPoint'), 'LineWidth',3);
    cPointerBehavior.traverseFcn = [];
    cPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'cBallPoint'), 'LineWidth',1);
    
    xPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'xBallPoint'), 'LineWidth',3);
    xPointerBehavior.traverseFcn = [];
    xPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'xBallPoint'), 'LineWidth',1);
    
    yPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'yBallPoint'), 'LineWidth',3);
    yPointerBehavior.traverseFcn = [];
    yPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'yBallPoint'), 'LineWidth',1);
    
    zPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'zBallPoint'), 'LineWidth',3);
    zPointerBehavior.traverseFcn = [];
    zPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'zBallPoint'), 'LineWidth',1);
    
    iptSetPointerBehavior(cBallPoint, cPointerBehavior);
    iptSetPointerBehavior(xBallPoint, xPointerBehavior);
    iptSetPointerBehavior(yBallPoint, yPointerBehavior);
    iptSetPointerBehavior(zBallPoint, zPointerBehavior);
    
    xzRotPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'xzRotLine'), 'LineWidth',7);
    xzRotPointerBehavior.traverseFcn = [];
    xzRotPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'xzRotLine'), 'LineWidth',5);
    
    xyRotPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'xyRotLine'), 'LineWidth',7);
    xyRotPointerBehavior.traverseFcn = [];
    xyRotPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'xyRotLine'), 'LineWidth',5);
    
    iptSetPointerBehavior(xzRot, xzRotPointerBehavior);
    iptSetPointerBehavior(xyRot, xyRotPointerBehavior);
    
    squareRotPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'normBallPoint'), 'LineWidth',3);
    squareRotPointerBehavior.traverseFcn = [];
    squareRotPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'normBallPoint'), 'LineWidth',1);
    
    iptSetPointerBehavior(normBallPoint, squareRotPointerBehavior);
           
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
    
    startPositionI = [moveHandles(1).XData;moveHandles(1).YData;moveHandles(1).ZData];
    startPositionRotI = cell(1, length(rotHandles));
    for rotN=1:length(rotHandles)
        startPositionRotI{rotN} = [rotHandles(rotN).XData;rotHandles(rotN).YData;rotHandles(rotN).ZData];
    end
    
    updateDirection(vRot,theta,rotHandles,startPositionI,startPositionRotI,pointA,pointB)


    %% callback function called when a button press is performed on an active gizmo part
    function gizmoClick(src,evt)
    
        % get rotation of the axes system
        azimuth = wrapTo360(ax.View(1));
        elevation = ax.View(2);    
    
        % get position of the gizmo center in uM world and in pixel world
        startPosition = [moveHandles(1).XData;moveHandles(1).YData;moveHandles(1).ZData];
        cBallPointArray = [moveHandles(1).XData,moveHandles(1).YData,moveHandles(1).ZData];
        startPositionPix = MicroMToPixelPosition(cBallPointArray,ax); 
    
        % get initial position of the selected part in pixel world
        srcArray = [src.XData,src.YData,src.ZData];
        startPositionSrcPix = MicroMToPixelPosition(srcArray,ax);    

        % get initial position of the pointer in pixel world
        startScreenPosition = get(0,'Pointerlocation');
    
        % get starting position of rotational elements
        startPositionRot = cell(1, length(rotHandles));
        for rotN2=1:length(rotHandles)
            startPositionRot{rotN2} = [rotHandles(rotN2).XData;rotHandles(rotN2).YData;rotHandles(rotN2).ZData];
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
        
                    dy = D*YmicMetrPerPix;    
        
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
                        startPositionRot{rotN3} = [rotHandles(rotN3).XData;rotHandles(rotN3).YData;rotHandles(rotN3).ZData];
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
                    theta = sign(sind(elevation))*thetaVect(3);
        
                    updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)
                 
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

        handles(i).XData = handles(i).XData + dX;
        handles(i).YData = handles(i).YData + dY;
        handles(i).ZData = handles(i).ZData + dZ;

    end

    % save position of centre of the plane (pointA) and point on the normal (pointB)
    pointA.XData = handles(1).XData;
    pointA.YData = handles(1).YData;
    pointA.ZData = handles(1).ZData;

    pointB.XData = handles(10).XData;
    pointB.YData = handles(10).YData;
    pointB.ZData = handles(10).ZData;
end

%% function calculating new position via rotation
function updateDirection(vRot,theta,handles,startPosition,startPositionRot,~,pointB)

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
                handles(i).XData(corner) = P1_rotated(1);
                handles(i).YData(corner) = P1_rotated(2);
                handles(i).ZData(corner) = P1_rotated(3);
            end
        end
    end

    % save position of point on the normal (pointB) - centre of the plane (pointA) is not affected by rotation
    pointB.XData = handles(3).XData;
    pointB.YData = handles(3).YData;
    pointB.ZData = handles(3).ZData;    
end