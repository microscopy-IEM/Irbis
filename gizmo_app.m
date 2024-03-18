function originalCallbacks = gizmo_app(ax,fig,stickyPoints,pointA,pointB)
            
            buttonMotionCallback = fig.WindowButtonMotionFcn;
            buttonUpCallback = fig.WindowButtonUpFcn;
            scrollWheelCallback = fig.WindowScrollWheelFcn;

            originalCallbacks = {buttonMotionCallback,buttonUpCallback,scrollWheelCallback};

            % disable selectivity for all currently plotted components  
            h = ax.Children;
            for i = 1:length(h)
                if isprop(h(i), 'PickableParts')
                    set(h(i), 'PickableParts', 'none');
                end
            end
            
            x0 = 0;
            y0 = 0;
            z0 = 0;
            p0 = [x0 y0 z0];

            figH = fig;

            % clear old components
            delete(findobj(ax,'Tag','cBallPoint'))
            delete(findobj(ax,'Tag','xBallPoint'))
            delete(findobj(ax,'Tag','yBallPoint'))
            delete(findobj(ax,'Tag','zBallPoint'))

            delete(findobj(ax,'Tag','xlineLink'))

            delete(findobj(ax,'Tag','xzRotLine'))
            delete(findobj(ax,'Tag','xyRotLine'))
            delete(findobj(ax,'Tag','normSquare'))
            delete(findobj(ax,'Tag','3dPlane'))
            delete(findobj(ax,'Tag','normLink'))

            % default colors and transparency
            edgeCol = [0.3 0.3 0.3];
            % linkCol = [0.3 0.3 0.3];
            planeCol = [0.3 0.3 0.4];

            xCol = [0.4660 0.7740 0.1880];
            yCol = [0.7350 0.0780 0.1840];
            zCol = [0.3010 0.6450 0.9930];

            planeTansparency = 0.2;
            
            % gizmo size
            spacing = 1.2;
            ballSize = 12;
            planeEdgeSize = 3;

            %% Translation elements
        
            lx = line(ax,[x0,x0+spacing],[y0 y0],[z0 z0],'Tag','xlineLink','Color',xCol,'LineWidth',1);
            ly = line(ax,[x0,x0],[y0 y0+spacing],[z0 z0],'Tag','xlineLink','Color',yCol,'LineWidth',1);
            lz = line(ax,[x0,x0],[y0 y0],[z0 z0+spacing],'Tag','xlineLink','Color',[0.3010 0.7450 0.9330],'LineWidth',1);
  
            cBallPoint = plot3(ax,x0,y0,z0,'k','Marker','o','MarkerFaceColor','k','MarkerSize',ballSize,'Tag','cBallPoint','MarkerEdgeColor',edgeCol,'LineWidth',1);
            
            xBallPoint = plot3(ax,x0+spacing,y0,z0,'r','Marker','o','MarkerFaceColor',xCol,'MarkerSize',ballSize,'Tag','xBallPoint','MarkerEdgeColor',edgeCol,'UserData',[1 0 0]);
            yBallPoint = plot3(ax,x0,y0+spacing,z0,'g','Marker','o','MarkerFaceColor',yCol,'MarkerSize',ballSize,'Tag','yBallPoint','MarkerEdgeColor',edgeCol,'UserData',[0 1 0]);
            zBallPoint = plot3(ax,x0,y0,z0+spacing,'b','Marker','o','MarkerFaceColor',zCol,'MarkerSize',ballSize,'Tag','zBallPoint','MarkerEdgeColor',edgeCol,'UserData',[0 0 1]);
                  
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
            
            normPlane = fill3(ax,x,y,z,planeCol,'FaceAlpha',planeTansparency,'Tag','3dPlane');
            normLine = line(ax,[0 1.2*spacing],[0 0],[0 0],'LineWidth',1,'Color','k','Tag','normLink');
            normSquare = line(ax,1.25*spacing,0,0,'Marker','o','MarkerFaceColor',[0.4 0.4 0.4],'MarkerSize',15,'Tag','normSquare','LineWidth',1);

            %% Interactivity settings
            
            % disable selectivity for passive elements
            normPlane.PickableParts = "none";
            normLine.PickableParts = "none";
            lx.PickableParts = "none";
            ly.PickableParts = "none";
            lz.PickableParts = "none";
               
            % save handles of all objects
            moveHandles = [cBallPoint xBallPoint yBallPoint zBallPoint lx ly lz normLine normPlane normSquare xzRot xyRot];
            rotHandles = [normLine normPlane normSquare xzRot xyRot];

            % Assign ButtonDownFcn to elements
            % for central element only if there are sticky points
            if ~isempty(stickyPoints)
                cBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);
                cBallPoint.UserData = stickyPoints;
            end

            xBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);
            yBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);
            zBallPoint.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);

            xBallPoint.UserData = spacing;
            normSquare.UserData = radius;

            normSquare.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);
            xyRot.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);
            xzRot.ButtonDownFcn = @(src,evt)gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);


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

            squareRotPointerBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'normSquare'), 'LineWidth',3);
            squareRotPointerBehavior.traverseFcn = [];
            squareRotPointerBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'normSquare'), 'LineWidth',1);

            iptSetPointerBehavior(normSquare, squareRotPointerBehavior);
                   
            % enable Pointmanage within figure
            iptPointerManager(figH, 'enable');


            %% MOVE TO SET POSITION

            newPosition = [pointA.XData,pointA.YData,pointA.ZData];
            updatePosition(newPosition,moveHandles)            

            v1 = [normSquare.XData;normSquare.YData;normSquare.ZData] - [pointA.XData;pointA.YData;pointA.ZData];
            v2 = - [pointA.XData;pointA.YData;pointA.ZData] + [pointB.XData;pointB.YData;pointB.ZData];

            v1 = v1/norm(v1);
            v2 = v2/norm(v2);

            vRot = cross(v1,v2);

            theta = acos(dot(v1,v2)/(norm(v1)*norm(v2)));

            startPositionI = [moveHandles(1).XData;moveHandles(1).YData;moveHandles(1).ZData];
            startPositionRotI = {};
            for i=1:length(rotHandles)
                startPositionRotI{i} = [rotHandles(i).XData;rotHandles(i).YData;rotHandles(i).ZData];
            end

            updateDirection(vRot,theta,rotHandles,startPositionI,startPositionRotI,pointA,pointB)
            
