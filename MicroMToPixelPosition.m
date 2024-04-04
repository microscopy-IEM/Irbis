% function that gets uM position of an object and return its position in pixel coordinates of the screen
function PixelPos = MicroMToPixelPosition(MicroMArray,ax)

    %% get current rotation of the axes
    elevation = ax.View(2);
    azimuth = wrapTo360(ax.View(1));

    %% get the absolute position of the bounding box lower right corner in pixels

    % get overall position of the parent structures
    xParentPix = 0;
    yParentPix = 0;

    currentObject = ax.Parent;

    while true
        pos = currentObject.Position;
        xParentPix = xParentPix + pos(1);
        yParentPix = yParentPix + pos(2);
        if isa(currentObject,'matlab.ui.Figure')
            break
        end
        currentObject = currentObject.Parent;
    end

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
    
    % coordinate position in microM
    xCMic = MicroMArray(:,1)-ax.XLim(1);
    yCMic = MicroMArray(:,2)-ax.YLim(1);
    zCMic = MicroMArray(:,3)-ax.ZLim(1);

    %% calculate the relative position of the coordinate in respect to the bounding box in pixels 

    % calculating proportional contribution by x and y, depending on the rotation
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

    % calculating contribution of axes weighted by their length
    cosRatio = abs(cosd(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));
    sinRatio = abs(sind(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth)));

    sinRE = abs(sind(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));
    cosRE = abs(cosd(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));

    sinREw = sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth)))/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    cosREw = cosRE*zLimMic/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));

    %% get the absolute position in pixels

    xCPix = xParentPix + x0Pix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    yCPix = yParentPix + y0Pix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zCMic)/zLimMic;

    % set(ax,'PlotBoxAspectRatio',[1,1,1]);

    PixelPos = [xCPix,yCPix];


end