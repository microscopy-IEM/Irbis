function T = generateConstantShaft(T, selectedRowIds, radius)

    if ~isempty(selectedRowIds)
        rowNames = string(selectedRowIds);
    else
        rowNames = T.Properties.RowNames;
    end   
    for n=1:length(rowNames)

        V = cell2mat(T{rowNames(n),'CentreLine'});

    if ~isempty(V)

        zScaleFactor = cell2mat(T{rowNames(n),'ZScale'});

        seg = 12;
        step = 10;
        depth = 8;

        Vplot = V(1:step:end,:);
        Rplot = radius;

        [X,Y,Z] = tubeplot(Vplot(:,1),Vplot(:,2),Vplot(:,3),Rplot,[],seg,zScaleFactor);

        XYZ = [X(:),Y(:),Z(:)];

        % % drift correction
        % if app.TimeDriftcorrectionCheckBox.Value
        %     XYZ = XYZ + app.model.timeDrift(currentTimePoint,:);
        %     Vplot = Vplot + app.model.timeDrift(currentTimePoint,:);
        % end
        
        shaftQP = unique(XYZ,'rows');

        % prepare points as input to Python
        ptVertices = py.numpy.array(shaftQP);
        % convert dendritic shaft to pointCloud
        shaft_ptCloud = pointCloud(shaftQP);

        shaftQP = shaft_ptCloud.Location;


        % Calculate normals for dendritic shaft
        N = length(shaftQP);
        shaftNorms = nan(size(shaftQP));

        for ind = 1:N

            k = dsearchn(Vplot,shaftQP(ind,:));
            n0 = -(Vplot(k,:))+shaftQP(ind,:); 
            shaftNorms(ind,:) = n0;

        end

        % prepare normals as input to Python
        ptNormals = py.numpy.array(shaftNorms);

        % assignt normals to dendritic shaft pointCloud
        shaft_ptCloud.Normal = shaftNorms;

        % Initialize the struct with vertices and vertex normals
        mesh_data{1} = struct('vertices', ptVertices, ...
                                'vertexNormals', ptNormals);

        [nObjects, meshCell, ~] = reconstruct_mesh_python(depth,mesh_data,0);
        % [~,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(depth,ptVertices,ptNormals,0);

        % regionID = 1;
        % verticesDict = dictionary(vertices);
        % facesDict = dictionary(faces);
        % vertexNormalsDict = dictionary(vertex_normals);
        % faceNormalsDict = dictionary(face_normals);
        % 
        % vertices = double(verticesDict(py.int(regionID)));
        % faces = double(facesDict(py.int(regionID)))+1;
        % vertexNormals = double(vertexNormalsDict(py.int(regionID)));
        % faceNormals = double(faceNormalsDict(py.int(regionID)));
        % 
        % 
        % dendriticMesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
        % 
        % [mesh,radii] = pc2surfacemesh(ptCloudIn,"ball-pivot")

        dendriticMesh = meshCell{1};
        if nObjects > 1
            disp('there is something wrong - more than one shaft is produced')
        end

        T{rowNames(n),'Mesh'} = {dendriticMesh};
        T{rowNames(n),'RadiusScale'} = radius;

    end
    end

end