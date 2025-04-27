classdef LineAveragedPlot < plot.PlotInterface
    methods
        function plot(~, data, axesHandle)
            groupData = data.groupData;

            xData = data.xData;
            yData = data.yData;
    
            if isempty(groupData)
                meanX = mean(xData, 1, 'omitmissing'); % TO OPTIMIZE - make sure this is what we want
                    % we might instead want to use the length of the xData
                meanX = permute(meanX, [1, 3, 2]);  % permutation used to have row vector - required by fill function

                meanY = mean(yData, 1, 'omitmissing');  
                meanY = permute(meanY, [1, 3, 2]);
                
                stdY = std(yData, 0, 1, 'omitmissing'); % we are probably not intested in std of x
                stdY = permute(stdY, [1, 3, 2]);

                plot(axesHandle, meanX, meanY, '-x', 'LineWidth', 2); 

                hold(axesHandle, 'on');
                color = [0.9 0.9 0.9];  % light-gray
                plot.LineAveragedPlot.plotConfidenceInterval(axesHandle, meanX, meanY, stdY, color);
                % fill(axesHandle, [meanX fliplr(meanX)], [meanY+stdY fliplr(meanY-stdY)], ...
                %      [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', 'Confidence Interval');
                    % to work correctly, the data coming to fill needs to be row vector -> therefore, I do not use permute
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
                    mask = groupData == categoryList(i);
                    groupXData = xData(mask, :, :);  % problem here - we overwrite the xData and then use it again in the next iteration
                    groupYData = yData(mask, :, :);

                    meanX = mean(groupXData, 1, 'omitmissing'); % TO OPTIMIZE - make sure this is what we want
                        % we might instead want to use the length of the xData
                    meanX = permute(meanX, [1, 3, 2]); % permutation used to have row vector - required by fill function

                    meanY = mean(groupYData, 1, 'omitmissing');  
                    meanY = permute(meanY, [1, 3, 2]);

                    stdY = std(groupYData, 0, 1, 'omitmissing'); % we are probably not intested in std of x
                    stdY = permute(stdY, [1, 3, 2]);
                    stdY(isnan(stdY)) = 0;

                    plotHandle = plot(axesHandle, meanX, meanY, '-x', 'Color', categoryColormap(i, :), ...
                        'LineWidth', 2);  % LineWidth increased to avoid getting lost in confidence interval

                    legendHandles(i) = plotHandle(1);
                    legendNames{i} = char(categoryList(i)); 

                    % add confidence interval
                    plot.LineAveragedPlot.plotConfidenceInterval(axesHandle, meanX, meanY, stdY, categoryColormap(i, :));
                    % fillHandle = fill(axesHandle, [meanX fliplr(meanX)], [meanY+stdY fliplr(meanY-stdY)], ...
                    %     categoryColormap(i, :), 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                    % fillHandle.Vertices

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
    methods (Static, Access = private)
        function plotConfidenceInterval(axesHandle, meanX, meanY, stdY, color)

            upperY = meanY + stdY;
            lowerY = meanY - stdY;

            % Find valid indices where data is not NaN
            validIdx = ~isnan(upperY) & ~isnan(lowerY) & ~isnan(meanX);

            % Find start/end of contiguous valid regions
            d = diff([false, validIdx, false]);
            segmentStarts = find(d == 1);
            segmentEnds = find(d == -1) - 1;

            % Plot each valid segment
            for seg = 1:numel(segmentStarts)
                idx = segmentStarts(seg):segmentEnds(seg);

                xSegment = meanX(idx);
                yUpper = upperY(idx);
                yLower = lowerY(idx);

                fillX = [xSegment, fliplr(xSegment)];
                fillY = [yUpper, fliplr(yLower)];

                fill(axesHandle, fillX, fillY, ...
                    color, 'EdgeColor', 'none', 'FaceAlpha', 0.3);
            end

        end
    end
end