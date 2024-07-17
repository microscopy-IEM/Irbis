function fileNameWithTimePoints = reorderFileNames(fileNames)
    % Create a figure window for reordering and time point input
    fig = figure('Name', 'Set Time Points for Files', 'NumberTitle', 'off', ...
                 'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off', ...
                 'Position', [500, 500, 450, 450]);

    % Create a label to provide instructions
    instructionLabel = uicontrol('Style', 'text', 'Position', [20, 380, 410, 50], ...
                                 'String', ['Edit the "TimePoint" column to set the time point for each file. ' ...
                                 'Ensure each file has a unique time point and click "OK" when done.'], ...
                                 'HorizontalAlignment', 'left', ...
                                 'FontSize', 10, 'BackgroundColor', fig.Color);

    % Create a table to display filenames and time points
    data = [num2cell((1:numel(fileNames))'), fileNames(:)];
    t = uitable('Parent', fig, 'Data', data, 'ColumnEditable', [true false], ...
                'ColumnName', {'TimePoint', 'FileName'}, ...
                'ColumnWidth', {70, 300}, ...
                'Position', [20, 50, 400, 300], ...
                'CellEditCallback', @validateTimePoints);

    % Create 'OK' button
    btnOK = uicontrol('Style', 'pushbutton', 'String', 'OK', ...
                      'Position', [200, 10, 60, 30], ...
                      'Callback', @okButtonCallback);

    % Wait for the user to close the window
    uiwait(fig);
    
    % Get the sorted filenames and time points from the table
    fileNameWithTimePoints = t.Data;
    
    % Close the figure
    close(fig);

    function validateTimePoints(~, ~)
        % Get data from the table
        tableData = t.Data;
        timePoints = cell2mat(tableData(:, 1));
        
        % Check for duplicate time points
        [uniqueTimePoints, ~, idx] = unique(timePoints);
        duplicateIndices = setdiff(1:length(timePoints), idx);
        
        % Reset background colors
        t.BackgroundColor = repmat([1 1 1], size(t.Data, 1), 1);
        
        if ~isempty(duplicateIndices)
            % Highlight duplicate rows
            for i = duplicateIndices
                t.BackgroundColor(i, :) = [1 0.6 0.6]; % Highlight with a red color
            end
        end
    end

    function okButtonCallback(~, ~)
        % Get data from the table
        tableData = t.Data;
        timePoints = cell2mat(tableData(:, 1));
        
        % Check for duplicate time points
        [uniqueTimePoints, ~, idx] = unique(timePoints);
        duplicateIndices = setdiff(1:length(timePoints), idx);
        
        if isempty(duplicateIndices)
            % If no duplicates, resume
            uiresume(fig);
        else
            % Highlight duplicate rows and show a warning
            warningMessage = 'Duplicate time points found. Please ensure each file has a unique time point.';
            warndlg(warningMessage, 'Duplicate Time Points');
        end
    end
end
