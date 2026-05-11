function result = proposeCutPlanesFromReferences(referenceMeshes, merged, opts)
%PROPOSECUTPLANESFROMREFERENCES Segment a merged mesh and propose interface cut planes.
%
% This function assigns each vertex of the merged mesh to the closest
% reference mesh (via nearest-reference-vertex distance), smooths the labels
% on the mesh adjacency graph, and fits cutting planes at label interfaces.
%
% Inputs
%   referenceMeshes : 1xN cell array of meshes (structs with .Vertices)
%   merged          : mesh struct with fields .Vertices (Nx3) and .Faces (Mx3)
%
% Name-value options (opts)
%   SmoothIterations      : number of smoothing iterations
%   SmoothnessWeight      : neighbor agreement weight (higher -> smoother)
%   MinBoundaryVertices   : minimum boundary vertices to fit a plane
%   MaxPlanes             : keep up to this many planes (largest boundaries)
%   PlaneNormalMode       : "pca" | "localSurface" | "surfaceAware"
%   SurfaceNormalBlend    : blend factor for the above modes
%   LocalSurfaceVertexCount : local vertices to estimate surface normal
%   LocalSurfaceRadius    : optional radius for local surface sampling
%   Visualize             : debug visualization
%
% Output
%   result.labels          : vertex labels (1..nReferences)
%   result.distances       : NxR distances to each reference mesh
%   result.referenceCenters: Rx3 reference centroids
%   result.planes          : struct array with fields point, normal, size, labelPair
%
arguments
    referenceMeshes (1,:) cell
    merged (1,1)
    opts.SmoothIterations (1,1) double = 10
    opts.SmoothnessWeight (1,1) double = 0.25
    opts.MinBoundaryVertices (1,1) double = 10
    opts.MaxPlanes double = Inf
    opts.PlaneNormalMode (1,1) string {mustBeMember(opts.PlaneNormalMode, ["pca","localSurface","surfaceAware"])} = "pca"
    opts.SurfaceNormalBlend (1,1) double = 0.2
    opts.LocalSurfaceVertexCount (1,1) double = 40
    opts.LocalSurfaceRadius double = []
    opts.Visualize (1,1) logical = false
end

% Normalize inputs into a clean 1xR cell array.
% Why: downstream code assumes a row-vector cell array and ignores empty
% entries; doing it up front keeps the rest of the function simpler.
referenceMeshes = referenceMeshes(:).';
referenceMeshes = referenceMeshes(~cellfun(@isempty, referenceMeshes));

if numel(referenceMeshes) < 2
    error("proposeCutPlanesFromReferences:TooFewReferences", ...
        "At least two reference meshes are required.");
end

V = merged.Vertices;
F = merged.Faces;
% if isempty(opts.MaxPlanes)
%     maxPlanes = max(nReferences - 1, 1);
% else
%     maxPlanes = opts.MaxPlanes;
% end

nVertices = size(V, 1);
nReferences = numel(referenceMeshes);

% 1) Vertex-to-reference distances (approx via nearest reference vertex).
% Why this approximation: we only need a robust per-vertex “which reference
% is closest” signal. Using nearest reference vertex is fast and avoids more
% expensive point-to-triangle distance computations.
distances = zeros(nVertices, nReferences);
referenceCenters = zeros(nReferences, 3);

for referenceIndex = 1:nReferences
    Vr = referenceMeshes{referenceIndex}.Vertices;
    % For each merged vertex, find the closest *reference vertex*.
    % Why: knnsearch is highly optimized and gives a consistent proxy for how
    % close that merged vertex is to the reference object.
    nearestIndexes = knnsearch(Vr, V);
    distances(:, referenceIndex) = vecnorm(V - Vr(nearestIndexes,:), 2, 2);
    % Cache reference centroids so we can later choose a consistent plane
    % normal direction (label1 -> label2) for reproducible UI orientation.
    referenceCenters(referenceIndex,:) = mean(Vr, 1);
