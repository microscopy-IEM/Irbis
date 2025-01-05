function [columnNamesScalar, columnNamesVector, columnNamesCategorical, columnNamesCell] = groupColumnsByType(T)

    % groupColumnsByType - Groups columns of a table by their data type.
    %
    % Inputs:
    %   T - Table containing data to be analyzed.
    %
    % Outputs:
    %   columnNamesScalar - Cell array of names of columns containing scalar numeric values.
    %   columnNamesVector - Cell array of names of columns containing vector numeric values.
    %   columnNamesCategorical - Cell array of names of columns containing categorical values.
    %   columnNamesCell - Cell array of names of columns containing cell values.
    %
    % Description:
    %   This function identifies and groups the columns of a table 'T' based on their data types.
    %   It categorizes columns into numeric, categorical, and cell types. Additionally, it further
    %   distinguishes numeric columns into those containing scalar values and those containing vector values.
    %
    % Notes:
    %   - The function checks only the first entry of each numeric column to determine if it is scalar or vector.

    % Identify numeric, categorical, and cell columns
    numericCols = varfun(@isnumeric, T, 'OutputFormat', 'uniform');
    columnNamesNumeric = T.Properties.VariableNames(numericCols);
    categoricalCols = varfun(@iscategorical, T, 'OutputFormat', 'uniform');
    columnNamesCategorical = T.Properties.VariableNames(categoricalCols);
    cellCols = varfun(@iscell, T, 'OutputFormat', 'uniform');
    columnNamesCell = T.Properties.VariableNames(cellCols);

    % Initialize empty arrays for scalars and vectors
    columnNamesScalar = {};
    columnNamesVector = {};

    % Loop through numeric columns and check if the first value is scalar or vector
    for i = 1:numel(columnNamesNumeric)
        colData = T.(columnNamesNumeric{i});
        
        % Check if the first entry is scalar or vector
        firstEntry = colData(1);
        
        if isscalar(firstEntry)
            columnNamesScalar{end+1} = columnNamesNumeric{i};
        elseif isvector(firstEntry)
            columnNamesVector{end+1} = columnNamesNumeric{i};
        end
    end

end
