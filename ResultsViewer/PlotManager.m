classdef PlotManager < handle
    properties (Access = private)
        tableProcessorHandles
        tableTypes
        appStateManagerHandle       % the plotManager will listen, whether there are some changes in app state
        axesHandle
        formatter DataFormatter
        plotType = 'histogram';

        useGrouping = false
        useIndividual = false
        useJitter = false
        lineErrorMetric = "sem"
        lineErrorStyle = "shaded"
        lineColor = [0 0.4470 0.7410]
        lineErrorColor = [0.9 0.9 0.9]

        requiredParametersNum = 1; % number of parameters required for the plot
        lastPlotData = []
    end
    
    methods
        function obj = PlotManager(appStateManagerHandle, axesHandle)
            obj.appStateManagerHandle = appStateManagerHandle;
            % addlistener(appStateManagerHandle, 'newModalityLoaded', @(~, ~) obj.loadNewTableFormatter());   % modality should not change formatter
            addlistener(appStateManagerHandle, 'tableTypeChanged', @(~, ~) obj.loadNewTableFormatter());
            obj.axesHandle = axesHandle;

            [obj.tableProcessorHandles, obj.tableTypes] = appStateManagerHandle.getTableProcessorHandles();

            obj.replaceFormatter();

            obj.setDefaultInterpreterForAxes();
        end


        function setState(obj, plotState)
            obj.plotType = plotState.plotType;
            obj.useGrouping = plotState.useGrouping;
            obj.useIndividual = plotState.useIndividual;
            if isfield(plotState, 'useJitter')
                obj.useJitter = plotState.useJitter;
            end
            if isfield(plotState, 'lineErrorMetric')
                obj.lineErrorMetric = string(plotState.lineErrorMetric);
            end
            if isfield(plotState, 'lineErrorStyle')
                obj.lineErrorStyle = string(plotState.lineErrorStyle);
            end
            if isfield(plotState, 'lineColor')
                obj.lineColor = obj.normalizeColor(plotState.lineColor);
            end
            if isfield(plotState, 'lineErrorColor')
                obj.lineErrorColor = obj.normalizeColor(plotState.lineErrorColor);
            end
            obj.findRequiredParametersNum();
            obj.replaceFormatter();
        end

        function plotState = getState(obj)
            % Return every plot option needed to recreate the current plot view.
            % App Designer should store this struct directly instead of rebuilding
            % plotState from individual UI controls; otherwise newer dialog-owned
            % settings such as errorMetric, errorStyle, and colors are easy to
            % forget when saving a stored view.
            plotState = struct();
            plotState.plotType = obj.plotType;
            plotState.useGrouping = obj.useGrouping;
            plotState.useIndividual = obj.useIndividual;
            plotState.useJitter = obj.useJitter;
            plotState.lineErrorMetric = obj.lineErrorMetric;
            plotState.lineErrorStyle = obj.lineErrorStyle;
            plotState.lineColor = obj.lineColor;
            plotState.lineErrorColor = obj.lineErrorColor;
        end

        function turnGroupingUseOn(obj)
            obj.useGrouping = true;
            obj.formatter.turnGroupingUseOn();
        end

        function turnGroupingUseOff(obj)
            obj.useGrouping = false;
            obj.formatter.turnGroupingUseOff();
        end

        function turnIndividualUseOn(obj)
            obj.useIndividual = true;
            obj.formatter.turnIndividualUseOn();
        end
        
        function turnIndividualUseOff(obj)
            obj.useIndividual = false;
            obj.formatter.turnIndividualUseOff();
        end

        function turnJitterOn(obj)
            % Keep the legacy app callbacks working while routing all jitter
            % updates through the same setting path used by the settings dialog.
            obj.setUseJitter(true);
        end

        function turnJitterOff(obj)
            % Keep the legacy app callbacks working while routing all jitter
            % updates through the same setting path used by the settings dialog.
            obj.setUseJitter(false);
        end

        function setLineErrorMetric(obj, metric)
            obj.lineErrorMetric = string(metric);
            obj.redrawLastPlot();
        end

        function setLineErrorStyle(obj, style)
            obj.lineErrorStyle = string(style);
            obj.redrawLastPlot();
        end

        function settings = getPlotSettings(obj)
            % Expose plot rendering settings as a plain struct so UI code can
            % build controls without reaching into PlotManager internals.
            settings = struct();
            settings.useJitter = obj.useJitter;
            settings.lineErrorMetric = obj.lineErrorMetric;
            settings.lineErrorStyle = obj.lineErrorStyle;
            settings.lineColor = obj.lineColor;
            settings.lineErrorColor = obj.lineErrorColor;
        end

        function setPlotSetting(obj, name, value)
            % Central dispatch keeps the dialog generic: it only needs setting
            % names, while PlotManager remains responsible for side effects such
            % as redrawing cached data or updating DataFormatter state.
            switch lower(string(name))
                case "usejitter"
                    obj.setUseJitter(value);
                case "lineerrormetric"
                    obj.setLineErrorMetric(value);
                case "lineerrorstyle"
                    obj.setLineErrorStyle(value);
                case "linecolor"
                    obj.setLineColor(value);
                case "lineerrorcolor"
                    obj.setLineErrorColor(value);
                otherwise
                    error('PlotManager:UnknownPlotSetting', 'Unknown plot setting: %s', string(name));
            end
        end

        function dialog = openPlotSettingsDialog(obj, parentFigure)
            % App Designer code can call this one method from a toolbar/button
            % callback. PlotManager owns the settings, while PlotSettingsDialog
            % owns the UI that edits them.
            if nargin < 2
                parentFigure = [];
            end

            dialog = PlotSettingsDialog.show(parentFigure, obj);
        end

        function changePlotType(obj, plotType)
            obj.plotType = plotType;
            obj.findRequiredParametersNum();
            obj.formatter.setRequiredParametersNum(obj.requiredParametersNum);
        end

        function findRequiredParametersNum(obj)
            switch obj.plotType
                case {'histogram', 'stacked histogram', 'histogram with cdf', 'line histogram', 'ratio bar plot'}
                    obj.requiredParametersNum = 1;
                case 'two variables'
                    obj.requiredParametersNum = 2;
                case {'line: individual', 'line: averaged'}
                    obj.requiredParametersNum = 1;
                case 'radial density histogram'
                    obj.requiredParametersNum = 1;
                otherwise
                    error('Unsupported plot type.');
            end
        end

        function replaceFormatter(obj)
            obj.cleanPlot();
            obj.lastPlotData = [];
            if ~isempty(obj.formatter)
                % disp('Deleting old formatter...');
                delete(obj.formatter);  % this does not work if DataFormatter is not a handle class
            end
            % disp('Replacing formatter...');

            if ~isempty(obj.tableProcessorHandles)
                % assignin("base", 'processor', obj.tableProcessorHandles)
                obj.formatter = DataFormatter(obj, obj.tableProcessorHandles, obj.useGrouping, obj.useIndividual, obj.useJitter, obj.requiredParametersNum, obj.tableTypes);
                obj.formatter.processData([]);
            else
                % disp('empty')
            end
        end

        function cleanPlot(obj)
            % Clear every child, including objects with HandleVisibility='off'.
            % This matters for shaded error regions: they are not legend entries,
            % but they still must be removed on every redraw when settings change.
            delete(allchild(obj.axesHandle));
            xlabel(obj.axesHandle, '');
            ylabel(obj.axesHandle, '');

            % Turn of formatting of the text, to prevent _ from being interpreted as subscript
            % set(obj.axesHandle, 'TickLabelInterpreter', 'none');
            % set(obj.axesHandle, 'legend', 'Interpreter', 'none');
            % set(obj.axesHandle, 'Title', 'Interpreter', 'none');
            % set(obj.axesHandle, 'XLabel', 'Interpreter', 'none');
            % set(obj.axesHandle, 'YLabel', 'Interpreter', 'none');
        end

        function plotData(obj, data)
            obj.lastPlotData = data;
            obj.renderData(data);
        end
    end

    methods (Access = private)
        function setUseJitter(obj, useJitter)
            obj.useJitter = logical(useJitter);

            if isempty(obj.formatter)
                return
            end

            if obj.useJitter
                obj.formatter.turnJitterOn();
            else
                obj.formatter.turnJitterOff();
            end
        end

        function setLineColor(obj, color)
            obj.lineColor = obj.normalizeColor(color);
            obj.redrawLastPlot();
        end

        function setLineErrorColor(obj, color)
            obj.lineErrorColor = obj.normalizeColor(color);
            obj.redrawLastPlot();
        end

        function redrawLastPlot(obj)
            if isempty(obj.lastPlotData)
                return
            end

            obj.renderData(obj.lastPlotData);
        end

        function renderData(obj, data)

            plotter = obj.getPlotter();
            % cla(obj.axesHandle);
            obj.cleanPlot();

            % TO IMPLEMENT - add an additional processing that would add jitter to the data

            plotter.plot(data, obj.axesHandle);
        end

        function plotter = getPlotter(obj)
            switch obj.plotType
                case 'histogram'
                    plotter = plot.HistogramPlot();
                case 'stacked histogram'
                    plotter = plot.HistogramStackedPlot();
                case 'histogram with cdf'
                    plotter = plot.HistogramWithCDFPlot();
                case 'line histogram'
                    plotter = plot.HistogramLinePlot();
                case 'two variables'
                    plotter = plot.TwoVariablesPlot();
                case 'line: individual'
                    plotter = plot.LineIndividualPlot();
                case 'line: averaged'
                    options = struct( ...
                        'errorMetric', obj.lineErrorMetric, ...
                        'errorStyle', obj.lineErrorStyle, ...
                        'lineColor', obj.lineColor, ...
                        'errorColor', obj.lineErrorColor);
                    plotter = plot.LineAveragedPlot(options);
                case 'radial density histogram'
                    plotter = plot.RadialDensityHistogramPlot();
                case 'ratio bar plot'
                    plotter = plot.RatioBarPlot();
                otherwise
                    error('Unsupported plot type.');
            end
        end

        function loadNewTableFormatter(obj)
            % Load new table store and update the plot
            % disp('Loading new table store...');
            [obj.tableProcessorHandles, obj.tableTypes] = obj.appStateManagerHandle.getTableProcessorHandles();
            % disp(obj.tableProcessorHandles);
            % disp(class(obj.tableProcessorHandles));
            obj.replaceFormatter(); % Recreate formatter with the new table store
        end


        
        function setDefaultInterpreterForAxes(~)
            % Set the default interpreter for axes to 'none' to prevent underscores from being interpreted as subscripts
            set(groot, 'defaultAxesTickLabelInterpreter', 'none')
            set(groot, 'defaultTextInterpreter', 'none')
            set(groot, 'defaultLegendInterpreter', 'none')
            set(groot, 'defaultColorbarTickLabelInterpreter', 'none')
        end

        function color = normalizeColor(~, color)
            % Color pickers return numeric RGB triplets, but keeping this guard
            % here protects PlotManager if a future UI sends string/cell values.
            color = double(color);
            if ~isnumeric(color) || numel(color) ~= 3
                error('PlotManager:InvalidColor', 'Plot colors must be RGB triplets.');
            end

            color = reshape(color, 1, 3);
            color = min(max(color, 0), 1);
        end
    end
end
