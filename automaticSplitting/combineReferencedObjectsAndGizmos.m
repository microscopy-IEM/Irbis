function [objectMesh, gizmoMesh, componentTable] = combineReferencedObjectsAndGizmos(tableArray, usedGizmos)
%COMBINEREFERENCEDOBJECTSANDGIZMOS Combine referenced object meshes and gizmo meshes.
%
% [objectMesh, gizmoMesh, componentTable] = combineReferencedObjectsAndGizmos(tableArray, usedGizmos)
% resolves the objects referenced by usedGizmos.timePoint/inputId and
% returns one concatenated mesh for the referenced objects and one
% concatenated mesh for all usedGizmos.helperMesh entries.
%
% Inputs:
%   tableArray   Cell array of object tables. Each table must contain Mesh
%                and use object ids as RowNames.
%   usedGizmos   ManualEditing-style table returned by reviewMatchEventsUI.
%
% Outputs:
%   objectMesh      SurfaceMesh object with Vertices and Faces for referenced objects.
%   gizmoMesh       SurfaceMesh object with Vertices and Faces for cutting cuboids.
%   componentTable  Per-component provenance and index ranges.

arguments
    tableArray cell
    usedGizmos table
end

componentTable = initializeComponentTable();

if height(usedGizmos) == 0
    objectMesh = emptyMesh();
    gizmoMesh = emptyMesh();
    return
end

objectVertices = zeros(0, 3);
objectFaces = zeros(0, 3);
gizmoVertices = zeros(0, 3);
gizmoFaces = zeros(0, 3);

[objectKeys, objectRows] = uniqueReferencedObjects(usedGizmos);

for objectIndex = 1:size(objectKeys, 1)
    timePoint = objectKeys(objectIndex, 1);
    inputId = objectKeys(objectIndex, 2);
    editingRows = objectRows{objectIndex};

    mesh = getObjectMeshById(tableArray, timePoint, inputId);

    [objectVertices, objectFaces, componentTable] = appendComponent( ...
        objectVertices, ...
        objectFaces, ...
        componentTable, ...
        mesh, ...
        "object", ...
        timePoint, ...
        inputId, ...
        editingRows);
end

for gizmoRow = 1:height(usedGizmos)
    helperMesh = usedGizmos.helperMesh{gizmoRow};

    [gizmoVertices, gizmoFaces, componentTable] = appendComponent( ...
        gizmoVertices, ...
        gizmoFaces, ...
        componentTable, ...
        helperMesh, ...
        "gizmo", ...
        usedGizmos.timePoint(gizmoRow), ...
        usedGizmos.inputId(gizmoRow), ...
        gizmoRow);
end

objectMesh = surfaceMesh(objectVertices, objectFaces);

gizmoMesh = surfaceMesh(gizmoVertices, gizmoFaces);

end



function mesh = emptyMesh()

mesh = struct( ...
    'Vertices', zeros(0, 3), ...
    'Faces', zeros(0, 3));

end



function componentTable = initializeComponentTable()

componentTable = table( ...
    strings(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    cell(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    zeros(0, 1), ...
    'VariableNames', { ...
        'componentType', ...
        'timePoint', ...
        'inputId', ...
        'usedGizmoRows', ...
        'vertexStart', ...
        'vertexEnd', ...
        'faceStart', ...
        'faceEnd'});

end



function [objectKeys, objectRows] = uniqueReferencedObjects(usedGizmos)

keys = [usedGizmos.timePoint(:), usedGizmos.inputId(:)];
validMask = all(isfinite(keys), 2);
keys = keys(validMask, :);
validRows = find(validMask);

if isempty(keys)
    objectKeys = zeros(0, 2);
    objectRows = {};
    return
end

[objectKeys, ~, groupIds] = unique(keys, 'rows');
objectRows = cell(size(objectKeys, 1), 1);

for groupIndex = 1:size(objectKeys, 1)
    objectRows{groupIndex} = validRows(groupIds == groupIndex);
end

end



function mesh = getObjectMeshById(tableArray, timePoint, inputId)

if timePoint < 1 || timePoint > numel(tableArray)
    error('CombineMeshes:InvalidTimePoint', ...
        'Time point %g is outside tableArray.', timePoint);
end

objectTable = tableArray{timePoint};
rowNames = string(objectTable.Properties.RowNames);
rowIndex = find(rowNames == string(inputId), 1);

if isempty(rowIndex)
    error('CombineMeshes:UnknownObjectId', ...
        'Object id %g was not found at time point %g.', ...
        inputId, ...
        timePoint);
end

mesh = objectTable.Mesh{rowIndex};

end



function [allVertices, allFaces, componentTable] = appendComponent( ...
    allVertices, ...
    allFaces, ...
    componentTable, ...
    mesh, ...
    componentType, ...
    timePoint, ...
    inputId, ...
    usedGizmoRows)

[vertices, faces] = meshToVerticesFaces(mesh);

if isempty(vertices) || isempty(faces)
    return
end

vertexOffset = size(allVertices, 1);
faceOffset = size(allFaces, 1);

allVertices = [allVertices; vertices]; %#ok<AGROW>
allFaces = [allFaces; faces + vertexOffset]; %#ok<AGROW>

newRow = height(componentTable) + 1;
componentTable.componentType(newRow) = string(componentType);
componentTable.timePoint(newRow) = timePoint;
componentTable.inputId(newRow) = inputId;
componentTable.usedGizmoRows{newRow} = usedGizmoRows(:).';
componentTable.vertexStart(newRow) = vertexOffset + 1;
componentTable.vertexEnd(newRow) = size(allVertices, 1);
componentTable.faceStart(newRow) = faceOffset + 1;
componentTable.faceEnd(newRow) = size(allFaces, 1);

end



function [vertices, faces] = meshToVerticesFaces(mesh)

if isempty(mesh)
    vertices = zeros(0, 3);
    faces = zeros(0, 3);
    return
end

if isstruct(mesh)
    vertices = getMeshField(mesh, "Vertices", "vertices");
    faces = getMeshField(mesh, "Faces", "faces");
elseif isobject(mesh) && isprop(mesh, 'Vertices') && isprop(mesh, 'Faces')
    vertices = mesh.Vertices;
    faces = mesh.Faces;
else
    error('CombineMeshes:UnsupportedMeshType', ...
        'Mesh must be a struct or object with Vertices/Faces.');
end

vertices = double(vertices);
faces = double(faces);

if size(vertices, 2) ~= 3 || size(faces, 2) ~= 3
    error('CombineMeshes:InvalidMeshShape', ...
        'Mesh vertices and faces must be N-by-3 arrays.');
end

if ~isempty(faces) && min(faces(:)) == 0
    faces = faces + 1;
end

end



function value = getMeshField(mesh, upperName, lowerName)

if isfield(mesh, upperName)
    value = mesh.(upperName);
elseif isfield(mesh, lowerName)
    value = mesh.(lowerName);
else
    error('CombineMeshes:MissingMeshField', ...
        'Mesh is missing field %s/%s.', upperName, lowerName);
end

end
