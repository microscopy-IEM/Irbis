classdef HistogramLinePlot < plot.PlotInterface
    methods
        function plot(~, data, axesHandle)

            cla(axesHandle,'reset')

            groupData = data.groupData;
            xData = data.xData;

            if isempty(groupData)
                % Create histogram data
                [binCounts, binEdges] = histcounts(xData,'Normalization','pdf');

                % Convert bin edges to bin centers (for x-values)
                binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
                % 
                % % Add optional jitter (set jitter to 0 if no jitter is required)
                % jitter = 0.5;  % Adjust jitter size as needed
                % jitterValues = jitter * randn(size(binCounts));  % Small random noise

                plot(axesHandle, binCenters, binCounts, '-', 'LineWidth', 2);

            else
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                hold(axesHandle, 'on');
                for i = 1:length(categoryList)

                    mask = groupData == categoryList(i);
          
                    [binCounts, binEdges] = histcounts(xData(mask, :, :),'Normalization','pdf');
                    % Convert bin edges to bin centers (for x-values)
                    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
                    % 
                    % % Add optional jitter (set jitter to 0 if no jitter is required)
                    % jitter = 0.5;  % Adjust jitter size as needed
                    % jitterValues = jitter * randn(size(binCounts));  % Small random noise

                    plotHandle = plot(axesHandle, binCenters, binCounts, '-', 'LineWidth', 2, ...
                        'Color', categoryColormap(i, :));         

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i));
                end
                hold(axesHandle, 'off');
                
                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end
            end

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, 'Probability density');
        end
    end
end
