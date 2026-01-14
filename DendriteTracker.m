classdef DendriteTracker < handle
    % DendriteTracker - Class for processing and tracking dendrites in Z-stacks
    %
    % This class provides functionality to track dendrites through 3D image stacks
    % using fast marching algorithms and image processing techniques.
    
    properties (SetAccess = private)
        pixelSizeInUM       % Pixel size in micrometers
        zSpacingInUM        % Z spacing in micrometers
        nPlanes             % Number of planes
        channelToTrack      % Channel to track
        currentTimePoint    % Current time point
        parentBranch        % Parent branch name
        resFactorXY         % XY scaling factor
        resFactorZ          % Z scaling factor
        downScaleFactor     % Downscale factor for processing
    end
    
    properties (Constant, Access = private)
        GAUSSIAN_SIGMA_UM = 0.15  % Gaussian filter sigma size in micrometers
        ENDPOINT_REPLACEMENT_COUNT = 30  % Number of points to replace at trajectory ends
        DEFAULT_DOWNSCALE_FACTOR = 0.5   % Default downscaling factor for processing
    end
    
    methods
        function obj = DendriteTracker(pixel_size, z_spacing, nPlanes)
            % Constructor for DendriteTracker
            %
            % Parameters:
            %   pixel_size - Pixel size in micrometers
            %   z_spacing - Z spacing in micrometers
            %   nPlanes - Number of planes in the Z-stack

            % Validate inputs
            if nargin < 3
                error('DendriteTracker requires pixel_size, z_spacing, nPlanes');
            end
            
            % Initialize properties from app
            obj.pixelSizeInUM = pixel_size;
            obj.zSpacingInUM = z_spacing;
            obj.nPlanes = nPlanes;

            obj.downScaleFactor = obj.DEFAULT_DOWNSCALE_FACTOR;  % Default downscale factor

            obj.calculateScaleFactors();  % Calculate scaling factors
        end

        function calculateScaleFactors(obj)          % Calculate scaling factors
            zRatio = round(obj.zSpacingInUM/obj.pixelSizeInUM);
            obj.resFactorXY = obj.downScaleFactor;
            obj.resFactorZ = zRatio * obj.downScaleFactor;
        end
        
        function traj = trackDendrite(obj, zstack, startPoint, endPoint, restrictedAreas, xlim, ylim, drift)
            % Track dendrite between two points in 3D space
            %
            % Parameters:
            %   startPoint - Starting point coordinates [x,y,z]
            %   endPoint - Ending point coordinates [x,y,z]
            %
            % Returns:
            %   traj - Trajectory points as Nx3 matrix [x,y,z]
            
            % Validate inputs
            if nargin < 3
                error('startPoint and endPoint are required');
            end

            % Process data
            zstack = obj.preprocessZstack(zstack);
            [startPoint, endPoint] = obj.preprocessEndpoints(startPoint, endPoint, zstack);
            
            % calculate constraint bitmap if needed
            constraintBitmap = obj.calculateConstraintBitmap(restrictedAreas, zstack, xlim, ylim, drift);

            % Find trajectory
            traj = obj.findTrajectory(zstack, startPoint, endPoint, constraintBitmap);
            
            % Post-process trajectory
            traj = obj.postprocessTrajectory(traj);
        end
        
        function zstack = preprocessZstack(obj, zstack)
            % Preprocess Z-stack for dendrite tracking
            %
            % Returns:
            %   zstack - Processed Z-stack
            
            % Get Z-stack for current channel and time point
            zstack = squeeze(zstack);
            
            % Resize with anisotropic scaling compensation
            zstack = imresize3(zstack, ...
                [size(zstack,1)*obj.resFactorXY, size(zstack,2)*obj.resFactorXY, size(zstack,3)*obj.resFactorZ], ...
                'method', 'linear');
            
            % Apply Gaussian smoothing
            sigma = obj.GAUSSIAN_SIGMA_UM/obj.pixelSizeInUM;
            zstack = imgaussfilt3(zstack, sigma);
            
            % Normalize to [0,1] and enhance contrast
            zstack = double(zstack)./(2^16);
            zstack = zstack.^2;
            
            % Final normalization
            imMax = max(zstack(:));
            imMin = min(zstack(:));
            zstack = imadjustn(zstack, [imMin imMax], []);
        end
        
        function [startPoint, endPoint] = preprocessEndpoints(obj, startPoint, endPoint, zstack)
            % Preprocess start and end points for tracking
            %
            % Parameters:
            %   startPoint - Starting point [x,y,z]
            %   endPoint - Ending point [x,y,z]
            %   zstack - Processed Z-stack
            %
            % Returns:
            %   startPoint - Adjusted start point
            %   endPoint - Adjusted end point
            
            % Transpose and swap coordinates
            % Ensure points are column vectors (3×1) for consistent processing
            startPoint = reshape(startPoint, [], 1);
            endPoint = reshape(endPoint, [], 1);
            
            startPoint([1,2,3],:) = startPoint([2,1,3],:);
            endPoint([1,2,3],:) = endPoint([2,1,3],:);
            
            % Scale coordinates
            startPoint(1:2) = startPoint(1:2).*obj.resFactorXY;
            endPoint(1:2) = endPoint(1:2).*obj.resFactorXY;
            startPoint(3) = startPoint(3).*obj.resFactorZ;
            endPoint(3) = endPoint(3).*obj.resFactorZ;
            
            % Ensure integer coordinates
            startPoint = ceil(startPoint);
            endPoint = ceil(endPoint);
            
            % Adjust points to stay within boundaries
            [startPoint, endPoint] = obj.adjustPointsToBoundaries(startPoint, endPoint, zstack);
        end
    end
    
    methods (Access = private)
        function [startPoint, endPoint] = adjustPointsToBoundaries(obj, startPoint, endPoint, zstack)
            % Adjust points to stay within image boundaries
            
            for i=1:3
                if startPoint(i) < 1
                    diff = 1 - startPoint(i);
                    startPoint(i) = 1;
                    endPoint(i) = endPoint(i) + diff;
                elseif startPoint(i) > size(zstack,i)
                    diff = startPoint(i) - size(zstack,i);
                    startPoint(i) = size(zstack,i);
                    endPoint(i) = endPoint(i) - diff;
                end
                
                if endPoint(i) < 1
                    diff = 1 - endPoint(i);
                    endPoint(i) = 1;
                    startPoint(i) = startPoint(i) + diff;
                elseif endPoint(i) > size(zstack,i)
                    diff = endPoint(i) - size(zstack,i);
                    endPoint(i) = size(zstack,i);
                    startPoint(i) = startPoint(i) - diff;
                end
            end
        end
        
        function traj = findTrajectory(obj, zstack, startPoint, endPoint, constraintBitmap)
            % Find the trajectory using fast marching algorithm
            
            try
                if isempty(constraintBitmap)
                    traj = IS_getTrajectory_fast_marching(zstack, startPoint, endPoint);
                else
                    traj = IS_getTrajectory_fast_marching(zstack, startPoint, endPoint, constraintBitmap);
                end
            catch ME
                warning(ME.identifier, 'Failed to find trajectory: %s', ME.message);
                traj = [];
            end
        end
        
        function traj = postprocessTrajectory(obj, traj)
            % Post-process the trajectory points
            
            if isempty(traj)
                return;
            end
            
            try
                % Convert pixels to micrometers
                traj(1:2,:) = traj(1:2,:) .* obj.pixelSizeInUM;
                traj(3,:) = traj(3,:) .* obj.zSpacingInUM;
                
                % Adjust for downscaling
                traj(1:2,:) = traj(1:2,:) ./ obj.resFactorXY;
                traj(3,:) = traj(3,:) ./ obj.resFactorZ;
                
                % Switch order of x and y
                traj([1,2,3],:) = traj([2,1,3],:); 
                
                % Transpose to Nx3 format
                traj = traj';
                
                % Smooth trajectory ends
                traj = obj.smoothTrajectoryEnds(traj);
            catch ME
                warning(ME.identifier, 'Error in trajectory post-processing: %s', ME.message);
                traj = [];
            end
        end
        
        function traj = smoothTrajectoryEnds(obj, traj)
            % Smooth the ends of the trajectory
            
            numP = obj.ENDPOINT_REPLACEMENT_COUNT;
            
            if (size(traj, 1) < 2*numP+1) || numP == 0
                return; % Not enough points to smooth or smoothing disabled
            end
            
            % Calculate direction vectors
            CVectStart = mean(traj(numP:2*numP,:)-traj(numP+1:(2*numP+1),:), 1);
            CVectEnd = mean(traj((end-2*numP):(end-numP),:)-traj((end-2*numP-1):(end-numP-1),:), 1);
            
            % Redefine edge points
            for i = 1:numP
                traj(i,:) = traj(1+numP,:) + CVectStart .* (numP+1-i);
                traj(end-numP+i,:) = traj((end-numP),:) + CVectEnd .* i;
            end
        end


        function constraintBitmap = calculateConstraintBitmap(~, restrictedAreas, zstack, xlim, ylim, drift)
            % constrain tracking
        
            if isempty(restrictedAreas)
                constraintBitmap = [];
            else
        
                % make a constraint map
                xVector = linspace(xlim(1),xlim(2),size(zstack,2));
                yVector = linspace(ylim(1),ylim(2),size(zstack,1));
        
                [xGrid,yGrid] = meshgrid(xVector,yVector);
        
                inROI = zeros(size(xGrid));
                for roiNum = 1:length(restrictedAreas)
                    roi = restrictedAreas(roiNum);
                    inROI = inROI + inpolygon(xGrid,yGrid,roi.Position(:,1)-drift(1),roi.Position(:,2)-drift(2));
                end
        
                inROI = double(inROI);
                inROI(inROI > 0) = -Inf;
                inROI(inROI == 0) = Inf;
        
                constraintBitmap = repmat(inROI,[1,1,size(zstack,3)]);
            end
        end
    end
end
