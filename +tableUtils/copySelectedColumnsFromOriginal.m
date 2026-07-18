function T = copySelectedColumnsFromOriginal(T, originalRowId, newObjectId, columnsToCopy)

    % Split children should keep only selected provenance/display values from the original object.
    for columnName = columnsToCopy
        if ~ismember(columnName, string(T.Properties.VariableNames))
            continue
        end

        T(num2str(newObjectId), char(columnName)) = T(num2str(originalRowId), char(columnName));
    end

end
