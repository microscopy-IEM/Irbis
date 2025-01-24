function resultTable = categoricaldByTimepointTableFromCombinedList(combinedList, categoricalParameter, attribute)
    % Input:
    % inputTable: Table with columns: timepoint (categorical), groupId (numeric), and attribute (numeric or other type)
    % attribute: The name of the attribute column to use as values in the pivot table (string)

    % Check if the input table contains the required columns
    if ~all(ismember({'timePoint', categoricalParameter, attribute}, combinedList.Properties.VariableNames))
        fprintf('Input table must contain columns: timePoint, groupId, and %s', attribute);
        resultTable = [];
        return
    end

    if isempty(combinedList)
        resultTable = [];
        return
    end

    % Select only the necessary columns (timepoint, groupId, and attribute)
    inputTable = combinedList(:, {'timePoint', categoricalParameter, attribute});
    % inputTable.timePoint = string(inputTable.timePoint);
    % inputTable.groupId = str2double(string(inputTable.groupId));

    % Unstack the table: timepoints as columns, groupIds as rows
    resultTable = unstack(inputTable, attribute, 'timePoint',"AggregationFunction",@mean,"VariableNamingRule","preserve");

    disp(resultTable)
    
    % % Set the row names as groupId
    resultTable.Properties.RowNames = cellstr(string(resultTable.(categoricalParameter)));
    resultTable.groupId = []; % Remove the groupId column since it's now the row names
    % resultTable.Properties.VariableNames = categories(inputTable.timePoint);

    

    % 
    % % Fill missing combinations with NaN
    % resultTable = standardizeMissing(resultTable, []); % Optional, to ensure missing values are set as NaN
end
