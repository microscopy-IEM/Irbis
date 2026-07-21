classdef LineAveragedPlot < plot.PlotInterface
    properties (Access = private)
        errorMetric = "sem"
        errorStyle = "shaded"
        lineColor = [0 0.4470 0.7410]
        errorColor = [0.9 0.9 0.9]
    end

    methods
        function obj = LineAveragedPlot(options)
            if nargin < 1 || isempty(options)
                return
            end

            if isfield(options, 'errorMetric')
                obj.errorMetric = lower(string(options.errorMetric));
            end

            if isfield(options, 'errorStyle')
                obj.errorStyle = lower(string(options.errorStyle));
            end

            if isfield(options, 'lineColor')
                obj.lineColor = plot.LineAveragedPlot.normalizeColor(options.lineColor);
            end

            if isfield(options, 'errorColor')
                obj.errorColor = plot.LineAveragedPlot.normalizeColor(options.errorColor);
            end
        end

        function plot(obj, data, axesHandle)
            groupData = data.groupData;

            xData = data.xData;
            yData = data.yData;

            if ~isnumeric(xData) || ~isnumeric(yData)
                % Use allchild because previous shaded error patches may have
                % been hidden from normal handle discovery in older plot states.
                delete(allchild(axesHandle));
                xlabel(axesHandle, '');
                ylabel(axesHandle, '');
                legend(axesHandle, 'off');
                return
            end
    
            if isempty(groupData)
                [meanX, meanY, errorY] = obj.computeLineStatistics(xData, yData);
                obj.plotLineWithError(axesHandle, meanX, meanY, errorY, obj.lineColor, obj.errorColor);
                plottedX = meanX;

            else
                categoryList = unique(groupData);
                plottedX = [];

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                hold(axesHandle, 'on');
                for i = 1:numel(categoryList)
                    mask = groupData == categoryList(i);
                    groupXData = xData(mask, :, :);  % problem here - we overwrite the xData and then use it again in the next iteration
                    groupYData = yData(mask, :, :);

                    [meanX, meanY, errorY] = obj.computeLineStatistics(groupXData, groupYData);
                    plotHandle = obj.plotLineWithError(axesHandle, meanX, meanY, errorY, categoryColormap(i, :), categoryColormap(i, :));
                    plottedX = [plottedX, meanX]; %#ok<AGROW>

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i)); 

                end
                hold(axesHandle, 'off');

                if ~isempty(legendNames)
                    legend(axesHandle, legendHandles, legendNames, 'Location', 'best'); 
                end
            end

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, data.yLabel);
            obj.formatXAxisForData(axesHandle, plottedX);
        end

    end
    methods (Access = private)
        function [meanX, meanY, errorY] = computeLineStatistics(obj, xData, yData)
            meanX = mean(xData, 1, 'omitmissing'); % TO OPTIMIZE - make sure this is what we want
                % we might instead want to use the length of the xData
            meanX = plot.LineAveragedPlot.toRowVector(meanX);  % required by fill/errorbar functions

            meanY = mean(yData, 1, 'omitmissing');
            meanY = plot.LineAveragedPlot.toRowVector(meanY);

            stdY = std(yData, 0, 1, 'omitmissing');
            n = sum(~ismissing(yData), 1);

            switch obj.errorMetric
                case {"std", "standard deviation"}
                    errorY = stdY;
                case {"sem", "standard error"}
                    errorY = stdY ./ sqrt(n);
                case {"ci95", "ci", "95ci", "95% ci", "confidence interval"}
                    errorY = 1.96 .* stdY ./ sqrt(n);
                case {"none", "off"}
                    errorY = [];
                    return
                otherwise
                    errorY = stdY;
            end

            errorY = plot.LineAveragedPlot.toRowVector(errorY);
            errorY(~isfinite(errorY)) = 0;
        end

        function plotHandle = plotLineWithError(obj, axesHandle, meanX, meanY, errorY, lineColor, errorColor)
            hold(axesHandle, 'on');

            switch obj.errorStyle
                case {"bars", "bar", "errorbar", "errorbars"}
                    if isempty(errorY)
                        plotHandle = plot(axesHandle, meanX, meanY, '-x', 'Color', lineColor, 'LineWidth', 2);
                    else
                        plotHandle = errorbar(axesHandle, meanX, meanY, errorY, '-x', 'Color', lineColor, 'LineWidth', 2);
                    end
                otherwise
                    if ~isempty(errorY)
                        plot.LineAveragedPlot.plotErrorShade(axesHandle, meanX, meanY, errorY, errorColor);
                    end
                    plotHandle = plot(axesHandle, meanX, meanY, '-x', 'Color', lineColor, 'LineWidth', 2);
            end

            hold(axesHandle, 'off');
        end

        function formatXAxisForData(~, axesHandle, plottedX)
            % Error bars at the first and last x values need a little horizontal
            % breathing room. MATLAB's automatic ticks can also create more labels
            % than there are x data points, which makes sparse line plots look more
            % precise than the data actually are.
            plottedX = plottedX(:);
            plottedX = plottedX(isfinite(plottedX));

            if isempty(plottedX)
                return
            end

            uniqueX = unique(plottedX, 'stable');
            minX = min(uniqueX);
            maxX = max(uniqueX);

            if isequal(minX, maxX)
                padding = max(abs(minX) * 0.05, 0.5);
            else
                padding = 0.03 * (maxX - minX);
            end

            xlim(axesHandle, [minX - padding, maxX + padding]);

            % currentTicks = axesHandle.XTick;
            % if numel(currentTicks) > numel(uniqueX)
            %     axesHandle.XTick = sort(uniqueX);
            % end
        end
    end

    methods (Static, Access = private)
        function plotErrorShade(axesHandle, meanX, meanY, errorY, color)

            upperY = meanY + errorY;
            lowerY = meanY - errorY;

            % Find valid indices where data is not NaN
            validIdx = ~isnan(upperY) & ~isnan(lowerY) & ~isnan(meanX);

            % Find start/end of contiguous valid regions
            d = diff([false, validIdx, false]);
            segmentStarts = find(d == 1);
            segmentEnds = find(d == -1) - 1;

            % Plot each valid segment
            for seg = 1:numel(segmentStarts)
                idx = segmentStarts(seg):segmentEnds(seg);

                xSegment = meanX(idx);
                yUpper = upperY(idx);
                yLower = lowerY(idx);

                fillX = [xSegment, fliplr(xSegment)];
                fillY = [yUpper, fliplr(yLower)];

                fillHandle = fill(axesHandle, fillX, fillY, ...
                    color, 'EdgeColor', 'none', 'FaceAlpha', 0.3);

                % Keep the patch out of the legend without making it invisible
                % to axes cleanup. Hidden handles are easy to accidentally leave
                % behind during redraws, which makes the shade stack brighter.
                fillHandle.Annotation.LegendInformation.IconDisplayStyle = 'off';
            end

        end

        function color = normalizeColor(color)
            color = double(color);
            if ~isnumeric(color) || numel(color) ~= 3
                error('LineAveragedPlot:InvalidColor', 'Line colors must be RGB triplets.');
            end

            color = reshape(color, 1, 3);
            color = min(max(color, 0), 1);
        end

        function rowVector = toRowVector(values)
            % Statistics can arrive as 1-by-N, 1-by-1-by-N, or scalar arrays
            % depending on whether the formatter supplied 2-D or paged data.
            % Plotting and shaded-error construction expect simple row vectors.
            rowVector = squeeze(values);
            rowVector = rowVector(:).';
        end
    end
end
