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

        shaftQP = unique(XYZ,'rows');

        % prepare points as input to Python
        ptVertices = py.numpy.array(shaftQP);

        % Calculate normals for dendritic shaft
        nearestVertices = dsearchn(Vplot, shaftQP);
        shaftNorms = shaftQP - Vplot(nearestVertices, :);

        % prepare normals as input to Python
        ptNormals = py.numpy.array(shaftNorms);

        % Initialize the struct with vertices and vertex normals
        mesh_data{1} = struct('vertices', ptVertices, ...
                                'vertexNormals', ptNormals);

        [nObjects, meshCell, ~] = reconstruct_mesh_python(depth,mesh_data,0);

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