end

[~, labels] = min(distances, [], 2);
% Initial hard assignment: each vertex gets the closest reference label.

% 2) Graph smoothing (vectorized via sparse one-hot label matrix).
% Why smoothing: raw nearest-neighbor assignments can be noisy near
% boundaries and on thin structures. Smoothing encourages spatially
% coherent labels by rewarding agreement with neighboring vertices.
adj = meshVertexAdjacency(F, nVertices);

for iteration = 1:opts.SmoothIterations
    % One-hot encoding of the current labels.
    % Why: multiplying adjacency * S gives, for each vertex, how many
    % neighbors currently belong to each reference label.
    S = sparse(1:nVertices, labels, 1, nVertices, nReferences);
    neighborCounts = adj * S;

    % We treat distances as a data-term and neighbor agreement as a prior.
    % Subtracting neighborCounts means: “if many neighbors are label k,
    % reduce the effective cost of choosing k”.
    scores = distances - opts.SmoothnessWeight * full(neighborCounts);
    [~, labels] = min(scores, [], 2);
end

% 3) Fit interface planes from boundary edges (single pass over edges).
% Why edge-based boundaries: boundary vertices live on edges whose endpoints
% have different labels. Extracting boundaries from unique undirected edges
% avoids repeatedly scanning faces per label pair.
planes = fitInterfacePlanesFromLabels( ...
    V, ...
    F, ...
    labels, ...
    referenceCenters, ...
    opts.MinBoundaryVertices, ...
    opts.MaxPlanes, ...
    opts.PlaneNormalMode, ...
    opts.SurfaceNormalBlend, ...
    opts.LocalSurfaceVertexCount, ...
    opts.LocalSurfaceRadius);

if isempty(planes)
    error("proposeCutPlanesFromReferences:NoInterfacePlanes", ...
        "No label interfaces with enough boundary vertices were found.");
end

result = struct();
result.labels = labels;
result.distances = distances;
result.referenceCenters = referenceCenters;
result.referenceMeshes = referenceMeshes;
result.planes = planes;

result.planePoints = vertcat(planes.point);
result.planeNormals = vertcat(planes.normal);
result.planeSizes = vertcat(planes.size);
result.planePoint = result.planePoints(1,:);
result.planeNormal = result.planeNormals(1,:);
result.planeSize = result.planeSizes(1);

if isfield(planes, 'boundaryVerts') && ~isempty(planes)
    try
        result.boundaryVerts = vertcat(planes.boundaryVerts);
    catch
        % ignore
    end
end

if opts.Visualize
    % Debug-only visualization that shows the smoothed segmentation and the
    % proposed planes.
    visualizeSplitPrototype(V, F, labels, planes);
end

end


function adj = meshVertexAdjacency(F, nVertices)

%MESHVETEXADJACENCY Build an undirected vertex adjacency matrix.
%
% We treat the mesh as an unweighted graph where vertices are connected if
% they share a face edge.
% Why: adjacency is used for label smoothing; an undirected graph is the
% simplest way to propagate neighbor agreement.

i = [F(:,1); F(:,2); F(:,3)];
j = [F(:,2); F(:,3); F(:,1)];
I = [i; j];
J = [j; i];
adj = sparse(I, J, true, nVertices, nVertices);

end


function planes = fitInterfacePlanesFromLabels( ...
    V, ...
    F, ...
    labels, ...
    referenceCenters, ...
    minBoundaryVertices, ...
    maxPlanes, ...
    planeNormalMode, ...
    surfaceNormalBlend, ...
    localSurfaceVertexCount, ...
    localSurfaceRadius)

%FITINTERFACEPLANESFROMLABELS Find label interfaces and fit a plane per interface.
%
% Strategy:
%  - Build the set of unique (undirected) mesh edges.
%  - Keep only “boundary edges” whose endpoint labels differ.
%  - Group boundary edges by label pair (e.g. [2 5]).
%  - For each label pair with enough boundary vertices, fit a plane using PCA
%    and optionally refine its normal.
%
% Why PCA: boundary vertices roughly lie on a separating surface; the plane
% normal is the direction with smallest variance.

