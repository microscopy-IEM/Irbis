function summarizedTable = calculateGroupStats(dataTable, groupParam, targetParam, selectedParams)
    % CALCULATEGROUPSTATS Computes statistics for a parameter grouped by another parameter.
    %   groupStats = calculateGroupStats(dataTable, groupParam, targetParam, selectedParams, statFunctions)
    %   computes statistics (e.g., mean, min, max, etc.) of a target parameter for
    %   groups defined by the group parameter, including additional selected parameters.
    %
    %   INPUTS:
    %     dataTable      - (table) Input table with rows as objects and columns as properties.
    %     groupParam     - (char or string) Column name to group by.
    %     targetParam    - (char or string) Column name of the parameter to calculate statistics for.
    %     selectedParams - (cell array of char or string) List of additional columns to include.
    %     statFunctions  - (cell array of function handles) Statistics functions to apply
    %                      (e.g., {@mean, @min, @max}).
    %
    %   OUTPUT:
    %     summarizedTable     - (table) Output table with computed statistics for each group.
    %
    %   EXAMPLES:
    %     % Example table
    %     data = table(categorical({'A'; 'A'; 'B'; 'B'; 'C'}), ...
    %                  [10; 20; 15; 25; 30], ...
    %                  [1.5; 2.5; 3.5; 4.5; 5.5], ...
    %                  'VariableNames', {'Group', 'Value', 'Slope'});
    %
    %     % Compute stats
    %     stats = calculateGroupStats(data, 'Group', 'Value', {'Slope'}, {@mean, @min, @max});
    %     disp(stats);
    
    % Validate inputs
    if ~ismember(groupParam, dataTable.Properties.VariableNames)
        error("Group parameter not found in the table.");
    end
    if ~ismember(targetParam, dataTable.Properties.VariableNames)
        error("Target parameter not found in the table.");
    end
    if ~all(ismember(selectedParams, dataTable.Properties.VariableNames))
        error("Some selected parameters are not in the table.");
    end
    
    % Convert group parameter to categorical if not already
    if ~iscategorical(dataTable.(groupParam))
        dataTable.(groupParam) = categorical(dataTable.(groupParam));
    end

    tableCell = cell(1, numel(selectedParams));

    for i = 1:numel(selectedParams)
        % added support for categorical parameters - those form just one column with a mode value (not divided to tps)
        selectedParameter = selectedParams{i};
        if iscategorical(dataTable.(selectedParameter))
            pivotedTable = groupsummary(dataTable, groupParam, @(x) mode(x), selectedParameter);
                % returns a table with groupParam in the first column, GroupCounts in the second and the mode in the third
            % Find index of the column to rename
            colIdx = strcmp(pivotedTable.Properties.VariableNames, ['fun1_' selectedParameter]);
            pivotedTable.Properties.VariableNames{colIdx} = ['mode_' selectedParameter];   
                % the column is named 'fun1_selectedParameter' -> change to 'mode_selectedParameter'
            pivotedTable(:, ['mode_' selectedParameter])
            tableCell{i} = pivotedTable(:, ['mode_' selectedParameter]);
        else
            % Create pivot table with the target parameter and group parameter
            pivotedTable = pivotTable(dataTable, targetParam, groupParam, selectedParameter);
            statisticsTable = computePivotTableStatistics(pivotedTable);
            statisticsTable = renamevars(statisticsTable, statisticsTable.Properties.VariableNames, ...
                        strcat(statisticsTable.Properties.VariableNames, '_', selectedParameter, '_by_', targetParam));
            tableCell{i} = statisticsTable;
        end
    end

    % Combine the tables
    summarizedTable = horzcat(tableCell{:});
    % summarizedTable.Properties.RowNames = string(pivotedTable.(groupParam));

end
    