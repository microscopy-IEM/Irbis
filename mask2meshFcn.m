% Function accepts binary 2D or 3D matrix labled mask (each region has different number)
% Generates mesh by Poisson surface reconstriction for each regoion
% separately and return table filled with generated objects

function T = mask2meshFcn(mask,pixel_size,z_spacing)

    % default paramateres
    padSize = 2;
    sigma = 1.2;
    scaleF = 2;
        

    % pixel_size = 0.0484;
    % z_scaling = 0.115;
    % 
    % pixel_size = 0.03385;
% z_spacing = 0.2;

    isoThres = 0.02;
        
    % 2D mode    
    if size(mask,3) == 1

        % pad the 2d mask matrix to have dimensions X x Y x 3
        padSize = 2;
        mask = padarray(mask,[0,0,padSize],0,'both');  
        mode3D = 0;

    else
        
        mode3D = 1;

    end
    
    regions = regionprops(mask,'Centroid',"FilledImage","BoundingBox")

    regions(1)
    
    nRegions = size(regions,1);
    
    % nRegions = 10;
    
   
    
    % T = app.model.(branch).List{modelId};
    T = getBaseStruct('table','model',nRegions);
       
    
    meshObjInd = 1;
    
    for regInd = 1:nRegions
    
        % get array of pixels defined as bounding box of curren region
        currentRegion = regions(regInd).FilledImage;
        
        % pad current reguion with zeros so there is gradient from edge of array towards the edge of objects 
        v = padarray(currentRegion,[padSize,padSize,padSize],0,'both');  
        v = double(v);

        sz = size(v);

        % size(v)
        
        if mode3D
            % scale to increase numebr of vertices in reconstruction
            v = imresize3(v,scaleF,'method','cubic');
            
            % smooth with gaussian filter to cover "pixel corners"
            v = imgaussfilt3(v,sigma);

        else
            
          
            v(:,:,padSize+1) = imgaussfilt(v(:,:,padSize+1),sigma/2);

                  
            % v = imresize3(v,[scaleF,scaleF,1],'method','cubic');
            v = imresize3(v,[sz(1)*scaleF sz(2)*scaleF 5],'method','cubic');
            % v = imresize3(v,[sz(1)*scaleF sz(2)*scaleF 1],'method','cubic');

        end

        
    
        % run marching cubes to get vertices
        [~,verts] = extractIsosurface(v,isoThres);
            
        % calculate normals
        normals = isonormals(v,verts);
    
        % move the region to its origin position
        % verts = verts + scaleF.*regions(regInd).Centroid;

        dxy = regions(regInd).BoundingBox(1:3);

        verts = verts + scaleF.*dxy - scaleF*padSize - 0.5;

        % verts = verts;

        verts(:,1) = verts(:,1)./scaleF;
        verts(:,2) = verts(:,2)./scaleF;

        if mode3D
            verts(:,3) = verts(:,3)./scaleF;
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
        
        [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(9,pt_vertices,pt_normals,1,1);
        nReg = int8(n_objects);
    
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
            
            if ~mode3D
            vertices(:,3) = vertices(:,3) - mean(vertices(:,3))+z_spacing;
            end
            
            mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
            mesh = smoothSurfaceMesh(mesh,8);
               
            
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