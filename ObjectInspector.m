classdef ObjectInspector < handle
    properties
        fig
        tableList
        parametersToShow
        meshAxes
        paramTable
        plotAxes
        dropdown
        slider
        bottomPanel
        controlPanel
    end

    methods
        function obj = ObjectInspector(tableList, parametersToShow)
            if nargin < 1 || isempty(tableList)
                tableList = {[]};
            end
            if nargin < 2
                parametersToShow = {};
            end
            obj.tableList = tableList;
            obj.parametersToShow = parametersToShow;
            obj.createUI();
            obj.refresh();
        end

        function setTableList(obj, newTableList)
            obj.tableList = newTableList;
            obj.refresh();
        end

        function setParametersToShow(obj, params)
            obj.parametersToShow = params;
            obj.refresh();
        end

        function createUI(obj)
            obj.fig = uifigure('Name', 'Object Inspector', 'Position', [100 100 1200 700]);
            gl = uigridlayout(obj.fig, [2 2]);
            gl.RowHeight = {'1x', 200};
            gl.ColumnWidth = {'2x', '1x'};

            % Mesh axes
            obj.meshAxes = uiaxes(gl);
            obj.meshAxes.Layout.Row = 1;
            obj.meshAxes.Layout.Column = 1;
            axis(obj.meshAxes, 'equal');
            view(obj.meshAxes, 3);
            camlight(obj.meshAxes);
            lighting(obj.meshAxes, 'gouraud');

            % Parameter table
            obj.paramTable = uitable(gl);
            obj.paramTable.Layout.Row = 1;
            obj.paramTable.Layout.Column = 2;
            obj.paramTable.ColumnName = {'Parameter', 'Value', 'Unit'};
            obj.paramTable.CellSelectionCallback = @(src, evt) obj.onTableRowSelected(evt);

            % Bottom panel (plot + controls)
            obj.bottomPanel = uipanel(gl);
            obj.bottomPanel.Layout.Row = 2;
            obj.bottomPanel.Layout.Column = [1 2];
            bottomGL = uigridlayout(obj.bottomPanel, [1 2]);
            bottomGL.ColumnWidth = {'1x', 150};

            obj.plotAxes = uiaxes(bottomGL);
            obj.plotAxes.Layout.Column = 1;

            obj.controlPanel = uipanel(bottomGL);
            obj.controlPanel.Layout.Column = 2;
        end

        function refresh(obj)
            % Remove old controls if they exist
            delete(findall(obj.controlPanel, 'Type', 'uislider'));

            % Determine available parameters
            T = obj.getCurrentTable();
            if isempty(T)
                featureNames = {};
            else
                varNames = T.Properties.VariableNames;
                meshCol = strcmp(varNames, 'Mesh');
                featureNames = varNames(~meshCol);
            end
            % Use parametersToShow if provided, else all
            if isempty(obj.parametersToShow)
                params = featureNames;
            else
                params = intersect(obj.parametersToShow, featureNames, 'stable');
            end

            % Slider for time selection
            nTime = numel(obj.tableList);
            obj.slider = uislider(obj.controlPanel, ...
                'Limits', [1 max(1, nTime)], ...
                'Value', 1, ...
                'MajorTicks', 1:nTime, ...
                'Position', [10 80 120 3]);
            obj.slider.ValueChangedFcn = @(src, evt) obj.onTimeChanged(round(src.Value));

            % Initial draw
            obj.updateMesh(1);
            obj.updateTable(1);
            obj.updatePlot();
        end

        function T = getCurrentTable(obj)
            if isempty(obj.tableList) || isempty(obj.tableList{1})
                T = [];
            else
                T = obj.tableList{1};
            end
        end

        function updateMesh(obj, timeIdx)
            ax = obj.meshAxes;
            cla(ax);
            if isempty(obj.tableList) || isempty(obj.tableList{timeIdx})
                return;
            end
            T = obj.tableList{timeIdx};
            if isempty(T) || ~ismember('Mesh', T.Properties.VariableNames)
                return;
            end
            mesh = T.Mesh{1};
            if isempty(mesh)
                return;
            end
            patch(ax, ...
                'Vertices', mesh.Vertices, ...
                'Faces', mesh.Faces, ...
                'FaceColor', [0.7 0.7 0.8], ...
                'EdgeColor', 'none');
            axis(ax, 'equal');
            view(ax, 3);
            camlight(ax);
            lighting(ax, 'gouraud');
            rotate3d(ax, 'on');
        end

        function updateTable(obj, timeIdx)
            if isempty(obj.tableList) || isempty(obj.tableList{timeIdx})
                obj.paramTable.Data = {};
                return;
            end
            T = obj.tableList{timeIdx};
            if isempty(T)
                obj.paramTable.Data = {};
                return;
            end
            if isempty(obj.parametersToShow)
                varNames = T.Properties.VariableNames;
                meshCol = strcmp(varNames, 'Mesh');
                params = varNames(~meshCol);
            else
                params = intersect(obj.parametersToShow, T.Properties.VariableNames, 'stable');
            end
            units = T.Properties.VariableUnits;
            nVars = numel(params);
            tableData = cell(nVars, 3);
            for i = 1:nVars
                var = params{i};
                val = T.(var)(1);
                if isnumeric(val)
                    valStr = num2str(val);
                elseif iscategorical(val) || isstring(val)
                    valStr = char(val);
                else
                    valStr = '-';
                end
                unitIdx = strcmp(T.Properties.VariableNames, var);
                if ~isempty(units) && any(unitIdx)
                    unitStr = units{unitIdx};
                else
                    unitStr = '';
                end
                tableData{i,1} = var;
                tableData{i,2} = valStr;
                tableData{i,3} = unitStr;
            end
            obj.paramTable.Data = tableData;
        end

        function updatePlot(obj, selectedVar)
            ax = obj.plotAxes;
            cla(ax);
            if nargin < 2 || isempty(selectedVar)
                % Default: plot first parameter if available
                data = obj.paramTable.Data;
                if isempty(data)
                    return;
                end
                selectedVar = data{1,1};
            end
            nTime = numel(obj.tableList);
            values = nan(1, nTime);
            for t = 1:nTime
                T = obj.tableList{t};
                if isempty(T) || ~ismember(selectedVar, T.Properties.VariableNames)
                    continue;
                end
                values(t) = T.(selectedVar)(1);
            end
            plot(ax, 1:nTime, values, '-o', 'LineWidth', 1.5);
            xlabel(ax, 'Time point');
            ylabel(ax, selectedVar);
            title(ax, ['Temporal development: ' selectedVar]);
            grid(ax, 'on');
        end

        function onTableRowSelected(obj, evt)
            if isempty(evt.Indices)
                return;
            end
            row = evt.Indices(1);
            data = obj.paramTable.Data;
            if isempty(data) || row > size(data,1)
                return;
            end
            selectedVar = data{row,1};
            obj.updatePlot(selectedVar);
        end

        function onTimeChanged(obj, timeIdx)
            obj.updateMesh(timeIdx);
            obj.updateTable(timeIdx);
        end
    end
end
