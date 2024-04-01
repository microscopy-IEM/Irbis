% function that gets uM position of an object and return its position in pixel coordinates of the screen
function PixelPos = MicroMToPixelPosition_testing(MicroMArray,ax)

    p1Pos = ax.Parent.Position;
    xP1 = p1Pos(1);
    yP1 = p1Pos(2);
    p2Pos = ax.Parent.Parent.Position;
    xP2 = p2Pos(1);
    yP2 = p2Pos(2);
    p3Pos = ax.Parent.Parent.Parent.Position;
    xP3 = p3Pos(1);
    yP3 = p3Pos(2);
    % p4Pos = ax.Parent.Parent.Parent.Parent.Position;
    % xP4 = p4Pos(1);
    % yP4 = p4Pos(2);

    xParentPix = xP1 + xP2 + xP3;
    yParentPix = yP1 + yP2 + yP3;

    % xParentPix = xP1 + xP2 + xP3;
    % yParentPix = yP1 + yP2 + yP3;
    
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
    % cosRatio = abs(cosd(azimuth)*xLimMic)/(abs(cosd(azimuth)*xLimMic) + abs(sind(azimuth)*yLimMic));
    % sinRatio = abs(sind(azimuth)*yLimMic)/(abs(cosd(azimuth)*yLimMic) + abs(sind(azimuth)*yLimMic));
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

    sinRE = abs(sind(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));
    cosRE = abs(cosd(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));

    sinREw = sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth)))/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    cosREw = cosRE*zLimMic/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));

    xCPix = x0Pix + xParentPix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    yCPix = y0Pix + yParentPix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zCMic-ax.ZLim(1))/zLimMic;
    

    % sinRE = abs(sind(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));
    % cosRE = abs(cosd(elevation))/(abs(sind(elevation))+abs(cosd(elevation)));
    % 
    % sinREw = sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth)))/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    % cosREw = cosRE*zLimMic/(cosRE*zLimMic+sinRE*(xLimMic*abs(sind(azimuth))+yLimMic*abs(cosd(azimuth))));
    % 
    % xCPix = x0Pix + xParentPix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    % yCPix = y0Pix + yParentPix + yPix*sinREw*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*sinREw*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*cosREw*(zCMic-ax.ZLim(1))/zLimMic;

    % xCPix = x0Pix + xParentPix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    % yCPix = y0Pix + yParentPix + yPix*abs(sind(elevation))*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*abs(sind(elevation))*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*(1-abs(sind(elevation)))*(zCMic-ax.ZLim(1))/zLimMic;
    % xCPix = x0Pix + xParentPix + xPix*cosRatio*xXratio + xPix*sinRatio*yXratio;
    % yCPix = y0Pix + yParentPix + yPix*abs(sind(elevation))*sinRatio*xYratio + yPix*abs(sind(elevation))*cosRatio*yYratio + yPix*(1-abs(sind(elevation)))*(zCMic-ax.ZLim(1))/zLimMic;


    % calculating the position of point in pixel world relative to the origin in coordinates of the screen
    % disp(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % disp(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio))
    % xCPix = x0Pix + xParentPix + xPix*xXratio*(xLimMic*cosRatio/(xLimMic*cosRatio+yLimMic*sinRatio)) + xPix*yXratio*(yLimMic*sinRatio/(xLimMic*cosRatio+yLimMic*sinRatio));
    % yCPix = y0Pix + yParentPix + yPix*xYratio*(xLimMic*sinRatio/(xLimMic*sinRatio+yLimMic*cosRatio)) + yPix*yYratio*(yLimMic*cosRatio/(xLimMic*sinRatio+yLimMic*cosRatio));

    % xCPix = x0Pix + xParentPix + xXratio*xPix*abs(cosd(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth))*yLimMic/xLimMic) + yXratio*xPix*abs(sind(azimuth))/(abs(cosd(azimuth))*xLimMic/yLimMic + abs(sind(azimuth)));
    % yCPix = y0Pix + yParentPix + yYratio*yPix*abs(cosd(azimuth))/(abs(cosd(azimuth)) + abs(sind(azimuth))*xLimMic/yLimMic) + xYratio*yPix*abs(sind(azimuth))/(abs(cosd(azimuth))*yLimMic/xLimMic + abs(sind(azimuth)));
    % xCPix = x0Pix + xParentPix + xPix*cosRatio*xXratio + xPix*sinRatio*yXratio;
    % yCPix = y0Pix + yParentPix + yPix*abs(sind(elevation))*sinRatio*xYratio + yPix*abs(sind(elevation))*cosRatio*yYratio + yPix*(1-abs(sind(elevation)))*(zCMic-ax.ZLim(1))/zLimMic;

    % xLimPix = (xPix*cosd(azimuth) - yPix*sind(azimuth))/(cosd(azimuth)^2 - sind(azimuth)^2);
    % yLimPix = (yPix*cosd(azimuth) + xPix*sind(azimuth))/(cosd(azimuth)^2 - sind(azimuth)^2);
    % 
    % xCPix = x0Pix + xParentPix + xXratio*xLimPix*cosd(azimuth) + yXratio*yLimPix*sind(azimuth);
    % yCPix = y0Pix + yParentPix + yYratio*yLimPix*cosd(azimuth) + xYratio*xLimPix*sind(azimuth);
    % 

    % co = abs(cosd(azimuth));
    % si = abs(sind(azimuth));
    % xCPix = x0Pix + xParentPix + xXratio*xPix*xLimMic*co/(xLimMic*co+yLimMic*si) + yXratio*xPix*yLimMic*si/(xLimMic*co+yLimMic*si);
    % yCPix = y0Pix + yParentPix + xYratio*yPix*xLimMic*si/(xLimMic*si+yLimMic*co)*abs(sind(elevation)) + yYratio*yPix*yLimMic*co/(xLimMic*si+yLimMic*co)*abs(sind(elevation)) + yPix*(1-abs(sind(elevation)))*(zCMic-ax.ZLim(1))/zLimMic;

    % xCPix = x0Pix + xParentPix + xXratio*xPix*co*1/(1*co+2*si) + yXratio*xPix*(1-sind(azimuth))*2/(1*co+2*(1-sind(azimuth)));
    % % xCPix = x0Pix + xParentPix + xXratio*xPix*co*2/(2*co+1*si) + yXratio*xPix*si*1/(2*co+1*si);
    % yCPix = y0Pix + yParentPix + xYratio*yPix*si*1/(1*si+2*co) + yYratio*yPix*co*2/(1*si+2*co);
    % 

    % yCPix = y0Pix + yParentPix + (0.3411/(1+0.3411))*yPix;
    % yCPix = y0Pix + yParentPix + (0.5/(1+0.5))*yPix;


    % checks 
    disp(['sin: ' num2str(sind(azimuth))])
    disp(['cos: ' num2str(cosd(azimuth))])

    disp(['cosRatio ' num2str(cosRatio)])
    disp(['sinRatio ' num2str(sinRatio)])

    disp(['xPix ' num2str(xPix)])
    disp(['yPix ' num2str(yPix)])    

    disp(['xXratio ' num2str(xXratio)])
    disp(['yXratio ' num2str(yXratio)]) 
    disp(['xYratio ' num2str(xYratio)])
    disp(['yYratio ' num2str(yYratio)])

    disp(azimuth)
    disp(elevation)

    disp(['yCPix ' num2str(yCPix)])
    disp(['ycont ' num2str(yCPix - (y0Pix + yParentPix))])

    PixelPos = [xCPix,yCPix];

    set(0,'PointerLocation',[x0Pix + xParentPix,y0Pix + yParentPix])
    pause(1)
    % set(0,'PointerLocation',[xCPix,y0Pix + yParentPix])
    % set(0,'PointerLocation',[x0Pix + xParentPix,yCPix])
    set(0,'PointerLocation',[xCPix,yCPix])

end