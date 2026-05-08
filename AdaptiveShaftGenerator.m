classdef (Sealed) AdaptiveShaftGenerator

    properties
        endsBuffer = 30

        sizeIm = 100 % size of the image in which the contours are calculated
        realCenterDim

        ringSpacingPix = 20 % spacing between points of centreline used for generating mesh slices, in points of the centreline
        nRingNeighbors = 2 % number of slices on each side to add to the current slice to generate one contour (2 means that 1+2+2 = 5 will be combined)

        doMorphologicalPostprocessing = false % whether to apply morphological opening and closing to the binary image before extracting the contour
        structuringElementRadius = 2 % radius of the structuring element used in morphological operations

        verbose = false;
    end

    methods
        function obj = AdaptiveShaftGenerator(contourSpacingPix, nNeighbors, doMorphologicalPostprocessing, structuringElementRadius)
            % Constructor - stores all the user-defined parameters

            arguments
                contourSpacingPix (1,1) {mustBePositive} = 20
                nNeighbors (1,1) {mustBeNonnegative} = 2
                doMorphologicalPostprocessing (1,1) {mustBeNumericOrLogical} = false
                structuringElementRadius (1,1) {mustBePositive} = 2
             end

            obj.ringSpacingPix = contourSpacingPix;
            obj.nRingNeighbors = nNeighbors;
            obj.doMorphologicalPostprocessing = doMorphologicalPostprocessing;
            obj.structuringElementRadius = structuringElementRadius;
        end


        function [middlePointsArray, contoursArray, radii] = run(obj, centreline, mesh)
            [contours, A, B] = obj.runInPython(centreline, mesh);

            contours = obj.addMissingContours(A, B, contours);
            [middlePointsArray, contoursArray] = obj.processOutputArrays(A, contours);
            radii = obj.calculateRadii(middlePointsArray, contoursArray);
        end


        function contour = runForOnePosition(obj, centreline, mesh, position)
            [contours, ~, ~] = obj.runSingleInPython(centreline, mesh, position);

            disp(size(contours))

            contour = contours{1}; % there should be only one contour as the position is specified
        end


        function [contours, A, B] = runInPython(obj, centreline, mesh)
            centrelinePy = py.numpy.array(centreline);
            verticesPy = py.numpy.array(mesh.Vertices);
            facesPy = py.numpy.array(mesh.Faces - 1); % adjust for Python 0-based indexing

            parameters = struct("buffer", obj.endsBuffer, ...
                "spacing", obj.ringSpacingPix, ...
                "ahead_index", 5, ...
                "grid_size", 100, ...
                "min_val", -1.0, ...
                "max_val", 1.0, ...
                "n_neighbors", obj.nRingNeighbors, ...
                "do_morphological_processing", obj.doMorphologicalPostprocessing, ...
                "disk_radius", obj.structuringElementRadius);
            
            [contoursPy, pointsPy, normalsPy] = pyrunfile("generate_outlines_from_mesh_slices_py_script.py", ["contours_3d", "points", "normals"], ...
            vertices=verticesPy, faces=facesPy, centerline=centrelinePy, matlab_params=parameters);

            contoursPy = cell(contoursPy);
            contours = cell(size(contoursPy));
            for i = 1:numel(contoursPy) 
                if py.isinstance(contoursPy{i}, py.type(py.None))
                    contours{i} = [];
                else
                    contours{i} = double(contoursPy{i});
                end
            end

            A = double(pointsPy);
            B = double(normalsPy);
        end


        function [contours, A, B] = runSingleInPython(obj, centreline, mesh, position)
            centrelinePy = py.numpy.array(centreline);
            verticesPy = py.numpy.array(mesh.Vertices);
            facesPy = py.numpy.array(mesh.Faces - 1); % adjust for Python 0-based indexing

            parameters = struct("buffer", obj.endsBuffer, ...
                "spacing", obj.ringSpacingPix, ...
                "ahead_index", 5, ...
                "grid_size", 100, ...
                "min_val", -1.0, ...
                "max_val", 1.0, ...
                "n_neighbors", obj.nRingNeighbors, ...
                "do_morphological_processing", obj.doMorphologicalPostprocessing, ...
                "disk_radius", obj.structuringElementRadius);
            
            [contoursPy, pointsPy, normalsPy] = pyrunfile("generate_outlines_from_mesh_slices_py_script.py", ["contours_3d", "points", "normals"], ...
            vertices=verticesPy, faces=facesPy, centerline=centrelinePy, matlab_params=parameters, test_point=position);

            contoursPy = cell(contoursPy);
            contours = cell(size(contoursPy));
            for i = 1:numel(contoursPy) 
                if py.isinstance(contoursPy{i}, py.type(py.None))
                    contours{i} = [];
                else
                    contours{i} = double(contoursPy{i});
                end
            end

            A = double(pointsPy);
            B = double(normalsPy);
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

                % compute distances from middle point to all contour points at this slice
                contourAtSlice = contours(Idx,:);
                middlePointAtSlice = middlePoints(Idx,:);
                if ~isempty(contourAtSlice) && ~isempty(middlePointAtSlice)
                    distances = pdist2(middlePointAtSlice, contourAtSlice);
                    radii(radiusId) = mean(distances);
                else
                    radii(radiusId) = NaN;
                end
                radiusId = radiusId + 1;
            end
        end


        function contours = addMissingContours(~, A, B, contours)
            % Substitute missing contours with translated and rotated closest contour
            % TO OPTIMIZE: instead of just translating the contour from another place, also adjust its shape

            % For each missing contour, find the closest non-missing contour
            nonEmptyIndices = find(~cellfun('isempty', contours));  % find returns indices of all non-zero elements
            emptyIndices = find(cellfun('isempty', contours));
            disp('empty contours:')
            disp(numel(emptyIndices))

            % for each empty contour, find the index of the closest non-empty contour
            % in case of two contours being equally close, the one with smaller index is chosen implicitly
            closestIndices = zeros(size(emptyIndices));
            for iEmpty = 1:numel(emptyIndices)
                emptyIdx = emptyIndices(iEmpty);
                [~, iValid] = min(abs(nonEmptyIndices - emptyIdx));
                closestIndices(iEmpty) = nonEmptyIndices(iValid);
            end

            % For each of the missing contours, take the closest, rotate and translate it and save it into the cell array
            for iEmpty = 1:numel(emptyIndices)
                AEmpty = A(emptyIndices(iEmpty), :);
                BEmpty = B(emptyIndices(iEmpty), :);
                NormalVectorEmpty = (BEmpty - AEmpty)/norm(BEmpty - AEmpty);

                AClosest = A(closestIndices(iEmpty), :);
                BClosest = B(closestIndices(iEmpty), :);
                NormalVectorClosest = (BClosest - AClosest)/norm(BClosest - AClosest);

                % Calculate rotation matrix from closest to empty
                cosTheta = dot(NormalVectorClosest, NormalVectorEmpty)/(norm(NormalVectorClosest)*norm(NormalVectorEmpty));
                sinTheta = norm(cross(NormalVectorClosest, NormalVectorEmpty))/(norm(NormalVectorClosest)*norm(NormalVectorEmpty));

                C = cross(NormalVectorClosest, NormalVectorEmpty);
                u1 = C(1)/norm(C);
                u2 = C(2)/norm(C);
                u3 = C(3)/norm(C);

                R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
                    u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
                    u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];

                % Apply rotation and translation to the closest contour
                contourClosest = contours{closestIndices(iEmpty)};
                contourTranslated = (contourClosest - AClosest) * R' + AEmpty;  % R is the rotation matrix
                contours{emptyIndices(iEmpty)} = contourTranslated;
            end
        end


        function [middlePointsArray, contoursArray] = processOutputArrays(~, middlePoints, contours)
            % Throw away empty contours and corresponding middle points
            nonEmptyIndices = ~cellfun('isempty', contours);
            emptyIndices = cellfun('isempty', contours);
            disp('empty after:')
            disp(numel(find(emptyIndices)))
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