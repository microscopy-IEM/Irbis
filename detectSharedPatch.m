function [patches] = detectSharedPatch(verticesMesh1, facesMesh1, verticesMesh2, varargin)
% Detect the patch on mesh 1 that is shared with mesh 2.
%
% [patches] = detectSharedPatch(verticesMesh1, facesMesh1, verticesMesh2)
% [patches] = detectSharedPatch(..., 'DistanceTolerance', 1e-6)
%
% Inputs
%   verticesMesh1 : (N1,3) mesh 1 vertices
%   facesMesh1    : (M1,3) mesh 1 triangle indices
%   verticesMesh2 : (N2,3) mesh 2 vertices
%
% Optional name-value pairs
%   DistanceTolerance       : Max distance for a mesh 1 vertex to be
%                             considered shared with mesh 2 (default 1e-6)
%   PlotSharedVertices      : If true, plot shared vertices over dim mesh
%                             (default false)
%   KeepLargestComponent    : If true, keep only the largest connected
%                             shared patch (default false)
%
% Outputs
%   patches        : struct array sorted from largest to smallest patch.
%                    Each struct contains fields:
%                    vertices, faces, face_indices,
%                    vertex_indices_global, num_faces, num_vertices

    p = inputParser;
    addParameter(p, 'DistanceTolerance', 1e-6, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'PlotSharedVertices', false, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'KeepLargestComponent', false, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    distanceTolerance = p.Results.DistanceTolerance;
    plotSharedVertices = p.Results.PlotSharedVertices;
    keepLargestComponent = p.Results.KeepLargestComponent;

    validateattributes(verticesMesh1, {'numeric'}, {'2d', 'ncols', 3, 'nonempty'}, mfilename, 'verticesMesh1', 1);
    validateattributes(facesMesh1, {'numeric'}, {'2d', 'ncols', 3, 'nonempty', 'integer', 'positive'}, mfilename, 'facesMesh1', 2);
    validateattributes(verticesMesh2, {'numeric'}, {'2d', 'ncols', 3, 'nonempty'}, mfilename, 'verticesMesh2', 3);

    if max(facesMesh1(:)) > size(verticesMesh1, 1)
        error('facesMesh1 references vertex indices outside verticesMesh1.');
    end

    if size(facesMesh1, 1) < 1
        error('Mesh 1 must contain at least one face.');
    end

    nearestDistancesToMesh2Vertices = nearestVertexDistance(verticesMesh1, verticesMesh2);
    sharedVertexMask = nearestDistancesToMesh2Vertices <= distanceTolerance;

    if plotSharedVertices
        plotSharedVerticesOnMesh(verticesMesh1, facesMesh1, sharedVertexMask);
    end

    components = connectedComponentsFromSharedEdges(facesMesh1, sharedVertexMask);
    if ~isempty(components)
        componentSizes = cellfun(@numel, components);
        [~, sortIndices] = sort(componentSizes, 'descend');
        components = components(sortIndices);
    end

    if keepLargestComponent && ~isempty(components)
        components = components(1);
    end

    numberOfComponents = numel(components);
    patches = repmat(struct( ...
        'vertices', [], ...
        'faces', []), numberOfComponents, 1);

    for i = 1:numberOfComponents
        [patchVertices, patchFaces, ~] = reindexPatch(verticesMesh1, facesMesh1, components{i});
        patches(i).vertices = patchVertices;
        patches(i).faces = patchFaces;
    end
end

function plotSharedVerticesOnMesh(verticesMesh, facesMesh, sharedVertexMask)
    figure('Name', 'Shared Vertices on Mesh', 'NumberTitle', 'off');
    axesHandle = axes;
    hold(axesHandle, 'on');

    patch('Faces', facesMesh, 'Vertices', verticesMesh, ...
        'FaceColor', [0.7, 0.7, 0.7], ...
        'EdgeColor', [0.2, 0.2, 0.2], ...
        'FaceAlpha', 0.1, ...
        'EdgeAlpha', 0.03, ...
        'DisplayName', 'Original mesh');

    sharedVertices = verticesMesh(sharedVertexMask, :);
    scatter3(sharedVertices(:, 1), sharedVertices(:, 2), sharedVertices(:, 3), ...
        18, [1.0, 0.1, 0.1], 'filled', 'DisplayName', 'Shared vertices');

    axis(axesHandle, 'equal');
    grid(axesHandle, 'on');
    view(axesHandle, 3);
    xlabel(axesHandle, 'X');
    ylabel(axesHandle, 'Y');
    zlabel(axesHandle, 'Z');
    title(axesHandle, 'Shared Vertices Over Dim Mesh', 'FontWeight', 'bold');
    legend(axesHandle, 'Location', 'bestoutside');
    hold(axesHandle, 'off');
end



function [patchVertices, patchFaces, selectedVertexIds] = reindexPatch(vertices, faces, faceIndices)
    selectedFacesGlobal = faces(faceIndices, :);
    selectedVertexIds = unique(selectedFacesGlobal(:));

    reindexMap = zeros(size(vertices, 1), 1);
    reindexMap(selectedVertexIds) = 1:numel(selectedVertexIds);

    patchFaces = reshape(reindexMap(selectedFacesGlobal), size(selectedFacesGlobal));
    patchVertices = vertices(selectedVertexIds, :);
end



function nearestDistances = nearestVertexDistance(queryPoints, referencePoints)
% Compute nearest-neighbor distances from queryPoints to referencePoints.
% Uses knnsearch (KD-tree) when available, falls back to blockwise brute force.

    try
        [~, nearestDistances] = knnsearch(referencePoints, queryPoints, 'K', 1);
        return;
    catch
        numberOfQueryPoints = size(queryPoints, 1);
        numberOfReferencePoints = size(referencePoints, 1);
        minSquaredDistances = inf(numberOfQueryPoints, 1);

        blockSize = max(1, floor(2e7 / max(numberOfQueryPoints, 1)));
        blockSize = min(blockSize, numberOfReferencePoints);

        for startIndex = 1:blockSize:numberOfReferencePoints
            endIndex = min(startIndex + blockSize - 1, numberOfReferencePoints);
            referenceBlock = referencePoints(startIndex:endIndex, :);

            deltaX = queryPoints(:, 1) - referenceBlock(:, 1)';
            deltaY = queryPoints(:, 2) - referenceBlock(:, 2)';
            deltaZ = queryPoints(:, 3) - referenceBlock(:, 3)';
            squaredDistancesBlock = deltaX.^2 + deltaY.^2 + deltaZ.^2;

            minSquaredDistances = min(minSquaredDistances, min(squaredDistancesBlock, [], 2));
        end

        nearestDistances = sqrt(minSquaredDistances);
    end
end



function components = connectedComponentsFromSharedEdges(faces, sharedVertexMask)
% Find connected face components among fully shared faces.
% A fully shared face has all three vertices within distance tolerance.

    faceFullySharedMask = all(sharedVertexMask(faces), 2);
    activeFaceIndices = find(faceFullySharedMask);

    if isempty(activeFaceIndices)
        components = {};
        return;
    end

    % Build edges exclusively from fully-shared faces to avoid spurious
    % connections through partially-shared triangles.
    activeFaces = faces(activeFaceIndices, :);
    edgeVertex12 = sort(activeFaces(:, [1, 2]), 2);
    edgeVertex23 = sort(activeFaces(:, [2, 3]), 2);
    edgeVertex31 = sort(activeFaces(:, [3, 1]), 2);
    sharedFaceEdges = [edgeVertex12; edgeVertex23; edgeVertex31];

    % Build a vertex graph and label connected components.
    % graph(s,t) numbers nodes 1..max([s;t]), so componentLabels is indexed
    % by vertex index, not by face index.
    edgeGraph = graph(sharedFaceEdges(:, 1), sharedFaceEdges(:, 2));
    componentLabels = conncomp(edgeGraph);

    % Map each active face to its component via its first vertex.
    % All three vertices of a fully-shared face are guaranteed to share the
    % same component label, so any one of them is sufficient.
    faceComponentLabels = componentLabels(activeFaces(:, 1));

    activeComponentLabels = unique(faceComponentLabels);
    components = cell(numel(activeComponentLabels), 1);
    for i = 1:numel(activeComponentLabels)
        currentLabel = activeComponentLabels(i);
        components{i} = activeFaceIndices(faceComponentLabels == currentLabel);
    end
end
