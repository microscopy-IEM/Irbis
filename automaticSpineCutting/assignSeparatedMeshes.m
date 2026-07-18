function [tableArray, usedGizmos, assignmentTable, objectsToRemove] = assignSeparatedMeshes(tableArray, usedGizmos, separatedMeshes, timePoint, opts)
%ASSIGNSEPARATEDMESHES Assign boolean result meshes to original objects.
%
% [tableArray, usedGizmos, assignmentTable, objectsToRemove] = ...
%     assignSeparatedMeshes(...)
% Maps separatedMeshes back to original objects referenced by usedGizmos.timePoint/inputId.
% Fills usedGizmos.outputIds and writes the separated meshes into tableArray.
%
% One original object may receive many separated meshes.
% If any referenced original object receives no separated mesh, an exception is thrown.
% If exactly one separated mesh maps to an original object, it keeps the original object id and overwrites that row's Mesh.
% If multiple meshes map to one original object, all of them receive new unused ids and are added to the end of the time point table.
% The original id is returned in objectsToRemove but is not removed from tableArray.

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

% Nothing to resolve if the user did not accept any cutting gizmos.
if height(usedGizmos) == 0
    return
end

% Work with unique original objects for this time point.
% Several gizmos can target the same object, but assignment should happen once per object.
originalObjects = collectReferencedOriginalObjects(tableArray, usedGizmos, timePoint);

if isempty(originalObjects)
    return
end

% Compare every separated result mesh against every referenced original object.
% The score is intentionally geometric, because the boolean backend returns meshes without provenance.
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

% Assign each separated mesh to the original object with the best score.
% Low-score meshes are ignored so small fragments/noise do not become output objects.
[bestScores, bestObjectIndexes] = max(scoreMatrix, [], 2);
assignedOutputIds = cell(numel(originalObjects), 1);
assignedMeshIndexes = cell(numel(originalObjects), 1);

for meshIndex = 1:numel(separatedMeshes)
    if ~isfinite(bestScores(meshIndex)) || bestScores(meshIndex) < opts.MinimumOverlapScore
        continue
    end

    objectIndex = bestObjectIndexes(meshIndex);
    assignedMeshIndexes{objectIndex}(end+1) = meshIndex; %#ok<AGROW>
end

missingObjectIndexes = find(cellfun(@isempty, assignedMeshIndexes));

% Every referenced object must produce at least one output.
% Otherwise later removal/replacement logic would leave the model table inconsistent.
if ~isempty(missingObjectIndexes)
    missingDescriptions = strings(numel(missingObjectIndexes), 1);

    for k = 1:numel(missingObjectIndexes)
        objectIndex = missingObjectIndexes(k);
        missingDescriptions(k) = sprintf( ...
            'timePoint=%g inputId=%g', ...
            originalObjects(objectIndex).timePoint, ...
            originalObjects(objectIndex).inputId);
    end

    error('AssignSeparatedMeshes:MissingOutputForOriginalObject', ...
        'No separated mesh was assigned to original object(s): %s.', ...
        strjoin(missingDescriptions, ', '));
end

assignedOutputIds = deduceOutputIdsFromOriginalTables( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes);

% Mutate tableArray only after the full assignment is known to be complete.
[tableArray, objectsToRemove] = applySeparatedMeshesToTableArray( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes, ...
    assignedOutputIds, ...
    separatedMeshes);

% Return an audit table.
% Write the resulting ids back to every matching editing row.
% Duplicate gizmos for the same input object receive the same output ids.
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

% Empty typed table used as a stable return value and append target.
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

% Split originals are not deleted here.
% Callers need to know which old ids should be removed after replacement rows are created.
objectsToRemove = table( ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    'VariableNames', { ...
        'timePoint', ...
        'objectId'});

end



function originalObjects = collectReferencedOriginalObjects(tableArray, usedGizmos, timePoint)

% Keep only valid object references for the requested time point.
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

    % Empty originals cannot be matched reliably, so fail before scoring.
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

