classdef LineIndividualPlot < plot.PlotInterface
    methods
        function plot(~, data, axesHandle)
            groupData = data.groupData;

            xData = data.xData;
            yData = data.yData;
    
            if isempty(groupData)
                xData = permute(xData, [3, 1, 2]);
                yData = permute(yData, [3, 1, 2]);

                plot(axesHandle, xData, yData, '-x'); % plot of multiple lines requires each line in a column - that's why we use permute
                % https://www.mathworks.com/help/matlab/ref/plot.html#btzitot-2
                %   'If the matrix is square, MATLAB plots one line for each column in the matrix.'

                legend(axesHandle, 'off'); % Hide legend
            else
                categoryList = unique(groupData);   % be careful - categories() is a function, so do not use it as variable name

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                hold(axesHandle, 'on');
                for i = 1:numel(categoryList)
                    mask = groupData == categoryList(i);
                    permutedXData = permute(xData(mask, :, :), [3, 1, 2]);
                    permutedYData = permute(yData(mask, :, :), [3, 1, 2]);
                    plotHandle = plot(axesHandle, permutedXData, permutedYData, '-x', ... 
                        'Color', categoryColormap(i, :)); % plot of multiple lines requires each line in a column - that's why we use permute

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i)); 
                end
                hold(axesHandle, 'off');

                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end
            end

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, data.yLabel);
        end
    end
end