% Build unique undirected edges from faces.
E = [F(:,[1 2]); F(:,[2 3]); F(:,[3 1])];
E = sort(E, 2);
E = unique(E, 'rows');

lu = labels(E(:,1));
lv = labels(E(:,2));
isBoundary = (lu ~= lv);

E = E(isBoundary, :);
lu = lu(isBoundary);
lv = lv(isBoundary);

planes = struct( ...
    'point', {}, ...
    'normal', {}, ...
    'size', {}, ...
    'labelPair', {}, ...
    'vertexIndexes', {}, ...
    'boundaryVerts', {});

if isempty(E)
    return
end

pairs = sort([lu lv], 2);

% Group boundary edges by label pair without rescanning faces.
% Why: this avoids an O(#pairs * #faces) pattern; everything is extracted
% in a single pass and then grouped.
%
% Note: The 1e6 multiplier is just a “large enough” base to make the mapping
% one-to-one for typical label counts. If you ever expect >1e6 labels, use a
% different keying strategy (e.g., sub2ind with known max label).
key = pairs(:,1) + 1e6 * pairs(:,2);
[uniqueKeys, ~, keyIndex] = unique(key);

for k = 1:numel(uniqueKeys)
    idx = (keyIndex == k);
    labelPair = pairs(find(idx, 1, 'first'), :); %#ok<FNDSB>

    boundaryVertexIndexes = unique(E(idx, :));

    if numel(boundaryVertexIndexes) < minBoundaryVertices
        continue
    end

    boundaryVerts = V(boundaryVertexIndexes,:);
    [planePoint, pcaPlaneNormal] = fitPlanePCA(boundaryVerts);

    % Direction from label1 centroid to label2 centroid.
    % Why: we use it to choose a consistent sign for the normal so the plane
    % orientation is stable across runs (important for UI expectations).
    centerDirection = referenceCenters(labelPair(2),:) - referenceCenters(labelPair(1),:);

    planeNormal = refinePlaneNormal( ...
        V, ...
        planePoint, ...
        pcaPlaneNormal, ...
        centerDirection, ...
        planeNormalMode, ...
        surfaceNormalBlend, ...
        localSurfaceVertexCount, ...
        localSurfaceRadius);

    if dot(planeNormal, centerDirection) < 0
        planeNormal = -planeNormal;
    end

    planeSize = estimatePlaneSize(boundaryVerts, planePoint, planeNormal);

    planes(end+1).point = planePoint; %#ok<AGROW>
    planes(end).normal = planeNormal;
    planes(end).size = planeSize;
    planes(end).labelPair = labelPair;
    planes(end).vertexIndexes = boundaryVertexIndexes;
    planes(end).boundaryVerts = boundaryVerts;
end

if isfinite(maxPlanes) && numel(planes) > maxPlanes
    boundaryCounts = arrayfun(@(plane) size(plane.boundaryVerts, 1), planes);
    [~, order] = sort(boundaryCounts, 'descend');
    planes = planes(order(1:maxPlanes));
end

end


function [point, normal] = fitPlanePCA(points)

%FITPLANEＰCA Fit a plane with PCA / SVD.
%
% The best-fit plane (in least squares sense) through points has normal equal
% to the direction of *smallest* variance. With SVD of centered coordinates,
% that is the last right-singular vector.

point = mean(points, 1);
X = points - point;
[~, ~, V] = svd(X, "econ");
normal = V(:, end).';
normal = normalizeVector(normal);

end


function normal = refinePlaneNormal( ...
    V, ...
    planePoint, ...
    pcaNormal, ...
    centerDirection, ...
    planeNormalMode, ...
    surfaceNormalBlend, ...
    localSurfaceVertexCount, ...
    localSurfaceRadius)

%REFINEPLANENORMAL Optionally adjust the PCA plane normal.
%
% Motivation: PCA of boundary vertices can be biased by curvature, uneven
% boundary sampling, or outliers. Two optional refinements are provided:
%  - "localSurface": blend the PCA normal with a locally estimated surface
%    normal around the plane point.
%  - "surfaceAware": prefer a normal that is (a) consistent with the
%    label-centroid direction but (b) tangential to the local surface (i.e.
%    not pointing “into” the surface), which tends to look better for cuts.

pcaNormal = normalizeVector(pcaNormal);
centerDirection = normalizeVector(centerDirection);

if planeNormalMode == "pca"
    normal = pcaNormal;
    return
end

[localSurfaceNormal, localSurfaceVertexIndexes] = fitLocalSurfaceNormal( ...
    V, planePoint, localSurfaceVertexCount, localSurfaceRadius);

if isempty(localSurfaceVertexIndexes) || all(localSurfaceNormal == 0)
    normal = pcaNormal;
    return
end

if dot(localSurfaceNormal, pcaNormal) < 0
    % Make normals consistent before blending.
    localSurfaceNormal = -localSurfaceNormal;
end

if planeNormalMode == "localSurface"
    surfaceNormalBlend = max(0, min(1, surfaceNormalBlend));
    normal = normalizeVector( ...
        (1 - surfaceNormalBlend) * pcaNormal + ...
        surfaceNormalBlend * localSurfaceNormal);

    if all(normal == 0)
        normal = localSurfaceNormal;
    end

    return
end

surfaceAwareNormal = centerDirection - ...
    dot(centerDirection, localSurfaceNormal) * localSurfaceNormal;

% Project centerDirection onto the tangent plane of the local surface.
% Why: we want a cut direction that separates the two components while
% remaining plausible with respect to the merged object's surface.

if norm(surfaceAwareNormal) <= eps
    surfaceAwareNormal = pcaNormal - ...
        dot(pcaNormal, localSurfaceNormal) * localSurfaceNormal;
end

surfaceAwareNormal = normalizeVector(surfaceAwareNormal);

if all(surfaceAwareNormal == 0)
    normal = pcaNormal;
    return
end

surfaceNormalBlend = max(0, min(1, surfaceNormalBlend));
normal = normalizeVector( ...
    (1 - surfaceNormalBlend) * pcaNormal + ...
    surfaceNormalBlend * surfaceAwareNormal);

if all(normal == 0)
    normal = surfaceAwareNormal;
end

end


function [surfaceNormal, localVertexIndexes] = fitLocalSurfaceNormal( ...
    V, ...
    planePoint, ...
    localSurfaceVertexCount, ...
    localSurfaceRadius)

%FITLOCALSURFACENORMAL Estimate a local surface normal near a plane point.
%
% We pick a neighborhood of vertices around planePoint and fit a PCA plane
% to that neighborhood. Its normal is used as a local surface estimate.
% Why: it provides a geometrically grounded direction for refinement modes.

distances = vecnorm(V - planePoint, 2, 2);

if ~isempty(localSurfaceRadius) && isfinite(localSurfaceRadius)
    % Radius-based neighborhood if provided.
    localVertexIndexes = find(distances <= localSurfaceRadius);
else
    localVertexIndexes = [];
end

if numel(localVertexIndexes) < 3
    % Fallback: take K nearest vertices.
    nLocalVertices = min(max(round(localSurfaceVertexCount), 3), size(V, 1));
    [~, localVertexIndexes] = mink(distances, nLocalVertices);
end

localVerts = V(localVertexIndexes,:);

if size(localVerts, 1) < 3
    surfaceNormal = [0 0 0];
    localVertexIndexes = [];
    return
end

[~, surfaceNormal] = fitPlanePCA(localVerts);

end


function vector = normalizeVector(vector)

%NORMALIZEVECTOR Safe unit-length normalization.
% Why: downstream calculations (dot/cross/projection) assume finite unit
% vectors; we return a zero vector when normalization isn't possible.

vectorLength = norm(vector);

if vectorLength <= eps || ~isfinite(vectorLength)
    vector = zeros(size(vector));
else
    vector = vector ./ vectorLength;
end

end


function planeSize = estimatePlaneSize(boundaryVerts, planePoint, planeNormal)

%ESTIMATEPLANESIZE Choose a visual/interaction size for the cut plane.
%
% We project boundary vertices into the plane coordinate system and take a
% robust radius estimate.
% Why: using the 95th percentile (rather than max) makes the plane size less
% sensitive to outliers and isolated stray boundary vertices.

U = basisFromNormal(planeNormal);
projected = (boundaryVerts - planePoint) * U;
r = vecnorm(projected, 2, 2);

% Expand slightly so the plane comfortably covers the boundary.
planeSize = prctile(r, 95) * 1.15;

if planeSize <= 0 || ~isfinite(planeSize)
    planeSize = max(range(boundaryVerts, 1)) * 0.5;
end

if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
    planeSize = 1;
end

end


function U = basisFromNormal(normal)

%BASISFROMNORMAL Build an orthonormal 2D basis spanning the plane.
%
% Returns U = [u v] where u and v are orthonormal and both perpendicular to
% the supplied normal.
% Why: this avoids calling null() (which is heavier) in tight loops.

normal = normalizeVector(normal);

if all(normal == 0)
    U = eye(3,2);
    return
end

tmp = [1 0 0];

if abs(dot(tmp, normal)) > 0.9
    tmp = [0 1 0];
end

u = cross(normal, tmp);
u = normalizeVector(u);

v = cross(normal, u);
v = normalizeVector(v);

U = [u(:) v(:)];

end


function visualizeSplitPrototype(V, F, labels, planes)

%VISUALIZESPLITPROTOTYPE Debug visualization.
% Why: when tuning smoothing/thresholds, it helps to see the segmentation
% and plane placement; this is intentionally kept out of the main pipeline.

figure;
hold on;
axis equal;
view(3);
grid on;

colors = lines(max(labels));
faceColor = colors(labels,:);

patch( ...
    'Vertices', V, ...
    'Faces', F, ...
    'FaceVertexCData', faceColor, ...
    'FaceColor', 'interp', ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.82);

for planeIndex = 1:numel(planes)
    boundaryVerts = planes(planeIndex).boundaryVerts;

    scatter3(boundaryVerts(:,1), boundaryVerts(:,2), boundaryVerts(:,3), ...
        20, 'k', 'filled');

    drawPlane( ...
        planes(planeIndex).point, ...
        planes(planeIndex).normal, ...
        planes(planeIndex).size);
end

camlight;
lighting gouraud;

title('Proposed cut planes');
xlabel('X');
ylabel('Y');
zlabel('Z');

end


function drawPlane(point, normal, planeSize)

%DRAWPLANE Simple plane quad + normal arrow for debugging.

normal = normalizeVector(normal);

if all(normal == 0)
    return
end

tmp = [1 0 0];

if abs(dot(tmp, normal)) > 0.9
    tmp = [0 1 0];
end

u = cross(normal, tmp);
u = normalizeVector(u);

v = cross(normal, u);
v = normalizeVector(v);

scale = planeSize;

corners = [
    point + scale * (-u - v)
    point + scale * ( u - v)
    point + scale * ( u + v)
    point + scale * (-u + v)
];

patch( ...
    'Vertices', corners, ...
    'Faces', [1 2 3 4], ...
    'FaceColor', [0 0 0], ...
    'FaceAlpha', 0.2, ...
    'EdgeColor', 'k');

quiver3(point(1), point(2), point(3), ...
    normal(1)*scale, normal(2)*scale, normal(3)*scale, ...
    'LineWidth', 2, ...
    'Color', 'k');

end
