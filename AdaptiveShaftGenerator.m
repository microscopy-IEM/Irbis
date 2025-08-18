classdef (Sealed) AdaptiveShaftGenerator

    properties
        ROIsize = 2 % um
        ROIdepth = 0.8 % um
        stepToROIsizeRatio = 0.4
        ROIstep % calculated as ROIdepth * stepToROIsizeRatio

        Iterations = 300
        ContractionBias = -0.5
        SmoothFactor = 1

        initialRadius

        radiusFactor = 1.3 % factor by which the radius is multiplied at the end
    
        endsBuffer = 30

        goParallel = true

        sizeIm = 100 % size of the image in which the contours are calculated
        realCenterDim

        structuringElementRadius = 2 % radius of the structuring element used in morphological operations

        verbose = false;
    end

    methods
        function obj = AdaptiveShaftGenerator(ROIsize, ROIdepth, stepToROIsizeRatio, Iterations, ContractionBias, SmoothFactor, initialRadius, radiusFactor, goParallel, verbose)
            % Constructor - stores all the user-defined parameters

            arguments
                ROIsize
                ROIdepth
                stepToROIsizeRatio
                Iterations
                ContractionBias
                SmoothFactor
                initialRadius
                radiusFactor
                goParallel
                verbose = false
            end

            obj.ROIsize = ROIsize;
            obj.ROIdepth = ROIdepth;
            obj.stepToROIsizeRatio = stepToROIsizeRatio;
            obj.ROIstep = ROIdepth * stepToROIsizeRatio;

            obj.Iterations = Iterations;
            obj.ContractionBias = ContractionBias;
            obj.SmoothFactor = SmoothFactor;

            obj.initialRadius = initialRadius;

            obj.radiusFactor = radiusFactor;

            obj.goParallel = goParallel;

            obj.realCenterDim = obj.ROIsize;

            obj.verbose = verbose;
        end


        function [middlePointsArray, contoursArray, radii] = run(obj, centreline, vertices)
            [A, B] = obj.calculatePointsOnCentreline(centreline);

            if obj.goParallel
                contours = obj.runInParallel(A, B, vertices);
            else
                contours = obj.runInSerial(A, B, vertices);
            end

            [middlePointsArray, contoursArray] = obj.processOutputArrays(A, contours);
            radii = obj.calculateRadii(middlePointsArray, contoursArray);
        end


        function contour = runForOnePosition(obj, ax, pointA, pointB, vertices)

            % ax.YDir = "normal"; % set Y direction to normal, so that the rotation is correct

            cuboidOrigin = obj.calculateCuboidOriginBeforeRotation(pointA, obj.ROIdepth, obj.ROIsize);
            rotationDegrees = obj.calculateCuboidRotation(pointA, pointB);

            % Display the rotated cuboid for visualization
            if obj.verbose
                figure;
                % ax = gca;
                hold(ax, 'on');
                
                % Define cuboid dimensions
                dims = [obj.ROIdepth obj.ROIsize obj.ROIsize];
                
                % Get cuboid vertices (corners) in local coordinates
                [x, y, z] = meshgrid([0 1], [0 1], [0 1]);
                vertices = [x(:) y(:) z(:)];
                vertices = vertices .* dims - dims/2;  % Scale and center at origin

                % Apply rotation
                rotXYZrad = deg2rad(rotationDegrees);
                cx = cos(rotXYZrad(1)); sx = sin(rotXYZrad(1));
                cy = cos(rotXYZrad(2)); sy = sin(rotXYZrad(2));
                cz = cos(rotXYZrad(3)); sz = sin(rotXYZrad(3));
                
                rotationMatrix = [  cy*cz,  -cy*sz,  sy ; ...
                                  sx*sy*cz + cx*sz,  -sx*sy*sz + cx*cz, -sx*cy ; ...
                                 -cx*sy*cz + sx*sz,   cx*sy*sz + sx*cz,  cx*cy ];

                % H = diag([-1 1 -1]);  % change this if your LH differs by flipping X or Y instead
                % rotationMatrix = H * rotationMatrix * H;
                
                rotatedVertices = vertices * rotationMatrix;
                
                % Translate to actual position
                rotatedVertices = rotatedVertices + cuboidOrigin + dims/2;
                
                % Define faces for patch
                faces = [1 2 4 3; 5 6 8 7; 1 2 6 5; 3 4 8 7; 1 3 7 5; 2 4 8 6];
                
                % Plot the cuboid
                patch(ax, 'Vertices', rotatedVertices, 'Faces', faces, ...
                      'FaceColor', 'c', 'FaceAlpha', 0.3, 'EdgeColor', 'b');
                
                % Plot the points A and B
                plot3(ax, pointA(1), pointA(2), pointA(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
                plot3(ax, pointB(1), pointB(2), pointB(3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
                
                % Draw a line from A to B
                line(ax, [pointA(1) pointB(1)], [pointA(2) pointB(2)], [pointA(3) pointB(3)], 'Color', 'k', 'LineWidth', 2);
                
                axis(ax, 'equal');
                grid(ax, 'on');
                xlabel(ax, 'X');
                ylabel(ax, 'Y');
                zlabel(ax, 'Z');
                title(ax, 'Rotated Cuboid with Points A and B');
                view(ax, 3);
                
                hold("off")
            end

            verticesInCuboid = obj.getVerticesInCuboid(obj.ROIdepth, obj.ROIsize, cuboidOrigin, rotationDegrees, vertices);

            size(verticesInCuboid)

            contour = obj.calculateContour(verticesInCuboid, pointA, pointB);
        end


        function contours = runInParallel(obj, A, B, vertices)
            % run in parallel
            nPos = size(A, 1);
            contours = cell(1, nPos);

            parfor i = 1:nPos
                pointA = A(i,:);
                pointB = B(i,:);

                cuboidOrigin = obj.calculateCuboidOriginBeforeRotation(pointA, obj.ROIdepth, obj.ROIsize);
                rotationDegrees = obj.calculateCuboidRotation(pointA, pointB);

                verticesInCuboid = obj.getVerticesInCuboid(obj.ROIdepth, obj.ROIsize, cuboidOrigin, rotationDegrees, vertices);

                contours{i} = obj.calculateContour(verticesInCuboid, pointA, pointB);
            end
        end


        function contours = runInSerial(obj, A, B, vertices)
            % run in serial
            nPos = size(A, 1);
            contours = cell(1, nPos);

            for i = 1:nPos
                % i
                pointA = A(i,:);
                pointB = B(i,:);

                cuboidOrigin = obj.calculateCuboidOriginBeforeRotation(pointA, obj.ROIdepth, obj.ROIsize);
                rotationDegrees = obj.calculateCuboidRotation(pointA, pointB);

                verticesInCuboid = obj.getVerticesInCuboid(obj.ROIdepth, obj.ROIsize, cuboidOrigin, rotationDegrees, vertices);

                contours{i} = obj.calculateContour(verticesInCuboid, pointA, pointB);
            end
        end


        function vertices = getVerticesInCuboid(obj, ROIdepth, ROIsize, cuboidOrigin, rotationDegrees, vertices)

            inside = obj.isInRotatedCuboid(vertices, cuboidOrigin, [ROIdepth ROIsize, ROIsize], rotationDegrees);
            vertices = vertices(inside, :);

        end


        function cuboidOrigin = calculateCuboidOriginBeforeRotation(~, pointA, ROIdepth, ROIsize)
            xmin = pointA(1)-ROIdepth/2;
            ymin = pointA(2)-ROIsize/2;
            zmin = pointA(3)-ROIsize/2;

            cuboidOrigin = [xmin, ymin, zmin]
        end


        function [A, B] = calculatePointsOnCentreline(obj, centreline)
            % get subset of points on centreline to calculate contours from

            % calculate mean distance between consecutive points in centre line
            % this is done so that we can calculate the factor by which we need to subsample the centreline
            distVect = sqrt(sum(abs(diff(centreline)).^2, 2));   % sum(_, 2) sums across columns (x^2 + y^2 + z^2)
            meanDist = mean(distVect);
            step = round(obj.ROIstep/meanDist);

            % endsBuffer excludes several points on the edges, that might be imprecise and turned away from the actual direction
            pos =(obj.endsBuffer+1):step:(size(centreline,1)-obj.endsBuffer);
            % preallocating A and B cells for speed

            displacement = 5;   % points A and B are taken displaced relative to the calculated position vector
            % I could also say that idxA = pos, but then there would be larger buffer needed for B on one side

            if ~(obj.endsBuffer > displacement)
                error('endsBuffer must be greater than displacement');
                % otherwise, this would lead to out-of-bounds indexing
            end
            idxA = pos - displacement;                    % all row indices for A
            idxB = pos + displacement;                    % all row indices for B

            A = centreline(idxA , :);
            B = centreline(idxB , :);
        end


        function rotationDegrees = calculateCuboidRotation(~, pointA, pointB)
            normV = (pointB-pointA)/norm(pointB-pointA);

            vX = [1,0,0];

            % rotation around z:
            normVZ = [normV(1),normV(2),0];
            cosThetaZ = dot(vX,normVZ)/(norm(vX)*norm(normVZ));
            crossProductZ = cross(vX,normVZ);
            thetaZ = sign(crossProductZ(3))*acos(cosThetaZ);   

            % rotation around y:

            normVY= [norm([normV(1),normV(2)]),0,normV(3)];
            cosThetaY = dot(vX,normVY)/(norm(vX)*norm(normVY));
            crossProductY = cross(vX,normVY);
            thetaY = sign(crossProductY(2))*acos(cosThetaY);  

            rotationDegrees = [0,rad2deg(thetaY),rad2deg(thetaZ)]
        end


        function inside = isInRotatedCuboid(~, origPointsPositions, pos, dims, rotXYZdeg)
            % check whether each point lies within a cuboid specified by its origin position, size and rotation

            % origPointsPositions         N×3 [x y z] point cloud  (double | single)
            % pos       [xmin ymin zmin]         (origin corner BEFORE rotation)
            % dims      [dx dy dz]               (edge lengths ≥ 0)
            % rotXYZdeg [θx θy θz]   degrees     (roll, pitch, yaw —  Euler XYZ)

            % 1. translate points to the centre
            centre = pos + dims/2;          % world-space centre of the cuboid
            pointsPos = origPointsPositions - centre;                 % shift all vertices so cuboid is centred

            % 2. rotate points to get correct orientation relative to the cuboid
            rotXYZrad = deg2rad(rotXYZdeg);
            cx = cos(rotXYZrad(1)); 
            sx = sin(rotXYZrad(1));     % Rx(θx)
            cy = cos(rotXYZrad(2)); 
            sy = sin(rotXYZrad(2));     % Ry(θy)
            cz = cos(rotXYZrad(3)); 
            sz = sin(rotXYZrad(3));     % Rz(θz)

            % Forward rotation  R = Rz * Ry * Rx   (XYZ Euler convention)
            rotationMatrix = [  cy*cz,  -cy*sz,  sy ; ...
                sx*sy*cz + cx*sz,  -sx*sy*sz + cx*cz, -sx*cy ; ...
                -cx*sy*cz + sx*sz,   cx*sy*sz + sx*cz,  cx*cy ];

            pointsPos = pointsPos * rotationMatrix.';   % inverse = transpose (rotationMatrix orthonormal)

            % 3. test which of the points are within the cuboid
            h = dims/2 + eps;          % half-sizes (+eps ⇢ include surface)
            inside =  abs(pointsPos(:,1)) <= h(1) ...
                    & abs(pointsPos(:,2)) <= h(2) ...
                    & abs(pointsPos(:,3)) <= h(3);
        end


        function contours = calculateContour(obj, verticesInCuboid, pointA, pointB)
            % calculate contour from vertices in cuboid
            if isempty(verticesInCuboid)
                contours = [];
                return;
            end

            % new way of calculating contours
            contours = obj.calculateContourMorphologically(verticesInCuboid, pointA, pointB);

            % old way - using active contours
            % contours = IS_active_contour(pointA, pointB, verticesInCuboid,'RadiusScaling',obj.radiusFactor, ...
            % 'Iterations',obj.Iterations,'ContractionBias',obj.ContractionBias, ...
            % 'SmoothFactor',obj.SmoothFactor,'sizeIm',obj.sizeIm,'realCenterDim',obj.realCenterDim,'initialRadius',obj.initialRadius);
        end


        function radii = calculateRadii(~, middlePoints, contours)
            % calculate mean radius of the shaft (moved from adjust fnc)
            unq = unique(middlePoints(:,1));    % why?
            middlePointsIdx = 1:length(unq);

            % middlePointsIdx = 1:length(middlePoints(:,1));

            % calculate mean radius of the current shaft
            % radii = [];
            radii = zeros(numel(2:5:max(middlePointsIdx-5)),1);
            radiusId = 1;
            for r=2:5:max(middlePointsIdx-5)
                Idx = find(middlePoints(:,1) == unq(r),1);

                [~,radius] = knnsearch(middlePoints(Idx,:),contours(Idx,:));

                % radii = [radii;radius(1)];
                radii(radiusId) = radius(1);
                radiusId = radiusId + 1;
            end
        end

        function [middlePointsArray, contoursArray] = processOutputArrays(~, middlePoints, contours)
            % Throw away empty contours and corresponding middle points
            nonEmptyIndices = ~cellfun('isempty', contours);
            contours = contours(nonEmptyIndices);
            middlePoints = middlePoints(nonEmptyIndices, :);
            
            % Convert to n x 3 arrays
            contoursArray = vertcat(contours{:});

            tempCellStructure = cell(1, numel(contours));
            % Process each cell in the contours and middlePoints
            for i = 1:numel(contours)
                % Get the number of rows in the current contour
                numRows = size(contours{i}, 1);
                
                % Repeat the current middle point row numRows times
                repeatedPoints = repmat(middlePoints(i,:), numRows, 1);
                
                tempCellStructure{i} = repeatedPoints;
            end

            % Concatenate all repeated middle points into a single array
            middlePointsArray = vertcat(tempCellStructure{:});
        end


        function result = calculateContourMorphologically(obj, pointsInROI, pointA, pointB)

            if obj.verbose
                figure
                scatter3(pointsInROI(:,1), pointsInROI(:,2), pointsInROI(:,3), 10, 'filled');
            end

            obj.sizeIm = obj.sizeIm;
            obj.realCenterDim = obj.realCenterDim;
            radiusScaling = obj.radiusFactor;

            % predefined lists:
            pointsRescaled = [];
            contourRescaled = [];

            NormalVector = (pointB-pointA)/norm(pointB-pointA);
            % BA is the normal vector obtained from the central line direction

            ProjVector = [0,1,0];
            % currently, the points are rotated and projected into the xz plane
            % subsequently, they are transformed into the binary image

            % parameters describing the rotation into the plane:
            cosTheta = dot(ProjVector,NormalVector)/(norm(ProjVector)*norm(NormalVector));
            sinTheta = norm(cross(ProjVector,NormalVector))/(norm(ProjVector)*norm(NormalVector));

            C = cross(ProjVector,NormalVector);
            u1 = C(1)/norm(C);
            u2 = C(2)/norm(C);
            u3 = C(3)/norm(C);

            R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
                u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
                u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];

            % using matrix operations to perform the rotation instead
            v = pointsInROI - pointA;
            pointsRotated = v * R;

            if isempty(pointsRotated)
                result = [];
                return
            end

            % projecting the point cloud onto a plane and rescaling the dimensions:
            pointsRescaled(:,1) = (pointsRotated(:,1))*obj.sizeIm/obj.realCenterDim + obj.sizeIm/2;
            pointsRescaled(:,2) = 0;
            pointsRescaled(:,3) = (pointsRotated(:,3))*obj.sizeIm/obj.realCenterDim + obj.sizeIm/2;

            % transforming the projected and rescaled points into a binary image:
            binaryImage = zeros(obj.sizeIm,obj.sizeIm);

            for i=1:size(pointsRescaled,1)

                xR = pointsRescaled(i,1);
                yR = pointsRescaled(i,3);
                if xR >= 1 && xR <= obj.sizeIm && yR >= 1 && yR <= obj.sizeIm
                    binaryImage(round(yR),round(xR)) = 255;
                end
            end

            if obj.verbose
                figure
                imshow(binaryImage, []);
                title('Binary Image after Projection');
            end

            binaryImage = imgaussfilt(binaryImage,2);
            binaryImage(binaryImage>5) = 255;

            % assignin("base", "binaryImage", binaryImage)


            % % Adjust the mask: remove areas with positive values in binaryImage
            %     % this should avoid expansion to the white areas and formation of bubbles and bulges
            % mask(binaryImage > 0) = 0;

            % % if the centre found by the centre line is off, return an empty contour
            % if all(mask(:) == 0)
            %     result = [];
            %     return
            % end


            simpCont = obj.doRollingBall(binaryImage);

            if isempty(simpCont)
                result = [];
                return;
            end

            % rescaling contour back into the um within the plane:
            contourRescaled(:,1) = ((simpCont(:,1)-obj.sizeIm/2)*(obj.realCenterDim)/obj.sizeIm)*radiusScaling;
            contourRescaled(:,2) = zeros(size(simpCont,1),1);
            contourRescaled(:,3) = ((simpCont(:,2)-obj.sizeIm/2)*(obj.realCenterDim)/obj.sizeIm)*radiusScaling;

            R_inv = R';

            % perform back-rotation by matrix operation instead
            contourFinal = contourRescaled * R_inv;
            contourFinal = contourFinal + pointA;

            result = contourFinal(:,:);
        end


        function outlineCoordinates = doRollingBall(obj, binaryImage)
            Igray = binaryImage;
            Ibin   = imbinarize(Igray);              % white = background, black = object
            Ibin   = imcomplement(Ibin);             % make the black region == 1 (logical)

            if obj.verbose
                figure
                imshow(Ibin, []);
                title('Binary Image');
            end

            %% --- 2½.  Keep only the most-central black blob -------------------------
            CC     = bwconncomp(Ibin);                         % find all foreground blobs
            if isempty(CC)
                disp('No blobs found in the image');
                outlineCoordinates = [];
                return;
            end
            stats  = regionprops(CC, 'Centroid', 'PixelIdxList', 'BoundingBox');  % get their centroids, pixel indices and bounding boxes

            % Sometimes, when there was a black area at the edges, its centroid was close to centre -> choosen instead of the central blob
            imgSz  = size(Ibin);                      % [rows  cols]
            keep   = false(numel(stats),1);            % pre-allocate logical mask

            for k = 1:numel(stats)
                % disp(['k: ', num2str(k)])
                bb   = stats(k).BoundingBox;          % [xmin ymin width height] (0-based)
                xmin = bb(1);                      % convert to 1-based pixel coords
                ymin = bb(2);
                xmax = xmin + bb(3);
                ymax = ymin + bb(4);

                % ----- which borders does this blob touch? ---------------------------
                touchesLeft   =  xmin <= 1;
                touchesRight  =  xmax >= imgSz(2);
                touchesTop    =  ymin <= 1;
                touchesBottom =  ymax >= imgSz(1);

                nTouched      = touchesLeft + touchesRight + touchesTop + touchesBottom;

                keep(k)       = (nTouched <= 2);       % accept 0, 1 or 2 borders touched
            end

            stats = stats(keep);                       % throw away 3- & 4-side blobs

            % image centre = (rows/2 , cols/2)
            ctrImg = fliplr(size(Ibin))/2;                     % [x y] order for vecnorm
            % disp('first')
            % size(cat(1,stats.Centroid))
            % disp('second')
            % size(ctrImg)
            
            % Check if stats is empty after filtering
            if isempty(stats)
                % figure
                % imshow(Ibin,[])
                disp('No valid blobs remained after filtering');
                outlineCoordinates = [];
                return;
            end
            
            d      = vecnorm(cat(1,stats.Centroid) - ctrImg, 2, 2);  % Euclidean distance
            [~,ix] = min(d);                                   % index of the closest blob

            Icentral = false(size(Ibin));
            Icentral(stats(ix).PixelIdxList) = true;           % retain only that blob
            % -------------------------------------------------------------------------
            %% --- 3. “Rolling-ball” smoothing  ---------------------------------------
            R      = obj.structuringElementRadius;                             % <-- ball radius in pixels
            se     = strel('disk', R, 0);            % 0 = flat (exact morphology)

            % From here on, use Icentral instead of Ibin
            Iopened   = imopen(Icentral, se);
            Ismoothed = imclose(Iopened, se);

            % Iclosed   = imclose(Icentral, se);
            % Ismoothed = imopen(Iclosed, se);
            % size(Ismoothed)

            %% --- 4. Extract the outline ---------------------------------------------
            B = bwboundaries(Ismoothed);               % cell array of [row col] coords
            if isempty(B)
                disp('No boundaries found in the smoothed image');
                outlineCoordinates = [];
                return;
            end
            px = B{1}(:,2);  py = B{1}(:,1);         % x = columns, y = rows
            outlineCoordinates = [B{1}(:,2), B{1}(:,1)];  % [x y] order for vecnorm
            % Keep only every second point in the outline
            outlineCoordinates = outlineCoordinates(1:4:end, :);
            % size(outlineCoordinates)

            assignin('base', 'outlineCoordinates', outlineCoordinates)
            % figure, imshow(Ismoothed,[])

            % Check if outline touches the edge of the image
            imSize = size(Ismoothed);
            touchesEdge = any(px == 1 | px == imSize(2) | py == 1 | py == imSize(1));

            if touchesEdge
                disp('Warning: Outline touches the edge of the image');
                % figure, imshow(Ismoothed,[])
                % figure, imshow(Igray,[]), hold on
                % plot(px, py, 'r', 'LineWidth', 3)      % smoothed contour
                % title(sprintf('Rolling-ball outline (R = %d px)', R));
                % hold off
            end


        end

    end




    methods (Static)

        function mesh = generateMesh(contourPoints, middlePoints, smoothingFactor)
            contourPointNormals = AdaptiveShaftGenerator.calculateNormals(contourPoints, middlePoints);

            % assignin('base', 'contourPointNormals', contourPointNormals);
            % unique without anything sorts the values in ascending order
                % this can cause problems as the first point might not have the lowest value
                % to fix this, 'stable' is used - prevents sorting
            [~,~,middlePointsIdx] = unique(middlePoints(:,1),'stable');

            % assignin('base', 'contourPoints', contourPoints);
            % assignin('base', 'contourPointNormals', contourPointNormals);
            % add start plug
            idx = 1;
            [startPlugPoints, startPlugPointNormals] = AdaptiveShaftGenerator.addPlug(contourPoints, contourPointNormals, middlePoints, middlePointsIdx, idx);

            % add end plug
            idx = max(middlePointsIdx);
            [endPlugPoints, endPlugPointNormals] = AdaptiveShaftGenerator.addPlug(contourPoints, contourPointNormals, middlePoints, middlePointsIdx, idx);

            contourPoints = [startPlugPoints; contourPoints; endPlugPoints];
            contourPointNormals = [startPlugPointNormals; contourPointNormals; endPlugPointNormals];

            assignin('base', 'contourPoints', contourPoints);
            assignin('base', 'contourPointNormals', contourPointNormals);

            mesh = AdaptiveShaftGenerator.reconstructMesh(contourPoints, contourPointNormals);
            mesh = AdaptiveShaftGenerator.smoothMesh(mesh, smoothingFactor);
        end


        function mesh = generateScaledMesh(contourPoints, middlePoints, selectedRadius, meanRadius, smoothingFactor)
            contourPointNormals = AdaptiveShaftGenerator.calculateNormals(contourPoints, middlePoints);
            contourPoints = AdaptiveShaftGenerator.changeRadius(contourPoints, contourPointNormals, selectedRadius, meanRadius);

            [~,~,middlePointsIdx] = unique(middlePoints(:,1),'stable');
            % add start plug
            idx = 1;
            [startPlugPoints, startPlugPointNormals] = AdaptiveShaftGenerator.addPlug(contourPoints, contourPointNormals, middlePoints, middlePointsIdx, idx);

            % add end plug
            idx = max(middlePointsIdx);
            [endPlugPoints, endPlugPointNormals] = AdaptiveShaftGenerator.addPlug(contourPoints, contourPointNormals, middlePoints, middlePointsIdx, idx);

            contourPoints = [startPlugPoints; contourPoints; endPlugPoints];
            contourPointNormals = [startPlugPointNormals; contourPointNormals; endPlugPointNormals];

            mesh = AdaptiveShaftGenerator.reconstructMesh(contourPoints, contourPointNormals);
            mesh = AdaptiveShaftGenerator.smoothMesh(mesh, smoothingFactor); 
        end


        function contourPointNormals = calculateNormals(contourPoints, middlePoints)

            % Calculate direction vectors from center points to contour points
            directionVectors = contourPoints - middlePoints;
            
            % Normalize all vectors at once (row-wise)
            magnitudes = sqrt(sum(directionVectors.^2, 2));
            contourPointNormals = directionVectors ./ magnitudes(:, ones(1, 3));
        end


        function contourPoints = changeRadius(contourPoints, contourPointNormals, selectedRadius, meanRadius)

            % calculate proportion to enlarge or shring the shaft
            k = selectedRadius-meanRadius;
        
            contourPoints = contourPoints + contourPointNormals.*k;
        end


        function [plugPoints, plugPointNormals] = addPlug(contourPoints, contourPointNormals, middlePoints, middlePointsIdx, idx)
            contourIdx = middlePointsIdx == idx;

            selectedContourPoints = contourPoints(contourIdx,:);
            selectedContourPointNormals = contourPointNormals(contourIdx,:);

            selectedMiddlePointIdx = find(middlePointsIdx == idx, 1);
            middlePoint = middlePoints(selectedMiddlePointIdx,:);

            % calculate radiuses between middle point of contour and points of the contour
            radiuses = pdist2(middlePoint,selectedContourPoints);

            innerRing1 = selectedContourPoints - selectedContourPointNormals.*radiuses'.*0.6;
            innerRing2 = selectedContourPoints - selectedContourPointNormals.*radiuses'.*0.3;

            plugPoints = [middlePoint; innerRing2; innerRing1];

            if idx == max(middlePointsIdx)
                pointBidx = find(middlePointsIdx == (max(middlePointsIdx)-1),1);
            elseif idx == 1
                pointBidx = find(middlePointsIdx == 2,1);
            end
            pointB = middlePoints(pointBidx,:);
            plugNormal = (middlePoint-pointB)/norm(middlePoint-pointB);

            plugPointNormals = repmat(plugNormal,size(plugPoints,1),1);
        end


        function mesh = reconstructMesh(vertices, normals)
            % prepare points as input to Python
            verticesNumpy = py.numpy.array(vertices);
            % prepare normals as input to Python
            normalsNumpy = py.numpy.array(normals);

            % generate mesh by Poisson surface reconstruction
            depth = 9;
            % Initialize the struct with vertices and vertex normals
            mesh_data{1} = struct('vertices', verticesNumpy, ...
                                    'vertexNormals', normalsNumpy);

            [nObjects, meshCell, ~] = reconstruct_mesh_python(depth,mesh_data,0);

            mesh = meshCell{1};
            if nObjects > 1
                disp('there is something wrong - more than one shaft is produced')
            end
        end
        

        function mesh = smoothMesh(mesh, smoothingFactor)
            if smoothingFactor > 0
                mesh = smoothSurfaceMesh(mesh, smoothingFactor);
            end
        end

    end
end