end

function updatePosition(newPosition,handles,pointA,pointB)

    dX = newPosition(1) - handles(1).XData(1);
    dY = newPosition(2) - handles(1).YData(1);
    dZ = newPosition(3) - handles(1).ZData(1);

    for i = 1:length(handles)

        handles(i).XData = handles(i).XData + dX;
        handles(i).YData = handles(i).YData + dY;
        handles(i).ZData = handles(i).ZData + dZ;

    end

    % saving current position for output
    pointA.XData = handles(1).XData;
    pointA.YData = handles(1).YData;
    pointA.ZData = handles(1).ZData;

    pointB.XData = handles(10).XData;
    pointB.YData = handles(10).YData;
    pointB.ZData = handles(10).ZData;
end

function updateDirection(vRot,theta,handles,startPosition,startPositionRot,~,pointB)
    u = vRot;

    R = [cos(theta) + (u(1))^2 * (1 - cos(theta))      (u(1)) * (u(2)) * (1 - cos(theta)) - (u(3)) * sin(theta)    (u(1)) * (u(3)) * (1 - cos(theta)) + (u(2)) * sin(theta);
        (u(2)) * (u(1)) * (1 - cos(theta)) + (u(3)) * sin(theta)    cos(theta) + (u(2))^2 * (1 - cos(theta))    (u(2)) * (u(3)) * (1 - cos(theta)) - (u(1)) * sin(theta);
        (u(3)) * (u(1)) * (1 - cos(theta)) - (u(2)) * sin(theta)    (u(3)) * (u(2)) * (1 - cos(theta)) + (u(1)) * sin(theta)    cos(theta) + (u(3))^2 * (1 - cos(theta))];


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

    % saving current position for output - point A doesn't move by rotation
    pointB.XData = handles(3).XData;
    pointB.YData = handles(3).YData;
    pointB.ZData = handles(3).ZData;    
