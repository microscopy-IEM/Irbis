% Function accepts binary 2D or 3D matrix labled mask (each region has different number)
% Generates mesh by Poisson surface reconstriction for each regoion
% separately and return table filled with generated objects

function T = mask2meshFcnCombined(dividedImages,nMasks,pixel_size,z_spacing,wb_handle)


    % pixel_size = pixel_size/2;

    % default paramateres
    padSize = 3;
    sigma = 1;
    scaleF = 2;
    isoThres = 0.3;
    depth = 8;

    % wb_handle.Value = 0;

    nd = ndims(dividedImages{1});

    if nd == 2

        mode = '2D';

    elseif nd == 3
          
        mode = '3D';

    end
         
    % TO OPTIMIZE - acces the 
    T = getBaseStruct('table','model',nMasks+10);
           
    meshObjInd = 0;
    
    for maskImageNum = 1:length(dividedImages)

        % wb_handle.Value = regInd/nRegions;
        wb_handle.Message = ['Processing ' num2str(maskImageNum) ' of ' num2str(length(dividedImages))];

        % disp(['Processing ' num2str(regInd) ' of ' num2str(nRegions)])
    
        switch mode
            case '3D'

                vol = double(dividedImages{maskImageNum});
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

                vol = double(dividedImages{maskImageNum});
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

                verts(:,1) = verts(:,1) - padSize; 
                verts(:,2) = verts(:,2) - padSize; 
                verts(:,3) = verts(:,3) - padSize; 

                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;
                verts(:,3) = verts(:,3)./scaleF;

            case '2D'

                verts(:,1) = verts(:,1) - padSize; 
                verts(:,2) = verts(:,2) - padSize; 

                verts(:,1) = verts(:,1)./scaleF;
                verts(:,2) = verts(:,2)./scaleF;
  
        end


        % convert to um
        verts(:,1:2) = verts(:,1:2).*pixel_size;
        verts(:,3) = verts(:,3).*z_spacing;

        
        ptCloud = pointCloud(verts);
        ptCloud.Normal = normals;

        % downsample pointCLoud using pixel size

        gridStep = pixel_size/1.5;
        ptCloud = pcdownsample(ptCloud,'gridAverage',gridStep,'PreserveStructure',true);
        figure
        quiver3(ptCloud.Location(:,1),ptCloud.Location(:,2),ptCloud.Location(:,3),ptCloud.Normal(:,1)*1000,ptCloud.Normal(:,2)*1000,ptCloud.Normal(:,3)*1000)
        axis equal 

        verts = double(verts);
                     
        % Run Poisson surface reconstruction in python
        pt_vertices = py.numpy.array(ptCloud.Location);
        pt_normals = py.numpy.array(ptCloud.Normal);

        % Initialize the struct with vertices and vertex normals
        mesh_data{1} = struct('vertices', pt_vertices, ...
                                'vertexNormals', pt_normals);
        
        tic
        [nReg, meshCell, components] = reconstruct_mesh_python(depth,mesh_data,1,1);
        disp(['reconstructMesh took ' num2str(toc)])
        disp(['number of meshes produced ' num2str(nReg)])

        % save mesh if was generated
        if nReg > 0

            for id = 1:nReg
                rowNum = id + meshObjInd;

                switch mode
                    case '3D'
                        mesh = meshCell{id};
                        
                    case '2D'
                        componentsUnpacked = components{id};
                        vertices = componentsUnpacked.vertices;
                        vertices(:,3) = vertices(:,3) - mean(vertices(:,3));
                        vertices(:,3) = vertices(:,3).*0.5;
                        mesh = surfaceMesh(vertices,componentsUnpacked.faces,"VertexNormals",componentsUnpacked.vertexNormals,"FaceNormals",componentsUnpacked.faceNormals);
                end
                
                % mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
                mesh = smoothSurfaceMesh(mesh,4);
                   
                
                T(rowNum,1:11) = {0,verts,{mesh},"S1",0,0,{},{},0,0,{[0,0,0]}};
                T.Properties.RowNames{rowNum} = num2str(rowNum);

            end
        
            meshObjInd = meshObjInd+nReg;
    
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