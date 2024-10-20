% 
% % inputs:
% colormap
% selectedParameter
% individualColoringOn 
% 
% cmap = colormap;
% selectedColumn = selectedParameter;
% 
% % TO OPTIMIZE - currently, only the visualization changes the color
%             % but it does not change in the tracksList table
% 
%             currentIndex = app.timeline.currentIndex.tracks;
%             for tp=1:app.timeline.nTimePoints
% 
%                 if ~isequal(currentIndex(tp),0)
% 
%                     tracksId = currentIndex(tp);
% 
%                     if isequal(app.tracksColorMapDropDown_2.Value,'random')
%                         app.appData.tracks.colors{tracksId} = cell2mat(app.tracks.tracksList{tracksId}.color);
%                             % TO OPTIMIZE - what to do with the appData ones
%                         continue
%                     end
% 
%                     % Get the selected column name
%                     % selectedColumn = app.tracksColorCodeDropDown.Value;
% 
%                     % Get the colormap function
%                     % cmap = app.tracksColorMapDropDown_2.Value;
%                     cmapFcn = str2func(cmap);
% 
%                     nTracks = app.tracks.nTracks{tracksId};
%                     % Get the column data dynamically
%                     columnData = app.tracks.tracksList{tracksId}.(selectedColumn);
% 
%                     % Initialize color array
%                     c = zeros(nTracks, 3);
% 
%                     % Sort the column data
%                     if isnumeric(columnData)
%                         % Define the range for normalization
%                         minVal = min(columnData);
%                         maxVal = max(columnData);
% 
%                         if isequal(maxVal-minVal,0)
%                             cr = cmapFcn(1);
%                             c = repmat(cr, nTracks, 1);
%                         else
%                             % Normalize the values
%                             normalizedValues = (columnData - minVal) / (maxVal - minVal);
% 
%                             cr = cmapFcn(app.tracks.nTracks{tracksId});
% 
%                             % Map the normalized values to the colormap
%                             colorIndices = round(normalizedValues * (nTracks - 1)) + 1;
%                             c = cr(colorIndices, :);
%                         end
%                     elseif iscategorical(columnData)
%                         cats = categories(columnData);
%                         nCats = numel(cats);
%                         % Generate a colormap with a sufficient number of colors
%                         cr = cmapFcn(nCats);
% 
%                         for i = 1:nCats
%                             category = cats{i};
%                             indices = columnData == category;
%                             c(indices,:) = repmat(cr(i,:), sum(indices), 1);
%                         end
%                     else
%                         error('Unsupported column data type for sorting.');
%                     end
% 
%                     % Update the colors in the app data
%                     app.appData.tracks.colors{tracksId} = c;
%                 end
% 
%             end
% 
%             % Redraw the tracks with the updated colors
%             app.plotTracks();


function colorColumn = getColorColumn(List, selectedParameter, colormap)

    nRows = height(List);
    if isequal(colormap,'random')
        colorColumn = mat2cell(rand(nRows,3), ones(nRows, 1), 3);
        return
    end

    % Get the colormap function
    cmapFcn = str2func(colormap);
    

    % Get the column data dynamically
    columnData = List.(selectedParameter);
    
    % Initialize color array
    c = zeros(nRows, 3);
    
    % Sort the column data
    if isnumeric(columnData)
        % Define the range for normalization
        minVal = min(columnData);
        maxVal = max(columnData);
    
        if isequal(maxVal-minVal,0)
            cr = cmapFcn(1);
            c = repmat(cr, nRows, 1);
        else
            % Normalize the values
            normalizedValues = (columnData - minVal) / (maxVal - minVal);
    
            cr = cmapFcn(nRows);
    
            % Map the normalized values to the colormap
            colorIndices = round(normalizedValues * (nRows - 1)) + 1;
            c = cr(colorIndices, :);
        end
    elseif iscategorical(columnData)
        cats = categories(columnData);
        nCats = numel(cats);
        % Generate a colormap with a sufficient number of colors
        cr = cmapFcn(nCats);
    
        for i = 1:nCats
            category = cats{i};
            indices = columnData == category;
            c(indices,:) = repmat(cr(i,:), sum(indices), 1);
        end
    else
        error('Unsupported column data type for sorting.');
    end
    
    % Update the colors in the app data
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