% function that gets uM position of an object and return its position in pixel coordinates of the screen
function PixelPos = MicroMToPixelPosition(MicroMArray,ax)

    clc

    disp(ax.CameraUpVector)
    % ax.CameraUpVector = [0 0 1];

    %% get current rotation of the axes
    % elevation = ax.View(2);
    % azimuth = wrapTo360(ax.View(1));

    xSign = 1;
    if ax.XDir == "reverse"
        xSign = -1;
    end

    ySign = 1;
    if ax.YDir == "reverse"
        ySign = -1;
    end

    disp(ax.CameraPosition)
    disp(ax.CameraTarget)
    % sightVector =  ax.CameraTarget - ax.CameraPosition
    % azimuth = -atan2d(xSign*sightVector(1), ySign*sightVector(2))

    sightVector = ax.CameraPosition - ax.CameraTarget;
    azimuth = -atan2d(-xSign*sightVector(1), -ySign*sightVector(2))

    disp('original view')
    disp(ax.View)

    % azimuth = atan2d(ax.CameraUpVector(1), ax.CameraUpVector(2))

    if ax.CameraUpVector(3) < 0
        azimuth = azimuth + 180
    end

    a = [0 0 1];
    elevation = acosd(dot(a, sightVector)/norm(sightVector));
    elevation = 90 - elevation

    % if isequal(elevation, 90) || isequal(elevation, -90)
        % if the elevation is 90 or -90, the projection of sight to xy plane is zero
        azimuth2 = -atan2d(-xSign*ax.CameraUpVector(1), -ySign*ax.CameraUpVector(2))    % elevation negative
        azimuth2 = -atan2d(xSign*ax.CameraUpVector(1), ySign*ax.CameraUpVector(2))  % elevation positive
    % end

    %% get the absolute position of the bounding box lower right corner in pixels

    % get overall position of the parent structures
    xParentPix = 0;
    yParentPix = 0;

    currentObject = ax.Parent;

    cycle = 0;
    while true
        % cycle = cycle + 1
        % if ~isa(currentObject, 'matlab.ui.container.GridLayout')
        %     disp(class(currentObject))
        %     currentObject
        % end
        % currentObject
        pos = currentObject.Position;
        % disp(pos)
        xParentPix = xParentPix + pos(1);
        yParentPix = yParentPix + pos(2);
        if isa(currentObject,'matlab.ui.Figure')
            break
        end
        currentObject = currentObject.Parent;
    end

    xParentPix = xParentPix - (ax.InnerPosition(1) - ax.OuterPosition(1));
    yParentPix = yParentPix - (ax.InnerPosition(2) - ax.OuterPosition(2));

    % p1Pos = ax.Parent.Position;
    % xP1 = p1Pos(1);
    % yP1 = p1Pos(2);
    % p2Pos = ax.Parent.Parent.Position;
    % xP2 = p2Pos(1);
    % yP2 = p2Pos(2);
    % p3Pos = ax.Parent.Parent.Parent.Position;
    % xP3 = p3Pos(1);
    % yP3 = p3Pos(2);
    % p4Pos = ax.Parent.Parent.Parent.Parent.Position;
    % xP4 = p4Pos(1);
    % yP4 = p4Pos(2);
    % isa(ax.Parent.Parent.Parent.Parent,'matlab.ui.Figure')
    % 
    % xParentPix = xP1 + xP2 + xP3 + xP4 -3;
    % yParentPix = yP1 + yP2 + yP3 + yP4 -1;

 
    %% get dimensions of the axes object

    % dimensions of axes in pixels
    tighPos = ax.tightPosition;
    x0Pix = tighPos(1);
    y0Pix = tighPos(2);
    xPix = tighPos(3);
    yPix = tighPos(4);
        
    % axes limits in microM
    xLimMic = ax.XLim(2)-ax.XLim(1);
    yLimMic = ax.YLim(2)-ax.YLim(1);
    zLimMic = ax.ZLim(2)-ax.ZLim(1);

    if isempty(MicroMArray)
        MicroMArray = get(ax, 'currentpoint');
        MicroMArray = MicroMArray(1,1:3);
    end
    
    % coordinate position in microM
    xCMic = MicroMArray(:,1)-ax.XLim(1);
    yCMic = MicroMArray(:,2)-ax.YLim(1);
    zCMic = MicroMArray(:,3)-ax.ZLim(1);

    %% calculate the relative position of the coordinate in respect to the bounding box in pixels 

    % calculating proportional contribution by x and y, depending on the rotation
    xXratio = xSign*sign(cosd(azimuth))*xCMic/xLimMic;
    if xSign*sign(cosd(azimuth)) < 0
    xXratio = 1 + xXratio;
    end
    xYratio = xSign*sign(-sind(azimuth))*sign(sind(elevation))*xCMic/xLimMic;
    if xSign*sign(-sind(azimuth))*sign(sind(elevation)) < 0
    xYratio = 1 + xYratio;
    end
    % reversed y - minus sign in sign(-sind(azimuth)) instead of plus
    yXratio = ySign*sign(sind(azimuth))*yCMic/yLimMic;
    if ySign*sign(sind(azimuth)) < 0
    yXratio = 1 + yXratio;
    end
    % reversed y - minus sign in sign(-cosd(azimuth)) instead of plus
    yYratio = ySign*sign(cosd(azimuth))*sign(sind(elevation))*yCMic/yLimMic;
    if ySign*sign(cosd(azimuth))*sign(sind(elevation)) < 0
    yYratio = 1 + yYratio;
    end    

    % calculating contribution of axes weighted by their length
    cosRatio = abs(cosd(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));
    sinRatio = abs(sind(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));

    sinRE = abs(sind(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));
    cosRE = abs(cosd(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));

    % sinREw = sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth)))/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    % cosREw = cosRE*zLimMic/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));

    sinREw = sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth)))/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    cosREw = cosRE*zLimMic/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));

    %% get the absolute position in pixels

    % disp('ratio')
    % cosRatio
    % yXratio
    % % abs(xLimMic*cosd(azimuth))/(abs(xLimMic*cosd(azimuth)) + abs(yLimMic*sind(azimuth)))
    % (xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % (yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio))

    xCPix = xParentPix + x0Pix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    yCPix = yParentPix + y0Pix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zCMic)/zLimMic;

    if ax.CameraUpVector(3) < 0
        yCPix = yParentPix + y0Pix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zLimMic-zCMic)/zLimMic;
    end

    % if ax.CameraUpVector(3) < 0
    %     yCPix = yParentPix + y0Pix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) - yPix*cosREw*(zCMic)/zLimMic;
    % end
    % xCPix = xParentPix + x0Pix + xPix*xXratio*(yLimMic*cosRatio/(yLimMic*cosRatio+xLimMic*sinRatio)) + xPix*yXratio*(xLimMic*sinRatio/(yLimMic*cosRatio+xLimMic*sinRatio));
    % yCPix = yParentPix + y0Pix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zCMic)/zLimMic;

    % set(ax,'PlotBoxAspectRatio',[1,1,1]);

    PixelPos = [xCPix,yCPix];

    % set(ax, 'Box', 'on');

    % set(0,'PointerLocation',[xParentPix  + x0Pix,yParentPix + y0Pix]);
    % pause(1)
    % % set(0,'PointerLocation',[xParentPix + x0Pix + xPix,yParentPix + y0Pix]);
    % % pause(1)
    % set(0,'PointerLocation',[xParentPix + x0Pix + xPix,yParentPix + y0Pix + yPix]);
    % pause(1)

    % ax.View

    % a = [0 1];
    % sightVector = ax.CameraPosition - ax.CameraTarget;
    % b = -sightVector(1:2);
    % azimuth = acosd(dot(a, b)/norm(b))
    % s = sign(dot(a, b))

    % -atan2d(-sightVector(1), -sightVector(2))

    % a = [0 0 1];
    % sightVector = ax.CameraPosition - ax.CameraTarget;
    % elevation = acosd(dot(a, sightVector)/norm(sightVector))
    % s = sign(dot(a, sightVector))
    % elevation2 = 90 - elevation

    set(0,'PointerLocation',[xCPix,yCPix])

    assignin('base', 'ax', ax);


end