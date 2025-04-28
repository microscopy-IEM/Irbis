classdef RadialDensityHistogramPlot < plot.PlotInterface

    % Stepan's special histogram to calculate density of radial distribution

    properties (Constant)
        MIN_RADIAL_DISTANCE = 0;
        MAX_RADIAL_DISTANCE = 4;
        STEP = 0.05;
    end

    methods
        function plot(obj, data, axesHandle)

            cla(axesHandle,'reset')

            groupData = data.groupData;
            xData = data.xData;
            binEdges = obj.MIN_RADIAL_DISTANCE : obj.STEP : obj.MAX_RADIAL_DISTANCE; % 0:0.05:4;    % TO OPTIMIZE - this contains hard-coded values

            hold(axesHandle, 'on');
            if isempty(groupData)

                [binCounts, binEdges] = histcounts(xData, binEdges, 'Normalization', 'pdf');

                binArea = pi.*diff(binEdges.^2);

                densityPerBin = binCounts./binArea;
                binCounts = densityPerBin;

                binEdges = binEdges(2:end);

                plot(axesHandle, binEdges, binCounts, '-', 'LineWidth', 2);
                ylabel(axesHandle, 'Counts');
            else
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3

                % hold(axesHandle, 'on');
                % for i = 1:numel(categoryList)
                %     mask = groupData == categoryList(i); % TO FIX - this does not work if there are numbers in categorical
                %     plotHandle = histogram(axesHandle, xData(mask, :, :), ...
                %     'FaceColor', categoryColormap(i, :));

                %     legendHandles(i) = plotHandle(1);
                %     legendNames{i} = char(categoryList(i)); 

                % end
                % hold(axesHandle, 'off');
                % if ~isempty(legendNames)
                %     legend(legendHandles, legendNames, 'Location', 'best'); 
                % end

                % Special plot SK

                % colors = lines(5);

                                        
                for i = 1:length(categoryList)

                    mask = groupData == categoryList(i);

                    % [binCounts, binEdges] = histcounts(xData(groupData == categoryList{i}),binEdges,'Normalization','pdf');
                    [binCounts, binEdges] = histcounts(xData(mask, :, :), binEdges, 'Normalization', 'count');
                    
                    binArea = pi.*diff(binEdges.^2);

                    % S = pi.*binEdges(1:end-1).^2

                    densityPerBin = binCounts./binArea;
                    binCounts = densityPerBin;
                    % binCounts = binCounts./max(binCounts);

                    % binCounts = binCounts-max(binCounts);

                    binEdges = binEdges(2:end);

                    eqPoint = 3;
                    k = find(binEdges >= eqPoint,1);

                    binCounts = binCounts./(binCounts(k));

                    % plot(axesHandle, binEdges, binCounts, '-', 'LineWidth', 2);
                    % ylabel(axesHandle, 'Counts');

                    % plot(axesHandle, binCenters, binCounts, '-', 'LineWidth', 2, 'Color',colors(i,:));
                    plotHandle = plot(axesHandle, binEdges, binCounts, '-', 'LineWidth', 2, 'Color', categoryColormap(i, :));

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i));
                end
            end

            xline(axesHandle, 1, 'LineStyle', '--') % plot the object edge position
            hold(axesHandle, 'off');

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, 'Counts');
        end
    end
end
