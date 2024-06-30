function colors = mapValuesToColors(values, colormapName)
    % values: List of numerical values to map to colors
    % colormapName: Name of the colormap to use (e.g., 'jet', 'hot', 'parula')

    % Define the range for normalization
    minVal = min(values);
    maxVal = max(values);

    % Normalize the values to [0, 1]
    normalizedValues = (values - minVal) / (maxVal - minVal);

    % Get the colormap
    cmap = colormap(colormapName);

    % Get the number of colors in the colormap
    nColors = size(cmap, 1);

    % Map the normalized values to the colormap
    colorIndices = round(normalizedValues * (nColors - 1)) + 1;
    colors = cmap(colorIndices, :);
end
