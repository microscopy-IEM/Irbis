classdef HistogramPlot < plot.PlotInterface
    methods
        function plot(~, data, axesHandle)

            cla(axesHandle,'reset')

            groupData = data.groupData;
            xData = data.xData;

            if isempty(groupData)
                hold(axesHandle, 'on');
                histogram(axesHandle, xData);

                % Draw a line showing a threshold 
                if isnumeric(xData)
                    triangleThreshold = threshold.Triangle.compute(xData); % compute threshold and plot it
                    xline(axesHandle, triangleThreshold, 'r--', 'LineWidth', 2, 'Label', ['Triangle Threshold: ' num2str(triangleThreshold)]);
                end

                hold(axesHandle, 'off');
            else
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                hold(axesHandle, 'on');
                for i = 1:numel(categoryList)
                    mask = groupData == categoryList(i); % TO FIX - this does not work if there are numbers in categorical
                    plotHandle = histogram(axesHandle, xData(mask, :, :), ...
                    'FaceColor', categoryColormap(i, :));

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i)); 

                end
                hold(axesHandle, 'off');
                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end
            end

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, 'Counts');
        end
    end
end
