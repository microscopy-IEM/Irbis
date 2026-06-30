function [objectIndices, objectInfo] = meshObjectsToVoxelIndices(surfaceMeshes, gridSize, voxelSize, origin, varargin)
% meshObjectsToVoxelIndices Voxelize many meshes into compact index lists.
%
%   [objectIndices, objectInfo] = meshObjectsToVoxelIndices(surfaceMeshes, ...
%       gridSize, voxelSize, origin)
%
%   This function is a batch-oriented version of meshToVoxelMask. It assumes
%   all objects live in the same global voxel space, but it voxelizes each
%   object inside a small local region of interest (ROI) instead of allocating
%   and filling a full-size mask for every object. That keeps the work close
%   to the size of each object, which is important when processing tens to
%   hundreds of small meshes.
%
%   Inputs:
%     surfaceMeshes  Cell array where each cell contains one surfaceMesh
%                    object, usually created by readSurfaceMesh. Each object
%                    must provide Vertices and Faces properties.
%
%                    Example:
%                      surfaceMeshes = {
%                          readSurfaceMesh("object_001.ply")
%                          readSurfaceMesh("object_002.ply")
%                      };
%
%                    For compatibility, this function also accepts structs or
%                    objects with Vertices/Faces, an Nx2 {vertices, faces}
%                    cell table, or cells where each item is {vertices, faces}.
%     gridSize       [ny nx nz] size of the shared output voxel space.
%     voxelSize      [vx vy vz] voxel spacing in the same units as vertices.
%     origin         [x0 y0 z0], the physical center of voxel (1,1,1).
%
%   Outputs:
%     objectIndices{i} contains global linear indices for voxels occupied by
%       object i. These are indices into an array with size gridSize.
%     objectInfo is a struct array with per-object ROI bounds, voxel counts,
%       mesh sizes, and clipping information.
%
%   Name-value options:
%     Padding          Extra voxels added around each object's local ROI.
%                      Scalar or [x y z]. Default: 1.
%                      Padding gives the slice filler a little room around
%                      the mesh boundary, which reduces edge clipping issues.
%     SamplesPerVoxel  Line rasterization density for triangle-plane
%                      intersection segments. Default: 2.
%
%   Example:
%     surfaceMeshes = {
%         readSurfaceMesh("object_001.ply")
%         readSurfaceMesh("object_002.ply")
%     };
%
%     [objectIndices, objectInfo] = meshObjectsToVoxelIndices( ...
%         surfaceMeshes, [248 776 41], [0.0677 0.0677 0.1500], [0 0 0]);
%
%     labelMask = objectVoxelIndicesToLabelMask(objectIndices, [248 776 41]);

    if nargin < 4 || isempty(origin)
        origin = [0 0 0];
    end

    options = parseVoxelizationOptions(varargin{:});

    gridSize = validateFixedLengthVector(gridSize, 3, 'gridSize');
    voxelSize = validateFixedLengthVector(voxelSize, 3, 'voxelSize');
    origin = validateFixedLengthVector(origin, 3, 'origin');

    if any(gridSize < 1) || any(mod(gridSize, 1) ~= 0)
        error('gridSize must contain three positive integer values.');
    end

    if any(voxelSize <= 0)
        error('voxelSize must contain three positive values.');
    end

    objectCount = countSurfaceMeshInputs(surfaceMeshes);
    objectIndices = cell(objectCount, 1);
    objectInfo = repmat(createEmptyObjectInfo(), objectCount, 1);

    for objectIndex = 1:objectCount
        [vertices, faces] = extractSurfaceMeshGeometry(surfaceMeshes, objectIndex);

        % The slicing math expects doubles and MATLAB-style 1-based triangle
        % indices. Some Python/PLY workflows use 0-based faces, so normalize
        % them at the boundary of this function.
        vertices = double(vertices);
        faces = normalizeFaces(faces, size(vertices, 1), objectIndex);

        [objectIndices{objectIndex}, objectInfo(objectIndex)] = ...
            voxelizeObjectInLocalRoi(vertices, faces, gridSize, voxelSize, origin, options);

        objectInfo(objectIndex).ObjectIndex = objectIndex;
    end

