function summaryTable = computePivotTableStatistics(inputTable)
    % Calculates summary statistics for rows in input table.
    % Input: table (combinedTable from results viewer) with groupId per line
    % Output: table with summary statistics for each row
    % The table needs to contain only the uniform column, not the column with the group names!

    % Initialize result table
    stats = {'Mean', 'StdDev', 'Min', 'Max', 'Slope', 'RSquared', 'ObservationCount'};
    summaryTable = array2table(zeros(size(inputTable, 1), numel(stats)), ...
                              'VariableNames', stats, ...
                              'RowNames', inputTable.Properties.RowNames);

    % Convert table to array for efficient computation
    dataArray = table2array(inputTable);

    % Basic statistics (vectorized)
    summaryTable.Mean = mean(dataArray, 2, 'omitnan');
    summaryTable.StdDev = std(dataArray, 0, 2, 'omitnan');
    summaryTable.Min = min(dataArray, [], 2, 'omitnan');
    summaryTable.Max = max(dataArray, [], 2, 'omitnan');
    summaryTable.ObservationCount = sum(~isnan(dataArray), 2);

    % Slope and R^2 calculations (row-wise)
    x = 1:size(dataArray, 2); % Independent variable
    for i = 1:size(dataArray, 1)
        rowData = dataArray(i, :);

        % Skip empty rows
        if all(isnan(rowData))
            continue;
        end

        validIdx = ~isnan(rowData);
        if sum(validIdx) > 1
            % Fit linear model
            p = polyfit(x(validIdx), rowData(validIdx), 1);
            summaryTable.Slope(i) = p(1);

            % Compute R^2
            yFit = polyval(p, x(validIdx));
            SSres = sum((rowData(validIdx) - yFit).^2);
            SStot = sum((rowData(validIdx) - mean(rowData(validIdx))).^2);
            summaryTable.RSquared(i) = 1 - (SSres / SStot);
        else
            summaryTable.Slope(i) = NaN;
            summaryTable.RSquared(i) = NaN;
        end
    end
end
