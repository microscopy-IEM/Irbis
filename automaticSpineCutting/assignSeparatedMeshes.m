function [tableArray, usedGizmos, assignmentTable, objectsToRemove] = assignSeparatedMeshes(tableArray, usedGizmos, separatedMeshes, timePoint, opts)
%ASSIGNSEPARATEDMESHESTOUSEGIZMOS Assign boolean result meshes to original objects.
%
% [tableArray, usedGizmos, assignmentTable, objectsToRemove] = ...
%     assignSeparatedMeshesToUsedGizmos(...)
% maps each mesh in separatedMeshes back to the original object referenced
% by usedGizmos.timePoint/inputId, fills usedGizmos.outputIds, and writes
% the separated meshes into tableArray.
%
% One original object may receive many separated meshes. If any referenced
% original object receives no separated mesh, an exception is thrown.
% If exactly one separated mesh maps to an original object, it keeps the
% original object id and overwrites that row's Mesh. If multiple meshes map
% to one original object, all of them receive new unused ids and are added
% to the end of the time point table. The original id is returned in
% objectsToRemove but is not removed from tableArray.

arguments
    tableArray cell
    usedGizmos table
    separatedMeshes cell
    timePoint double
    opts.MinimumOverlapScore (1,1) double = 0.001
    opts.BoundingBoxPaddingFraction (1,1) double = 0.03
end

assignmentTable = initializeAssignmentTable();
objectsToRemove = initializeObjectsToRemoveTable();

if height(usedGizmos) == 0
    return
end

originalObjects = collectReferencedOriginalObjects(tableArray, usedGizmos, timePoint);

if isempty(originalObjects)
    return
end

scoreMatrix = zeros(numel(separatedMeshes), numel(originalObjects));

for meshIndex = 1:numel(separatedMeshes)
    separatedVertices = meshVertices(separatedMeshes{meshIndex});

    if isempty(separatedVertices)
        continue
    end

    separatedCenter = mean(separatedVertices, 1);

    for objectIndex = 1:numel(originalObjects)
        scoreMatrix(meshIndex, objectIndex) = objectCorrespondenceScore( ...
            separatedVertices, ...
            separatedCenter, ...
            originalObjects(objectIndex), ...
            opts.BoundingBoxPaddingFraction);
    end
end

[bestScores, bestObjectIndexes] = max(scoreMatrix, [], 2);
assignedOutputIds = cell(numel(originalObjects), 1);
assignedMeshIndexes = cell(numel(originalObjects), 1);

for meshIndex = 1:numel(separatedMeshes)
    if bestScores(meshIndex) < opts.MinimumOverlapScore
        continue
    end

    objectIndex = bestObjectIndexes(meshIndex);
    assignedMeshIndexes{objectIndex}(end+1) = meshIndex; %#ok<AGROW>
end

missingObjectIndexes = find(cellfun(@isempty, assignedMeshIndexes));

if ~isempty(missingObjectIndexes)
    missingDescriptions = strings(numel(missingObjectIndexes), 1);

    for k = 1:numel(missingObjectIndexes)
        objectIndex = missingObjectIndexes(k);
        missingDescriptions(k) = sprintf( ...
            'timePoint=%g inputId=%g', ...
            originalObjects(objectIndex).timePoint, ...
            originalObjects(objectIndex).inputId);
    end

    warning('AssignSeparatedMeshes:MissingOutputForOriginalObject', ...
        'No separated mesh was assigned to original object(s): %s.', ...
        strjoin(missingDescriptions, ', '));
end

assignedOutputIds = deduceOutputIdsFromOriginalTables( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes);

[tableArray, objectsToRemove] = applySeparatedMeshesToTableArray( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes, ...
    assignedOutputIds, ...
    separatedMeshes);

