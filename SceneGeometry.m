classdef (Sealed) SceneGeometry
    properties
    end

    methods (Static)
        function positionPix = convertMicromToPixelPosition(positionUM, ax)

            % clc
            % Assumptions: 
            %   - We manually change the position of the camera position and target, and CameraViewAngle
            %   - CameraUpVector automatically adjusts to the other parameters
            %   - DataAspectRatio of axes is set to [1 1 1], PlotBoxAspectRatio corresponds to the axes aspect ratio
            %   - positionUM is in the same units (micrometers in our case) as the 3D system of the axes

            % get information about axes organization and rotation
            [xSign, ySign, ~] = SceneGeometry.getAxesDirection(ax);

            [azimuth, elevation, isUpsideDown] = SceneGeometry.calculateRotation(ax);
            % disp(ax.View)

            [xPosUM, yPosUM, zPosUM] = SceneGeometry.getMicromPosition(ax, positionUM);
            [xRangeUM, yRangeUM, zRangeUM] = SceneGeometry.getAxesRanges(ax);

            [xFractionToWidth, xFractionToHeight] = SceneGeometry.calculateXaxisContributions(azimuth, elevation, xSign, xPosUM, xRangeUM);
            [yFractionToWidth, yFractionToHeight] = SceneGeometry.calculateYaxisContributions(azimuth, elevation, ySign, yPosUM, yRangeUM);

            % calculate the horizontal position within the bounding box
            [xWidth, yWidth] = SceneGeometry.calculateWidthDivision(azimuth, xRangeUM, yRangeUM);

            [widthPix, heightPix] = SceneGeometry.calculateBoundingBoxSize(ax);

            xContributionToWidth = xFractionToWidth * xWidth * widthPix;
            yContributionToWidth = yFractionToWidth * yWidth * widthPix;

            xInsidePix = xContributionToWidth + yContributionToWidth;
            
            % calculate the vertical position within the bounding box
            [xHeight, yHeight, zHeight] = SceneGeometry.calculateHeightDivision(azimuth, elevation, xRangeUM, yRangeUM, zRangeUM);

            xContributionToHeight = xFractionToHeight * xHeight * heightPix;
            yContributionToHeight = yFractionToHeight * yHeight * heightPix;

            zFractionToHeight = SceneGeometry.calculateZaxisContribution(zPosUM, zRangeUM, isUpsideDown);
            zContributionToHeight = zFractionToHeight * zHeight * heightPix;

            yInsidePix = xContributionToHeight + yContributionToHeight + zContributionToHeight;

            % sum all origin positions to get the absolute position in pixels
            [xParentPix, yParentPix] = SceneGeometry.calculateContainerOrigin(ax);
            [xOriginPix, yOriginPix] = SceneGeometry.calculateBoundingBoxOrigin(ax);

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



        function coordinates = calculatePanelWorldCoord(ax, panel)
            % returns 2 x 4 x 3 array, where rows correspond to top x bottom, each column is one panel corner and the third dimension is the coordinate (x, y, z)
            if isequal(nargin, 1)
                panel = ax.Parent;
            end

            panelSize = panel.Position(3:4);
            tightPos = ax.tightPosition;
            axSize = tightPos(3:4);
            axOrigin = tightPos(1:2);

            panelOriginRelative = -axOrigin ./ axSize;
            panelEndRelative = (-axOrigin + panelSize) ./ axSize;

            % Corner list using the two given values and the two "complemented" combos
            xO = panelOriginRelative(1);
            yO = panelOriginRelative(2);
            xE = panelEndRelative(1);   
            yE = panelEndRelative(2);

            XY = [xO, yO;   % k=1
                xE, yO;   % k=2
                xE, yE;   % k=3
                xO, yE ]; % k=4

            [~, elevation, ~] = SceneGeometry.calculateRotation(ax);
            if abs(elevation) > 0.5
                coordinates = zeros(2, 4, 3);
                for k = 1:4
                    % bottom (zWorldFraction = 0)
                    zWorldFraction = 0;
                    [x,y,z]    = SceneGeometry.convertRelativePositionToMicrom(ax, XY(k,1), XY(k,2), zWorldFraction);
                    coordinates(1,k,:) = [x y z];

                    % top (zWorldFraction = 1)
                    zWorldFraction = 1;
                    [x,y,z]    = SceneGeometry.convertRelativePositionToMicrom(ax, XY(k,1), XY(k,2), zWorldFraction);
                    coordinates(2,k,:) = [x y z];
                end
            else 
                coordinates = [];
            end
        end



        function [xPosUM, yPosUM, zPosUM] = convertRelativePositionToMicrom(ax, widthFraction, heightFraction, zWorldFraction)
            % Known inputs: widthFraction, heightFraction, xWidth, yWidth, xHeight, yHeight,
            %               xSign, ySign, azimuth, elevation, xRangeUM, yRangeUM, zHeight, isUpsideDown

            % zWorldfraction can be between 0 and 1

            [azimuth, elevation, isUpsideDown] = SceneGeometry.calculateRotation(ax);
            [xRangeUM, yRangeUM, zRangeUM] = SceneGeometry.getAxesRanges(ax);
            % for now, I am counting with all the axes starting with 0 - if not, I would need to add ax.Lim(1)
            [xWidth, yWidth] = SceneGeometry.calculateWidthDivision(azimuth, xRangeUM, yRangeUM);
            [xHeight, yHeight, zHeight] = SceneGeometry.calculateHeightDivision(azimuth, elevation, xRangeUM, yRangeUM, zRangeUM);


            zFrac  = zWorldFraction;
            if isUpsideDown
                zFrac = 1 - zWorldFraction;
            end
            heightFractionEff = heightFraction - zHeight * zFrac;

            % --- sign coefficients (same as before) ---
            [xSign, ySign, ~] = SceneGeometry.getAxesDirection(ax);
            axw = xSign * sign(cosd(azimuth));
            axh = xSign * sign(-sind(azimuth)) * sign(sind(elevation));
            ayw = ySign * sign(sind(azimuth));
            ayh = ySign * sign(cosd(azimuth)) * sign(sind(elevation));

            bxw = double(axw < 0);
            bxh = double(axh < 0);
            byw = double(ayw < 0);
            byh = double(ayh < 0);

            % --- 2x2 system for X and Y (Z already accounted for) ---
            A = [xWidth*axw,  yWidth*ayw;
                xHeight*axh, yHeight*ayh];

            rhs = [widthFraction  - xWidth*bxw  - yWidth*byw;
                heightFractionEff - xHeight*bxh - yHeight*byh];

            sol = A \ rhs;          % or pinv(A)*rhs for robustness
            X = sol(1);  Y = sol(2);

            xPosUM = X * xRangeUM;
            yPosUM = Y * yRangeUM;
            zPosUM = zWorldFraction * zRangeUM;
        end



        function pixelWidth = calculatePixelWidth(ax)
            % calculate the pixel width of the axes
            tightPos = ax.tightPosition; % tight position of the axes
            widthPix = tightPos(3);
            [azimuth, ~, ~] = SceneGeometry.calculateRotation(ax);
            widthUM = ax.XLim(2) * abs(cosd(azimuth)) + ax.YLim(2) * abs(sind(azimuth));

            pixelWidth = widthUM / widthPix;
        end


        function fitAxesToPanel(panel, ax, adjustRatio)
            panelPos = panel.Position;

            axPos = ax.Position;
            axTightPos = ax.tightPosition;
            if nargin > 2 && adjustRatio 
                % for now, we just want to adjust width and height to the same value
                % having the same width and height seems to lead to the least mismatch in CameraViewAngle
                xTightRatio = axTightPos(3) / panelPos(3);
                yTightRatio = axTightPos(4) / panelPos(4);
                [axToPanelRatio, scaledDim] = max([xTightRatio, yTightRatio]);
            else
                xRatio = axPos(3) / panelPos(3);
                yRatio = axPos(4) / panelPos(4);
                axToPanelRatio = max(xRatio, yRatio);
            end

            if nargin > 2 && adjustRatio
                width = 0.8 * axPos(scaledDim + 2) / axToPanelRatio;
                height = 0.8 * axPos(scaledDim + 2) / axToPanelRatio;
            else
                % this preserves the existing ratio of width and height
                width = 0.8 * axPos(3) / axToPanelRatio;
                height = 0.8 * axPos(4) / axToPanelRatio;
            end

            xPos = (panelPos(3) - width) / 2;
            yPos = (panelPos(4) - height) / 2;

            ax.Position = [xPos yPos width height];
        end



        function cameraViewAngle = calculateCameraViewAngleFor(ax, widthRatio)

            [xRange, yRange, ~] = SceneGeometry.getAxesRanges(ax);
            [azimuth, ~, ~] = SceneGeometry.calculateRotation(ax);
            widthUM = xRange * abs(cosd(azimuth)) + yRange * abs(sind(azimuth));
            realWidthUM = widthUM * widthRatio;

            sightVector = (ax.CameraPosition - ax.CameraTarget)./ax.DataAspectRatio;
            sightVectorLen = norm(sightVector);

            alpha = atand(realWidthUM/(2*sightVectorLen));
            
            cameraViewAngle = 2*atand(ax.InnerPosition(4)*sind(alpha)/(ax.InnerPosition(3)));
        end


        %% HELPER FUNCTIONS

        function [azimuth, elevation, isUpsideDown] = calculateRotation(ax)
            [xSign, ySign, zSign] = SceneGeometry.getAxesDirection(ax);

            sightVector = ax.CameraPosition - ax.CameraTarget;

            z = [0 0 1*zSign];
            cosTheta = dot(z, sightVector)/(norm(sightVector)*norm(z));
            cosTheta = max(-1, min(1, cosTheta)); % clamp to [-1, 1] to avoid NaN from roundoff
            elevation = acosd(cosTheta);
            elevation = 90 - elevation;

            upVector = ax.CameraUpVector;
            isUpsideDown = false;
            
            tol = 1e-6; % tolerance for floating-point comparison
            if abs(elevation - 90) < tol
                % if the elevation is 90 or -90, the projection of sight to xy plane is zero
                azimuth = -atan2d(zSign*xSign*upVector(1), zSign*ySign*upVector(2));
            elseif abs(elevation + 90) < tol
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
    end
end