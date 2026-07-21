classdef test_PlotManagerState < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function getStateIncludesDialogOwnedPlotSettings(testCase)
            mockApp = MockApp();
            appStateManager = AppStateManager(mockApp);
            fig = uifigure('Visible', 'off');
            cleanup = onCleanup(@() testCase.deleteHandles(fig, appStateManager, mockApp));
            axesHandle = uiaxes(fig);

            plotManager = PlotManager(appStateManager, axesHandle);
            plotManager.setState(struct( ...
                'plotType', 'line: averaged', ...
                'useGrouping', false, ...
                'useIndividual', false, ...
                'useJitter', false, ...
                'lineErrorMetric', "sem", ...
                'lineErrorStyle', "shaded", ...
                'lineColor', [0 0.4470 0.7410], ...
                'lineErrorColor', [0.9 0.9 0.9]));
            plotManager.setPlotSetting('useJitter', true);
            plotManager.setPlotSetting('lineErrorMetric', 'ci95');
            plotManager.setPlotSetting('lineErrorStyle', 'bars');
            plotManager.setPlotSetting('lineColor', [0.1 0.2 0.3]);
            plotManager.setPlotSetting('lineErrorColor', [0.4 0.5 0.6]);

            plotState = plotManager.getState();

            % Stored views should ask PlotManager for state instead of copying
            % selected app controls manually. This protects dialog-owned settings
            % from being omitted whenever new plot options are added.
            testCase.verifyEqual(plotState.plotType, 'line: averaged');
            testCase.verifyTrue(plotState.useJitter);
            testCase.verifyEqual(plotState.lineErrorMetric, "ci95");
            testCase.verifyEqual(plotState.lineErrorStyle, "bars");
            testCase.verifyEqual(plotState.lineColor, [0.1 0.2 0.3]);
            testCase.verifyEqual(plotState.lineErrorColor, [0.4 0.5 0.6]);
        end
    end



    methods (Access = private)
        function deleteHandles(~, fig, appStateManager, mockApp)
            if isa(fig, 'handle') && isvalid(fig)
                delete(fig);
            end

            if isa(appStateManager, 'handle') && isvalid(appStateManager)
                delete(appStateManager);
            end

            if isa(mockApp, 'handle') && isvalid(mockApp)
                delete(mockApp);
            end
        end
    end
end
