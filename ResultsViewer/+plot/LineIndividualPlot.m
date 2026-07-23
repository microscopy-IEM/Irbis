classdef LineIndividualPlot < plot.PlotInterface
    methods
        function plot(obj, data, axesHandle)
            groupData = data.groupData;

            xData = data.xData;
            yData = data.yData;
    
            if isempty(groupData)
                [colorValues, hasNumericColor] = obj.getNumericLineColorData(data, yData);

                if hasNumericColor
                    obj.plotNumericallyColoredLines(data, axesHandle, colorValues);
                else
                    xData = permute(xData, [3, 1, 2]);
                    yData = permute(yData, [3, 1, 2]);

                    plot(axesHandle, xData, yData, '-x'); % plot of multiple lines requires each line in a column - that's why we use permute
                    % https://www.mathworks.com/help/matlab/ref/plot.html#btzitot-2
                    %   'If the matrix is square, MATLAB plots one line for each column in the matrix.'
                end

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

            xlabel(axesHandle, data.xLabel, 'Interpreter', 'none');
            ylabel(axesHandle, data.yLabel, 'Interpreter', 'none');
        end
    end



    methods (Access = private)
        function [colorValues, hasNumericColor] = getNumericLineColorData(~, data, yData)
            colorValues = [];
            hasNumericColor = false;

            if ~isfield(data, 'colorData') || isempty(data.colorData)
                return
            end

            if ~isfield(data, 'colorType') || string(data.colorType) ~= "numeric"
                return
            end

            if ~isfield(data, 'colorScope') || string(data.colorScope) ~= "line"
                return
            end

            squeezedColorData = squeeze(data.colorData);
            lineCount = size(yData, 1);

            if ~isvector(squeezedColorData) || numel(squeezedColorData) ~= lineCount
                return
            end

            colorValues = double(squeezedColorData(:));
            hasNumericColor = true;
        end



        function plotNumericallyColoredLines(obj, data, axesHandle, colorValues)
            [lineColors, colorLimits] = obj.mapValuesToColors(colorValues);
            lineCount = size(data.yData, 1);

            hold(axesHandle, 'on');
            for lineIdx = 1:lineCount
                xLine = squeeze(data.xData(lineIdx, :, :));
                yLine = squeeze(data.yData(lineIdx, :, :));
                xLine = xLine(:);
                yLine = yLine(:);

                if numel(xLine) ~= numel(yLine)
                    continue
                end

                plot(axesHandle, xLine, yLine, '-x', 'Color', lineColors(lineIdx, :));
            end
            hold(axesHandle, 'off');

            % The axes colormap and colorbar communicate the continuous mapping.
            % Individual line handles keep fixed RGB values so the plot remains stable if the user later edits unrelated axes properties.
            colormap(axesHandle, parula(256));
            clim(axesHandle, colorLimits);
            plot.ColorbarHelper.addInsideNorthColorbar(axesHandle, data.colorLabel);
        end



        function [lineColors, colorLimits] = mapValuesToColors(~, colorValues)
            colormapValues = parula(256);
            finiteMask = isfinite(colorValues);

            if ~any(finiteMask)
                lineColors = repmat([0.5 0.5 0.5], numel(colorValues), 1);
                colorLimits = [0 1];
                return
            end

            minValue = min(colorValues(finiteMask));
            maxValue = max(colorValues(finiteMask));

            if isequal(minValue, maxValue)
                normalizedValues = repmat(0.5, size(colorValues));
                colorLimits = [minValue - 0.5, maxValue + 0.5];
            else
                normalizedValues = (colorValues - minValue) ./ (maxValue - minValue);
                normalizedValues = min(max(normalizedValues, 0), 1);
                colorLimits = [minValue, maxValue];
            end

            colorIdx = 1 + round(normalizedValues * (size(colormapValues, 1) - 1));
            colorIdx(~finiteMask) = 1;
            lineColors = colormapValues(colorIdx, :);
            lineColors(~finiteMask, :) = repmat([0.5 0.5 0.5], sum(~finiteMask), 1);
        end
    end
end
