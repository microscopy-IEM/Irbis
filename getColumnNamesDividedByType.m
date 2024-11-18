function [columnNamesNumerical, columnNamesCategorical, columnNamesCell] = getColumnNamesDividedByType(inputTable)
    % takes a table and outputs names of numerical, categorical and cell columns

    % numeric columns
    doubleCols = varfun(@isnumeric, inputTable, 'OutputFormat', 'uniform');
    columnNamesNumerical = inputTable.Properties.VariableNames(doubleCols);

    % categorical columns
    categoricalCols = varfun(@iscategorical, inputTable, 'OutputFormat', 'uniform');
    columnNamesCategorical = inputTable.Properties.VariableNames(categoricalCols);

    % cell columns
    cellCols = varfun(@iscell, inputTable, 'OutputFormat', 'uniform');
    columnNamesCell = inputTable.Properties.VariableNames(cellCols);
end