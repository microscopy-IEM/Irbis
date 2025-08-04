function positionPix = MicroMToPixelPosition(positionUM, ax)

    % clc
    % Assumptions: 
    %   - We manually change the position of the camera position and target, and CameraViewAngle
    %   - CameraUpVector automatically adjusts to the other parameters
    %   - DataAspectRatio of axes is set to [1 1 1], PlotBoxAspectRatio corresponds to the axes aspect ratio
    %   - positionUM is in the same units (micrometers in our case) as the 3D system of the axes

    % get information about axes organization and rotation
    [xSign, ySign, zSign] = getAxesDirection(ax);

    [azimuth, elevation, isUpsideDown] = calculateRotation(ax, xSign, ySign, zSign);
    % disp(ax.View)

    [xPosUM, yPosUM, zPosUM] = getMicromPosition(ax, positionUM);
    [xRangeUM, yRangeUM, zRangeUM] = getAxesRanges(ax);

    [xFractionToWidth, xFractionToHeight] = calculateXaxisContributions(azimuth, elevation, xSign, xPosUM, xRangeUM);
    [yFractionToWidth, yFractionToHeight] = calculateYaxisContributions(azimuth, elevation, ySign, yPosUM, yRangeUM);

    % calculate the horizontal position within the bounding box
    [xWidth, yWidth] = calculateWidthDivision(azimuth, xRangeUM, yRangeUM);

    [widthPix, heightPix] = calculateBoundingBoxSize(ax);

    xContributionToWidth = xFractionToWidth * xWidth * widthPix;
    yContributionToWidth = yFractionToWidth * yWidth * widthPix;

    xInsidePix = xContributionToWidth + yContributionToWidth;
    
    % calculate the vertical position within the bounding box
    [xHeight, yHeight, zHeight] = calculateHeightDivision(azimuth, elevation, xRangeUM, yRangeUM, zRangeUM);

    xContributionToHeight = xFractionToHeight * xHeight * heightPix;
    yContributionToHeight = yFractionToHeight * yHeight * heightPix;

    zFractionToHeight = calculateZaxisContribution(zPosUM, zRangeUM, isUpsideDown);
    zContributionToHeight = zFractionToHeight * zHeight * heightPix;

    yInsidePix = xContributionToHeight + yContributionToHeight + zContributionToHeight;

    % sum all origin positions to get the absolute position in pixels
    [xParentPix, yParentPix] = calculateContainerOrigin(ax);
    [xOriginPix, yOriginPix] = calculateBoundingBoxOrigin(ax);

    xAbsolutePix = xParentPix + xOriginPix + xInsidePix;
    yAbsolutePix = yParentPix + yOriginPix + yInsidePix;

    positionPix = [xAbsolutePix, yAbsolutePix];

    % set(0,'PointerLocation',[xParentPix,yParentPix])
    % pause(0.3)

    % set(0, 'PointerLocation',[xParentPix+xOriginPix,yParentPix+yOriginPix])
    % pause(0.3)

    % set(0,'PointerLocation',[xAbsolutePix,yAbsolutePix])

    % assignin('base', 'ax', ax);
end


%% HELPER FUNCTIONS

function [azimuth, elevation, isUpsideDown] = calculateRotation(ax, xSign, ySign, zSign)
    sightVector = ax.CameraPosition - ax.CameraTarget;

    z = [0 0 1*zSign];
    elevation = acosd(dot(z, sightVector)/norm(sightVector));
    elevation = 90 - elevation;

    upVector = ax.CameraUpVector;
    isUpsideDown = false;

    if isequal(elevation, 90)
        % if the elevation is 90 or -90, the projection of sight to xy plane is zero
        azimuth = -atan2d(zSign*xSign*upVector(1), zSign*ySign*upVector(2));
    elseif isequal(elevation, -90)
        azimuth = -atan2d(-zSign*xSign*upVector(1), -zSign*ySign*upVector(2));
    else
        azimuth = -atan2d(-xSign*sightVector(1), -ySign*sightVector(2));

        if upVector(3) < 0
            azimuth = azimuth + 180;
            isUpsideDown = true;
        end
    end

    if zSign < 0
        azimuth = azimuth + 180;
    end
    
end


function [xSign, ySign, zSign] = getAxesDirection(ax)
    xSign = 1;
    if ax.XDir == "reverse"
        xSign = -1;
    end

    ySign = 1;
    if ax.YDir == "reverse"
        ySign = -1;
    end

    zSign = 1;
    if ax.ZDir == "reverse"
        zSign = -1;
    end
end


function [xPosUM, yPosUM, zPosUM] = getMicromPosition(ax, positionUM)
    % extract the x, y, and z position in micrometers

    if isempty(positionUM)
        % if the position is empty, use the current point instead - mainly for debugging
        positionUM = get(ax, 'currentpoint');
        positionUM = positionUM(1, 1:3);
    end

    xPosUM = positionUM(1);
    yPosUM = positionUM(2);
    zPosUM = positionUM(3);
