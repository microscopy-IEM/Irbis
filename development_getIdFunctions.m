function objectId = getObjectIdFromGroupId(groupId, T)
    arguments
        groupId {mustBeNumeric, mustBePositive}
        T {mustBeA(T, 'table')}
    end

    % Find the row where groupId matches and get the corresponding objectId
    rowNum = find(T.groupId == groupId);
    if isempty(rowNum)
        objectId = [];
    else

        if ~istable(T) || isempty(T.Properties.RowNames)
            error('Table T must have row names');
        end

        if length(rowNum) > 1
            error('Multiple rows found for groupId %d', groupId);
        end

        objectId = T.Properties.RowNames{rowNum};
    end
end

function columnValue = getColumnValueFromObjectId(objectId, columnName, T)
    arguments
        objectId {mustBeNumeric, mustBePositive}
        columnName {mustBeTextScalar}
        T {mustBeA(T, 'table')}
    end

    % Find the row where objectId matches and get the corresponding column value
    rowName = string(objectId);
    rowNum = find(strcmp(rowName, T.Properties.RowNames));
    if isempty(rowNum)
        columnValue = [];
    else

        if ~istable(T) || isempty(T.Properties.RowNames)
            error('Table T must have row names');
        end

        if length(rowNum) > 1
            error('Multiple rows found for objectId %s', objectId);
        end

        columnValue = T{rowNum, columnName};
    end
end

function groupId = getGroupIdFromObjectId(objectId, T)
    arguments
        objectId {mustBeNumeric, mustBePositive}
        T {mustBeA(T, 'table')}
    end

    % Find the row where objectId matches and get the corresponding groupId
    rowName = string(objectId);
    rowNum = find(strcmp(rowName, T.Properties.RowNames));
    if isempty(rowNum)
        groupId = [];
    else

        if ~istable(T) || isempty(T.Properties.RowNames)
            error('Table T must have row names');
        end

        if length(rowNum) > 1
            error('Multiple rows found for objectId %s', objectId);
        end

        groupId = T.groupId(rowNum);
    end
end

function columnValue = getColumnValueFromGroupId(groupId, columnName, T)
    arguments
        groupId {mustBeNumeric, mustBePositive}
        columnName {mustBeTextScalar}
        T {mustBeA(T, 'table')}
    end

    % Find the row where groupId matches and get the corresponding column value
    rowNum = find(T.groupId == groupId);
    if isempty(rowNum)
        columnValue = [];
    else

        if ~istable(T) || isempty(T.Properties.RowNames)
            error('Table T must have row names');
        end

        if length(rowNum) > 1
            error('Multiple rows found for groupId %d', groupId);
        end

        columnValue = T{rowNum, columnName};
    end
end