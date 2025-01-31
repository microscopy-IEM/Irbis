% Function accepts binary 2D or 3D matrix labled mask (each region has different number)
% Generates mesh by Poisson surface reconstriction for each regoion
% separately and return table filled with generated objects

function T = mask2meshFcn(mask,pixel_size,z_spacing,greyMap,wb_handle)

    % pixel_size = pixel_size/2;

    % default paramateres
    padSize = 4;
    sigma = 2;
    scaleF = 2;
    isoThres = 0.3;
    % dataPrecision = 'single';
    % depth = 4

    % wb_handle.Value = 0;

    nd = ndims(mask);

    if nd == 2

        mode = '2D';
        regions = regionprops(mask,greyMap,'Centroid',"Image","BoundingBox",'MeanIntensity','MaxIntensity');

    elseif nd == 3
          
        mode = '3D';
        regions = regionprops3(mask,greyMap,'Centroid',"Image","BoundingBox",'MeanIntensity','MaxIntensity');
       
    end

    nRegions = size(regions,1);
         
    % TO OPTIMIZE - acces the 
    T = getBaseStruct('table','model',nRegions);

    % Adding feature "mean intensity" to table
    newTabCol = nan(height(T), 1);
    T.meanInt = newTabCol;
    T.maxInt = newTabCol;
           
    meshObjInd = 1;
    
    for regInd = 1:nRegions

        % wb_handle.Value = regInd/nRegions;
        wb_handle.Message = ['Processing ' num2str(regInd) ' of ' num2str(nRegions)];

        % disp(['Processing ' num2str(regInd) ' of ' num2str(nRegions)])
    
        switch mode
            case '3D'

                currentRegion = regions.Image{regInd};
                vol = currentRegion;
                vol = double(vol);
                % regions
                meanInt = regions.MeanIntensity(regInd);
                maxInt = regions.MaxIntensity(regInd);
                % sz = size(vol);

                % scale to increase numebr of vertices in reconstruction
                vol = imresize3(vol,scaleF,'method','linear');

                % pad current reguion with zeros so there is gradient from edge of array towards the edge of objects 
                vol = padarray(vol,[padSize,padSize,padSize],0,'both');  
                                
                % smooth with gaussian filter to cover "pixel corners"
                vol = imgaussfilt3(vol,sigma*2);

            case '2D'

                % z_spacing = 0.0;
                
                z_spacing = 0.75;

                currentRegion = regions(regInd).Image;               
                meanInt = regions(regInd).MeanIntensity;
                maxInt = regions(regInd).MaxIntensity;

                % greyMap(idx{:})
                % f = greyMap(regions(regInd).PixelList)
                % 
                % size(greyMap)

                vol = currentRegion;
                vol = double(vol);
                sz = size(vol);

                vol = imresize(vol,[sz(1)*scaleF sz(2)*scaleF],'method','bilinear');
                               
                % pad current reguion with zeros so there is gradient from edge of array towards the edge of objects 
                vol = padarray(vol,[padSize,padSize,padSize],0,'both'); 

                % figure(2)
                % nexttile
                % imshow(vol(:,:,padSize+1),[],'InitialMagnification',1000)
                
                % blurr only single plane (exclude pad array)
                vol(:,:,padSize+1) = imgaussfilt(vol(:,:,padSize+1),sigma*2); 

                % vol(:,:,padSize:padSize+2) = imgaussfilt3(vol(:,:,padSize:padSize+2),sigma*2); 

                % vol = imgaussfilt3(vol,sigma*2);
                % vol = imgaussfilt(vol,sigma*2); 
                                                 
                % figure(2)
                % nexttile
                % imshow(vol(:,:,padSize+1),[],'InitialMagnification',1000)

        end     
            
        % run marching cubes to get vertices and faces 
        [faces,verts] = extractIsosurface(vol,isoThres);

        % extractIsosurface returns single
        % faces = double(faces);
        % verts = double(verts);
       
            
        % calculate normals
        % normals = isonormals(vol,verts);

        % set all NaN normals to 0
        % normals(isnan(normals)) = 0;

        if isempty(verts)
            disp('Empty verts')
        end
    
        % Continue only if some vertices were extracted
        if ~isempty(verts)
            
                        
            switch mode
                case '3D'
    
                    % assignin('base','regions',regions);
                    dxyz =  regions.BoundingBox(regInd,1:3);
    
                    % revert padding
                    verts(:,1) = verts(:,1) - padSize; 
                    verts(:,2) = verts(:,2) - padSize; 
                    verts(:,3) = verts(:,3) - padSize; 
    
                    % revert scaling
                    verts(:,1) = verts(:,1)./scaleF;
                    verts(:,2) = verts(:,2)./scaleF;
                    verts(:,3) = verts(:,3)./scaleF;
    
                    % move the region to its origin position
                    verts = verts + dxyz - 0.5;
    
                case '2D'
    
                    regions(regInd).BoundingBox;
                    dxyz = regions(regInd).BoundingBox(1:3);
                    
                    dxyz(:,3) = z_spacing;
    
                    % revert padding
                    verts(:,1) = verts(:,1) - padSize; 
                    verts(:,2) = verts(:,2) - padSize; 
    
                    % revert scaling
                    verts(:,1) = verts(:,1)./scaleF;
                    verts(:,2) = verts(:,2)./scaleF;
                   
                    % move the region to its origin position
                    verts = verts + dxyz - 0.5;
                    
            end
        
            % convert vertices to micro-meters
            verts(:,1:2) = verts(:,1:2).*pixel_size;
            verts(:,3) = verts(:,3).*z_spacing;       
                    

            switch mode
                
                case '3D'
    
                    % mesh = surfaceMesh(verts,faces,"VertexNormals",normals);
                    % compute normals for faces
                    % computeNormals(mesh,"face")
                    mesh = surfaceMesh(verts,faces);
                    computeNormals(mesh)
    
                case '2D'
    
                    verts(:,3) = verts(:,3).*0.5;
                    verts(:,3) = verts(:,3) - mean(verts(:,3));
                   
                    % mesh = surfaceMesh(verts,faces);
            
                    % mesh = surfaceMesh(verts,faces,"VertexNormals",normals);
                    % compute normals for faces
                    % computeNormals(mesh,"face")
                    mesh = surfaceMesh(verts,faces);
                    computeNormals(mesh)
                    
                    % mesh = surfaceMesh(verts,faces,"VertexNormals",components.vertexNormals,"FaceNormals",components.faceNormals);
                    % mesh = smoothSurfaceMesh(mesh,2)
    
                    % simplify(mesh,SimplificationMethod="quadric-decimation",TargetNumFaces=100)
                    % simplify(mesh,SimplificationMethod="quadric-decimation",VoxelSize=pixel_size*0.5)
                    % simplify(mesh,SimplificationMethod="quadric-decimation",BoundaryWeight=0.9);
    
                    simplify(mesh,SimplificationMethod="vertex-clustering",VoxelSize=pixel_size)
    
                    % simplify(mesh)
                    removeDefects(mesh,"unreferenced-vertices")
                    % "vertex-clustering"
                    % BoundaryWeight
                    % VoxelSize
                    % mesh
                   
            end
            
            % verts = mesh.Vertices;
            % Not saving points to reduce size
            verts = [];
            % T(meshObjInd,1:11) = {0,verts,{mesh},"S1",0,0,{},{},0,0,{[0,0,0]}};
    
            T(meshObjInd,:) = {0,verts,{mesh},"S1",0,0,{},{},0,0,{[0,0,0]},{[1 0 0]},false,meanInt,maxInt};
            T.Properties.RowNames{meshObjInd} = num2str(meshObjInd);
    
            
            meshObjInd = meshObjInd+1;
    
   
        end

    end

    assignin('base','T',T);

    % normalize intensities for current time point
    T.meanInt = T.meanInt./mean(T.meanInt,"omitmissing");
    T.maxInt = T.maxInt./mean(T.maxInt,"omitmissing");

    % remove empty rows cuased by skipped regions
    nSkipped = nRegions-meshObjInd;
    T(end-nSkipped:end,:) = [];
    

end