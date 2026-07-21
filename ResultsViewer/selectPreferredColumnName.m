function selectedName = selectPreferredColumnName(columnNames, preferredNames)
%selectPreferredColumnName Choose the first available name from a preference list.
%
% Several ResultsViewer components need the same defaulting rule: use a
% semantically richer column such as fileId_groupId when it exists, otherwise
% fall back to the older groupId default, and finally use the first available
% column. Keeping the rule in one helper prevents Pivoted and Summarized tables
% from drifting apart as more preferred identifiers are added.

    selectedName = '';

    if isempty(columnNames)
        return
    end

    if isstring(columnNames)
        columnNames = cellstr(columnNames);
    end

    if ischar(columnNames)
        columnNames = {columnNames};
    end

    if isstring(preferredNames)
        preferredNames = cellstr(preferredNames);
    end

    if ischar(preferredNames)
        preferredNames = {preferredNames};
    end

    for preferredId = 1:numel(preferredNames)
        preferredName = preferredNames{preferredId};
        if ismember(preferredName, columnNames)
            selectedName = preferredName;
            return
        end
    end

    selectedName = columnNames{1};
end
