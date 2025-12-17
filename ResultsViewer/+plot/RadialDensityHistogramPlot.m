classdef RadialDensityHistogramPlot < plot.PlotInterface

    % Stepan's uPaint special histogram to calculate density of
    % localization in and near object (synapse)

    properties (Constant)
        MIN_RADIAL_DISTANCE = 0;
        MAX_RADIAL_DISTANCE = 4;
        STEP = 0.05;
        eqPoint = 3;
        eqPointRange = 0.5;
    end

    methods
        function plot(obj, data, axesHandle)
            
            cla(axesHandle,'reset')

            groupData = data.groupData;
            xData = data.xData;
            binEdges = obj.MIN_RADIAL_DISTANCE : obj.STEP : obj.MAX_RADIAL_DISTANCE; % 0:0.05:4;    % TO OPTIMIZE - this contains hard-coded value

          
            hold(axesHandle, 'on');
            if isempty(groupData)

                [binCounts, binEdges] = histcounts(xData, binEdges, 'Normalization', 'pdf');

                binArea = pi.*diff(binEdges.^2);

                densityPerBin = binCounts./binArea;
                % binCounts = densityPerBin;

                binEdges = binEdges(2:end);

                eqValues = densityPerBin(binEdges >= obj.eqPoint-obj.eqPointRange & binEdges <= obj.eqPoint+obj.eqPointRange);

                normalizationValue = mean(eqValues);

                densityPerBinNormalized = densityPerBin./normalizationValue;


                plot(axesHandle, binEdges, densityPerBinNormalized, '-', 'LineWidth', 2);
                ylabel(axesHandle, 'Counts');
            else
               
                categoryList = unique(groupData);

                % start legend entries
                legendHandles = gobjects(numel(categoryList), 1);
                legendNames = cell(numel(categoryList), 1);

                % generate colors for each line
                categoryColormap = lines(numel(categoryList)); % generate distinct color for each category - array of size numel(categoryList) x 3
                
                
                                        
                for i = 1:length(categoryList)

                    mask = groupData == categoryList(i);

                    % [binCounts, binEdges] = histcounts(xData(groupData == categoryList{i}),binEdges,'Normalization','pdf');
                    [binCounts, binEdges] = histcounts(xData(mask, :, :), binEdges, 'Normalization', 'count');
                    
                    binArea = pi.*diff(binEdges.^2); % circular approximation of area between two bins
                    
                    densityPerBin = binCounts./binArea;                   
                    
                    binEdges = binEdges(2:end);
                                        
                    eqValues = densityPerBin(binEdges >= obj.eqPoint-obj.eqPointRange & binEdges <= obj.eqPoint+obj.eqPointRange);

                    normalizationValue = mean(eqValues);

                    densityPerBinNormalized = densityPerBin./normalizationValue;

                    plotHandle = plot(axesHandle, binEdges, densityPerBinNormalized, '-', 'LineWidth', 2, 'Color', categoryColormap(i, :));

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i));
                end

                if ~isempty(legendNames)
                    legend(legendHandles, legendNames, 'Location', 'best'); 
                end
            end

            xline(axesHandle, 1, 'LineStyle', '--') % plot the object edge position
            hold(axesHandle, 'off');

            xlabel(axesHandle, data.xLabel);
            ylabel(axesHandle, 'Counts');

            
        end
    end
end