end

% function to return currert position of gizmo defined  by centre element
function pos = getPosition(handles)

end

% function to reture current direction (normal) od the gizmo
function dir = getDirection(handles)

end

% function that gets uM position of an object and return its position in pixel coordinates of the screen
function PixelPos = MicroMToPixelPositionArray(MicroMArray,tool)

    ax = tool.Parent;
    p1Pos = tool.Parent.Parent.Position;
    xP1 = p1Pos(1);
    yP1 = p1Pos(2);
    p2Pos = tool.Parent.Parent.Parent.Position;
    xP2 = p2Pos(1);
    yP2 = p2Pos(2);
    p3Pos = tool.Parent.Parent.Parent.Parent.Position;
    xP3 = p3Pos(1);
    yP3 = p3Pos(2);
    p4Pos = tool.Parent.Parent.Parent.Parent.Parent.Position;
    xP4 = p4Pos(1);
    yP4 = p4Pos(2);

    xParentPix = xP1 + xP2 + xP3 + xP4 -3;
    yParentPix = yP1 + yP2 + yP3 + yP4 -1;

    elevation = ax.View(2);
    azimuth = wrapTo360(ax.View(1));
    
    % getting dimensions of the axes object
    tighPos = ax.tightPosition;
    x0Pix = tighPos(1);
    y0Pix = tighPos(2);
    xPix = tighPos(3);
    yPix = tighPos(4);
        
    xLimMic = ax.XLim(2)-ax.XLim(1);
    yLimMic = ax.YLim(2)-ax.YLim(1); 
    zLimMic = ax.ZLim(2)-ax.ZLim(1);
    
    xCMic = MicroMArray(:,1);
    yCMic = MicroMArray(:,2);
    zCMic = MicroMArray(:,3);

    % calculating ratio of x and y side, in respect to the bounding box
    cosRatio = abs(cosd(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));
    sinRatio = abs(sind(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));

    % % calculating proportional movement contribution by x and y, depending on the rotation - new rotational system
    % xXratio = sign(cosd(azimuth))*xCMic/xLimMic;
    % if sign(cosd(azimuth)) < 0
    % xXratio = 1 + xXratio;
    % end
    % xYratio = sign(-sind(azimuth))*sign(sind(elevation))*xCMic/xLimMic;
    % if sign(sind(azimuth)) < 0
    % xYratio = 1 + xYratio;
    % end
    % yXratio = sign(-sind(azimuth))*yCMic/yLimMic;
    % if sign(-sind(azimuth)) < 0
    % yXratio = 1 + yXratio;
    % end
    % yYratio = sign(cosd(azimuth))*sign(sind(elevation))*yCMic/yLimMic;
    % if sign(-cosd(azimuth)) < 0
    % yYratio = 1 + yYratio;
    % end
    % 
    % % calculating proportional movement contribution by x and y, depending on the rotation - old rotational system
    % xXratio = sign(cosd(azimuth))*xCMic/xLimMic;
    % if sign(cosd(azimuth)) < 0
    % xXratio = 1 + xXratio;
    % end
    % xYratio = sign(-sind(azimuth))*sign(sind(elevation))*xCMic/xLimMic;
    % if sign(sind(azimuth)) < 0
    % xYratio = 1 + xYratio;
    % end
    % yXratio = sign(-sind(azimuth))*yCMic/yLimMic;
    % if sign(-sind(azimuth)) < 0
    % yXratio = 1 + yXratio;
    % end
    % yYratio = sign(-cosd(azimuth))*sign(sind(elevation))*yCMic/yLimMic;
    % if sign(-cosd(azimuth)) < 0
    % yYratio = 1 + yYratio;
    % end

    % calculating proportional movement contribution by x and y, depending on the rotation - new rotational system
    xXratio = sign(cosd(azimuth))*xCMic/xLimMic;
    if sign(cosd(azimuth)) < 0
    xXratio = 1 + xXratio;
    end
    xYratio = sign(-sind(azimuth))*sign(sind(elevation))*xCMic/xLimMic;
    if sign(-sind(azimuth))*sign(sind(elevation)) < 0
    xYratio = 1 + xYratio;
    end
    yXratio = sign(sind(azimuth))*yCMic/yLimMic;
    if sign(sind(azimuth)) < 0
    yXratio = 1 + yXratio;
    end
    yYratio = sign(cosd(azimuth))*sign(sind(elevation))*yCMic/yLimMic;
    if sign(cosd(azimuth))*sign(sind(elevation)) < 0
    yYratio = 1 + yYratio;
    end    

    % calculating the position of point in pixel world relative to the origin in coordinates of the screen
    xCPix = x0Pix + xParentPix + xPix*cosRatio*xXratio + xPix*sinRatio*yXratio;
    yCPix = y0Pix + yParentPix + yPix*abs(sind(elevation))*sinRatio*xYratio + yPix*abs(sind(elevation))*cosRatio*yYratio + yPix*(1-abs(sind(elevation)))*(zCMic-ax.ZLim(1))/zLimMic;
    
    PixelPos = [xCPix,yCPix];
