function pivotedTable = pivotTable(inputTable, varR, varC, varD, groupByR, groupByC)
    % Pivots a table based on specified row, column, and data variables.
    % Inputs:
    %   inputTable - MATLAB table containing the data
    %   varR - Row variable (categorical, numerical, or logical)
    %   varC - Column variable (categorical, numerical, or logical)
    %   varD - Data variable to aggregate in the pivot table
    %   groupByR - (Optional) Grouping for varR [minVal, maxVal, binWidth]
    %   groupByC - (Optional) Grouping for varC [minVal, maxVal, binWidth]

    % Convert numerical/logical row variable to categorical if grouping is specified
    if nargin > 4 && ~isempty(groupByR)
        if isnumeric(inputTable.(varR)) || islogical(inputTable.(varR))
            inputTable.(varR) = groupNumeric(inputTable.(varR), groupByR(1), groupByR(2), groupByR(3));
        end
    end

    % Convert numerical/logical column variable to categorical if grouping is specified
    if nargin > 4 && ~isempty(groupByC)
        if isnumeric(inputTable.(varC)) || islogical(inputTable.(varC))
            inputTable.(varC) = groupNumeric(inputTable.(varC), groupByC(1), groupByC(2), groupByC(3));
        end
    end

    % Ensure row and column variables are categorical
    inputTable.(varR) = categorical(inputTable.(varR));
    inputTable.(varC) = categorical(inputTable.(varC));

    % Pivot the data
    [rowCategories, ~, rowIdx] = unique(inputTable.(varR));
    [colCategories, ~, colIdx] = unique(inputTable.(varC));
    pivotedData = accumarray([rowIdx, colIdx], inputTable.(varD), [], @mean, NaN); % Aggregation using mean

    % Create output table
    pivotedTable = array2table(pivotedData, 'RowNames', cellstr(rowCategories), ...
        'VariableNames', cellstr(colCategories));
end

function groupedData = groupNumeric(data, minVal, maxVal, binWidth)
    % Groups numerical data into bins
    edges = minVal:binWidth:maxVal;
    edges(end) = edges(end) + 1; % Include upper boundary
    groupedData = discretize(data, edges, 'categorical', string(edges(1:end-1)));
end
