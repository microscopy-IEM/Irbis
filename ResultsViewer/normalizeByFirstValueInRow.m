function normalizedTable = normalizeByFirstValueInRow(tableToNormalize)
    % Normalize each value in the table by the first value in its row
    normalizedTable = tableToNormalize;  % Initialize the normalized table with the same structure
    for i = 1:size(tableToNormalize, 1)  % Loop through each row
        rowValues = tableToNormalize{i, :};  % Get numeric values in the row

        % Find first valid normalization value (not 0 and not NaN)
        validIdx = find(~isnan(rowValues) & rowValues ~= 0, 1, 'first');

        if ~isempty(validIdx)
            normValue = rowValues(validIdx);
            normalizedTable{i, :} = rowValues / normValue;  % Normalize by first valid value
        else
            normalizedTable{i, :} = rowValues;  % No valid value found; keep original row
        end
    end
end
