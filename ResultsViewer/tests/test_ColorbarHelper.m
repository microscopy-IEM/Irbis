classdef test_ColorbarHelper < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function northColorbarPreservesUIAxesPositionAndAddsHeadroom(testCase)
            fig = uifigure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            axesHandle = uiaxes(fig);

            plot(axesHandle, 1:3, [1 2 3]);
            drawnow;

            originalPosition = axesHandle.Position;
            originalYLimits = axesHandle.YLim;

            colorbarHandle = plot.ColorbarHelper.addInsideNorthColorbar(axesHandle, 'intensity');
            drawnow;

            testCase.verifyEqual(string(colorbarHandle.Location), "north");
            testCase.verifyEqual(axesHandle.Position, originalPosition);
            testCase.verifyEqual(axesHandle.YLim(1), originalYLimits(1));
            testCase.verifyGreaterThan(axesHandle.YLim(2), originalYLimits(2));
        end
    end
end
