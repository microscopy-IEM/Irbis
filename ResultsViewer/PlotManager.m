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

        requiredParametersNum = 1; % number of parameters required for the plot
    end
    
    methods
        function obj = PlotManager(appStateManagerHandle, axesHandle)
            obj.appStateManagerHandle = appStateManagerHandle;
            % addlistener(appStateManagerHandle, 'newModalityLoaded', @(~, ~) obj.loadNewTableFormatter());   % modality should not change formatter
            addlistener(appStateManagerHandle, 'tableTypeChanged', @(~, ~) obj.loadNewTableFormatter());
            obj.axesHandle = axesHandle;

            [obj.tableProcessorHandles, obj.tableTypes] = appStateManagerHandle.getTableProcessorHandles();

            obj.replaceFormatter();
        end


        function setState(obj, plotState)
            obj.plotType = plotState.plotType;
            obj.useGrouping = plotState.useGrouping;
            obj.useIndividual = plotState.useIndividual;
            obj.findRequiredParametersNum();
            obj.replaceFormatter();
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
            if ~isempty(obj.formatter)
                % disp('Deleting old formatter...');
                delete(obj.formatter);  % this does not work if DataFormatter is not a handle class
            end
            % disp('Replacing formatter...');

            if ~isempty(obj.tableProcessorHandles)
                % assignin("base", 'processor', obj.tableProcessorHandles)
                obj.formatter = DataFormatter(obj, obj.tableProcessorHandles, obj.useGrouping, obj.useIndividual, obj.requiredParametersNum, obj.tableTypes);
                obj.formatter.processData([]);
            else
                % disp('empty')
            end
        end

        function cleanPlot(obj)
            % Clear the plot
            cla(obj.axesHandle);
            xlabel(obj.axesHandle, '');
            ylabel(obj.axesHandle, '');
        end

        function plotData(obj, data)

            plotter = obj.getPlotter();
            cla(obj.axesHandle);

            % TO IMPLEMENT - add an additional processing that would add jitter to the data

            plotter.plot(data, obj.axesHandle);
        end
    end

    methods (Access = private)
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
                    plotter = plot.LineAveragedPlot();
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
    end
end
