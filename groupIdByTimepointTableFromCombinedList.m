function resultTable = groupIdByTimepointTableFromCombinedList(combinedList, attribute)
    % Input:
    % inputTable: Table with columns: timepoint (categorical), groupId (numeric), and attribute (numeric or other type)
    % attribute: The name of the attribute column to use as values in the pivot table (string)

    % Check if the input table contains the required columns
    if ~all(ismember({'timePoint', 'groupId', attribute}, combinedList.Properties.VariableNames))
        disp('Input table must contain columns: timePoint, groupId, and %s', attribute);
        resultTable = [];
        return
    end

    % Remove rows where groupId is 0
    combinedList(combinedList.groupId == categorical("0"), :) = [];

    if isempty(combinedList)
        resultTable = [];
        return
    end

    % Select only the necessary columns (timepoint, groupId, and attribute)
    inputTable = combinedList(:, {'timePoint', 'groupId', attribute});
    % inputTable.timePoint = string(inputTable.timePoint);
    % inputTable.groupId = str2double(string(inputTable.groupId));

    % Unstack the table: timepoints as columns, groupIds as rows
    resultTable = unstack(inputTable, attribute, 'timePoint',"AggregationFunction",@mean,"VariableNamingRule","preserve");

    % % Set the row names as groupId
    resultTable.Properties.RowNames = cellstr(string(resultTable.groupId));
    resultTable.groupId = []; % Remove the groupId column since it's now the row names
    % resultTable.Properties.VariableNames = categories(inputTable.timePoint);

    % 
    % % Fill missing combinations with NaN
    % resultTable = standardizeMissing(resultTable, []); % Optional, to ensure missing values are set as NaN
end
