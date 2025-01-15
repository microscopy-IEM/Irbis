function fillColorbar(colorbarAxesHandle, columnData, colormapName, selectedColumn, backgroundColor, modality)
    % Fills the colorbar with colors and labels, with a wider default segment for NaN/uncategorized values.

    % Check if a colormap other than 'random' is selected
    if isequal(colormapName, 'random')
        return;
    end

    % Determine the number of colors based on the data type
    if isnumeric(columnData)
        nColors = 256; % High resolution for numeric data
        hasNaN = any(isnan(columnData)); % Check for NaN values
    elseif iscategorical(columnData)
        cats = categories(columnData);
        nColors = numel(cats); % Number of unique categories
        hasNaN = any(isundefined(columnData)); % Check for uncategorized values
    else
        error('Unsupported data type for colorbar.');
    end

    % Add an extra color for NaN or uncategorized values
    if hasNaN
        nColors = nColors + 1;
    end

    % Generate the colormap
    cmapFcn = str2func(colormapName); % Convert colormap name to function handle
    cmap = cmapFcn(nColors - 1); % Generate colors for valid values

    % Assign a default color for NaN or uncategorized values
    if strcmp(colormapName, 'gray')
        defaultColor = [1, 0, 0]; % Red for gray colormap
    else
        defaultColor = [0.5, 0.5, 0.5]; % Gray for other colormaps
    end
    cmap = [cmap; defaultColor]; % Append default color

    % Create coordinates for the colorbar
    defaultSegmentWidth = 0.05; % Proportion of the bar for the default color
    validSegmentWidth = (1 - defaultSegmentWidth) / (nColors - 1); % Evenly split remaining width
    x = [0:validSegmentWidth:(1 - defaultSegmentWidth), 1 - defaultSegmentWidth, 1]; % Include default segment

    % Fixed Y-coordinates (colorbar height)
    y = [0, 0, 1, 1];

    % Plot the colorbar
    hold(colorbarAxesHandle, 'on');
    for i = 1:nColors
        fill(colorbarAxesHandle, [x(i), x(i + 1), x(i + 1), x(i)], y, cmap(i, :), ...
            'EdgeColor', 'none', 'Tag', 'colorbar');
    end
    hold(colorbarAxesHandle, 'off');

    % Calculate luminance to determine label text color
    % backgroundColor = app.PanelPlot.BackgroundColor; % Background color of the panel
    luminance = 0.299 * backgroundColor(1) + 0.587 * backgroundColor(2) + 0.114 * backgroundColor(3);
    textColor = [0, 0, 0]; % Default to black
    if luminance <= 0.5
        textColor = [1, 1, 1]; % Use white text for dark backgrounds
    end

    % Add tick labels
    if isnumeric(columnData)
        % Numeric data: add scaled tick labels
        minVal = min(columnData, [], 'omitnan'); % Ignore NaN values
        maxVal = max(columnData, [], 'omitnan');
        tickValues = linspace(0, 1 - defaultSegmentWidth, 6); % Normalized tick positions for valid values
        tickLabels = arrayfun(@(v) sprintf('%.2g', v), linspace(minVal, maxVal, 6), 'UniformOutput', false);

        for i = 1:length(tickValues)
            text(colorbarAxesHandle, tickValues(i), -0.2, tickLabels{i}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
                'Units', 'normalized', 'Color', textColor);
        end
        % Add label for NaN values
        if hasNaN
            text(colorbarAxesHandle, 1 - defaultSegmentWidth / 2, -0.2, 'NaN', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
                'Units', 'normalized', 'Color', textColor);
        end

    elseif iscategorical(columnData)
        % Categorical data: add category labels
        tickValues = linspace(0, 1 - defaultSegmentWidth, nColors - hasNaN); % Normalized tick positions

        for i = 1:(nColors - hasNaN)
            text(colorbarAxesHandle, tickValues(i), -0.2, cats{i}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
                'Units', 'normalized', 'Color', textColor);
        end
        % Add label for uncategorized values
        if hasNaN
            text(colorbarAxesHandle, 1 - defaultSegmentWidth / 2, -0.2, 'Undefined', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
                'Units', 'normalized', 'Color', textColor);
        end
    end

    % Add column name label
    text(colorbarAxesHandle, 0.5, 1.2, [modality ' : ' selectedColumn], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'Units', 'normalized', 'Color', textColor);
end