end


% function set button callback when clicked on specific element
function gizmoClick(src,evt,moveHandles,rotHandles,pointA,pointB,fig,buttonMotionCallback,buttonUpCallback,scrollWheelCallback)

    tool = src;
    ax = src.Parent;
    figHandle = fig; %src.Parent.Parent;

    % position of the gizmo center in uM world and in pixel world
    startPosition = [moveHandles(1).XData;moveHandles(1).YData;moveHandles(1).ZData];
    cBallPointArray = [moveHandles(1).XData,moveHandles(1).YData,moveHandles(1).ZData];
    startPositionPix = MicroMToPixelPositionArray(cBallPointArray,tool);

    % initial position of the pointer in pixel world
    startScreenPosition = get(0,'Pointerlocation');
    
    % initial position of the selected part in pixel world
    toolArray = [tool.XData,tool.YData,tool.ZData];
    startPositionToolPix = MicroMToPixelPositionArray(toolArray,tool);

    % set(0,'PointerLocation',startPositionToolPix)

    startPositionRot = {};
    for i=1:length(rotHandles)
        startPositionRot{i} = [rotHandles(i).XData;rotHandles(i).YData;rotHandles(i).ZData];
    end

    if evt.Button == 3
       
            switch src.Tag
                case 'xBallPoint'
                    ax.View = [0 90];
                case 'yBallPoint'
                    ax.View = [90 0];
        
                case 'zBallPoint'
                    ax.View = [0 0];
    
                case 'cBallPoint'
                    ax.View = [-30 30];    
        
            end
    
    elseif evt.Button == 1      % this makes it translate only when left button is pressed
            
        figHandle.WindowButtonMotionFcn = @(src,evt)gizmoMove(src,evt,moveHandles,rotHandles,startPosition,startPositionRot,tool,startScreenPosition,startPositionPix,startPositionToolPix,pointA,pointB,fig);
        figHandle.WindowButtonUpFcn = @(src,evt)resetClb(src,evt,figHandle,buttonMotionCallback,buttonUpCallback,scrollWheelCallback);

    elseif evt.Button == 2      % assings the scrollwheel callback

        figHandle.WindowScrollWheelFcn = @(src,evt)scrollwheelMove(src,evt);
        theta = 0;
        dPos = 0;
        scrolledElement = tool;

    end

    % Assign ButtonDownFcn to elements
    % for central element only if there are sticky points
    if ~isempty(moveHandles(1).UserData)
        stickyPoints2DArray = MicroMToPixelPositionArray(moveHandles(1).UserData,moveHandles(1));
        moveHandles(4).UserData = stickyPoints2DArray;
    end

    function gizmoMove(~,evt,moveHandles,rotHandles,startPosition,startPositionRot,tool,startScreenPosition,startPositionPix,startPositionToolPix,pointA,pointB,fig)

        ax = tool.Parent;
        cursorPoint = evt.IntersectionPoint;
        currentScreenPosition = get(0,'Pointerlocation');

        % spacing information saved in xBallPoint element userData
        spacing = moveHandles(2).UserData;

        if sum(isnan(cursorPoint)) == 0
                
                
                
                % check axis limits
                if cursorPoint(1) > ax.XLim(2)
                    cursorPoint(1) = ax.XLim(2);
                elseif cursorPoint(1) < ax.XLim(1)+spacing
                    cursorPoint(1) = ax.XLim(1)+spacing;
                
                end
                
                if cursorPoint(2) > ax.YLim(2)
                    cursorPoint(2) = ax.YLim(2);
                elseif cursorPoint(2) < ax.YLim(1)+spacing
                    cursorPoint(2) = ax.YLim(1)+spacing;
                
                end
                
                if cursorPoint(3) > ax.ZLim(2)
                    cursorPoint(3) = ax.ZLim(2);
                elseif cursorPoint(3) < ax.ZLim(1)+spacing
                    cursorPoint(3) = ax.ZLim(1)+spacing;
                end
                
        end

        azimuth = wrapTo360(ax.View(1));
        elevation = ax.View(2);

         switch tool.Tag
                
            case 'xBallPoint'
                
                % clc;
            
                % line equation - this calculation can be pre-calculated to speed up
                x0 = startScreenPosition(1);
                y0 = startScreenPosition(2);
 
                % IS 231115 line equation redefined using cos and sin
                aL = cosd(azimuth);
                bL = -sind(azimuth)*sind(elevation);
                aLn = aL/sqrt(aL^2 + bL^2);
                bLn = bL/sqrt(aL^2 + bL^2);
                cLn = -aLn*x0 -bLn*y0;
              
                x1 = currentScreenPosition(1);
                y1 = currentScreenPosition(2);
    
                % calculate distance of current point to line
    
                D = (aLn*x1 + bLn*y1 + cLn)/sqrt(aLn^2 + bLn^2);
    
                % get axes size in pixels
                tighPos = ax.tightPosition;
                xPix = tighPos(3);
       
                % measure distance "corner to corner" of % this calculation can be pre-calculated to speed up
                % axes (depends on axes azimuth)
               
                a = ax.XLim(2);
                b0 = ax.YLim(2);
    
                xDiagMic = abs(a*sind(azimuth)) + abs(b0*cosd(azimuth));
    
            
                % calculate micrometer to pixel ratio
                micMetrPerPix = xDiagMic/xPix;
    
                dx = D*micMetrPerPix;
    
                newPosition = [startPosition(1)+dx startPosition(2) startPosition(3)];
                updatePosition(newPosition,moveHandles,pointA,pointB)
    
                
            case 'yBallPoint'
                % clc
                x0 = startScreenPosition(1);
                y0 = startScreenPosition(2);
    
                aL = sind(azimuth);
                bL = cosd(azimuth)*sind(elevation);
                cL = -aL*x0 -bL*y0;
    
                x1 = currentScreenPosition(1);
                y1 = currentScreenPosition(2);                          
    
                D = (aL*x1 + bL*y1 + cL)/sqrt(aL^2 + bL^2);
    
                % get axes size in pixels
                tighPos = ax.tightPosition;
                xPix = tighPos(3);
       
                % measure distanec "corner to corner" of % this calculation can be pre-calculated to speed up
                % axes (depends on axes azimuth)
               
                a = ax.XLim(2);
                b0 = ax.YLim(2);
                xDiagMic = abs(a*sind(azimuth)) + abs(b0*cosd(azimuth));
    
    
                % calculate micrometer to pixel ratio
                micMetrPerPix = xDiagMic/xPix;
    
                dy = D*micMetrPerPix;    
    
                newPosition = [startPosition(1) startPosition(2)+dy  startPosition(3)];
                updatePosition(newPosition,moveHandles,pointA,pointB)                         
    
                                                        
            case 'zBallPoint'

                % block for total z projection (look from above xy plane)
                if elevation ~= 90
    
                    % get movement distance in pixels
                    z0 = startScreenPosition(2);
                    zc = currentScreenPosition(2);
                    mouseDist = z0-zc;
    
                    % Deal with axis orientation in two steps:
                    % First step deals with azimuth
                    % get axes size in pixels
                    tighPos = ax.tightPosition;
                    xPix = tighPos(3);
           
                    % measure distanec "corner to corner" of
                    % axes (depends on axes azimuth)
                    % xMic = sqrt(ax.XLim(2)^2 + ax.YLim(2)^2);  % this calculation can be pre-calculated to speed up
    
                    a = ax.XLim(2);
                    b0 = ax.YLim(2);
                    % xMic = a*sind(azimuth) + b*cosd(azimuth);
                    xDiagMic = abs(a*sind(azimuth)) + abs(b0*cosd(azimuth));
                
                    % calculate micrometer to pixel ratio
                    micMetrPerPix = xDiagMic/xPix;
    
                    % Second step deals with elevation
                    dz = mouseDist/sind(90-elevation);
                      
                    newPosition = [startPosition(1) startPosition(2) startPosition(3) - dz*micMetrPerPix];
                    updatePosition(newPosition,moveHandles,pointA,pointB)
    
                end
    
            case 'cBallPoint'
                % stick to points code + follow normal
   
                 % find the index in 2D...
                 stickyPoints2D = moveHandles(4).UserData;
                 stickyPoints3D = moveHandles(1).UserData;
                 csp = [currentScreenPosition(1) currentScreenPosition(2)];
                 [spineIndexes,~] = knnsearch(stickyPoints2D,csp);
                 %[spineIndexes,~] = knnsearch(tool.UserData,cursorPoint);

                 % ...and get the new position in 3D
                 newPosition = stickyPoints3D(spineIndexes,:);
    
                 updatePosition(newPosition,moveHandles,pointA,pointB)

                 % rotation:

                 if spineIndexes+5 < size(stickyPoints2D,1)
                    
                 pointB.XData = stickyPoints3D(spineIndexes+5,1);
                 pointB.YData = stickyPoints3D(spineIndexes+5,2);
                 pointB.ZData = stickyPoints3D(spineIndexes+5,3);

                 else
                     pointB.XData = stickyPoints3D(spineIndexes-5,1);
                     pointB.YData = stickyPoints3D(spineIndexes-5,2);
                     pointB.ZData = stickyPoints3D(spineIndexes-5,3);
                 end

                 pA = [pointA.XData;pointA.YData;pointA.ZData];
                 pB = [pointB.XData;pointB.YData;pointB.ZData];
                 pC = [rotHandles(3).XData;rotHandles(3).YData;rotHandles(3).ZData];
            
                 v1 = (pB - pA)/norm(pB - pA);
                 v2 = (pC - pA)/norm(pC - pA);
            
                 vRot = cross(v1,v2)/norm(cross(v1,v2));
            
                 theta = acos(-dot(v1,v2)/(norm(v1)*norm(v2)));
        
                 startPosition = pA;
        
                
                startPositionRot = {};
                for i=1:length(rotHandles)
                    startPositionRot{i} = [rotHandles(i).XData;rotHandles(i).YData;rotHandles(i).ZData];
                end
                updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)

             case 'normSquare'
                x0 = startPositionToolPix(1);
                y0 = startPositionToolPix(2);
                 
                vLine = startPositionToolPix - startPositionPix;

                cL = -vLine(1)*x0 -vLine(2)*y0;

                x1 = currentScreenPosition(1);
                y1 = currentScreenPosition(2);                

                D = (vLine(1)*x1 + vLine(2)*y1 + cL)/sqrt(vLine(1)^2 + vLine(2)^2);
    
                % get axes size in pixels
                tighPos = ax.tightPosition;
                xPix = tighPos(3);
       
                % measure distanec "corner to corner" of % this calculation can be pre-calculated to speed up
                % axes (depends on axes azimuth)
               
                a = ax.XLim(2);
                b0 = ax.YLim(2);
    
                xDiagMic = abs(a*sind(azimuth)) + abs(b0*cosd(azimuth));
    
            
                % calculate micrometer to pixel ratio
                micMetrPerPix = xDiagMic/xPix;

                vMicroM = - startPosition + startPositionRot{3};

                vMicroMnorm = vMicroM/norm(vMicroM);

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

    function scrollwheelMove(~,evt)
        % disp(['verticalScrollCount: ' num2str(evt.VerticalScrollCount)])

        switch scrolledElement.Tag

            case 'xBallPoint'
                dPos = dPos + evt.VerticalScrollCount*0.1;
                newPosition = [startPosition(1)+dPos startPosition(2) startPosition(3)];
                updatePosition(newPosition,moveHandles,pointA,pointB)
                % startPosition = newPosition;
            case 'yBallPoint'
                dPos = dPos + evt.VerticalScrollCount*0.1;
                newPosition = [startPosition(1) startPosition(2)+dPos startPosition(3)];
                updatePosition(newPosition,moveHandles,pointA,pointB)
                % startPosition = newPosition;                
            case 'zBallPoint'
                dPos = dPos + evt.VerticalScrollCount*0.1;
                newPosition = [startPosition(1) startPosition(2) startPosition(3)+dPos];
                updatePosition(newPosition,moveHandles,pointA,pointB)
                % startPosition = newPosition;                
            case 'cBallPoint'
            case 'normSquare'
                dx = rotHandles(3).XData - moveHandles(1).XData;
                dy = rotHandles(3).YData - moveHandles(1).YData;
                dz = rotHandles(3).ZData - moveHandles(1).ZData;

                % dv = sqrt(dx^2 + dy^2 + dz^2);
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