end

function options = parseVoxelizationOptions(varargin)
% parseVoxelizationOptions Validate user-facing name-value options.

    parser = inputParser;
    addParameter(parser, 'Padding', 1, ...
        @(value) isnumeric(value) && (isscalar(value) || numel(value) == 3));
    addParameter(parser, 'SamplesPerVoxel', 2, ...
        @(value) isnumeric(value) && isscalar(value) && isfinite(value) && value > 0);
    parse(parser, varargin{:});

    roiPadding = double(parser.Results.Padding(:).');
    if isscalar(roiPadding)
        roiPadding = repmat(roiPadding, 1, 3);
    end

    if any(~isfinite(roiPadding)) || any(roiPadding < 0)
        error('Padding must be finite and non-negative.');
    end

    options.Padding = ceil(roiPadding);
    options.SamplesPerVoxel = double(parser.Results.SamplesPerVoxel);
end

function values = validateFixedLengthVector(values, expectedLength, variableName)
% validateFixedLengthVector Convert vector-like inputs to a numeric row vector.

    values = double(values(:).');
    if numel(values) ~= expectedLength || any(~isfinite(values))
        error('%s must be a finite numeric vector with %d elements.', ...
            variableName, expectedLength);
    end
end

function objectCount = countSurfaceMeshInputs(surfaceMeshes)
% countSurfaceMeshInputs Count surfaceMesh cells and supported compatibility forms.

    if isempty(surfaceMeshes)
        objectCount = 0;
        return
    end

    if isVerticesFacesCellTable(surfaceMeshes)
        objectCount = size(surfaceMeshes, 1);
    else
        objectCount = numel(surfaceMeshes);
    end
end

function isCellTable = isVerticesFacesCellTable(surfaceMeshes)
% isVerticesFacesCellTable True for {vertices, faces; ...} input.

    isCellTable = iscell(surfaceMeshes) && ismatrix(surfaceMeshes) && ...
        size(surfaceMeshes, 2) == 2 && isnumeric(surfaceMeshes{1, 1}) && ...
        isnumeric(surfaceMeshes{1, 2});
end

function [vertices, faces] = extractSurfaceMeshGeometry(surfaceMeshes, objectIndex)
% extractSurfaceMeshGeometry Read Vertices/Faces from one surfaceMesh cell.
%
% The main expected form is surfaceMeshes{objectIndex}, where the cell
% contains a surfaceMesh object. The fallback branches keep the function
% usable with already-extracted vertices/faces or legacy struct arrays.

    if isVerticesFacesCellTable(surfaceMeshes)
        vertices = surfaceMeshes{objectIndex, 1};
        faces = surfaceMeshes{objectIndex, 2};
        return
    end

    if iscell(surfaceMeshes)
        surfaceMeshObject = surfaceMeshes{objectIndex};
    else
        surfaceMeshObject = surfaceMeshes(objectIndex);
    end

    if iscell(surfaceMeshObject) && numel(surfaceMeshObject) == 2
        vertices = surfaceMeshObject{1};
        faces = surfaceMeshObject{2};
        return
    end

    if hasMeshMember(surfaceMeshObject, 'Vertices') && hasMeshMember(surfaceMeshObject, 'Faces')
        vertices = getMeshMember(surfaceMeshObject, 'Vertices');
        faces = getMeshMember(surfaceMeshObject, 'Faces');
        return
    end

    if hasMeshMember(surfaceMeshObject, 'vertices') && hasMeshMember(surfaceMeshObject, 'faces')
        vertices = getMeshMember(surfaceMeshObject, 'vertices');
        faces = getMeshMember(surfaceMeshObject, 'faces');
        return
    end

    if hasMeshMember(surfaceMeshObject, 'Points') && hasMeshMember(surfaceMeshObject, 'ConnectivityList')
        vertices = getMeshMember(surfaceMeshObject, 'Points');
        faces = getMeshMember(surfaceMeshObject, 'ConnectivityList');
        return
    end

    error(['surfaceMeshes{%d} must contain a surfaceMesh object or another ', ...
        'mesh-like object with Vertices/Faces properties.'], objectIndex);
end

function hasMember = hasMeshMember(mesh, memberName)
% hasMeshMember Support both structs and MATLAB objects.

    if isstruct(mesh)
        hasMember = isfield(mesh, memberName);
    else
        hasMember = isprop(mesh, memberName);
    end
end

function value = getMeshMember(mesh, memberName)
% getMeshMember Read a field/property with one syntax.

    value = mesh.(memberName);
end

function faces = normalizeFaces(faces, vertexCount, objectIndex)
% normalizeFaces Validate triangles and convert 0-based indices if needed.

    faces = double(faces);

    if isempty(faces)
        faces = zeros(0, 3);
        return
    end

    if size(faces, 2) ~= 3
        error('Faces for object %d must be an Mx3 triangle index array.', objectIndex);
    end

    if any(~isfinite(faces(:))) || any(mod(faces(:), 1) ~= 0)
        error('Faces for object %d must contain finite integer indices.', objectIndex);
    end

    % A minimum index of 0 is a strong signal that faces came from a 0-based
    % environment such as Python, so convert once before validation.
    if min(faces(:)) == 0
        faces = faces + 1;
    end

    if any(faces(:) < 1) || any(faces(:) > vertexCount)
        error('Faces for object %d contain indices outside the vertex array.', objectIndex);
    end
end

function [globalIndices, info] = voxelizeObjectInLocalRoi( ...
        vertices, faces, gridSize, voxelSize, origin, options)
% voxelizeObjectInLocalRoi Voxelize one mesh in a cropped local grid.
%
% The local ROI is the key speed improvement. Small objects usually occupy a
% tiny fraction of the full volume, so this function slices and fills only
% the local bounding box, then converts the local voxels back to global
% linear indices.

    info = createEmptyObjectInfo();
    info.NumVertices = size(vertices, 1);
    info.NumFaces = size(faces, 1);
    globalIndices = zeros(0, 1);

    if isempty(vertices) || isempty(faces)
        return
    end

    if size(vertices, 2) ~= 3
        error('Vertices must be an Nx3 coordinate array.');
    end

    if any(~isfinite(vertices(:)))
        error('Vertices must contain only finite coordinates.');
    end

    % Convert physical coordinates to global voxel coordinates once. The
    % slicer below can then work in voxel units and avoid repeated divisions
    % for every z-slice and every segment.
    globalVoxelVertices = convertPhysicalToVoxelCoordinates(vertices, voxelSize, origin);

    [xLimits, yLimits, zLimits, wasClipped, isOutsideVolume] = ...
        computeObjectVoxelBounds(globalVoxelVertices, gridSize, options.Padding);

    info.XLimits = xLimits;
    info.YLimits = yLimits;
    info.ZLimits = zLimits;
    info.WasClipped = wasClipped;

    if isOutsideVolume
        return
    end

    localGridSize = [diff(yLimits) + 1, diff(xLimits) + 1, diff(zLimits) + 1];
    info.LocalGridSize = localGridSize;

    % Shift global voxel coordinates into the cropped local ROI. Local voxel
    % (1,1,1) corresponds to global voxel (xLimits(1), yLimits(1), zLimits(1)).
    localVoxelOffset = [xLimits(1) - 1, yLimits(1) - 1, zLimits(1) - 1];
    localVoxelVertices = globalVoxelVertices - localVoxelOffset;

    localMask = rasterizeMeshInVoxelCoordinates( ...
        localVoxelVertices, faces, localGridSize, options.SamplesPerVoxel);

    localIndices = find(localMask);
    if isempty(localIndices)
        return
    end

    % Store compact global linear indices rather than full object masks. This
    % keeps memory use low and lets a later function decide how labels should
    % be combined when objects overlap.
    [localY, localX, localZ] = ind2sub(localGridSize, localIndices);

    globalY = localY + yLimits(1) - 1;
    globalX = localX + xLimits(1) - 1;
    globalZ = localZ + zLimits(1) - 1;

    globalIndices = sub2ind(gridSize, globalY, globalX, globalZ);
    globalIndices = globalIndices(:);

    info.IsEmpty = false;
    info.NumVoxels = numel(globalIndices);
end

function voxelVertices = convertPhysicalToVoxelCoordinates(vertices, voxelSize, origin)
% convertPhysicalToVoxelCoordinates Map physical x/y/z to MATLAB voxel axes.
%
% The output columns are still [x y z], while masks are indexed [y x z].
% Keeping this distinction explicit avoids accidental x/y swaps.

    voxelVertices = zeros(size(vertices));
    voxelVertices(:, 1) = (vertices(:, 1) - origin(1)) ./ voxelSize(1) + 1;
    voxelVertices(:, 2) = (vertices(:, 2) - origin(2)) ./ voxelSize(2) + 1;
    voxelVertices(:, 3) = (vertices(:, 3) - origin(3)) ./ voxelSize(3) + 1;
end

function [xLimits, yLimits, zLimits, wasClipped, isOutsideVolume] = ...
        computeObjectVoxelBounds(voxelVertices, gridSize, padding)
% computeObjectVoxelBounds Find and clip the ROI for one object.
%
% Bounds are returned as inclusive voxel index limits. They are clipped to
% the global volume so meshes partly outside the image can still contribute
% their in-volume voxels.

    globalYSize = gridSize(1);
    globalXSize = gridSize(2);
    globalZSize = gridSize(3);

    rawXLimits = [floor(min(voxelVertices(:, 1))) - padding(1), ...
        ceil(max(voxelVertices(:, 1))) + padding(1)];
    rawYLimits = [floor(min(voxelVertices(:, 2))) - padding(2), ...
        ceil(max(voxelVertices(:, 2))) + padding(2)];
    rawZLimits = [floor(min(voxelVertices(:, 3))) - padding(3), ...
        ceil(max(voxelVertices(:, 3))) + padding(3)];

    xLimits = [max(1, rawXLimits(1)), min(globalXSize, rawXLimits(2))];
    yLimits = [max(1, rawYLimits(1)), min(globalYSize, rawYLimits(2))];
    zLimits = [max(1, rawZLimits(1)), min(globalZSize, rawZLimits(2))];

    wasClipped = any([rawXLimits ~= xLimits, rawYLimits ~= yLimits, rawZLimits ~= zLimits]);
    isOutsideVolume = xLimits(1) > xLimits(2) || ...
        yLimits(1) > yLimits(2) || zLimits(1) > zLimits(2);

    if isOutsideVolume
        xLimits = [NaN NaN];
        yLimits = [NaN NaN];
        zLimits = [NaN NaN];
    end
end

function mask = rasterizeMeshInVoxelCoordinates(voxelVertices, faces, gridSize, samplesPerVoxel)
% rasterizeMeshInVoxelCoordinates Slice a mesh and fill each local z-plane.
%
% This is the same basic algorithm as meshToVoxelMask, but the vertices are
% already in local voxel coordinates. Each z-slice intersects the mesh with a
% plane, draws the resulting boundary segments, and fills the enclosed area.

    ySize = gridSize(1);
    xSize = gridSize(2);
    zSize = gridSize(3);

    mask = false(ySize, xSize, zSize);

    triangleZCoordinates = reshape(voxelVertices(faces, 3), [], 3);
    triangleMinZ = min(triangleZCoordinates, [], 2);
    triangleMaxZ = max(triangleZCoordinates, [], 2);

    triangleEdgeVertexPairs = [1 2; 2 3; 3 1];

    for localZIndex = 1:zSize
        % Restrict each slice to triangles whose z-range crosses this plane.
        % That keeps the expensive edge-intersection loop focused on relevant
        % triangles only.
        intersectingTriangleRows = find(localZIndex >= triangleMinZ & ...
            localZIndex <= triangleMaxZ);
        if isempty(intersectingTriangleRows)
            continue
        end

        sliceFaces = faces(intersectingTriangleRows, :);
        sliceTriangleCount = size(sliceFaces, 1);

        contourSegments = zeros(sliceTriangleCount, 4);
        segmentCount = 0;

        for triangleIndex = 1:sliceTriangleCount
            triangleVertices = voxelVertices(sliceFaces(triangleIndex, :), :);
            intersectionPoints = zeros(3, 2);
            intersectionPointCount = 0;

            for edgeIndex = 1:3
                edgeStart = triangleVertices(triangleEdgeVertexPairs(edgeIndex, 1), :);
                edgeEnd = triangleVertices(triangleEdgeVertexPairs(edgeIndex, 2), :);

                startZ = edgeStart(3);
                endZ = edgeEnd(3);

                % Horizontal edges do not define a unique crossing point with
                % the current z-plane. Skipping them avoids duplicate contour
                % points along coplanar triangle edges.
                if abs(endZ - startZ) < eps
                    continue
                end

                if localZIndex >= min(startZ, endZ) && localZIndex <= max(startZ, endZ)
                    interpolationFraction = (localZIndex - startZ) / (endZ - startZ);

                    if interpolationFraction >= 0 && interpolationFraction <= 1
                        intersectionPoint = edgeStart + ...
                            interpolationFraction * (edgeEnd - edgeStart);
                        intersectionPointCount = intersectionPointCount + 1;
                        intersectionPoints(intersectionPointCount, :) = intersectionPoint(1:2);
                    end
                end
            end

            if intersectionPointCount >= 2
                % Vertices exactly on the slicing plane can produce the same
                % crossing twice through adjacent edges. Remove duplicates so
                % each triangle contributes at most one segment.
                uniqueIntersectionPoints = unique( ...
                    round(intersectionPoints(1:intersectionPointCount, :) ./ 1e-9) .* 1e-9, ...
                    'rows', 'stable');

                if size(uniqueIntersectionPoints, 1) >= 2
                    segmentCount = segmentCount + 1;
                    contourSegments(segmentCount, :) = [ ...
                        uniqueIntersectionPoints(1, 1), uniqueIntersectionPoints(1, 2), ...
                        uniqueIntersectionPoints(2, 1), uniqueIntersectionPoints(2, 2)];
                end
            end
        end

        contourSegments = contourSegments(1:segmentCount, :);
        if isempty(contourSegments)
            continue
        end

        sliceBoundaryMask = false(ySize, xSize);

        for segmentIndex = 1:segmentCount
            startX = contourSegments(segmentIndex, 1);
            startY = contourSegments(segmentIndex, 2);
            endX = contourSegments(segmentIndex, 3);
            endY = contourSegments(segmentIndex, 4);

            segmentLengthInVoxels = max(abs(endX - startX), abs(endY - startY));
            sampleCount = max(2, ceil(segmentLengthInVoxels * samplesPerVoxel));

            sampledX = round(linspace(startX, endX, sampleCount));
            sampledY = round(linspace(startY, endY, sampleCount));

            inBoundsSamples = sampledX >= 1 & sampledX <= xSize & ...
                sampledY >= 1 & sampledY <= ySize;
            sliceBoundaryMask(sub2ind([ySize xSize], ...
                sampledY(inBoundsSamples), sampledX(inBoundsSamples))) = true;
        end

        % imfill is applied after drawing all boundary segments for this
        % z-slice. The function expects closed contours, so the mesh should be
        % watertight for reliable filled interiors.
        mask(:, :, localZIndex) = imfill(sliceBoundaryMask, 'holes');
    end
end

function info = createEmptyObjectInfo()
% createEmptyObjectInfo Default metadata for an object with no filled voxels.

    info = struct( ...
        'ObjectIndex', 0, ...
        'IsEmpty', true, ...
        'NumVertices', 0, ...
        'NumFaces', 0, ...
        'NumVoxels', 0, ...
        'XLimits', [NaN NaN], ...
        'YLimits', [NaN NaN], ...
        'ZLimits', [NaN NaN], ...
        'LocalGridSize', [0 0 0], ...
        'WasClipped', false);
end
