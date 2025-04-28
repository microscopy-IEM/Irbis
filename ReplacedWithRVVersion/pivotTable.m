function pivotedTable = pivotTable(inputTable, columnVarName, rowVarName, dataVarName, varargin)
    % pivotTable - Creates a pivot table from the input table based on specified row, column, and data variables.
    %
    % Syntax:
    %   pivotedTable = pivotTable(inputTable, columnVarName, rowVarName, dataVarName)
    %   pivotedTable = pivotTable(inputTable, columnVarName, rowVarName, dataVarName, aggregationMethod, nRowBins, nColumnBins)
    %
    % Inputs:
    %   inputTable       - Input table containing the data to be pivoted.
    %   columnVarName    - Name of the variable to be used as columns in the pivot table.
    %   rowVarName       - Name of the variable to be used as rows in the pivot table.
    %   dataVarName      - Name of the variable to be used as data in the pivot table.
    %   aggregationMethod - (Optional) Method to aggregate data in the pivot table. Default is "mean". Categorical data is only aggregated using "mode".
    %   nRowBins         - (Optional) Number of bins for row variable. Default is "none". Can be used only if the variable is numerical.
    %   nColumnBins      - (Optional) Number of bins for column variable. Default is "none". Can be used only if the variable is numerical.
    %
    % Outputs:
    %   pivotedTable     - The resulting pivot table.
    %
    % Example:
    %   pivotedTable = pivotTable(inputTable, 'ColumnVar', 'RowVar', 'DataVar');
    %   pivotedTable = pivotTable(inputTable, 'ColumnVar', 'RowVar', 'DataVar', 'sum', 5, 5);
    %
    % Notes:
    %   - The function checks if the specified row, column, and data variables exist in the input table.
    %   - If the number of input arguments is not 4 or 7, an error is raised.
    %   - If the row or column variables are not numeric, binning is disabled for those variables.
    %   - If the data variable is categorical, the aggregation method is set to "mode".
    %   - If the data variable is logical, the aggregation method is set to "mean".

    % Ensure that selected variables are in the inputTable, raise error if not
    if ~ismember(columnVarName, inputTable.Properties.VariableNames)
        error("Column variable not found in the input table.");
    end
    if ~ismember(rowVarName, inputTable.Properties.VariableNames)
        error("Row variable not found in the input table.");
    end
    if ~ismember(dataVarName, inputTable.Properties.VariableNames)
        error("Data variable not found in the input table.");
    end

    if nargin == 7
        % Optional parameters added: 
        % aggregationMethod - method to aggregate data in the pivot table
        % nRowBins - number of bins for row variable
        % nColumnBins - number of bins for column variable

        if isempty(varargin{1})
            aggregationMethod = "mean";
        else
            aggregationMethod = varargin{1};
        end

        if isempty(varargin{2})
            rowGrouping = "none";
        else
            nRowBins = varargin{2};
            rowGrouping = nRowBins;
        end

        if isempty(varargin{3})
            columnGrouping = "none";
        else
            nColumnBins = varargin{3};
            columnGrouping = nColumnBins;
        end
    elseif nargin == 4
        aggregationMethod = "mean";
        rowGrouping = "none";
        columnGrouping = "none";
    else
        error("Invalid number of input arguments.");
    end

    % Check whether the optional parameters work with the variable types
    % Bins can be used only if the variable is numerical
    if ~isnumeric(inputTable.(rowVarName))
        rowGrouping = "none";
    end

    if ~isnumeric(inputTable.(columnVarName))
        columnGrouping = "none";
    end

    if iscategorical(inputTable.(dataVarName))
        aggregationMethod = "mode";    % changed to 'mode' (the most frequent category) from 'count'
    elseif islogical(inputTable.(dataVarName))
        aggregationMethod = "mean";
    end

    % disp(aggregationMethod)
    % disp(rowGrouping)
    % disp(columnGrouping)

    pivotedTable = pivot(inputTable, "Rows", rowVarName, "Columns", columnVarName, "DataVariable", dataVarName, ...
    "Method", aggregationMethod, "RowsBinMethod", rowGrouping, "ColumnsBinMethod", columnGrouping);

    % the first column contains the row info -> turn it into row names
    rowNames = pivotedTable{:, 1};
    missingList = ismissing(rowNames);
    if ~isempty(missingList)
        rowNames = string(rowNames);
        rowNames(missingList) = "NaN";
    else
        rowNames = string(rowNames);
    end

    % deal with some values being there multiple times - do not assign the row names
    if length(unique(rowNames)) == length(rowNames)
        pivotedTable.Properties.RowNames = rowNames;
    end

    pivotedTable(:, 1) = [];
end