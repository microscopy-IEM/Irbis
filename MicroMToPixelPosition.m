% function that gets uM position of an object and return its position in pixel coordinates of the screen
function PixelPos = MicroMToPixelPosition(MicroMArray,ax)

    p1Pos = ax.Parent.Position;
    xP1 = p1Pos(1);
    yP1 = p1Pos(2);
    p2Pos = ax.Parent.Parent.Position;
    xP2 = p2Pos(1);
    yP2 = p2Pos(2);
    p3Pos = ax.Parent.Parent.Parent.Position;
    xP3 = p3Pos(1);
    yP3 = p3Pos(2);
    p4Pos = ax.Parent.Parent.Parent.Parent.Position;
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