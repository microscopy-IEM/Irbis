function T = matlab_generateConstantShaft(T, selectedRowIds, radius)

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

        % assignt normals to dendritic shaft pointCloud
        shaft_ptCloud.Normal = shaftNorms;

        quiver3(shaftQP(:,1), shaftQP(:,2), shaftQP(:,3), shaftNorms(:,1),shaftNorms(:,2), shaftNorms(:,3))

        [dendriticMesh,radii] = pc2surfacemesh(shaft_ptCloud,"poisson")

        isWatertight(dendriticMesh)
        disp(radii)

        T{rowNames(n),'Mesh'} = {dendriticMesh};
        T{rowNames(n),'RadiusScale'} = radius;

    end
    end

end