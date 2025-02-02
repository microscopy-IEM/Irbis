function plotTimeDevelopment(axes, yData, xData, labelData, plotType)
    % Plots the selected parameter across time points
    % Each line represents one object, x-axis represents frames, y-axis represents the selected parameter
    % Supports categorical grouping for averaged plots and numerical gradients for individual plots

    % Check if categorical information exists
    if ~isempty(labelData)
        if isnumeric(labelData) && ~isscalar(unique(labelData)) % Numerical category for gradient coloring
            isNumericalCategory = true;
        elseif iscategorical(labelData) || isstring(labelData) % Categorical grouping
            isNumericalCategory = false;
            labelData = categorical(labelData); % Ensure categorical type
        else
            labelData = [];
            isNumericalCategory = false;
        end
    else
        labelData = [];
        isNumericalCategory = false;
    end

    % Plot based on the selected visualization mode
    switch plotType
        case "averaged"
            plotAveragedData(axes, xData, yData, labelData, isNumericalCategory);
        otherwise
            plotIndividualData(axes, xData, yData, labelData, isNumericalCategory);
    end

    % Configure plot appearance
    finalizePlot(axes);
end

function plotAveragedData(axes, xData, data, categories, isNumericalCategory)
    % Computes mean and standard deviation, then plots the averaged data with confidence intervals
    hold(axes, 'on');
    
    if isempty(categories) || isNumericalCategory
        % No grouping or numerical category (treat as single group)
        meanData = mean(data, 1, "omitmissing");
        stdData = std(data, 0, 1, "omitmissing");

        plot(axes, xData, meanData, '-x', 'DisplayName', 'Mean');
        fillConfidenceInterval(axes, xData, meanData, stdData);
    else
        % Categorical grouping for averaging
        uniqueCategories = unique(categories);
        colors = lines(numel(uniqueCategories)); % Distinct colors for categories

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
    % Helper function to add confidence intervals
    if nargin < 5
        color = [0.9, 0.9, 0.9]; % Default gray if no color provided
    end
    fill(axes, [xData, fliplr(xData)], [meanData + stdData, fliplr(meanData - stdData)], ...
         color, 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', 'Confidence Interval');
end

function plotIndividualData(axes, xData, data, categories, isNumericalCategory)
    % Plots individual data lines, optionally colored by category or using a gradient
    hold(axes, 'on');

    if isempty(categories)
        % No categorical information, plot normally
        plot(axes, xData, data', '-x');
    elseif isNumericalCategory
        % Numerical category: Use a colormap for line colors
        cmap = parula(numel(categories)); % Generate colors using parula colormap
        normalizedCategories = (categories - min(categories)) / (max(categories) - min(categories)); % Normalize to [0,1]
        colorIndices = round(1 + normalizedCategories * (size(cmap, 1) - 1)); % Scale to colormap indices

        for i = 1:size(data, 1)
            plot(axes, xData, data(i, :), '-x', 'Color', cmap(colorIndices(i), :), ...
                 'DisplayName', sprintf('Value: %.2f', categories(i)));
        end
        colorbar(axes); % Show color gradient scale
        colormap(axes, cmap);
        clim(axes, [min(categories), max(categories)]); % Set color scale
    else
        % Categorical data: Use distinct colors
        uniqueCategories = unique(categories);
        colors = lines(numel(uniqueCategories)); % Generate distinct colors

        for i = 1:numel(uniqueCategories)
            groupIdx = categories == uniqueCategories(i);
            groupData = data(groupIdx, :);
            plot(axes, xData, groupData', '-x', 'Color', colors(i, :), 'DisplayName', char(uniqueCategories(i)));
        end
    end

    hold(axes, 'off');
    legend(axes, 'show');
end

function finalizePlot(axes)
    % Sets plot labels and limits
    xlabel(axes, 'Time');
    title(axes, '');
    ylim(axes, 'auto');
end
