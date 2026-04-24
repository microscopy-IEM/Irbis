classdef (Sealed) IsosurfaceGenerator < handle

    properties
        warningLimit = 10   % min percentage of voxels with value above threshold to issue a warning

        currentChannel
        gaussFilterSigma
        gaussFilteringOn = false
        timePoints
        thresholds
        minVertexNum
        scaleFactor
        zScaleFactor
        bleachCompensation

        padSize = 1 % number of pixels to pad on each side

        XYstep 
        Zstep 
    end

    methods
        function obj = IsosurfaceGenerator(XYstep, Zstep)
            % Construct generator with voxel step configuration for XY and Z axes.

            arguments
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
            
            obj.currentChannel = UIComponent.channel;
            % obj.gaussFilterSigma = double(UIComponent.gaussFilterSigma);
            obj.timePoints = UIComponent.timePoints;
            obj.thresholds = UIComponent.threshold;
            obj.minVertexNum = double(UIComponent.minVertexNum);
            obj.scaleFactor = double(UIComponent.scaleFactor);
            obj.zScaleFactor = double(UIComponent.zScaleFactor);
            % if isequal(obj.gaussFilterSigma,0)
            %     obj.gaussFilteringOn = 0;
            % else
            %     obj.gaussFilteringOn = 1;
            % end
            obj.bleachCompensation = UIComponent.bleachCompensation;
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
                im = zstack(:,:,:, tp, obj.currentChannel);
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



        function validTimePoints = run(obj, zstack, wb, tableExistChecker, tableSetter)
            % Drive the full reconstruction workflow and return a list of time points for which objects were successfully generated.
            
            arguments
                obj
                zstack
                wb
                tableExistChecker 
                tableSetter
            end
            nSteps = 6;
            wb.Value = 1/nSteps;

            wb.Title = 'Calculating rescaling factors...';
            [oldXsize, oldYsize, oldZsize] = obj.getOldImageSize(zstack);
            [newXsize, newYsize, newZsize] = obj.calculateTargetImageSize(oldXsize, oldYsize, oldZsize);
            [newXstep, newYstep, newZstep] = obj.calculateNewStepSize(oldXsize, oldYsize, oldZsize, newXsize, newYsize, newZsize);

            validTimePoints = [];

            for tp = obj.timePoints
                % TO OPTIMIZE - using tp directly assumes that timePoints are ordered (does not have to be true for the model for example)
                wb.Title = ['Generating objects for time point ' num2str(tp)];
                im = zstack(:, :, :, tp, obj.currentChannel);

                % Preprocess image: resize, filter, pad
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



        function Mesh = generatePreview(obj, zstack, wb)
            % Drive the full reconstruction workflow and return a list of time points for which objects were successfully generated.
            
            arguments
                obj
                zstack
                wb
            end
            nSteps = 6;
            wb.Value = 1/nSteps;

            tp = 1;

            wb.Title = 'Calculating rescaling factors...';
            [oldXsize, oldYsize, oldZsize] = obj.getOldImageSize(zstack);
            [newXsize, newYsize, newZsize] = obj.calculateTargetImageSize(oldXsize, oldYsize, oldZsize);
            [newXstep, newYstep, newZstep] = obj.calculateNewStepSize(oldXsize, oldYsize, oldZsize, newXsize, newYsize, newZsize);

            % TO OPTIMIZE - using tp directly assumes that timePoints are ordered (does not have to be true for the model for example)
            wb.Title = ['Generating objects for time point ' num2str(tp)];
            im = zstack(:, :, :, tp, obj.currentChannel);

            % Preprocess image: resize, filter, pad
            wb.Message = 'Preprocessing image...';
            wb.Value = 2/nSteps;
            preprocessedIm = obj.preprocessImage(im, newXsize, newYsize, newZsize);

            wb.Message = 'Generating isosurface...';
            wb.Value = 3/nSteps;
            [verts, faces] = obj.generateMesh(tp, preprocessedIm);

            if isempty(verts) || isempty(faces)
                % no reconstruction was done - do not do anything and just go to the next timepoint
                disp(['no object reconstructed for timepoint ' num2str(tp)])
                Mesh = {};
                return
            end

            wb.Message = 'Separating disconnected objects...';
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
            if obj.gaussFilteringOn
                filteredIm = obj.applyGaussianFilter(resizedIm);
            else
                filteredIm = resizedIm;
            end
            preprocessedImage = obj.padImageBorders(filteredIm);
        end



        function resizedIm = resizeImage(~, im, newXsize, newYsize, newZsize)
            % Generate a cubic-interpolated volume matching the target voxel grid.
            
            resizedIm = imresize3(im, [newXsize,newYsize,newZsize], 'method', 'cubic');
            
            % used in the past:
            % im = imresize3(im,[newXsize,newYsize,newZsize],'method','linear');
        end



        function filteredIm = applyGaussianFilter(obj, im)
            % Blur the volume with a 3D Gaussian kernel when smoothing is enabled.
            
            % TO FIX - this is not a good setup, as sigma is in pixels
            % -> will have different effect depending on rescaling and pixel size
            sigma = obj.gaussFilterSigma;
            filteredIm = imgaussfilt3(im, sigma);
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
            % Simplify a mesh chunk, validate it, and store it into the results table.
            
            singleObjMesh = obj.isolateMesh(allVerts, allFaces, faceClusterIdx, objIdx);
            simplify(singleObjMesh);

            nVerts = size(singleObjMesh.Vertices, 1);
            if nVerts >= max(obj.minVertexNum, 4)
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
    end
end