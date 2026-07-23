classdef test_LineIndividualPlot < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function numericColorChannelColorsLinesAndCreatesColorbar(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            xData = zeros(3, 1, 3);
            yData = zeros(3, 1, 3);
            for lineIdx = 1:3
                xData(lineIdx, 1, :) = 1:3;
                yData(lineIdx, 1, :) = lineIdx + (0:2);
            end

            data = struct();
            data.xData = xData;
            data.yData = yData;
            data.groupData = [];
            data.colorData = [1; 2; 3];
            data.xLabel = 'timePoint';
            data.yLabel = 'value';
            data.groupLabel = '';
            data.colorLabel = 'intensity';
            data.colorType = "numeric";
            data.colorScope = "line";

            plotter = plot.LineIndividualPlot();
            plotter.plot(data, axesHandle);

            lineHandles = findall(axesHandle, 'Type', 'Line');
            colorbars = testCase.findColorbars(fig);

            testCase.verifyNumElements(lineHandles, 3);
            testCase.verifyNotEqual(lineHandles(1).Color, lineHandles(end).Color);
            testCase.verifyNotEmpty(colorbars);
            testCase.verifyEqual(string(colorbars(1).Location), "north");
            testCase.verifyEqual(axesHandle.XLabel.String, 'timePoint');
            testCase.verifyEqual(axesHandle.YLabel.String, 'value');
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
