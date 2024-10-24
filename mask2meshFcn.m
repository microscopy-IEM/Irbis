% Function accepts binary 2D or 3D matrix labled mask (each region has different number)
% Generates mesh by Poisson surface reconstriction for each regoion
% separately and return table filled with generated objects

function T = mask2meshFcn(mask,pixel_size,z_spacing,wb_handle)


    % pixel_size = pixel_size/2;

    % default paramateres
    padSize = 3;
    sigma = 1;
    scaleF = 2;
    isoThres = 0.3;
    depth = 4;

    % wb_handle.Value = 0;

    nd = ndims(mask);

    if nd == 2

        mode = '2D';
        regions = regionprops(mask,'Centroid',"Image","BoundingBox");

    elseif nd == 3
          
        mode = '3D';
        regions = regionprops3(mask,'Centroid',"Image","BoundingBox");
       
    end

    nRegions = size(regions,1);
         
    % TO OPTIMIZE - acces the 
    T = getBaseStruct('table','model',nRegions);
           
    meshObjInd = 1;
    
    for regInd = 1:nRegions

        wb_handle.Value = regInd/nRegions;
        wb_handle.Message = ['Processing ' num2str(regInd) ' of ' num2str(nRegions)];

        % disp(['Processing ' num2str(regInd) ' of ' num2str(nRegions)])
    
        switch mode
            case '3D'

                currentRegion = regions.Image{regInd};
                vol = currentRegion;
                vol = double(vol);
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

                % vol = imgaussfilt3(vol,sigma*2);
                % vol = imgaussfilt(vol,sigma*2); 
                                                 
                % figure(2)
                % nexttile
                % imshow(vol(:,:,padSize+1),[],'InitialMagnification',1000)


        end     
            
        % run marching cubes to get vertices
        [~,verts] = extractIsosurface(vol,isoThres);
            
        % calculate normals
        normals = isonormals(vol,verts);
    
        if isempty(verts)
            disp('Empty verts')
            break
        end
     
        switch mode
            case '3D'

                assignin('base','regions',regions);
                dxyz =  regions.BoundingBox(regInd,1:3);

                verts(:,1) = verts(:,1) - padSize; 
                verts(:,2) = verts(:,2) - padSize; 
                verts(:,3) = verts(:,3) - padSize; 

                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;
                verts(:,3) = verts(:,3)./scaleF;

                % move the region to its origin position
                verts = verts + dxyz - 0.5;

            case '2D'

                regions(regInd).BoundingBox;
                dxyz = regions(regInd).BoundingBox(1:3);
                
                dxyz(:,3) = z_spacing;

                verts(:,1) = verts(:,1) - padSize; 
                verts(:,2) = verts(:,2) - padSize; 

                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;
               
                % move the region to its origin position
                verts = verts + dxyz - 0.5;
                
        end


        % convert to um
        verts(:,1:2) = verts(:,1:2).*pixel_size;
        verts(:,3) = verts(:,3).*z_spacing;

        
        ptCloud = pointCloud(verts);
        ptCloud.Normal = normals;

        % downsample pointCLoud using pixel size

        gridStep = pixel_size/1.5;
        ptCloud = pcdownsample(ptCloud,'gridAverage',gridStep,'PreserveStructure',true);

        verts = double(verts);
                     
        % Run Poisson surface reconstruction in python
        pt_vertices = py.numpy.array(ptCloud.Location);
        pt_normals = py.numpy.array(ptCloud.Normal);
        
        % tic
        
        [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(depth,pt_vertices,pt_normals,1,1);
        nReg = int8(n_objects);
        % disp(['reconstructMesh took ' num2str(toc)])
       

        % tic
        % % mesh = pc2surfacemesh(ptCloud,'poisson',9)
        % disp('matlab')
        % toc
    
        if nReg > 1
            warning('Adaptive reconstruction produced more than 1 objects from current region')
        end
    
        % save mesh if was generated
        if nReg > 0
       
            verticesDict = dictionary(vertices);
            facesDict = dictionary(faces);
            vertexNormalsDict = dictionary(vertex_normals);
            faceNormalsDict = dictionary(face_normals);
            
            regionID = 1;
              
            vertices = double(verticesDict(py.int(regionID)));
            faces = double(facesDict(py.int(regionID)))+1;
            vertexNormals = double(vertexNormalsDict(py.int(regionID)));
            faceNormals = double(faceNormalsDict(py.int(regionID)));
          

            switch mode
                case '3D'
                    
                case '2D'
                    vertices(:,3) = vertices(:,3) - mean(vertices(:,3));
                    vertices(:,3) = vertices(:,3).*0.5;
            end
            
            mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
            mesh = smoothSurfaceMesh(mesh,4);
               
            
            T(meshObjInd,1:11) = {0,verts,{mesh},"S1",0,0,{},{},0,0,{[0,0,0]}};
            T.Properties.RowNames{meshObjInd} = num2str(meshObjInd);
        
            meshObjInd = meshObjInd+1;
    
        end
          
    
    end

    T
    % 
    % % surfaceMeshShow(mesh)
    % c = 'm'
    % figure
    % ax1 = axes;
    % for regInd = 1:nRegions
    %         c = rand(1,3);
    %         % mesh = allMeshes{regInd};
    %         mesh = T.Mesh{regInd};
    %         p = patch(ax1,'Faces',mesh.Faces,'Vertices',mesh.Vertices,'FaceColor',c);
    %         p.LineStyle = 'none';
    %         p.FaceAlpha = 0.6;
    %         hold on
    % 
    % end
    % 
    % axis equal
    % N
    % l1 = light(ax1)

end