% Reuse the original id for a one-to-one replacement.
% For true splits, assign fresh ids per time point so new rows never collide with existing objects.
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

% Row names are the source of truth for object ids in these model tables.
if timePoint < 1 || timePoint > numel(tableArray)
    error('AssignSeparatedMeshes:InvalidTimePoint', ...
        'Time point %g is outside tableArray.', timePoint);
end

rowNames = string(tableArray{timePoint}.Properties.RowNames);
existingIds = str2double(rowNames);

if any(~isfinite(existingIds))
    error('AssignSeparatedMeshes:NonNumericObjectId', ...
        'Object table row names must be numeric object IDs.');
end

end



function [tableArray, objectsToRemove] = applySeparatedMeshesToTableArray( ...
    tableArray, ...
    originalObjects, ...
    assignedMeshIndexes, ...
    assignedOutputIds, ...
    separatedMeshes)

objectsToRemove = initializeObjectsToRemoveTable();
columnsToInherit = tableUtils.getInheritableColumnNames();

% One output overwrites the original row.
% Multiple outputs start as blank rows and copy only stable provenance/display columns from the original object.
for objectIndex = 1:numel(originalObjects)
    originalObject = originalObjects(objectIndex);
    meshIndexes = assignedMeshIndexes{objectIndex};
    outputIds = assignedOutputIds{objectIndex};
    objectTable = tableArray{originalObject.timePoint};
    originalRowIndex = objectRowIndexById( ...
        objectTable, ...
        originalObject.inputId);

    if isequal(numel(meshIndexes), 1)
        objectTable.Mesh{originalRowIndex} = separatedMeshes{meshIndexes(1)};
        objectTable{originalRowIndex, 'edited'} = true;
        tableArray{originalObject.timePoint} = objectTable;
        continue
    end

    newRemoveRow = height(objectsToRemove) + 1;
    objectsToRemove.timePoint(newRemoveRow) = originalObject.timePoint;
    objectsToRemove.objectId(newRemoveRow) = originalObject.inputId;

    for localIndex = 1:numel(meshIndexes)
        newObjectId = outputIds(localIndex);
        newObjectRowName = char(string(newObjectId));
        objectTable = tableUtils.addBlankRow(objectTable, string(newObjectId));
        objectTable = tableUtils.copySelectedColumnsFromOriginal(objectTable, originalObject.inputId, newObjectId, columnsToInherit);
        objectTable.Mesh{newObjectRowName} = separatedMeshes{meshIndexes(localIndex)};
        objectTable{newObjectRowName, 'edited'} = true;
    end

    tableArray{originalObject.timePoint} = objectTable;
end

end



function score = objectCorrespondenceScore(separatedVertices, separatedCenter, originalObject, paddingFraction)

% Score mostly by bbox containment, with center distance as a soft tie-breaker.
% Padding absorbs small numerical/boolean-operation shifts at cut boundaries.
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

% Centralized lookup keeps object id validation consistent across helpers.
if timePoint < 1 || timePoint > numel(tableArray)
    error('AssignSeparatedMeshes:InvalidTimePoint', ...
        'Time point %g is outside tableArray.', timePoint);
end

objectTable = tableArray{timePoint};
rowIndex = objectRowIndexById(objectTable, inputId);

mesh = objectTable.Mesh{rowIndex};

end



function rowIndex = objectRowIndexById(objectTable, objectId)

% Model object ids are stored as row names, not as a regular table variable.
rowNames = string(objectTable.Properties.RowNames);
rowIndex = find(rowNames == string(objectId), 1);

if isempty(rowIndex)
    error('AssignSeparatedMeshes:UnknownObjectId', ...
        'Object id %g was not found in the object table.', ...
        objectId);
end

end



function vertices = meshVertices(mesh)

% Accept the mesh shapes used in this project and normalize them to double vertices.
% This keeps the geometric scoring code type-agnostic.
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
