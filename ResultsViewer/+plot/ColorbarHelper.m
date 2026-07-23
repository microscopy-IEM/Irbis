classdef ColorbarHelper
    methods (Static)
        function colorbarHandle = addInsideNorthColorbar(axesHandle, labelText)
            % Outside colorbars change the axes Position to reserve space.
            % In App Designer that geometry change can be amplified when the window is resized.
            % Keeping plot-owned colorbars inside the axes preserves the UI layout while still showing the continuous color scale.
            plot.ColorbarHelper.expandYLimitsForNorthColorbar(axesHandle);

            colorbarHandle = colorbar(axesHandle, 'north');
            colorbarHandle.Label.String = labelText;
            colorbarHandle.Label.Interpreter = 'none';
        end



        function expandYLimitsForNorthColorbar(axesHandle)
            % A north-inside colorbar overlaps the top of the plotting area.
            % Expanding the y-limits adds visual headroom so data points and line peaks are not hidden underneath it.
            yLimits = axesHandle.YLim;
            if numel(yLimits) ~= 2 || any(~isfinite(yLimits))
                return
            end

            paddingFraction = 0.18;
            if strcmpi(axesHandle.YScale, 'log') && all(yLimits > 0)
                plot.ColorbarHelper.expandLogYLimits(axesHandle, yLimits, paddingFraction);
            else
                plot.ColorbarHelper.expandLinearYLimits(axesHandle, yLimits, paddingFraction);
            end
        end



        function expandLinearYLimits(axesHandle, yLimits, paddingFraction)
            yRange = diff(yLimits);
            if isequal(yRange, 0)
                padding = max(abs(yLimits(2)) * paddingFraction, 1);
            else
                padding = abs(yRange) * paddingFraction;
            end

            if strcmpi(axesHandle.YDir, 'reverse')
                axesHandle.YLim = [yLimits(1) - padding, yLimits(2)];
            else
                axesHandle.YLim = [yLimits(1), yLimits(2) + padding];
            end
        end



        function expandLogYLimits(axesHandle, yLimits, paddingFraction)
            logLimits = log10(yLimits);
            logRange = diff(logLimits);
            if isequal(logRange, 0)
                logPadding = paddingFraction;
            else
                logPadding = abs(logRange) * paddingFraction;
            end

            if strcmpi(axesHandle.YDir, 'reverse')
                axesHandle.YLim = [10.^(logLimits(1) - logPadding), yLimits(2)];
            else
                axesHandle.YLim = [yLimits(1), 10.^(logLimits(2) + logPadding)];
            end
        end
    end
end
