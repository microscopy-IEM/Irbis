function columnTypes = determineColumnTypes(selectedData)
    % Identifies data types for each column
    isNumeric = varfun(@isnumeric, selectedData, 'OutputFormat', 'uniform');
    isCategorical = varfun(@iscategorical, selectedData, 'OutputFormat', 'uniform');
    isCell = varfun(@iscell, selectedData, 'OutputFormat', 'uniform');
    isLogical = varfun(@islogical, selectedData, 'OutputFormat', 'uniform');
    
    columnTypes = repmat({''}, 1, width(selectedData));
    columnTypes(isNumeric) = {'numeric'};
    columnTypes(isCategorical) = {'categorical'};
    columnTypes(isCell) = {'cell'};
    columnTypes(isLogical) = {'logical'};
    
    for i = find(~isNumeric & ~isCategorical & ~isCell & ~isLogical)
        columnTypes{i} = class(selectedData{1, i});
    end
end
