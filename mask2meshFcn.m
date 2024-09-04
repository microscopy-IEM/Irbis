% Function accepts binary 2D or 3D matrix labled mask (each region has different number)
% Generates mesh by Poisson surface reconstriction for each regoion
% separately and return table filled with generated objects

function T = mask2meshFcn(mask,pixel_size,z_spacing)

    % default paramateres
    padSize = 4;
    sigma = 1.5;
    scaleF = 4;
        
    isoThres = 0.3;

    z_spacing = 0.05
        
    % 2D mode  
    nd = ndims(mask);

    if nd == 2

        % pad the 2d mask matrix to have dimensions X x Y x 3
        % padSize = 2;
        % mask = padarray(mask,[0,0,padSize],0,'both');  
   
        mode = '2D';
        regions = regionprops(mask,'Centroid',"Image","BoundingBox");

    elseif nd == 3
          
        mode = '3D';
        regions = regionprops3(mask,'Centroid',"Image","BoundingBox")
        % regions = regionprops3(mask,'Centroid',"ConvexImage","BoundingBox");

    end

        
    % regions = regionprops(mask,'Centroid',"FilledImage","BoundingBox");
    
    
    nRegions = size(regions,1);
    
     
    T = getBaseStruct('table','model',nRegions);
           
    meshObjInd = 1;
    
    for regInd = 1:nRegions

        disp(['Processing ' num2str(regInd) ' of ' num2str(nRegions)])
    
        % get array of pixels defined as bounding box of curren region
        % currentRegion = regions(regInd).ConvexImage;
        % currentRegion = regions(regInd).Image;

        % currentRegion = regions{regInd}.Image;
        % vol = currentRegion;
        % 
        % 
        % vol = double(vol);
        % 
        % sz = size(vol);

        % size(v)

        switch mode
            case '3D'

                currentRegion = regions.Image{regInd}
                vol = currentRegion;
                vol = double(vol);
                sz = size(vol);

                % pad current reguion with zeros so there is gradient from edge of array towards the edge of objects 
                vol = padarray(vol,[padSize,padSize,padSize],0,'both');  

                % scale to increase numebr of vertices in reconstruction
                vol = imresize3(vol,scaleF,'method','cubic');
                
                % smooth with gaussian filter to cover "pixel corners"
                vol = imgaussfilt3(vol,sigma);

            case '2D'

                currentRegion = regions(regInd).Image;
                vol = currentRegion;
                vol = double(vol);
                sz = size(vol);

                % vol = imresize(vol,[sz(1)*scaleF sz(2)*scaleF],'method','bilinear');
                vol = imresize(vol,[sz(1)*scaleF sz(2)*scaleF],'method','nearest');

                vol = padarray(vol,[padSize,padSize,padSize],min(vol,[],"all"),'both'); 

                figure(2)
                nexttile
                % imshow(vol,[],'InitialMagnification',1000)
                imshow(vol(:,:,padSize+1),[],'InitialMagnification',1000)
                % vol = padarray(vol,[0,0,padSize],0,'both');  

                vol(:,:,padSize+1) = imgaussfilt(vol(:,:,padSize+1),sigma*2);
                
                % pad current reguion with zeros so there is gradient from edge of array towards the edge of objects 
                
                 
                 figure(2)
                nexttile
                imshow(vol(:,:,padSize+1),[],'InitialMagnification',1000)


        end     
            
        % run marching cubes to get vertices
        [~,verts] = extractIsosurface(vol,isoThres);
            
        % calculate normals
        normals = isonormals(vol,verts);
    
        % move the region to its origin position
        % verts = verts + scaleF.*regions(regInd).Centroid;

        
        % dxy = regions(regInd).BoundingBox(1:2);
        regions(regInd).BoundingBox;

        % verts = verts*scaleF;

        % verts = verts - padSize;
        % verts = verts - padSize*pixel_size/scaleF;
        % verts = verts - scaleF.*dxy - 0.0;
    

        % verts = verts;

        

        switch mode
            case '3D'
                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;
                verts(:,3) = verts(:,3)./scaleF;

                verts = verts + dxyz - 0.0;

            case '2D'

                dxyz = regions(regInd).BoundingBox(1:3)
                
                dxyz(:,3) = z_spacing;

                verts(:,1) = verts(:,1) - padSize; 
                verts(:,2) = verts(:,2) - padSize; 

                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;

               
                verts = verts + dxyz - 0.5;

                
                
        end

        % verts = mesh.Vertices;

        %     % convert to um
        verts(:,1:2) = verts(:,1:2).*pixel_size;
        verts(:,3) = verts(:,3).*z_spacing;
        
        ptCloud = pointCloud(verts);
        ptCloud.Normal = normals;

        verts = double(verts);
                     
        % Run Poisson surface reconstruction in python
        pt_vertices = py.numpy.array(ptCloud.Location);
        pt_normals = py.numpy.array(ptCloud.Normal);
        
        % tic
        [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(8,pt_vertices,pt_normals,1,1);
        nReg = int8(n_objects);
        % toc

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
                    vertices(:,3) = vertices(:,3) - mean(vertices(:,3))+z_spacing;
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