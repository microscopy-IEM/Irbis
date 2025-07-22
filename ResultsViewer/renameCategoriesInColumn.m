function newManualColumn = renameCategoriesInColumn(manualColumn, oldGroupNames, newGroupNames)

    % function taken originally from SummarizedTableComponentHelper - applyGroupNameChanges
    % Determine added, renamed, and removed group names
    addedGroups = newGroupNames((length(oldGroupNames) + 1):end);
    newManualColumn = addcats(manualColumn, addedGroups);
    
    removedGroupsIdx = find(cellfun('isempty', newGroupNames));
    removedGroupsIdx = removedGroupsIdx(removedGroupsIdx <= length(oldGroupNames)); % we care only about the groups that have a match in oldGroupNames
    removedGroups = oldGroupNames(removedGroupsIdx);
    newManualColumn = removecats(newManualColumn, removedGroups);

    renamedGroupsIdx = find(~cellfun('isempty', newGroupNames) & ~strcmp(oldGroupNames, newGroupNames));
    % Keep only renamedGroupsIdx with value max length of oldGroupNames
    renamedGroupsIdx = renamedGroupsIdx(renamedGroupsIdx <= length(oldGroupNames)); % we care only about the groups that have a match in oldGroupNames
    oldGroupNames = oldGroupNames(renamedGroupsIdx);
    newGroupNames = newGroupNames(renamedGroupsIdx);
    newManualColumn = renamecats(newManualColumn, oldGroupNames, newGroupNames);
end