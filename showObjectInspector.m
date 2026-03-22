function fig = showObjectInspector(tableList, objectIdx)
% tableList : cell array of tables (one per timepoint)
% objectIdx : index of object (row) to visualize

    nTime = numel(tableList);

    % --- extract variable names (excluding Mesh)
    varNames = tableList{1}.Properties.VariableNames;
    meshCol = strcmp(varNames, 'Mesh');
    featureNames = varNames(~meshCol);

    % --- figure layout
    fig = uifigure('Name', 'Object Inspector', 'Position', [100 100 1200 700]);

    gl = uigridlayout(fig, [2 2]);
    gl.RowHeight = {'1x', 200};
    gl.ColumnWidth = {'2x', '1x'};

    % --- axes for mesh
    axMesh = uiaxes(gl);
    axMesh.Layout.Row = 1;
    axMesh.Layout.Column = 1;
    axis(axMesh, 'equal');
    view(axMesh, 3);
    camlight(axMesh);
    lighting(axMesh, 'gouraud');

    % --- parameter table
    paramTable = uitable(gl);
    paramTable.Layout.Row = 1;
    paramTable.Layout.Column = 2;
    paramTable.ColumnName = {'Parameter', 'Value', 'Unit'};

    % --- bottom panel (plot + controls)
    bottomPanel = uipanel(gl);
    bottomPanel.Layout.Row = 2;
    bottomPanel.Layout.Column = [1 2];

    bottomGL = uigridlayout(bottomPanel, [1 2]);
    bottomGL.ColumnWidth = {'1x', 150};

    axPlot = uiaxes(bottomGL);
    axPlot.Layout.Column = 1;

    controlPanel = uipanel(bottomGL);
    controlPanel.Layout.Column = 2;

    dd = uidropdown(controlPanel, ...
        'Items', featureNames, ...
        'Position', [10 150 120 30]);

    % inside main function, after dropdown

    slider = uislider(controlPanel, ...
        'Limits', [1 numel(tableList)], ...
        'Value', 1, ...
        'MajorTicks', 1:numel(tableList), ...
        'Position', [10 80 120 3]);

    slider.ValueChangedFcn = @(src, evt) onTimeChanged(fig, round(src.Value));

    data.slider = slider;
    fig.UserData = data;

    % --- store shared state
    data.tableList = tableList;
    data.objectIdx = objectIdx;
    data.featureNames = featureNames;
    data.meshAxes = axMesh;
    data.paramTable = paramTable;
    data.plotAxes = axPlot;
    data.dropdown = dd;

    fig.UserData = data;

    % --- callbacks
    dd.ValueChangedFcn = @(src, evt) updatePlot(fig);

    % --- initial draw
    updateMesh(fig, 1);
    updateTable(fig, 1);
    updatePlot(fig);
end


function updateMesh(fig, timeIdx)

    data = fig.UserData;
    ax = data.meshAxes;

    cla(ax);

    T = data.tableList{timeIdx};
    mesh = T.Mesh{data.objectIdx};

    if isempty(mesh)
        return
    end

    p = patch(ax, ...
        'Vertices', mesh.Vertices, ...
        'Faces', mesh.Faces, ...
        'FaceColor', [0.7 0.7 0.8], ...
        'EdgeColor', 'none');

    axis(ax, 'equal');
    view(ax, 3);
    camlight(ax);
    lighting(ax, 'gouraud');

    % optional rotation interaction
    rotate3d(ax, 'on');
end



function updateTable(fig, timeIdx)

    data = fig.UserData;
    T = data.tableList{timeIdx};

    varNames = data.featureNames;
    units = T.Properties.VariableUnits;

    nVars = numel(varNames);

    tableData = cell(nVars, 3);

    for i = 1:nVars
        var = varNames{i};

        val = T.(var)(data.objectIdx);

        % convert to numeric/string safely
        if isnumeric(val)
            valStr = num2str(val);
        elseif iscategorical(val) || isstring(val)
            valStr = char(val);
        else
            valStr = '-';
        end

        tableData{i,1} = var;
        tableData{i,2} = valStr;
        tableData{i,3} = units{strcmp(T.Properties.VariableNames, var)};
    end

    data.paramTable.Data = tableData;
end



function updatePlot(fig)

    data = fig.UserData;

    ax = data.plotAxes;
    cla(ax);

    selectedVar = data.dropdown.Value;
    nTime = numel(data.tableList);

    values = nan(1, nTime);

    for t = 1:nTime
        T = data.tableList{t};

        if height(T) >= data.objectIdx && ismember(selectedVar, T.Properties.VariableNames)
            values(t) = T.(selectedVar)(data.objectIdx);
        end
    end

    plot(ax, 1:nTime, values, '-o', 'LineWidth', 1.5);

    xlabel(ax, 'Time point');
    ylabel(ax, selectedVar);
    title(ax, ['Temporal development: ' selectedVar]);

    grid(ax, 'on');
end


function onTimeChanged(fig, timeIdx)
    updateMesh(fig, timeIdx);
    updateTable(fig, timeIdx);
end