function resetClb(src,~,f,buttonMotionCallback,buttonUpCallback,scrollWheelCallback)
         
            ax = src;
                  
            f.WindowButtonMotionFcn = buttonMotionCallback;
            f.WindowButtonUpFcn = buttonUpCallback;
            f.WindowScrollWheelFcn = scrollWheelCallback;

            % TO FIX - return original WindowButtonMotionFcn after gizmo is switched off
            % MyDragzoom(ax,'on');        
end

% function rotateAndReset(src,evt,tool,moveHandles,rotHandles,pointA,pointB,f)
% 
%         ax = src;
%         f.WindowButtonMotionFcn = [];     
% 
%          % rotation:
% 
%          pA = [pointA.XData;pointA.YData;pointA.ZData];
%          pB = [pointB.XData;pointB.YData;pointB.ZData];
%          pC = [rotHandles(3).XData;rotHandles(3).YData;rotHandles(3).ZData];
% 
%          v1 = (pB - pA)/norm(pB - pA);
%          v2 = (pC - pA)/norm(pC - pA);
% 
%          vRot = cross(v1,v2)/norm(cross(v1,v2));
% 
%          theta = acos(-dot(v1,v2)/(norm(v1)*norm(v2)));
% 
%          startPosition = pA;
% 
% 
%         startPositionRot = {};
%         for i=1:length(rotHandles)
%             startPositionRot{i} = [rotHandles(i).XData;rotHandles(i).YData;rotHandles(i).ZData];
%         end
%         updateDirection(vRot,theta,rotHandles,startPosition,startPositionRot,pointA,pointB)
% 
%         MyDragzoom(ax,'on');  
% 
% end