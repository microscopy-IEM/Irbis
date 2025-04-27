classdef HistogramWithCDFPlot < plot.PlotInterface
    methods
        function plot(~, data, axesHandle)

            cla(axesHandle,'reset')
            
            groupData = data.groupData;
            xData = data.xData;

            if isempty(groupData)
                yyaxis(axesHandle,'left')
                histogram(axesHandle,xData)

                ylabel(axesHandle, 'Counts')
                yyaxis(axesHandle, 'right')

                histogram(axesHandle, xData, ...
                    'Normalization', 'cdf', 'DisplayStyle', 'stairs', 'LineWidth', 2);

                ylabel(axesHandle, 'Cumulative Probability')
            else
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                yyaxis(axesHandle,'left')
                hold(axesHandle, 'on');
                for i = 1:length(categoryList)
                    mask = groupData == categoryList(i);
                    histogram(axesHandle,xData(mask, :, :), 'FaceColor', categoryColormap(i, :))
                end

                ylabel(axesHandle, 'Counts')
                yyaxis(axesHandle, 'right')

                for i = 1:length(categoryList)
                    mask = groupData == categoryList(i);
                    plotHandle = histogram(axesHandle, xData(mask, :, :), ...
                        'Normalization', 'cdf','DisplayStyle', 'stairs', 'LineWidth', 2, 'EdgeColor', categoryColormap(i, :));
                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i)); 
                end
                hold(axesHandle, 'off');
                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end

                ylabel(axesHandle, 'Cumulative Probability')
            end
        end
    end
end