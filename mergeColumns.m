function [T, newColName] = mergeColumns(T, selectedCols)
    % Verify all selected columns exist in the table
    if ~all(ismember(selectedCols, T.Properties.VariableNames))
        missingCols = selectedCols(~ismember(selectedCols, T.Properties.VariableNames));
        error('Columns not found in table: %s', strjoin(missingCols, ', '));
    end

    mergedData = strings(height(T), 1);
    
    % Create new column name by joining selected column names
    newColName = strjoin(selectedCols, '_');
    
    for i = 1:numel(selectedCols)
        colData = string(T.(selectedCols{i}));
        
        % Handle NaN or undefined values by omitting them
        validIdx = ~ismissing(colData);
        
        % Merge only valid entries
        if i == 1
            mergedData(validIdx) = colData(validIdx);
        else
            mergedData(validIdx) = mergedData(validIdx) + "_" + colData(validIdx);
        end
    end
    
    % Add merged data as a new column with combined name
    T.(newColName) = categorical(mergedData);
end