end


function [xRangeUM, yRangeUM, zRangeUM] = getAxesRanges(ax)
    % get the ranges of the axes in micrometers
    xRangeUM = ax.XLim(2) - ax.XLim(1);
    yRangeUM = ax.YLim(2) - ax.YLim(1);
    zRangeUM = ax.ZLim(2) - ax.ZLim(1);
end



function [xParentPix, yParentPix] = calculateContainerOrigin(ax)
    % calculate starting pixel position of the axes container
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
end



function [widthPix, heightPix] = calculateBoundingBoxSize(ax)

    tightPos = ax.tightPosition;
    widthPix = tightPos(3);
    heightPix = tightPos(4);

end


function [xOriginPix, yOriginPix] = calculateBoundingBoxOrigin(ax)
    % calculate the origin of the bounding box in pixels

    tightPosition = ax.tightPosition;

    % TO OPTIMIZE - make sure this holds with different setup
    xOriginPix = tightPosition(1) - (ax.InnerPosition(1) - ax.OuterPosition(1));
    yOriginPix = tightPosition(2) - (ax.InnerPosition(2) - ax.OuterPosition(2));
end



function [xFractionToWidth, xFractionToHeight] = calculateXaxisContributions(azimuth, elevation, xSign, xPosUM, xRangeUM)

    % contribution of the world x axis to the x axis in 2D space
    xFractionToWidth = xSign*sign(cosd(azimuth))*xPosUM/xRangeUM;
    if xSign*sign(cosd(azimuth)) < 0
        xFractionToWidth = 1 + xFractionToWidth;
    end

    % contribution of the world x axis to the y axis in 2D space
    xFractionToHeight = xSign*sign(-sind(azimuth))*sign(sind(elevation))*xPosUM/xRangeUM;
    if xSign*sign(-sind(azimuth))*sign(sind(elevation)) < 0
        xFractionToHeight = 1 + xFractionToHeight;
    end
end


function [yFractionToWidth, yFractionToHeight] = calculateYaxisContributions(azimuth, elevation, ySign, yPosUM, yRangeUM)
    % reversed y - minus sign in sign(-sind(azimuth)) instead of plus
    % contribution of the world y axis to the x axis in 2D space

    yFractionToWidth = ySign*sign(sind(azimuth))*yPosUM/yRangeUM;
    if ySign*sign(sind(azimuth)) < 0
        yFractionToWidth = 1 + yFractionToWidth;
    end

    % reversed y - minus sign in sign(-cosd(azimuth)) instead of plus
    % contribution of the world y axis to the y axis in 2D space
    yFractionToHeight = ySign*sign(cosd(azimuth))*sign(sind(elevation))*yPosUM/yRangeUM;
    if ySign*sign(cosd(azimuth))*sign(sind(elevation)) < 0
        yFractionToHeight = 1 + yFractionToHeight;
    end   
end


function zFractionToHeight = calculateZaxisContribution(zPosUM, zRangeUM, isUpsideDown)
    % contribution of the world z axis to the y axis in 2D space
    zFractionToHeight = zPosUM/zRangeUM;

    if isUpsideDown
        zFractionToHeight = (zRangeUM - zPosUM)/zRangeUM;
    end
    
end


function [xWidth, yWidth] = calculateWidthDivision(azimuth, xRangeUM, yRangeUM)
    % calculating contribution of wold x and y axes to the 2D x axis

    cosSinSum = xRangeUM*abs(cosd(azimuth)) + yRangeUM*abs(sind(azimuth));

    xWidth = xRangeUM*abs(cosd(azimuth))/cosSinSum;
    yWidth = yRangeUM*abs(sind(azimuth))/cosSinSum;
end


function [xHeight, yHeight, zHeight] = calculateHeightDivision(azimuth, elevation, xRangeUM, yRangeUM, zRangeUM)

    % the relative contribution of xy is the opposite as to the width -> sin for x and cos for y 
    % the contribution of xy is determined by sin of elevation - 0 corresponds to no xy contribution
    xyRatio = abs(sind(elevation))*(xRangeUM*abs(sind(azimuth)) + yRangeUM*abs(cosd(azimuth)));
    % z contribution depends on cos of elevation - maximum contribution when elevation is 0
    zRatio = abs(cosd(elevation))*zRangeUM;

    % the relative contributions need to be divided by their sum
    elevationCosSinSum = xyRatio + zRatio;

    xyHeight = xyRatio/elevationCosSinSum;
    zHeight = zRatio/elevationCosSinSum;

    azimuthCosSinSum = xRangeUM*abs(sind(azimuth)) + yRangeUM*abs(cosd(azimuth));
    xHeight = xyHeight * xRangeUM * abs(sind(azimuth)) / azimuthCosSinSum;
    yHeight = xyHeight * yRangeUM * abs(cosd(azimuth)) / azimuthCosSinSum;
end

    

