classdef TwoVariablesPlot < plot.PlotInterface
    methods
        function plot(obj, data, axesHandle)

            cla(axesHandle,'reset')

            xData = data.xData;
            yData = data.yData;

            axesHandle.TickLabelInterpreter = 'none';
            
            
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
            
            % xlabel(axesHandle, data.xLabel);
            % ylabel(axesHandle, data.yLabel);
            
    
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
            useJitter = data.useJitter;     % added as a property of the data struct, which is set by the formatter based on the state of the plot manager - read from the checkbox in ResultsViewer GUI

            if isempty(groupData)
                if useJitter
                    % jitter implemented in undocumented way: 
                    % https://undocumentedmatlab.com/articles/undocumented-scatter-plot-jitter
                    scatter(axesHandle, xData, yData,'XJitter','rand');

                    xlabel(axesHandle, data.xLabel,'Interpreter','none');
                    ylabel(axesHandle, data.yLabel,'Interpreter','none');
                else
                    scatter(axesHandle, xData, yData);
                end

                % figure
                % 
                % values = hist3([xData(:) yData(:)],[51 51]);
                % values = values./max(values(:));
                % imagesc(values.')
                % colorbar
                % axis equal
                % axis xy
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
                    if useJitter
                        plotHandle = scatter(axesHandle, xData(mask, :, :), yData(mask, :, :), ...
                        'Color', categoryColormap(i, :),'XJitter','rand');
                    else
                        plotHandle = scatter(axesHandle, xData(mask, :, :), yData(mask, :, :), ...
                        'Color', categoryColormap(i, :));
                    end

                    legendHandles(i) = plotHandle(1); 
                    legendNames{i} = char(categoryList(i));
                end
                hold(axesHandle, 'off');
                if ~isempty(legendNames)
                    l = legend(legendHandles, legendNames, 'Location', 'best'); 
                    l.Interpreter = 'none';
                end
            end

            % the labels have to be defined after the plotting, otherwise they are reset by the plotting function
            xlabel(axesHandle, data.xLabel,'Interpreter','none');
            ylabel(axesHandle, data.yLabel,'Interpreter','none');

        end

        function plotBoxplot(~, data, axesHandle)

            useJitter = data.useJitter;
            xData = data.xData;
            yData = data.yData;
            groupData = data.groupData;

            assignin("base",'data',data)
          
            % Decide, which of the columns is categorical
            if iscategorical(xData)
                categoricalData = xData;
                categoricalLabel = data.xLabel;
                numericalData = yData;
                numericalLabel = data.yLabel;
            elseif iscategorical(yData)
                categoricalData = yData;
                categoricalLabel = data.yLabel;
                numericalData = xData;
                numericalLabel = data.xLabel;
            else
                error('Neither xData nor yData is categorical.')
            end

            if isempty(groupData)
                numericalData = permute(numericalData, [1, 3, 2]);  % D3 potentially contains vector data - must be as columns
                categoricalData = permute(categoricalData, [1, 3, 2]); 

                % clean the list of categories to those present in the data
                categoricalData = removecats(categoricalData);

                % boxplot(axesHandle, numericalData, categoricalData)   % X is numeric and g is categorical

                % boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.1,'JitterOutliers','on');

                % https://www.mathworks.com/help/stats/boxplot.html#bu180jd-2
                %    If x is a matrix, boxplot plots one box for each column of x.
                %    If x is a matrix, then the grouping variables must contain one row for each column of x.

                % Code for R2025a
                % ver = matlabRelease.Release;

                % tf = ~isMATLABReleaseOlderThan("R2025a")

                if ~isMATLABReleaseOlderThan("R2025a")

                    % boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.3,'BoxFaceColor','k','MarkerColor','k','MarkerStyle','.','JitterOutliers','on');


                    boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.3,'MarkerStyle','.','JitterOutliers',useJitter);
                    
                    axesHandle.TickLabelInterpreter = 'none';                  

                    axesHandle.NextPlot = 'add';

                    % axesHandle.UserData.groupLabel = data.xLabel;
                    % axesHandle.UserData.cGroupLabel = data.groupLabel;

                else

                    boxchart(axesHandle, categoricalData, numericalData,'BoxWidth',0.1,'JitterOutliers',useJitter);
                    

                  

                end

                
            else
                numericalData = permute(numericalData, [1, 3, 2]);  % D3 potentially contains vector data - must be as columns
                % if this is a matrix, it cannot be combined with yData!
                categoricalData = permute(categoricalData, [1, 3, 2]); 
                categoricalData = removecats(categoricalData);  % clean the list of categories to those present in the data
                groupData = permute(groupData, [1, 3, 2]);
                

                 % https://www.mathworks.com/help/matlab/ref/boxchart.html
                %    ydata must be a vector, and cgroupdata must have the same length as ydata
                %    you cannot specify xgroupdata when ydata is a matrix.
                                
                % Code for R2025a
          
                if ~isMATLABReleaseOlderThan("R2025a")

                    % numericalData = log10(numericalData);
                
                    % boxchart(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData,'BoxWidth',0.3,'BoxFaceColor','k','MarkerColor','k','MarkerStyle','.','JitterOutliers','on');
                    b = boxchart(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData,'BoxWidth',0.3,'MarkerStyle','.','JitterOutliers',useJitter);
                    
                    axesHandle.TickLabelInterpreter = 'none';     
                    legendGroups = unique(groupData);
                    l = legend(axesHandle, b, legendGroups, 'Location', 'northeast');
                    l.Interpreter = 'none';
                    
                    axesHandle.NextPlot = 'add';   
                    
                    
                    % v = violinplot(axesHandle, categoricalData, numericalData, 'GroupByColor', groupData);                    
                                      
             
                    % determine if both group and cGroup data have same categories
                    C1 = categories(categoricalData);
                    C2 = categories(groupData);
                    tf = iscategory(categorical(C1),C2);
                    concatenateCategories = all(tf);
                    
                    % TO OPTIMIZE - do not concatenate if the group and
                    % cGroup data are logical (problem is that we store
                    % logical as categorical with true/false categories

                    islogical(categoricalData)
                    
                    if concatenateCategories

                        disp('two categorical columns concatenated')

                        axesHandle.NextPlot = 'replace';
                        xDataDuplicated = cat(1,numericalData,numericalData);
    
                        categoricalDataMerged = cat(1,categoricalData,groupData);
    
                        groupLabel = categoricalLabel;
                        cGroupLabel = data.groupLabel;
                        
                        G = repmat({groupLabel},length(categoricalData),1);
                        cG = repmat({cGroupLabel},length(groupData),1);
                        
                        cGroupData = cat(1,G,cG);
                                     
                        b = boxchart(axesHandle, categoricalDataMerged, xDataDuplicated, 'GroupByColor', cGroupData,'BoxWidth',0.3,'MarkerStyle','.','JitterOutliers',useJitter);
                                                 
                        legendGroups = unique(cGroupData);
                        l = legend(axesHandle, b, legendGroups, 'Location', 'northeast');
                        l.Interpreter = 'none';

                    end

                    % axesHandle.YLabel.Interpreter = 'none';
                    % axesHandle.XLabel.Interpreter = 'none';
                   

                else

                    

                end
               
            end

            % Assign group and colorGroup label to axces userdata
            axesHandle.UserData.groupLabel = categoricalLabel;
            axesHandle.UserData.cGroupLabel = data.groupLabel;

            % xlabel(axesHandle, categoricalLabel);
            % ylabel(axesHandle, numericalLabel);

            axesHandle.YLabel.String = numericalLabel;
            axesHandle.YLabel.Interpreter = 'none';

            axesHandle.XLabel.String = categoricalLabel;
            axesHandle.XLabel.Interpreter = 'none';

           

        end

        function plotCategoricalScatter(~, data, axesHandle)
            xData = data.xData;
            yData = data.yData;
            groupData = data.groupData;

            axesHandle.UserData = data;

            xlabel(axesHandle, data.xLabel,'Interpreter','none');
            ylabel(axesHandle, data.yLabel,'Interpreter','none');

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

            % xCats = unique(xData)
            % yCats = unique(yData)

            [xIdx, xCats] = grp2idx(xData);     % unique(xData) was returning lower number of categories than actually present
            [yIdx, yCats] = grp2idx(yData);

            if isempty(groupData)

                counts = accumarray([xIdx(:), yIdx(:)], 1, ...
                    [length(xCats), length(yCats)]);
                sizes = counts(:);
                
                % sizes(sizes==0) = nan;    % alternative option to nonZero = sizes > 0;

                [xGrid, yGrid] = meshgrid(1:length(yCats), 1:length(xCats));
                xPlot = xGrid(:) + 0.5;
                yPlot = yGrid(:) + 0.5;

                nonZero = sizes > 0;    % the values going to scatter must be positive (or nan)

                scatter(axesHandle, xPlot(nonZero), yPlot(nonZero), sizes(nonZero), 'LineWidth', 2);
            else

                % groupCats = unique(groupData);
                % gIdx = double(groupData);

                [gIdx, groupCats] = grp2idx(groupData);  % ensure that gIdx is sequential from 1 to number of groups

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

                l = legend(axesHandle, groupCats, 'Location', 'best');
                l.Interpreter = 'none';

            end

            set(axesHandle, 'XTick', 1.5:length(yCats)+0.5, 'XTickLabel', yCats);
            set(axesHandle, 'YTick', 1.5:length(xCats)+0.5, 'YTickLabel', xCats);
            xlim(axesHandle, [0.5, length(yCats)+1]);
            ylim(axesHandle, [0.5, length(xCats)+1]);
            grid(axesHandle, 'on');
    
        end
    end
end