for objectIndex = 1:numel(originalObjects)
    meshIndexes = assignedMeshIndexes{objectIndex};

    for localIndex = 1:numel(meshIndexes)
        newRow = height(assignmentTable) + 1;
        assignmentTable.timePoint(newRow) = originalObjects(objectIndex).timePoint;
        assignmentTable.inputId(newRow) = originalObjects(objectIndex).inputId;
        assignmentTable.separatedMeshIndex(newRow) = meshIndexes(localIndex);
        assignmentTable.outputId(newRow) = assignedOutputIds{objectIndex}(localIndex);
        assignmentTable.score(newRow) = bestScores(meshIndexes(localIndex));
    end

    rowMask = usedGizmos.timePoint == originalObjects(objectIndex).timePoint & ...
        usedGizmos.inputId == originalObjects(objectIndex).inputId;

    usedGizmos.outputIds(rowMask) = ...
        repmat({assignedOutputIds{objectIndex}}, nnz(rowMask), 1);
end

end



function assignmentTable = initializeAssignmentTable()

assignmentTable = table( ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    'VariableNames', { ...
        'timePoint', ...
        'inputId', ...
        'separatedMeshIndex', ...
        'outputId', ...
        'score'});

end



function objectsToRemove = initializeObjectsToRemoveTable()

objectsToRemove = table( ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    'VariableNames', { ...
        'timePoint', ...
        'objectId'});

end



function originalObjects = collectReferencedOriginalObjects(tableArray, usedGizmos, timePoint)

% keep only entries matching the requested timePoint
tpMask = usedGizmos.timePoint(:) == timePoint;
keys = [usedGizmos.timePoint(tpMask), usedGizmos.inputId(tpMask)];
validMask = all(isfinite(keys), 2);
keys = unique(keys(validMask, :), 'rows');

originalObjects = struct( ...
    'timePoint', {}, ...
    'inputId', {}, ...
    'vertices', {}, ...
    'center', {}, ...
    'bboxMin', {}, ...
    'bboxMax', {}, ...
    'bboxSize', {});

for keyIndex = 1:size(keys, 1)
    timePoint = keys(keyIndex, 1);
    inputId = keys(keyIndex, 2);
    originalMesh = getObjectMeshById(tableArray, timePoint, inputId);
    vertices = meshVertices(originalMesh);

    if isempty(vertices)
        error('AssignSeparatedMeshes:EmptyOriginalMesh', ...
            'Original object timePoint=%g inputId=%g has no vertices.', ...
            timePoint, ...
            inputId);
    end

    bboxMin = min(vertices, [], 1);
    bboxMax = max(vertices, [], 1);

    originalObjects(end+1).timePoint = timePoint; %#ok<AGROW>
    originalObjects(end).inputId = inputId;
    originalObjects(end).vertices = vertices;
    originalObjects(end).center = mean(vertices, 1);
    originalObjects(end).bboxMin = bboxMin;
    originalObjects(end).bboxMax = bboxMax;
    originalObjects(end).bboxSize = max(bboxMax - bboxMin, eps);
end

end



function assignedOutputIds = deduceOutputIdsFromOriginalTables( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes)

assignedOutputIds = cell(numel(originalObjects), 1);
timePoints = unique([originalObjects.timePoint]);
nextObjectIds = containers.Map('KeyType', 'double', 'ValueType', 'double');

for timePoint = timePoints(:).'
    existingIds = existingObjectIdsAtTimePoint(tableArray, timePoint);

    if isempty(existingIds)
        nextObjectIds(timePoint) = 1;
    else
        nextObjectIds(timePoint) = max(existingIds) + 1;
    end
end

for objectIndex = 1:numel(originalObjects)
    nAssignedMeshes = numel(assignedMeshIndexes{objectIndex});

    if nAssignedMeshes == 0
        continue
    elseif nAssignedMeshes == 1
        assignedOutputIds{objectIndex} = originalObjects(objectIndex).inputId;
        continue
    end

    timePoint = originalObjects(objectIndex).timePoint;
    firstNewId = nextObjectIds(timePoint);
    newIds = firstNewId:(firstNewId + nAssignedMeshes - 1);
    nextObjectIds(timePoint) = newIds(end) + 1;
    assignedOutputIds{objectIndex} = newIds;
end

end



function existingIds = existingObjectIdsAtTimePoint(tableArray, timePoint)

if timePoint < 1 || timePoint > numel(tableArray)
    error('AssignSeparatedMeshes:InvalidTimePoint', ...
        'Time point %g is outside tableArray.', timePoint);
