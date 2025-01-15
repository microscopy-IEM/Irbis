function summaryTable = computeGroupIdStatistics(inputTable)
    % Calculates summary statistics for rows in input table.
    % Input: table (combinedTable from results viewer) with groupId per line
    % Output: table with summary statistics for each row

    % Initialize result table
    stats = {'Mean', 'StdDev', 'Min', 'Max', 'Slope', 'RSquared', 'ObservationCount'};
    summaryTable = array2table(zeros(size(inputTable, 1), numel(stats)), ...
                              'VariableNames', stats, ...
                              'RowNames', inputTable.Properties.RowNames);

    for i = 1:height(inputTable)
        rowData = inputTable{i, :};

        % Skip empty rows
        if all(isnan(rowData))
            continue;
        end

        % Calculate basic statistics
        summaryTable.Mean(i) = mean(rowData, 'omitnan');
        summaryTable.StdDev(i) = std(rowData, 'omitnan');
        summaryTable.Min(i) = min(rowData, [], 'omitnan');
        summaryTable.Max(i) = max(rowData, [], 'omitnan');

        % Fit a linear model to compute slope and goodness of fit
        x = 1:numel(rowData);
        validIdx = ~isnan(rowData);
        if length(x(validIdx)) > 1
            p = polyfit(x(validIdx), rowData(validIdx), 1);
            summaryTable.Slope(i) = p(1);

            % Compute R^2 for goodness of fit
            yFit = polyval(p, x(validIdx));
            SSres = sum((rowData(validIdx) - yFit).^2);
            SStot = sum((rowData(validIdx) - mean(rowData(validIdx))).^2);
            summaryTable.RSquared(i) = 1 - (SSres / SStot);
        else
            % disp(['Group id ' num2str(i) ' has less than 2 points.'])
            summaryTable.Slope(i) = NaN;
            summaryTable.RSquared(i) = NaN;
        end
 
        summaryTable.ObservationCount(i) = sum(validIdx);
    end
end