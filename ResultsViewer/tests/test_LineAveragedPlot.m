classdef test_LineAveragedPlot < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function xAxisHasMarginAndNoExtraTicks(testCase)
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = axes(fig);

            plotter = plot.LineAveragedPlot();
            data = struct();
            data.groupData = [];
            data.xData = [1, 2, 3; 1, 2, 3];
            data.yData = [2, 4, 6; 3, 5, 7];
            data.xLabel = 'timePoint';
            data.yLabel = 'Value';

            plotter.plot(data, axesHandle);

            % The first and last x values should not sit directly on the axes
            % edge, otherwise error-bar caps at the boundaries are easy to clip.
            testCase.verifyLessThan(axesHandle.XLim(1), 1);
            testCase.verifyGreaterThan(axesHandle.XLim(2), 3);

            % Sparse line plots should not display more x tick labels than the
            % number of actual x positions represented by the data.
            testCase.verifyLessThanOrEqual(numel(axesHandle.XTick), 3);
        end
    end
end
