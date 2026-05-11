function colorColumn = getColorColumn(List, selectedParameter, colormap)
    % Assign colors based on selected parameter and colormap, handling NaN/undefined values efficiently.

    nRows = height(List);

    % Handle 'random' colormap case: assign random colors
    if isequal(colormap, 'random')
        colorColumn = mat2cell(rand(nRows, 3), ones(nRows, 1), 3);
        return
    end

    % Convert colormap name to function handle
    cmapFcn = str2func(colormap);

    % Extract data and identify valid rows
    columnData = List.(selectedParameter);

    % default color for undefined values
    if isequal(colormap,'gray')
        colorForUndefined = [1, 0, 0];
    else
        colorForUndefined = [0.5, 0.5, 0.5];
    end

    % Initialize color matrix with default gray
    c = repmat(colorForUndefined, nRows, 1);

    if isnumeric(columnData)
        % Handle numerical data
        validRows = ~isnan(columnData);
        if any(validRows)
            % Compute normalization range (excluding NaN)
            minVal = min(columnData(validRows));
            maxVal = max(columnData(validRows));
            
            if maxVal == minVal
                % Assign single color for constant values
                c(validRows, :) = repmat(cmapFcn(1), sum(validRows), 1);
            else
                % Normalize valid data and compute color indices
                normalized = (columnData(validRows) - minVal) / (maxVal - minVal);
                cr = cmapFcn(nRows); % Precompute full colormap
                indices = round(normalized * (nRows - 1)) + 1;
                c(validRows, :) = cr(indices, :); % Map normalized values to colors
            end
        end

    elseif iscategorical(columnData)
        % Handle categorical data
        validRows = ~isundefined(columnData); % Redefine valid rows for categorical data
        if any(validRows)
            cats = categories(columnData(validRows)); % Unique categories
            nCats = numel(cats);
            cr = cmapFcn(nCats); % Generate colormap for categories

            % Map each category to a color using vectorized indexing
            [~, catIndices] = ismember(columnData(validRows), cats);
            c(validRows, :) = cr(catIndices, :);
        end
    elseif islogical(columnData)
        % Handle logical data: assign two distinct colors
        cr = cmapFcn(2); % Generate colormap for two categories
        c(columnData == true, :) = repmat(cr(2, :), sum(columnData == true), 1);
        c(columnData == false, :) = repmat(cr(1, :), sum(columnData == false), 1);
    else
        error('Unsupported column data type for sorting.');
    end

    % Convert RGB matrix to cell array of row-wise colors
    colorColumn = mat2cell(c, ones(nRows, 1), 3);
end
    

%% colorbar
            % % Add custom horizontal colorbar to the app.PanelPlot
            % % TO OPTIMIZE - add a checkbox to turn it on and off, add changing when changing time point
            % colorbarAxes = findobj(app.PanelPlot, 'Tag', 'colorbarAxes');
            % if isempty(colorbarAxes)
            %     colorbarAxes = axes('Parent', app.PanelPlot, 'Position', [0.75, 0.05, 0.2, 0.1], 'Tag', 'colorbarAxes', 'Visible', 'off');
            % end
            % delete(colorbarAxes.Children);
            % 
            % if ~isequal(app.tracksColorMapDropDown_2.Value, 'random')
            %     if isnumeric(columnData)
            %         nColors = 256;
            %     elseif iscategorical(columnData)
            %         nColors = numel(cats);
            %     end
            % 
            %     cmap = cmapFcn(nColors);
            % 
            %     % Create coordinates for the colorbar
            %     x = linspace(0, 1, nColors+1); % Adjust the range as needed
            %     y = [0, 0, 1, 1]; % Height of the colorbar
            % 
            %     % Plot the colorbar using fill
            %     hold(colorbarAxes, 'on');
            %     for i = 1:nColors
            %         fill(colorbarAxes, [x(i), x(i+1), x(i+1), x(i)], y, cmap(i, :), 'EdgeColor', 'none','Tag','colorbar');
            %     end
            %     hold(colorbarAxes, 'off');
            % 
            %     % Calculate luminance of the background color
            %     bgColor = app.PanelPlot.BackgroundColor;
            %     luminance = 0.299 * bgColor(1) + 0.587 * bgColor(2) + 0.114 * bgColor(3);
            %     textColor = [0, 0, 0]; % Default to black
            %     if luminance <= 0.5
            %         textColor = [1, 1, 1]; % Change to white if background is dark
            %     end
            % 
            %     if isnumeric(columnData)
            %         % Add labels
            %         tickValues = linspace(0, 1, 6);
            %         tickLabels = arrayfun(@(v) sprintf('%.2g', v), linspace(minVal, maxVal, 6), 'UniformOutput', false);
            %         for i = 1:length(tickValues)
            %             text(colorbarAxes, tickValues(i), -0.2, tickLabels{i}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Units', 'normalized', 'Color', textColor);
            %         end
            %     elseif iscategorical(columnData)
            %         % Add labels
            %         tickValues = linspace(0, 1, nColors);
            %         for i = 1:nColors
            %             text(colorbarAxes, tickValues(i), -0.2, cats{i}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Units', 'normalized', 'Color', textColor);
            %         end
            %     end
            % 
            %     % Add column name label
            %     text(colorbarAxes, 0.5, 1.2, selectedColumn, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Units', 'normalized', 'Color', textColor);
            %     app.colorbarCheckBox.Value = true;
            % end