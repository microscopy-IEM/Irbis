classdef RatioBarPlot < plot.PlotInterface
    % Same as HistogramStackedPlot, but adds normalization to 1
    methods
        function plot(~, data, axesHandle)

            cla(axesHandle,'reset')

            groupData = data.groupData;
            xData = data.xData;

            if ~iscategorical(xData)
                return
            end

            if isempty(groupData)

                % histogram(axesHandle, xData);
                p = pie(axesHandle,xData);
                % get(p)
                xlabel(axesHandle, data.xLabel);

                PieTexts = findobj(p,'Type','Text');
                set(PieTexts,'Interpreter','none');
                % axesHandle.Parent
                % p = piechart(axesHandle.Parent,xData)
                

            else

                categoryList = unique(groupData);

                if isnumeric(xData)
                    % nBins = sqrt(length(categoryList)) * 10;
                    % % nBins = 500;
                    % range = (max(xData) - min(xData));
                    % binWidth = range / nBins;
                    % % Create histogram counts for each group
                    % binEdges = min(xData):binWidth:max(xData);
                    % counts = zeros(length(categoryList), length(binEdges) - 1);
                    % 
                    % for i = 1:length(categoryList)
                    %     mask = groupData == categoryList(i);
                    %     dataToPlot = xData(mask, :, :);
                    %     counts(i, :) = histcounts(dataToPlot, binEdges);
                    % end
                    % 
                    % counts = normalize(counts, 'norm', 1).*100; % Normalize counts to sum to 1 for each category
                    % 
                    % % Plot stacked bars
                    % plotHandle = bar(axesHandle, binEdges(1:end-1) + binWidth/2, counts', 'stacked');
                else
                    counts = zeros(length(categoryList), length(categories(xData)));
                    for i = 1:length(categoryList)
                        mask = groupData == categoryList(i);
                        dataToPlot = xData(mask, :, :);
                        counts(i, :) = histcounts(dataToPlot);
                    end

                    counts = normalize(counts, 'norm', 1).*100; % Normalize counts to sum to 1 for each category

                    % Plot stacked bars
                    plotHandle = bar(axesHandle, counts', 'stacked','Interpreter','none');

                    % Keep the names of the categories as ticks
                    xticks(axesHandle, 1:length(categories(xData)))
                    xticklabels(axesHandle, categories(xData))
                end
                legend(plotHandle, categoryList, 'Location', 'NorthEast','Interpreter','none'); 
                %   assigned to plotHandle, not axesHandle, because we need to get the colors
            end

            ylabel(axesHandle, 'Proportion (%)');
            
            axesHandle.TickLabelInterpreter = 'none';



        end
    end
end