end

rowNames = string(tableArray{timePoint}.Properties.RowNames);
existingIds = str2double(rowNames);
existingIds = existingIds(isfinite(existingIds));

end



function [tableArray, objectsToRemove] = applySeparatedMeshesToTableArray( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes, ...
    assignedOutputIds, ...
    separatedMeshes)

objectsToRemove = initializeObjectsToRemoveTable();

for objectIndex = 1:numel(originalObjects)
    originalObject = originalObjects(objectIndex);
    meshIndexes = assignedMeshIndexes{objectIndex};
    outputIds = assignedOutputIds{objectIndex};
    objectTable = tableArray{originalObject.timePoint};
    originalRowIndex = objectRowIndexById( ...
        objectTable, ...
        originalObject.inputId);

    if numel(meshIndexes) == 1
        objectTable.Mesh{originalRowIndex} = separatedMeshes{meshIndexes(1)};
        objectTable{originalRowIndex, 'edited'} = true;
        tableArray{originalObject.timePoint} = objectTable;
        continue
    end

    newRemoveRow = height(objectsToRemove) + 1;
    objectsToRemove.timePoint(newRemoveRow) = originalObject.timePoint;
    objectsToRemove.objectId(newRemoveRow) = originalObject.inputId;

    for localIndex = 1:numel(meshIndexes)
        newObjectId = char(string(outputIds(localIndex)));
        objectTable(newObjectId, :) = objectTable(originalRowIndex, :);
        objectTable.Mesh{newObjectId} = separatedMeshes{meshIndexes(localIndex)};
        objectTable{newObjectId, 'edited'} = true;
    end

    tableArray{originalObject.timePoint} = objectTable;
end

end



function score = objectCorrespondenceScore(separatedVertices, separatedCenter, originalObject, paddingFraction)

padding = max(originalObject.bboxSize) * paddingFraction;
bboxMin = originalObject.bboxMin - padding;
bboxMax = originalObject.bboxMax + padding;

insideMask = all(separatedVertices >= bboxMin & separatedVertices <= bboxMax, 2);
insideFraction = mean(insideMask);

centerDistance = norm(separatedCenter - originalObject.center);
objectScale = max(norm(originalObject.bboxSize), eps);
distanceScore = exp(-centerDistance / objectScale);

score = 0.85 * insideFraction + 0.15 * distanceScore;

end



function mesh = getObjectMeshById(tableArray, timePoint, inputId)

if timePoint < 1 || timePoint > numel(tableArray)
    error('AssignSeparatedMeshes:InvalidTimePoint', ...
        'Time point %g is outside tableArray.', timePoint);
end

objectTable = tableArray{timePoint};
rowIndex = objectRowIndexById(objectTable, inputId);

mesh = objectTable.Mesh{rowIndex};

end



function rowIndex = objectRowIndexById(objectTable, objectId)

rowNames = string(objectTable.Properties.RowNames);
rowIndex = find(rowNames == string(objectId), 1);

if isempty(rowIndex)
    error('AssignSeparatedMeshes:UnknownObjectId', ...
        'Object id %g was not found in the object table.', ...
        objectId);
end

end



function vertices = meshVertices(mesh)

if isempty(mesh)
    vertices = zeros(0, 3);
elseif isstruct(mesh)
    if isfield(mesh, 'Vertices')
        vertices = mesh.Vertices;
    elseif isfield(mesh, 'vertices')
        vertices = mesh.vertices;
    else
        error('AssignSeparatedMeshes:MissingVertices', ...
            'Mesh struct is missing Vertices/vertices.');
    end
elseif isobject(mesh) && isprop(mesh, 'Vertices')
    vertices = mesh.Vertices;
else
    error('AssignSeparatedMeshes:UnsupportedMeshType', ...
        'Mesh must be a struct or object with Vertices.');
end

vertices = double(vertices);

if ~isempty(vertices) && size(vertices, 2) ~= 3
    error('AssignSeparatedMeshes:InvalidVertices', ...
        'Mesh vertices must be an N-by-3 array.');
end

end
