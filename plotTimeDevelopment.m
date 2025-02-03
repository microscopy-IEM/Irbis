function plotTimeDevelopment(axes, yData, xData, labelData, plotType, yLabel)
    % Plots the selected parameter across time points
    % Each line represents one object, x-axis represents frames, y-axis represents the selected parameter
    % Supports categorical grouping for averaged plots and numerical gradients for individual plots

    % Ensure plot resets properly
    cla(axes, 'reset'); 
    axes.NextPlot = 'replace'; 

    if isempty(yData) || isempty(xData)
        return;
    end 

    % Extract row names as labels if yData is a table
    if istable(yData)
        legendLabels = yData.Properties.RowNames;
        yData = table2array(yData);
    else
        legendLabels = [];
    end

    % Handle NaN in labelData
    isNumericalCategory = false;
    hasNaN = false;
    if ~isempty(labelData)
        if isnumeric(labelData)
            hasNaN = any(isnan(labelData));  % Detect NaNs
            isNumericalCategory = true;
        elseif iscategorical(labelData) || isstring(labelData)
            labelData = categorical(labelData);
            labelData(isundefined(labelData)) = 'Unknown'; % Replace NaN-equivalent values
        else
            labelData = [];
        end
    end

    % Plot based on visualization mode
    switch plotType
        case "rows: averaged"
            plotAveragedData(axes, xData, yData, labelData, isNumericalCategory);
        otherwise
            plotIndividualData(axes, xData, yData, labelData, isNumericalCategory, legendLabels, hasNaN);
    end

    % Configure plot appearance
    finalizePlot(axes, yLabel);
end

function plotAveragedData(axes, xData, data, categories, isNumericalCategory)
    % Computes mean and standard deviation, then plots the averaged data with confidence intervals
    hold(axes, 'off'); 

    hold(axes, 'on');
    if isempty(categories) || isNumericalCategory
        meanData = mean(data, 1, "omitmissing");
        stdData = std(data, 0, 1, "omitmissing");

        plot(axes, xData, meanData, '-x', 'DisplayName', 'Mean');
        fillConfidenceInterval(axes, xData, meanData, stdData);
    else
        uniqueCategories = unique(categories);
        colors = lines(numel(uniqueCategories));

        for i = 1:numel(uniqueCategories)
            groupIdx = categories == uniqueCategories(i);
            groupData = data(groupIdx, :);
            meanData = mean(groupData, 1, "omitmissing");
            stdData = std(groupData, 0, 1, "omitmissing");

            plot(axes, xData, meanData, '-x', 'Color', colors(i, :), 'DisplayName', char(uniqueCategories(i)));
            fillConfidenceInterval(axes, xData, meanData, stdData, colors(i, :));
        end
    end
    hold(axes, 'off');

    legend(axes, 'show');
end

function fillConfidenceInterval(axes, xData, meanData, stdData, color)
    if nargin < 5
        color = [0.9, 0.9, 0.9]; % Default gray
    end
    fill(axes, [xData, fliplr(xData)], [meanData + stdData, fliplr(meanData - stdData)], ...
         color, 'EdgeColor', 'none', 'FaceAlpha', 0.3);
end

function plotIndividualData(axes, xData, data, categories, isNumericalCategory, legendLabels, hasNaN)
    % Plots individual data lines, optionally colored by category or using a gradient
    hold(axes, 'off'); 

    if isempty(categories)
        % Plot all rows with row names as legend labels
        lines = plot(axes, xData, data', '-x');
        if ~isempty(legendLabels)
            for i = 1:numel(lines)
                if ~isempty(legendLabels{i}) && ~contains(legendLabels{i}, 'NaN')
                    lines(i).DisplayName = legendLabels{i};
                else
                    lines(i).DisplayName = sprintf('Row %d', i);
                end
            end
            legend(axes, 'show');
        end
    else
        if isNumericalCategory
            validIdx = ~isnan(categories); % Ignore NaN indices
            cmap = turbo(sum(validIdx)); % Generate colors only for valid entries
            minValue = min(categories(validIdx));
            maxValue = max(categories(validIdx));
            
            % Normalize categories ignoring NaNs
            if maxValue > minValue
                normalizedCategories = (categories(validIdx) - minValue) / (maxValue - minValue);
                colorIndices = round(1 + normalizedCategories * (size(cmap, 1) - 1));
            else
                colorIndices = ones(size(categories(validIdx)));
            end

            % disp('sizes')
            % disp(sum(validIdx))
            % size(colorIndices)
            % size(categories)

            hold(axes, 'on');
            validN = 1;
            for i = 1:size(data, 1)
                if validIdx(i)
                    % Assign colormap colors
                    plot(axes, xData, data(i, :), '-x', 'Color', cmap(colorIndices(validN), :), ...
                        'DisplayName', sprintf('Value: %.2f', categories(i)));
                    validN = validN + 1;
                else
                    % Assign out-of-range color (black)
                    plot(axes, xData, data(i, :), '-x', 'Color', [0, 0, 0], 'DisplayName', 'NaN Value');
                end
            end

            colorbar(axes);
            colormap(axes, cmap);
            clim(axes, [minValue, maxValue]); 

            % if hasNaN
            %     % Add legend entry for NaN values
            %     legendEntries = findobj(axes, 'Type', 'line');
            %     legendEntries = [legendEntries; plot(nan, nan, '-x', 'Color', [0, 0, 0], 'DisplayName', 'NaN Value')];
            %     legend(axes, legendEntries, 'Location', 'best');
            % end
            hold(axes, 'off');
        else
            uniqueCategories = unique(categories);
            colors = turbo(numel(uniqueCategories));

            hold(axes, 'on');
            for i = 1:numel(uniqueCategories)
                groupIdx = categories == uniqueCategories(i);
                groupData = data(groupIdx, :);
                plot(axes, xData, groupData', '-x', 'Color', colors(i, :), 'DisplayName', char(uniqueCategories(i)));
            end
            hold(axes, 'off');  
        end
    end
end

function finalizePlot(axes, yLabel)
    xlabel(axes, 'Time');
    ylabel(axes, yLabel);
    title(axes, '');
    ylim(axes, 'auto');
end
