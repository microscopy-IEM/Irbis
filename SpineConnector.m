% input: 
    % two masks, one corresponding to the spine and the other to the edge of dendritic shaft
    % speed map - created from the grayscale image, can be only a section of input      
    % optional: constraint map

% output: 
    % best path connecting the two masks
    % start point - point connected to the spine mask
    % end point - point connected to the shaft mask


% point processing before and after fast marching 
    % x and y coordinate are switched for start and end points before running the algorithm
    % y and y coordinate are switched again for the resulting trajectory
    % the zstack stays the same
    % constraint bitmap also the same?


% this could be called both when creating spines and manually from context menu

% let's first start without masking the other spines

% I need to also create a bounding box not to need to explore the whole space
    % based on the centre of the spine plus its expected size

classdef SpineConnector < handle

    properties
        pixelSizeInUM = 0.1;  % Pixel size in micrometers
        zSpacingInUM = 0.1;  % Z-spacing in micrometers
    end

    properties (Constant)
        GAUSSIAN_SIGMA_UM = 0.5;  % Gaussian smoothing sigma in micrometers
        EXPECTED_SPINE_SIZE_UM = 5;  % Expected size of the spine in micrometers    % CHANGED FROM 10 TO 5
        ERROR_MARGIN_SPINE_SIZE = 1;  % Error margin for spine size in micrometers  % CHANGED FROM 2 TO 1
    end

    methods
        function loadAllNecessaryInfo(obj, pixelSizeInUM, zSpacingInUM)
            obj.pixelSizeInUM = pixelSizeInUM;  % Set pixel size in micrometers
            obj.zSpacingInUM = zSpacingInUM;  % Set z-spacing in micrometers
        end



        function umPathInfo = main(obj, spineMesh, shaftMesh, zstack, varargin)
            % TO OPTIMIZE - if this is run in batch, some of the steps (dendrite conversion, speed map calculation) can be done only once
            profile on
            tic
            % convert the spine meshes to a list of coordinates in pixels - already assumes upsampled z
            spinePoints = obj.generateCoordinatesFromMesh(spineMesh);
            % assignin("base", 'spinePoints', spinePoints);  % Assign to base workspace for debugging
            shaftPoints = obj.generateCoordinatesFromMesh(shaftMesh);
            % assignin("base", 'shaftPoints', shaftPoints);  % Assign to base workspace for debugging

            % generate a speed map from the zstack - requires upsampling in zstack
            speedMap = obj.calculateSpeedMapFromImage(zstack);       

            % % Create debug visualization of the middle plane of speed map with points
            % if ~isempty(zstack) && ~isempty(spinePoints) && ~isempty(shaftPoints)
            %     midZ = round(size(zstack, 3) / 2);
                
            %     figure('Name', 'Speed Map Debug View');
                
            %     % Display middle plane of speed map
            %     subplot(1, 2, 1);
            %     imagesc(speedMap(:, :, midZ));
            %     colormap(gray);
            %     title('Middle Plane of Speed Map');
            %     hold on;
                
            %     % Find points near this z-plane
            %     nearZ = 2;  % Points within this range will be shown
            %     spineIdx = abs(spinePoints(3,:) - midZ) <= nearZ;
            %     shaftIdx = abs(shaftPoints(3,:) - midZ) <= nearZ;
                
            %     % Plot points
            %     scatter(spinePoints(1, spineIdx), spinePoints(2, spineIdx), 30, 'r', 'filled', 'MarkerEdgeColor', 'w');
            %     scatter(shaftPoints(1, shaftIdx), shaftPoints(2, shaftIdx), 30, 'g', 'filled', 'MarkerEdgeColor', 'w');
            %     legend('Spine Points', 'Shaft Points');
            %     axis image;
                
            %     % Display binary masks
            %     subplot(1, 2, 2);
            %     maskImg = zeros(size(speedMap, 1), size(speedMap, 2));
            %     for i = 1:size(spinePoints, 2)
            %         if abs(spinePoints(3,i) - midZ) <= nearZ
            %             maskImg(round(spinePoints(2,i)), round(spinePoints(1,i))) = 1;
            %         end
            %     end
            %     for i = 1:size(shaftPoints, 2)
            %         if abs(shaftPoints(3,i) - midZ) <= nearZ
            %             maskImg(round(shaftPoints(2,i)), round(shaftPoints(1,i))) = 2;
            %         end
            %     end
            %     imagesc(maskImg);
            %     colormap([0 0 0; 1 0 0; 0 1 0]);
            %     title('Spine (red) and Shaft (green) Points');
            %     axis image;
                
            %     drawnow;
            % end

            % crop the zstack and points to the ROI around the spine
            ROIedgesInPix = obj.calculateROIedges(spinePoints);
            % assignin('base', 'ROIedgesInPix', ROIedgesInPix);  % Assign to base workspace for debugging
            [croppedSpeedMap, croppedSpinePoints, croppedShaftPoints] = obj.crop(speedMap, spinePoints, shaftPoints, ROIedgesInPix);

            % disp('sizes')
            % disp(['Cropped speed map size: ' num2str(size(croppedSpeedMap))]);
            % disp(['Cropped spine points size: ' num2str(size(croppedSpinePoints))]);
            % disp(['Cropped shaft points size: ' num2str(size(croppedShaftPoints))]);

            % perform tracking using Fast Marching - output in pixels
            pixelPathInfo = obj.find(croppedSpinePoints, croppedShaftPoints, croppedSpeedMap);

            % reverse cropping - output still in pixels
            pixelPathInfo.startPoint = obj.reverseCrop(pixelPathInfo.startPoint, ROIedgesInPix);
            pixelPathInfo.endPoint = obj.reverseCrop(pixelPathInfo.endPoint, ROIedgesInPix);
            pixelPathInfo.path = obj.reverseCrop(pixelPathInfo.path, ROIedgesInPix);

            % convert pixel info to micrometers
            umPathInfo = obj.convertPixelPathToUM(pixelPathInfo);

            % assignin('base', 'umPathInfo', umPathInfo);  % Assign to base workspace for debugging
            toc
            profile off
            profile viewer
        end



        function pixelPathInfo = find(~, spinePoints, shaftPoints, speedMap, varargin)
            % Find the best path connecting the spine and shaft masks using Fast Marching
            % Expects points and speed map already prepared, except for the swapping

            pixelPathInfo = struct();

            spinePoints = spinePoints';  % Convert to n x 3 format for processing
            shaftPoints = shaftPoints';  % Convert to n x 3 format for processing

            assert(isequal(size(spinePoints, 1), 3), 'Spine points must be a 3xN array.');
            assert(isequal(size(shaftPoints, 1), 3), 'Shaft points must be a 3xN array.');

            spinePointsSwapped = spinePoints([2 1 3], :);  % Swap coordinates for Fast Marching
            shaftPointsSwapped = shaftPoints([2 1 3], :);  % Swap coordinates for Fast Marching

            % Run Fast Marching
            options.nb_iter_max = Inf;
            options.end_points = shaftPointsSwapped;  % Specify end points for early stopping
            
            [distanceMap, ~] = perform_fast_marching(speedMap, spinePointsSwapped, options);
            
            % Find the point on the shaft that was reached first
            % Get linear indices for all shaft points in the distance map (convert coordinates to one number describing position in array)
            linearIndices = sub2ind(size(distanceMap), ...
                shaftPointsSwapped(1,:), shaftPointsSwapped(2,:), shaftPointsSwapped(3,:));
            
            % Get distances at all shaft points and find the point that was reached first
            distances = distanceMap(linearIndices);
            [~, closestPointId] = min(distances);
            
            % Backtrack shortest path
            pathSwapped = compute_geodesic(distanceMap, shaftPointsSwapped(:, closestPointId));
                % compute_geodesic starts in the point and the dendrite and backtracks to the spine
            
            % Swap coordinates to match original system
            path = pathSwapped([2 1 3], :);

            pixelPathInfo.path = path;  % Store the path
            pixelPathInfo.startPoint = path(:, end);  % Start point is the last point in the path - on the spine
            pixelPathInfo.endPoint = path(:, 1);  % End point is on the shaft - the first point in the path

            % assignin('base', 'pixelPathInfo', pixelPathInfo);  % Assign to base workspace for debugging
        end


        function [croppedZStack, croppedSpinePoints, croppedShaftPoints] = crop(~, zstack, spinePoints, shaftPoints, ROIedgesInPix)
            % Crop the z-stack to the specified ROI edges
            % ROIedgesInPix is a 3x2 array with min and max boundaries for each dimension
            % Format: [xMin, yMin, zMin; xMax, yMax, zMax]
            % The points need to be already in pixel coordinates

            % Ensure ROI edges are within bounds of the z-stack
            xMin = max(ROIedgesInPix(1, 1), 1);
            yMin = max(ROIedgesInPix(2, 1), 1);
            zMin = max(ROIedgesInPix(3, 1), 1);
            xMax = min(ROIedgesInPix(1, 2), size(zstack, 2));
            yMax = min(ROIedgesInPix(2, 2), size(zstack, 1));
            zMax = min(ROIedgesInPix(3, 2), size(zstack, 3));

            % Crop the z-stack
            croppedZStack = zstack(yMin:yMax, xMin:xMax, zMin:zMax);

            % Flip rows and columns for the points
                % They are supplied as n x 3 vector, but here, I am working with them as 3 x n
            spinePoints = spinePoints';

            % Crop shaft points by throwing away points outside the ROI and recalculating their coordinates
            % Filter and adjust spine points
            validSpineIdx = spinePoints(1,:) >= xMin & spinePoints(1,:) <= xMax & ...
                           spinePoints(2,:) >= yMin & spinePoints(2,:) <= yMax & ...
                           spinePoints(3,:) >= zMin & spinePoints(3,:) <= zMax;

            croppedSpinePoints = spinePoints(:, validSpineIdx);
            % Adjust coordinates to be relative to the cropped region
            % The +1 is needed, because lower edge becomes 1, and if we just subtracted lower edge, we would get 0
            croppedSpinePoints(1,:) = croppedSpinePoints(1,:) - xMin + 1;
            croppedSpinePoints(2,:) = croppedSpinePoints(2,:) - yMin + 1;
            croppedSpinePoints(3,:) = croppedSpinePoints(3,:) - zMin + 1;


            shaftPoints = shaftPoints';
            % Filter and adjust shaft points
            validShaftIdx = shaftPoints(1,:) >= xMin & shaftPoints(1,:) <= xMax & ...
                           shaftPoints(2,:) >= yMin & shaftPoints(2,:) <= yMax & ...
                           shaftPoints(3,:) >= zMin & shaftPoints(3,:) <= zMax;

            croppedShaftPoints = shaftPoints(:, validShaftIdx);
            % Adjust coordinates to be relative to the cropped region
            croppedShaftPoints(1,:) = croppedShaftPoints(1,:) - xMin + 1;
            croppedShaftPoints(2,:) = croppedShaftPoints(2,:) - yMin + 1;
            croppedShaftPoints(3,:) = croppedShaftPoints(3,:) - zMin + 1;


            % % For debugging: Visualize the middle z-plane of the cropped stack with points
            % if ~isempty(croppedSpinePoints) && ~isempty(croppedShaftPoints)
            %     disp('Visualizing middle z-plane with spine and shaft points...');
            %     middleZ = round(size(croppedZStack, 3) / 2);
            %     % Find spine and shaft points on or near the middle plane
            %     nearZ = 2;  % Points within this range will be shown
            %     spineIdx = abs(croppedSpinePoints(3,:) - middleZ) <= nearZ;
            %     shaftIdx = abs(croppedShaftPoints(3,:) - middleZ) <= nearZ;
                
            %     % Create visualization
            %     figure;
            %     imshow(croppedZStack(:,:,middleZ), []);
            %     hold on;
            %     if ~isempty(croppedSpinePoints) && any(spineIdx)
            %         scatter(croppedSpinePoints(1,spineIdx), croppedSpinePoints(2,spineIdx), 25, 'r', 'filled');
            %     end
            %     if ~isempty(croppedShaftPoints) && any(shaftIdx)
            %         scatter(croppedShaftPoints(1,shaftIdx), croppedShaftPoints(2,shaftIdx), 25, 'g', 'filled');
            %     end
            %     title(['Middle Z-plane: ' num2str(middleZ) ' with spine (red) and shaft (green) points']);
            %     hold off;
            % else
            %     disp('No valid spine or shaft points found in the cropped region.');
            % end

            % Swap back 
            croppedSpinePoints = croppedSpinePoints';  % Convert back to n x 3 format
            croppedShaftPoints = croppedShaftPoints';  % Convert back to n x 3 format
        end



        function points = reverseCrop(~, croppedPoints, ROIedgesInPix)
            % Reverse crop the points to their original coordinates based on the ROI edges
            % croppedPoints is a 3xN array of points in pixel coordinates
            % ROIedgesInPix is a 3x2 array with min and max boundaries for each dimension

            points = zeros(size(croppedPoints));  % Initialize points array

            % Ensure ROI edges are within bounds of the original space
            xMin = ROIedgesInPix(1, 1);
            yMin = ROIedgesInPix(2, 1);
            zMin = ROIedgesInPix(3, 1);

            % Reverse crop the points
            points(1,:) = croppedPoints(1,:) + xMin - 1;  % Adjust x-coordinates
            points(2,:) = croppedPoints(2,:) + yMin - 1;  % Adjust y-coordinates
            points(3,:) = croppedPoints(3,:) + zMin - 1;  % Adjust z-coordinates
        end



        function ROIsizePix = calculateROIsize(obj)
            % Calculate the size of spine ROI based on the pixel size and expected spine size
            ROIsizePix = round((obj.EXPECTED_SPINE_SIZE_UM * obj.ERROR_MARGIN_SPINE_SIZE) / obj.pixelSizeInUM);
        end



        function ROIedgesInPix = calculateROIedges(obj, spinePoints)
            % Calculate the ROI around the spine point
            ROIsizePix = obj.calculateROIsize();

            % Calculate center of ROI by getting mean of spine points
            spineCenter = mean(spinePoints, 1);  % Average across all points in the spine

            % Calculate ROI bounds for each dimension (x, y, z)
            lowerBound = max(round(spineCenter - ROIsizePix/2), 1);  % Ensure lower bound is not below 1
            upperBound = round(spineCenter + ROIsizePix/2);

            % Create array with min and max boundaries for each dimension
            % Format: [xMin, yMin, zMin; xMax, yMax, zMax]
            ROIedgesInPix = [lowerBound(1), lowerBound(2), lowerBound(3);
                            upperBound(1), upperBound(2), upperBound(3)]';
            
            % This makes ROIedgesInPix a 3×2 array where:
            % ROIedgesInPix(:,1) contains lower bounds [xMin; yMin; zMin]
            % ROIedgesInPix(:,2) contains upper bounds [xMax; yMax; zMax]
        end



        function umPathInfo = convertPixelPathToUM(obj, pixelPathInfo)
            % Convert pixel path information to micrometers
            umPathInfo = struct();
            umPathInfo.path = pixelPathInfo.path * obj.pixelSizeInUM;  % Convert path to micrometers
            umPathInfo.startPoint = pixelPathInfo.startPoint * obj.pixelSizeInUM;  % Start point in micrometers
            umPathInfo.endPoint = pixelPathInfo.endPoint * obj.pixelSizeInUM;  % End point in micrometers
        end


        % function calculateIsotropicScaling(obj)
        %     % If we just scale the z dimension, we might not get to precisely isotropic scaling because of rounding 
        %     % Therefore, we need to upscale the z a bit and downscale/upscale xy correspondingly
        %     % For example, if xy were 0.1 and z was 0.15, z-upscaleFactor would be 1.5 -> we could not ensure proper scaling


        %     % I will round the final pixel number instead of the scaling, that might cause less problems - fix if it is causing too much trouble
        % end


        % function points = calculatePointsFromMask(obj, mask)
        %     % Convert binary mask to coordinates
        % end


        function speedMap = calculateSpeedMapFromImage(obj, zstack)
            % Preprocess the zstack 

            % Get Z-stack for current channel and time point
            zstack = squeeze(zstack);
            
            % Resize with anisotropic scaling compensation
            zUpscaleFactor = obj.zSpacingInUM / obj.pixelSizeInUM;  % this might have some decimal numbers
            zstack = imresize3(zstack, ...
                [size(zstack,1), size(zstack,2), round(size(zstack,3)*zUpscaleFactor)], ...
                'method', 'linear');
                % BE CAREFUL - rounding of the size in z might cause that xy and z will not be perfectly isotropic
            % disp('CHECK OF ISOTROPICITY: ')
            % disp(['Pixel size in z without rounding: ' num2str(size(zstack,3)*zUpscaleFactor)])
            % disp(['Pixel size after rounding: ' num2str(round(size(zstack,3)*zUpscaleFactor))])
            % disp(['Resulting pixel size in z: ' num2str(obj.zSpacingInUM*size(zstack,3)/(round(size(zstack,3)*zUpscaleFactor)))])
            
            % Apply Gaussian smoothing - omit for now
            % sigma = obj.GAUSSIAN_SIGMA_UM/obj.pixelSizeInUM;
            % zstack = imgaussfilt3(zstack, sigma);
            
            % Normalize to [0,1] and enhance contrast
            zstack = double(zstack)./(2^16);
            % zstack = zstack.^2; - omitted for now, we do not care about the highest intensities
            
            % Final normalization
            imMax = max(zstack(:));
            imMin = min(zstack(:));
            speedMap = imadjustn(zstack, [imMin imMax], []);
        end



        function voxelCoordinates = generateCoordinatesFromMesh(obj, mesh)
            % Generate a surface mask from a mesh object
            % It should create a binary mask representing the surface of the mesh
            % The mask should be in the same dimensions as the z-stack used for pathfinding
                % However, the z dimension needs to be upsampled to match xy - voxelization takes only 1 parameter
            

            voxelSize = obj.pixelSizeInUM;  % Voxel size in micrometers

            input_data = struct();
            input_data.vertices = mesh.Vertices;  % Mesh vertices
            input_data.faces = mesh.Faces - 1;  % Converting to 0-based indexing for Python

            voxel_coordinates_numpy = pyrunfile('voxelizeMesh_py_script.py', ...
                "voxel_coordinates", data=input_data, ...
                voxel_size=voxelSize);

            voxelCoordinates = double(voxel_coordinates_numpy);  % Convert to uint64
            voxelCoordinates = voxelCoordinates + 1; % add 1 for MATLAB 1-based indexing

            % disp('Voxel coordinates generated from mesh:');
            % disp(size(voxelCoordinates));

            % assignin('base', 'voxelCoordinates', voxelCoordinates);  % Assign to base workspace for debugging


            disp('finished')
        end
    end
end
