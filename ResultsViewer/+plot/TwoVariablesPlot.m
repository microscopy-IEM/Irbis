classdef TwoVariablesPlot < plot.PlotInterface
    methods
        function plot(obj, data, axesHandle)

            cla(axesHandle,'reset')

            xData = data.xData;
            yData = data.yData;

            
            
            if isnumeric(xData) && isnumeric(yData)
                % Check if both xData and yData are numeric
                obj.plotScatter(data, axesHandle);
            elseif xor(iscategorical(xData), iscategorical(yData))
                % Check if one of them is categorical
                obj.plotBoxplot(data, axesHandle);
            elseif iscategorical(xData) && iscategorical(yData)
                % Check if both xData and yData are categorical
                obj.plotCategoricalScatter(data, axesHandle);
            else
                error('Invalid data types for xData and yData. Both must be numeric or categorical, or one must be categorical and the other numeric.');
            end
            
            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, data.yLabel);
            
    
            % if isempty(groupData)
            %     scatter(axesHandle, data.xData, data.yData);
            % else
            %     categoryList = unique(groupData);
            %     hold(axesHandle, 'on');
            %     for i = 1:numel(categoryList)
            %         mask = groupData == categoryList(i);
            %         scatter(axesHandle, data.xData(mask, :, :), data.yData(mask, :, :), 'DisplayName', char(categoryList(i)));
            %     end
            %     hold(axesHandle, 'off');
            %     legend(axesHandle, 'show');
            % end

            % xlabel(axesHandle, data.xLabel);
            % ylabel(axesHandle, data.yLabel);
        end
    end


    methods (Access = private)
        function plotScatter(~, data, axesHandle)

            xData = data.xData;
            yData = data.yData;
            groupData = data.groupData;

            if isempty(groupData)
                scatter(axesHandle, xData, yData);
            else
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                hold(axesHandle, 'on');
                for i = 1:numel(categoryList)
                    mask = groupData == categoryList(i);
                    plotHandle = scatter(axesHandle, xData(mask, :, :), yData(mask, :, :), ...
                    'Color', categoryColormap(i, :));

                    legendHandles(i) = plotHandle(1); 
                    legendNames{i} = char(categoryList(i));
                end
                hold(axesHandle, 'off');
                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end
            end

        end

        function plotBoxplot(~, data, axesHandle)

            xData = data.xData;
            yData = data.yData;
            groupData = data.groupData;

            % SK
            % data
            

            % Decide, which of the columns is categorical
            if iscategorical(xData)
                categoricalData = xData;
                numericalData = yData;
            elseif iscategorical(yData)
                categoricalData = yData;
                numericalData = xData;
            else
                error('Neither xData nor yData is categorical.')
            end

            if isempty(groupData)
                numericalData = permute(numericalData, [1, 3, 2]);  % D3 potentially contains vector data - must be as columns
                categoricalData = permute(categoricalData, [1, 3, 2]); 

                % boxplot(axesHandle, numericalData, categoricalData)   % X is numeric and g is categorical

                boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.1,'JitterOutliers','on');

                % https://www.mathworks.com/help/stats/boxplot.html#bu180jd-2
                %    If x is a matrix, boxplot plots one box for each column of x.
                %    If x is a matrix, then the grouping variables must contain one row for each column of x.

                % Code for R2025a
                % ver = matlabRelease.Release;

                % tf = ~isMATLABReleaseOlderThan("R2025a")

                if ~isMATLABReleaseOlderThan("R2025a")

                    % boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.3,'BoxFaceColor','k','MarkerColor','k','MarkerStyle','.','JitterOutliers','on');

                    boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.3,'MarkerStyle','.','JitterOutliers','on');
                    axesHandle.NextPlot = 'add';

                    axData = axesHandle.UserData
                    
                    % violinplot(axesHandle, categoricalData, numericalData)
                    % axesHandle.NextPlot = 'replace';

                    axesHandle.UserData = data;

                    axData = axesHandle.UserData
                    999

                end

                
            else
                numericalData = permute(numericalData, [1, 3, 2]);  % D3 potentially contains vector data - must be as columns
                % if this is a matrix, it cannot be combined with yData!
                categoricalData = permute(categoricalData, [1, 3, 2]); 
                groupData = permute(groupData, [1, 3, 2]);

                boxchart(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData);

                 % https://www.mathworks.com/help/matlab/ref/boxchart.html
                %    ydata must be a vector, and cgroupdata must have the same length as ydata
                %    you cannot specify xgroupdata when ydata is a matrix.
                
                
                % Code for R2025a
                % ver = matlabRelease.Release;

                if ~isMATLABReleaseOlderThan("R2025a")

                    axesHandle.UserData = data;

                    axData = axesHandle.UserData

                    % numericalData = log10(numericalData);
                
                    % boxchart(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData,'BoxWidth',0.3,'BoxFaceColor','k','MarkerColor','k','MarkerStyle','.','JitterOutliers','on');
                    b = boxchart(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData,'BoxWidth',0.3,'MarkerStyle','.','JitterOutliers','on');
                    
                    axesHandle.NextPlot = 'add';                    
                    
                    % v = violinplot(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData);
                    
                    axesHandle.NextPlot = 'replace';

                    legendGroups = unique(groupData);
                    % legend(axesHandle, b, legendGroups, 'Location', 'best');
                    l = legend(axesHandle, b, legendGroups, 'Location', 'northeast');
                    l.Title.String = data.groupLabel;
                    l.Title.Interpreter = 'none';

                    
                    

                end
               
            end
        end

        function plotCategoricalScatter(~, data, axesHandle)
            xData = data.xData;
            yData = data.yData;
            groupData = data.groupData;

            axesHandle.UserData = data;

            % xCategories = unique(xData);
            % yCategories = unique(yData);
            
            % % Initialize the counts matrix
            % counts = zeros(length(xCategories), length(yCategories));
            
            % % Count occurrences of each combination of categories
            % for i = 1:length(xCategories)
            %     for j = 1:length(yCategories)
            %         % Count occurrences where xData is uniqueX(i) and yData is uniqueY(j)
            %         counts(i, j) = sum((xData == xCategories(i)) & (yData == yCategories(j)));
            %     end
            % end
            
            % % Create x, y, and size data for the bubble plot
            % [xGrid, yGrid] = meshgrid(1:length(yCategories), 1:length(xCategories));
            % xGrid = xGrid(:);
            % yGrid = yGrid(:);
            % sizes = counts(:);
            
            % % Remove zero counts to avoid plotting them
            % nonZeroIdx = sizes > 0;
            % xGridNonZero = xGrid(nonZeroIdx);
            % yGridNonZero = yGrid(nonZeroIdx);
            
            % % Optional: Scale the sizes to avoid bubbles being too large
            % scaledSizes = sizes(nonZeroIdx);  % Adjust factor as needed for better visualization
            
            % % Adjust the grid points to create spacing and ensure bubbles are not on the edges
            % xGridNonZero = xGridNonZero + 0.5;  % Offset x coordinates for better spacing
            % yGridNonZero = yGridNonZero + 0.5;  % Offset y coordinates for better spacing
            
            % % Create the bubble plot in axesHandle using scatter
            % scatter(axesHandle, xGridNonZero, yGridNonZero, scaledSizes, 'filled');
            
            % % Customize axes labels and ticks for categorical representation
            % set(axesHandle, 'XTick', 1.5:length(yCategories) + 0.5, 'XTickLabel', yCategories);
            % set(axesHandle, 'YTick', 1.5:length(xCategories) + 0.5, 'YTickLabel', xCategories);
            % grid(axesHandle, 'on');
            
            % % Adjust axis limits to provide some additional space around the plot
            % xlim(axesHandle, [0.5, length(yCategories) + 1]);
            % ylim(axesHandle, [0.5, length(xCategories) + 1]);

            xCats = unique(xData);
            yCats = unique(yData);

            xIdx = double(xData);
            yIdx = double(yData);

            if isempty(groupData)

                counts = accumarray([xIdx(:), yIdx(:)], 1, ...
                    [length(xCats), length(yCats)]);
                sizes = counts(:);

                [xGrid, yGrid] = meshgrid(1:length(yCats), 1:length(xCats));
                xPlot = xGrid(:) + 0.5;
                yPlot = yGrid(:) + 0.5;

                scatter(axesHandle, xPlot, yPlot, sizes(:), 'LineWidth', 2);
            else

                groupCats = unique(groupData);
                gIdx = double(groupData);

                counts = accumarray([xIdx, yIdx, gIdx], 1, ...
                    [length(xCats), length(yCats), length(groupCats)]);

                categoryColormap = lines(length(groupCats));
                hold(axesHandle, 'on');
    
                for g = 1:length(groupCats)
                    groupCount = counts(:, :, g);
                    
                    [xGrid, yGrid] = meshgrid(1:length(yCats), 1:length(xCats));
                    xPlot = xGrid(:) + 0.5;
                    yPlot = yGrid(:) + 0.5;
                    sizePlot = groupCount(:);
                    
                    nonZero = sizePlot > 0;
                    
                    scatter(axesHandle, ...
                        xPlot(nonZero), yPlot(nonZero), ...
                        sizePlot(nonZero), ...
                        'MarkerEdgeColor', categoryColormap(g, :), 'LineWidth', 2);
                end

                legend(axesHandle, groupCats, 'Location', 'best');

            end

            set(axesHandle, 'XTick', 1.5:length(yCats)+0.5, 'XTickLabel', yCats);
            set(axesHandle, 'YTick', 1.5:length(xCats)+0.5, 'YTickLabel', xCats);
            xlim(axesHandle, [0.5, length(yCats)+1]);
            ylim(axesHandle, [0.5, length(xCats)+1]);
            grid(axesHandle, 'on');
    
        end
    end
end