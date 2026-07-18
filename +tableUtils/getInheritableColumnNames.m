function columnsToInherit = getInheritableColumnNames()
    % Returns a string array of column names that can be inherited from the original object to the new object.
    % This is used when splitting an object to decide which of its properties are copied. 
    columnsToInherit = ["parentId", "parent", "positionShift", "color", "timePoint"];
end