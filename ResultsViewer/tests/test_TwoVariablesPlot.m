classdef test_TwoVariablesPlot < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function incompatiblePagedDataClearsPlotWithoutError(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            data = struct();
            data.xData = [1; 2];
            data.yData = cat(3, [10; 20], [30; 40]);
            data.groupData = [];
            data.xLabel = 'summarizedValue';
            data.yLabel = 'pivotedValue';
            data.groupLabel = '';
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();

            % A single summarized column combined with paged pivoted values does
            % not define a valid two-variable scatter pair. The plotter should
            % leave the axes empty instead of surfacing MATLAB's scatter size
            % error to the user.
            testCase.verifyWarningFree(@() plotter.plot(data, axesHandle));
            testCase.verifyEmpty(allchild(axesHandle));
            testCase.verifyEqual(axesHandle.XLabel.String, '');
            testCase.verifyEqual(axesHandle.YLabel.String, '');
        end



        function compatibleVectorDataStillPlots(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            data = struct();
            data.xData = [1; 2; 3];
            data.yData = [10; 20; 30];
            data.groupData = [];
            data.xLabel = 'x';
            data.yLabel = 'y';
            data.groupLabel = '';
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();
            plotter.plot(data, axesHandle);

            testCase.verifyNotEmpty(allchild(axesHandle));
            testCase.verifyEqual(axesHandle.XLabel.String, 'x');
            testCase.verifyEqual(axesHandle.YLabel.String, 'y');
        end



        function numericColorChannelCreatesScatterColorbar(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            data = struct();
            data.xData = [1; 2; 3];
            data.yData = [10; 20; 30];
            data.groupData = [];
            data.colorData = [0.1; 0.5; 0.9];
            data.xLabel = 'x';
            data.yLabel = 'y';
            data.groupLabel = '';
            data.colorLabel = 'intensity';
            data.colorType = "numeric";
            data.colorScope = "point";
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();
            plotter.plot(data, axesHandle);

            colorbars = testCase.findColorbars(fig);

            testCase.verifyNotEmpty(allchild(axesHandle));
            testCase.verifyNotEmpty(colorbars);
            testCase.verifyEqual(string(colorbars(1).Location), "north");
            testCase.verifyEqual(axesHandle.XLabel.String, 'x');
            testCase.verifyEqual(axesHandle.YLabel.String, 'y');
        end



        function numericColorbarDoesNotMoveUIAxes(testCase)
            fig = uifigure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = uiaxes(fig);
            originalPosition = axesHandle.Position;

            data = struct();
            data.xData = [1; 2; 3];
            data.yData = [10; 20; 30];
            data.groupData = [];
            data.colorData = [0.1; 0.5; 0.9];
            data.xLabel = 'x';
            data.yLabel = 'y';
            data.groupLabel = '';
            data.colorLabel = 'intensity';
            data.colorType = "numeric";
            data.colorScope = "point";
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();
            plotter.plot(data, axesHandle);
            drawnow;

            testCase.verifyEqual(axesHandle.Position, originalPosition);
            colorbars = testCase.findColorbars(fig);
            testCase.verifyNotEmpty(colorbars);
            testCase.verifyEqual(string(colorbars(1).Location), "north");
        end



        function scatterDatatipIncludesRowNames(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            data = struct();
            data.xData = [1; 2; 3];
            data.yData = [10; 20; 30];
            data.groupData = [];
            data.rowNames = ["cell_A"; "cell_B"; "cell_C"];
            data.xLabel = 'x';
            data.yLabel = 'y';
            data.groupLabel = '';
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();
            plotter.plot(data, axesHandle);

            scatterHandles = findall(axesHandle, 'Type', 'Scatter');
            testCase.verifyNumElements(scatterHandles, 1);

            rowLabels = string({scatterHandles(1).DataTipTemplate.DataTipRows.Label});
            testCase.verifyTrue(any(rowLabels == "Row"));

            rowDataTip = scatterHandles(1).DataTipTemplate.DataTipRows(rowLabels == "Row");
            testCase.verifyEqual(string(rowDataTip.Value(:)), data.rowNames);
        end



        function groupedScatterDatatipsKeepRowNamesPerGroup(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            data = struct();
            data.xData = [1; 2; 3; 4];
            data.yData = [10; 20; 30; 40];
            data.groupData = categorical(["control"; "treated"; "control"; "treated"]);
            data.rowNames = ["cell_A"; "cell_B"; "cell_C"; "cell_D"];
            data.xLabel = 'x';
            data.yLabel = 'y';
            data.groupLabel = 'condition';
            data.useJitter = false;

            plotter = plot.TwoVariablesPlot();
            plotter.plot(data, axesHandle);

            scatterHandles = findall(axesHandle, 'Type', 'Scatter');
            testCase.verifyNumElements(scatterHandles, 2);

            plottedRowNames = strings(0, 1);
            for scatterIdx = 1:numel(scatterHandles)
                rowLabels = string({scatterHandles(scatterIdx).DataTipTemplate.DataTipRows.Label});
                testCase.verifyTrue(any(rowLabels == "Row"));

                rowDataTip = scatterHandles(scatterIdx).DataTipTemplate.DataTipRows(rowLabels == "Row");
                plottedRowNames = [plottedRowNames; string(rowDataTip.Value(:))]; %#ok<AGROW>
            end

            testCase.verifyEqual(sort(plottedRowNames), sort(data.rowNames));
        end
    end



    methods (Access = private)
        function colorbars = findColorbars(~, fig)
            colorbars = findall(fig, 'Type', 'ColorBar');
            if isempty(colorbars)
                colorbars = findall(fig, 'Type', 'colorbar');
            end
        end
    end
end
