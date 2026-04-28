classdef (Sealed) IsosurfaceGenerator < handle

    properties
        channel = 1
        thresholds = 6000
        minVertexNum = 4
        scaleFactor = 1
        zScaleFactor = 1
        bleachCompensation = 0

        % simplify: https://www.mathworks.com/help/lidar/ref/surfacemesh.simplify.html
        simplificationOn = true
        simplificationMethod = 'quadric-decimation';    % method that can yield irregular vertex distribution but preserves overall shape 
        simplificationTargetReduction = 0.2;           % target reduction factor for simplification (e.g. 0.2 means reducing to 20% of original vertices)
        simplificationMaxError = inf;                  % maximum allowed error for simplification (set to inf to ignore error constraint)
        simplificationBoundaryWeight = 1;              % weight for preserving boundary edges during simplification

        % smoothSurfaceMesh: https://www.mathworks.com/help/lidar/ref/smoothsurfacemesh.html
        smoothingOn = false
        smoothingIterations = 1
        smoothingMethod = 'Taubin'              % method that should not cause shrinkage
        smoothingScaleFactorPositive = 0.5      % default value for the first Taubing filter scale factor
        smoothingScaleFactorNegative = -0.53    % default value for the second Taubing filter scale factor

        timePoints

        warningLimit = 10   % min percentage of voxels with value above threshold to issue a warning

        padSize = 1 % number of pixels to pad on each side

        XYstep 
        Zstep 
    end


    properties (Constant)
        % list of properties that are not reconstruction parameters and should not be included in the output of getDefaultParameters
        propertiesToExclude = {'timePoints', 'warningLimit', 'padSize', 'XYstep', 'Zstep', 'propertiesToExclude'}
    end




    methods
        function obj = IsosurfaceGenerator()
            % Construct generator - should be empty so that we can call static getDefaultParameters without problem 
            % (not sure if it would be problematic, though)
        end



        function loadMetadata(obj, XYstep, Zstep)
            % Load voxel step metadata from the image stack for accurate scaling.

            arguments
                obj
                XYstep
                Zstep
            end

            obj.XYstep = XYstep;
            obj.Zstep = Zstep;
        end



        function readParametersFromComponent(obj, UIComponent)
            % Synchronize generator settings with the provided UI component state.

            arguments
                obj
                UIComponent
            end
            
            obj.channel = UIComponent.channel;
            % TO OPTIMIZE - timePoints is not really a parameter - could be somewhere else
            obj.timePoints = UIComponent.timePoints;
            obj.thresholds = UIComponent.threshold;
            obj.scaleFactor = double(UIComponent.scaleFactor);
            obj.zScaleFactor = double(UIComponent.zScaleFactor);
            obj.bleachCompensation = UIComponent.bleachCompensation;

            obj.simplificationOn = UIComponent.simplificationOn;
            obj.smoothingOn = UIComponent.smoothingOn;
        end



        function checkForLowThreshold(obj, zstack, fig)
            % Warn the user when the chosen threshold risks generating excessive voxels.
            
            arguments
                obj
                zstack
                fig
            end

            % Evaluate selected threshold to prevent CPU/memory overload
            problematicTimePoints = [];
            for tp = obj.timePoints
                im = zstack(:,:,:, tp, obj.channel);
                isoThres = obj.thresholds(tp);
                BW = im > isoThres;

                % im(~BW) = NaN;

                selectedVol = sum(BW,"all");
                nCreatedObjects = numel(BW);
                perc = selectedVol/nCreatedObjects*100;
                clear BW

                if perc > obj.warningLimit
                    problematicTimePoints = [problematicTimePoints, tp];
                end
            end

            if ~isempty(problematicTimePoints)
                disp(['Warning: Low threshold level may cause memory overload at time points: ' num2str(problematicTimePoints)]);
                selection = uiconfirm(fig, ...
                "The threshold level is low and may cause memory overload. Continue 3D reconstruction?","Low threshold waring", ...
                "Icon","warning");

                if isequal(selection, 'Cancel')
                    % if user decides to cancel, throw an exception that will have to be caught by upstream processing
                    ME = MException("UserAbort:escapedLowThreshold", "User aborted processing after low threshold warning");
                    throw(ME);
                end
            end
        end



        function validTimePoints = run(obj, zstack, XYstep, Zstep, wb, tableExistChecker, tableSetter)
            % Drive the full reconstruction workflow and return a list of time points for which objects were successfully generated.
            
            arguments
                obj
                zstack
                XYstep
                Zstep
                wb
                tableExistChecker   % handle of function checking existence of table for a given time point, should take time point as argument and return boolean
                tableSetter         % handle of function setting the table for a given time point, should take table and time point as arguments and return nothing
            end
            nSteps = 6;
            wb.Value = 1/nSteps;

            obj.loadMetadata(XYstep, Zstep);

            wb.Title = 'Calculating rescaling factors...';
            [oldXsize, oldYsize, oldZsize] = obj.getOldImageSize(zstack);
            [newXsize, newYsize, newZsize] = obj.calculateTargetImageSize(oldXsize, oldYsize, oldZsize);
            [newXstep, newYstep, newZstep] = obj.calculateNewStepSize(oldXsize, oldYsize, oldZsize, newXsize, newYsize, newZsize);

            validTimePoints = [];

            for tp = obj.timePoints
                % TO OPTIMIZE - using tp directly assumes that timePoints are ordered (does not have to be true for the model for example)
                wb.Title = ['Generating objects for time point ' num2str(tp)];
                im = zstack(:, :, :, tp, obj.channel);

                % Preprocess image: resize, pad - 260424: gaussian filtering removed, we can do it 
                wb.Message = 'Preprocessing image...';
                wb.Value = 2/nSteps;
                preprocessedIm = obj.preprocessImage(im, newXsize, newYsize, newZsize);

                wb.Message = 'Generating isosurface...';
                wb.Value = 3/nSteps;
                [verts, faces] = obj.generateMesh(tp, preprocessedIm);

                if isempty(verts) || isempty(faces)
                    % no reconstruction was done - do not do anything and just go to the next timepoint
                    disp(['no object reconstructed for timepoint ' num2str(tp)])
                    continue
                end

                wb.Message = 'Separating disconnected objects...';
                wb.Value = 4/nSteps;
                verts = obj.rescaleMeshVertices(verts, newXstep, newYstep, newZstep);

                fullMesh = surfaceMesh(verts, faces);

                % simplification and smoothing added after rescaling, because the error should be in physical units
                if obj.simplificationOn
                    % 260424: simplification moved before clustering, we assume it is not a problem
                    targetNumFaces = round(size(fullMesh.Faces, 1) * obj.simplificationTargetReduction);
                    % simplify alters the mehs in-place
                    simplify(fullMesh, 'SimplificationMethod', obj.simplificationMethod, 'TargetNumFaces', targetNumFaces, 'MaxError', obj.simplificationMaxError, 'BoundaryWeight', obj.simplificationBoundaryWeight);
                end

                if obj.smoothingOn
                    fullMesh = smoothSurfaceMesh(fullMesh, obj.smoothingIterations, 'Method', obj.smoothingMethod, 'ScaleFactor', [obj.smoothingScaleFactorPositive, obj.smoothingScaleFactorNegative]);
                end

                verts = fullMesh.Vertices;
                faces = fullMesh.Faces;

                [faceClusterIdx, nObj] = obj.clusterMeshFaces(verts, faces);    % 260423: Having 'isolateMesh' in process object does not make sense, I already expect this to be done in clusterMeshFaces

                wb.Message = 'Processing and storing objects...';
                wb.Value = 5/nSteps;
                T = getBaseStruct('table', 'model', nObj);
                validObjectIdx = 0;
                invalidRowsMask = false(nObj, 1);
                for objIdx = 1:nObj
                    [T, validObjectIdx, invalidRowsMask] = obj.processObject(verts, faces, faceClusterIdx, objIdx, T, validObjectIdx, invalidRowsMask);
                end

                if isequal(validObjectIdx, 0)
                    disp(['No valid objects reconstructed for time point ' num2str(tp) ', skipping saving.']);
                    continue
                end

                % remove empty row caused by skipped regions due to low number of vertices
                T(invalidRowsMask, :) = [];

                % to be able to save the table, expose the storeModelTable fcn and pass it as argument
                tableExists = tableExistChecker(tp);
                if tableExists
                    disp(['Overwriting existing model at time point ' num2str(tp)]);
                end
                tableSetter(T, tp);

                validTimePoints = [validTimePoints, tp];
            end
        end



        function Mesh = generatePreview(obj, zstack, XYstep, Zstep, timePoint, wb)
            % Drive the full reconstruction workflow and return a list of time points for which objects were successfully generated.
            
            arguments
                obj
                zstack
                XYstep
                Zstep
                timePoint
                wb
            end
            nSteps = 6;
            wb.Value = 1/nSteps;

            obj.loadMetadata(XYstep, Zstep);

            wb.Message = 'Calculating rescaling factors...';
            [oldXsize, oldYsize, oldZsize] = obj.getOldImageSize(zstack);
            [newXsize, newYsize, newZsize] = obj.calculateTargetImageSize(oldXsize, oldYsize, oldZsize);
            [newXstep, newYstep, newZstep] = obj.calculateNewStepSize(oldXsize, oldYsize, oldZsize, newXsize, newYsize, newZsize);

            % TO OPTIMIZE - we might want to provide zstack in different dimension order
            wb.Title = 'Preview: THE OBJECTS WILL NOT BE STORED!';
            im = zstack(:, :, :, timePoint, obj.channel);

            % Preprocess image: resize, filter, pad
            wb.Message = 'Preprocessing image...';
            wb.Value = 2/nSteps;
            preprocessedIm = obj.preprocessImage(im, newXsize, newYsize, newZsize);

            wb.Message = 'Generating preview objects...';
            wb.Value = 3/nSteps;
            [verts, faces] = obj.generateMesh(timePoint, preprocessedIm);

            if isempty(verts) || isempty(faces)
                % no reconstruction was done - do not do anything and just go to the next timepoint
                disp(['no object reconstructed for timepoint ' num2str(timePoint)])
                Mesh = {};
                return
            end

            wb.Value = 4/nSteps;
            verts = obj.rescaleMeshVertices(verts, newXstep, newYstep, newZstep);

            Mesh = surfaceMesh(verts, faces);
        end



        function [oldXsize, oldYsize, oldZsize] = getOldImageSize(~, im)
            % Report the spatial dimensions of the original volume.
            
            oldXsize = size(im, 1);
            oldYsize = size(im, 2);
            oldZsize = size(im, 3);
        end



        function [newXsize, newYsize, newZsize] = calculateTargetImageSize(obj, oldXsize, oldYsize, oldZsize)
            % Determine the resampled image size needed to reach the desired scaling.
            
            % Resize factor to increase number of points (especially in z)
            resFactorXY = obj.scaleFactor;
            newXsize = ceil(oldXsize*resFactorXY);
            newYsize = ceil(oldYsize*resFactorXY);

            zRatio = round(obj.Zstep/obj.XYstep, 1);
            resFactorZ = zRatio*obj.scaleFactor*obj.zScaleFactor;
            % TO DISCUSS - the outcome is not isotropic, which might be problematic for example for gaussian blurring
            newZsize = round(oldZsize*resFactorZ);   
        end



        function [newXstep, newYstep, newZstep] = calculateNewStepSize(obj, oldXsize, oldYsize, oldZsize, newXsize, newYsize, newZsize)
            % Compute the physical spacing of the resampled volume along each axis.
            
            % x and y kept separately because the rounding error might vary the step size a bit
            newXstep = (oldXsize * obj.XYstep) / newXsize;
            newYstep = (oldYsize * obj.XYstep) / newYsize;
            newZstep = (oldZsize * obj.Zstep) / newZsize;
        end



        function preprocessedImage = preprocessImage(obj, im, newXsize, newYsize, newZsize)
            % Resize, optionally filter, and pad the input image before meshing.
            
            resizedIm = obj.resizeImage(im, newXsize, newYsize, newZsize);
            preprocessedImage = obj.padImageBorders(resizedIm);
        end



        function resizedIm = resizeImage(~, im, newXsize, newYsize, newZsize)
            % Generate a cubic-interpolated volume matching the target voxel grid.
            
            resizedIm = imresize3(im, [newXsize,newYsize,newZsize], 'method', 'cubic');
            
            % used in the past:
            % im = imresize3(im,[newXsize,newYsize,newZsize],'method','linear');
        end



        function paddedIm = padImageBorders(obj, im)
            % Extend the volume borders to avoid boundary artifacts during meshing.
            
            % Pad image borders to avoid artifacts at the edges during isosurface generation
            paddedIm = padarray(im, [obj.padSize, obj.padSize, obj.padSize], 0, 'both');
        end



        function [verts, faces] = generateMesh(obj, tp, im)
            % Extract vertices and faces for the current time point.
            
            isoThres = obj.thresholds(tp);
            % MarchingCubeFcn = @extractIsosurface;  % this one produces chewing gum artifacts
            MarchingCubeFcn = @isosurface;

            [faces, verts] = MarchingCubeFcn(im, isoThres);
        end



        function verts = rescaleMeshVertices(obj, verts, newXstep, newYstep, newZstep)
            % Convert padded, resampled vertex coordinates back to original spacing.
            
            verts = verts - obj.padSize;

            % Revert the upscaling
            verts(:,1) = verts(:,1).*newXstep;
            verts(:,2) = verts(:,2).*newYstep;
            verts(:,3) = verts(:,3).*newZstep;
        end



        function [clusterIdx, nObj] = clusterMeshFaces(~, vertices, faces)
            % Group connected faces into individual objects and report their count.
            
            fullMesh = surfaceMesh(vertices, faces);
            % TO OPTIMIZE - this could probably be replaced with something faster
            [clusterIdx, clusterNumFaces, ~] = clusterConnectedFaces(fullMesh);                   
            nObj = numel(clusterNumFaces);
        end



        function [T, validObjectIdx, invalidRowsMask] = processObject(obj, allVerts, allFaces, faceClusterIdx, objIdx, T, validObjectIdx, invalidRowsMask)
            % Isolate a mesh chunk, validate it, and store it into the results table.
            
            singleObjMesh = obj.isolateMesh(allVerts, allFaces, faceClusterIdx, objIdx);
            % simplify(singleObjMesh);

            nVerts = size(singleObjMesh.Vertices, 1);
            if nVerts >= max(obj.minVertexNum, 4)   % 260424: we deprecated minVertexNum from the component
                validObjectIdx = validObjectIdx + 1; 
                
                T.Properties.RowNames{objIdx} = num2str(validObjectIdx);  

                T{objIdx, 'Mesh'} = {singleObjMesh};
                T{objIdx, 'positionShift'} = {[0,0,0]};
                T{objIdx, 'color'} = {rand(1,3)};
            else
                invalidRowsMask(objIdx) = true;    
            end
        end



        function singleObjMesh = isolateMesh(~, allVerts, allFaces, faceClusterIdx, objIdx)
            % Extract a standalone surfaceMesh instance for a single clustered object.
            
            % this is faster approach to using allVerts in the mesh and then applying removeVertices
            used = false(size(allVerts, 1), 1);
            usedFaces = allFaces(faceClusterIdx==objIdx,:);
            used(usedFaces(:)) = true;                 % mark vertices referenced by any face

            oldToNew = zeros(size(allVerts,1), 1);
            oldToNew(used) = 1:nnz(used);      % mapping: old index -> compact new index

            usedVertices = allVerts(used, :);                   % compacted vertices
            usedFaces = reshape(oldToNew(usedFaces(:)), size(usedFaces));   % remap faces (same shape as F)

            singleObjMesh = surfaceMesh(usedVertices, usedFaces);
        end



        function singleObjMesh = isolateMeshOld(~, verts, faces, faceClusterIdx, objIdx)
            % This is the original, slower approach to extract a standalone mesh for a single object.
            % It seems to give the same result as isolateMesh, but is much less efficient.
            idx = 1:size(verts,1);
            firstFaces = faces(faceClusterIdx==objIdx,:);
            idx(unique(firstFaces))=[];
            singleObjMesh = surfaceMesh(verts,firstFaces);
            removeVertices(singleObjMesh,idx)
        end



        function parameters = getParameters(obj, currentTimePoint)
            % Return the current reconstruction parameters as a structure.
            warning('off','all')
            parameters = struct(obj);
            warning('on','all')
            parameters = rmfield(parameters, IsosurfaceGenerator.propertiesToExclude);

            % Threshold is timepoint-specific, so we need to get it separately
            parameters.threshold = obj.thresholds(currentTimePoint);
        end
    end



    methods (Static)
        function parameters = getDefaultParameters()
            % Provide a structure of default settings for the reconstruction.
            % We export all parameters that are not in the propertiesToExclude list
            warning('off','all')
            parameters = struct(IsosurfaceGenerator);
            parameters = rmfield(parameters, IsosurfaceGenerator.propertiesToExclude);
            warning('on','all')

            % mc = metaclass(IsosurfaceGenerator);
            % parameters = struct();

            % for i = 1:numel(mc.PropertyList)
            %     prop = mc.PropertyList(i);

            %     if strcmp(prop.GetAccess, 'public') && ~prop.Hidden && ~prop.Dependent
            %         name = prop.Name;
            %         parameters.(name) = IsosurfaceGenerator.(name);
            %     end
            % end
        end
    end
end