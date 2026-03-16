function [newBasePoints, capVertexIds, figH] = refine_base_points_from_mesh2(meshList, basePoints, mesh2, varargin)
%REFINE_BASE_POINTS_FROM_MESH2 Recompute base-point centers from cap vertices near mesh2.
%   [newBasePoints, capVertexIds, figH] = refine_base_points_from_mesh2(...)
%   takes a list of meshes (components), original basePoints (Nx3 or Nx6),
%   and the original subtractor mesh2. For each mesh, it finds vertices near
%   mesh2, picks a representative cap center, updates base point position,
%   and optionally updates normal (cols 4:6) to point inside the mesh.
%
%   Name-value parameters:
%       'DistanceThreshold' : scalar, default [] (auto per component)
%       'ShowFigure'        : logical, default true
%       'FaceAlpha'         : scalar in [0,1], default 0.25

    p = inputParser;
    addParameter(p, 'DistanceThreshold', [], @(x) isempty(x) || (isscalar(x) && x > 0));
    addParameter(p, 'ShowFigure', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'FaceAlpha', 0.25, @(x) isscalar(x) && x >= 0 && x <= 1);
    parse(p, varargin{:});

    fixedThreshold = p.Results.DistanceThreshold;
    showFigure = logical(p.Results.ShowFigure);
    % faceAlpha = p.Results.FaceAlpha;
    faceAlpha = 1;

    meshList = i_normalize_mesh_list(meshList);
    nMeshes = numel(meshList);

    if size(basePoints, 1) ~= nMeshes
        error('basePoints rows (%d) must match number of meshes (%d).', size(basePoints, 1), nMeshes);
    end

    [mesh2Vertices, mesh2Faces, ~] = i_unpack_mesh(mesh2);
    if isempty(mesh2Vertices)
        error('mesh2 does not contain valid vertices.');
    end

    mesh2EdgeMed = i_median_edge_length(mesh2Vertices, mesh2Faces);

    newBasePoints = basePoints;
    capVertexIds = cell(nMeshes, 1);

    for i = 1:nMeshes
        [vertices, faces, vertexNormals] = i_unpack_mesh(meshList{i});
        if isempty(vertices)
            newBasePoints(i, 1:min(3, size(newBasePoints, 2))) = nan;
            continue;
        end

        if isempty(fixedThreshold)
            distanceThreshold = i_auto_threshold(vertices, faces, mesh2EdgeMed);
        else
            distanceThreshold = fixedThreshold;
        end

        d = i_nearest_distances(vertices, mesh2Vertices);
        closeIdx = find(d < distanceThreshold);
        capVertexIds{i} = closeIdx;

        if ~isempty(closeIdx)
            localIdx = i_pick_representative_point(vertices(closeIdx, :));
            chosenVertexIdx = closeIdx(localIdx);
        else
            % Fallback: keep position anchored near the old point if available.
            if size(basePoints, 2) >= 3 && all(isfinite(basePoints(i, 1:3)))
                [~, chosenVertexIdx] = min(sum((vertices - basePoints(i, 1:3)).^2, 2));
            else
                chosenVertexIdx = 1;
            end
        end

        newBasePoints(i, 1:3) = vertices(chosenVertexIdx, :);

        if size(newBasePoints, 2) >= 6
            n = i_get_inward_normal(vertices, faces, vertexNormals, chosenVertexIdx);
            newBasePoints(i, 4:6) = n;
        end
    end

    if showFigure
        figH = figure('Name', 'Base Point Refinement');
        ax = axes(figH, 'Projection', 'orthographic', 'Clipping', 'off');
        hold(ax, 'on');

        nonCapColor = [0.70 0.78 0.92];
        capColor = [0.98 0.82 0.24];
        vertexMarkerSize = 10;

        for i = 1:nMeshes
            [vertices, faces, ~] = i_unpack_mesh(meshList{i});
            if isempty(vertices) || isempty(faces)
                continue;
            end

            % Per-vertex color coding: cap vertices vs non-cap vertices.
            vertexColors = repmat(nonCapColor, size(vertices, 1), 1);
            currentCap = capVertexIds{i};
            if ~isempty(currentCap)
                currentCap = currentCap(currentCap >= 1 & currentCap <= size(vertices, 1));
                vertexColors(currentCap, :) = repmat(capColor, numel(currentCap), 1);
            end

            patch(ax, 'Vertices', vertices, 'Faces', faces, ...
                'FaceVertexCData', vertexColors, 'FaceColor', 'interp', ...
                'EdgeColor', [0.4 0.4 0.4], ...
                'FaceAlpha', faceAlpha, 'Clipping', 'off');

            % Explicit vertex markers so cap/non-cap classification is visible on vertices.
            isCap = false(size(vertices, 1), 1);
            isCap(currentCap) = true;

            if any(~isCap)
                scatter3(ax, vertices(~isCap, 1), vertices(~isCap, 2), vertices(~isCap, 3), ...
                    vertexMarkerSize, nonCapColor, 'filled', ...
                    'MarkerEdgeColor', 'none', 'HandleVisibility', 'off', 'Clipping', 'off');
            end

            if any(isCap)
                scatter3(ax, vertices(isCap, 1), vertices(isCap, 2), vertices(isCap, 3), ...
                    vertexMarkerSize, capColor, 'filled', ...
                    'MarkerEdgeColor', 'none', 'HandleVisibility', 'off', 'Clipping', 'off');
            end
        end

        validOld = size(basePoints, 2) >= 3 & all(isfinite(basePoints(:, 1:3)), 2);
        validNew = all(isfinite(newBasePoints(:, 1:3)), 2);

        if any(validOld)
            scatter3(ax, basePoints(validOld, 1), basePoints(validOld, 2), basePoints(validOld, 3), ...
                36, 'r', 'filled', 'DisplayName', 'Original base points', 'Clipping', 'off');
        end
        if any(validNew)
            scatter3(ax, newBasePoints(validNew, 1), newBasePoints(validNew, 2), newBasePoints(validNew, 3), ...
                36, 'b', 'filled', 'DisplayName', 'Updated base points', 'Clipping', 'off');
        end

        % Add legend entries for cap/non-cap vertex colors.
        scatter3(ax, nan, nan, nan, 36, nonCapColor, 'filled', 'DisplayName', 'Non-cap vertices');
        scatter3(ax, nan, nan, nan, 36, capColor, 'filled', 'DisplayName', 'Cap vertices');

        axis(ax, 'equal');
        axis(ax, 'vis3d');
        grid(ax, 'on');
        view(ax, 3);
        camproj(ax, 'orthographic');
        rotate3d(figH, 'on');
        zoom(figH, 'on');
        xlabel(ax, 'X'); ylabel(ax, 'Y'); zlabel(ax, 'Z');
        title(ax, 'Meshes with Original (red) and Updated (blue) Base Points');
        % legend(ax, 'Location', 'best');
        hold(ax, 'off');
    else
        figH = [];
    end
end

function meshList = i_normalize_mesh_list(meshList)
    if iscell(meshList)
        return;
    end
    if isa(meshList, 'surfaceMesh')
        meshList = num2cell(meshList);
        return;
    end
    if isstruct(meshList)
        meshList = num2cell(meshList);
        return;
    end
    error('meshList must be a cell array, struct array, or surfaceMesh array.');
end

function [vertices, faces, vertexNormals] = i_unpack_mesh(mesh)
    vertices = [];
    faces = [];
    vertexNormals = [];

    if isa(mesh, 'surfaceMesh')
        vertices = double(mesh.Vertices);
        faces = double(mesh.Faces);
        if isprop(mesh, 'VertexNormals')
            vertexNormals = double(mesh.VertexNormals);
        end
    elseif isstruct(mesh)
        if isfield(mesh, 'vertices'), vertices = double(mesh.vertices); end
        if isfield(mesh, 'Vertices'), vertices = double(mesh.Vertices); end
        if isfield(mesh, 'faces'), faces = double(mesh.faces); end
        if isfield(mesh, 'Faces'), faces = double(mesh.Faces); end
        if isfield(mesh, 'vertexNormals'), vertexNormals = double(mesh.vertexNormals); end
        if isfield(mesh, 'VertexNormals'), vertexNormals = double(mesh.VertexNormals); end
    end

    if ~isempty(faces) && min(faces(:)) == 0
        faces = faces + 1;
    end
end

function edgeMed = i_median_edge_length(vertices, faces)
    if isempty(vertices) || isempty(faces)
        edgeMed = nan;
        return;
    end

    e = [faces(:, [1 2]); faces(:, [2 3]); faces(:, [3 1])];
    e = sort(e, 2);
    e = unique(e, 'rows');
    vec = vertices(e(:, 1), :) - vertices(e(:, 2), :);
    lengths = sqrt(sum(vec.^2, 2));
    edgeMed = median(lengths, 'omitnan');
end

function thr = i_auto_threshold(vertices, faces, mesh2EdgeMed)
    bboxDiag = norm(max(vertices, [], 1) - min(vertices, [], 1));
    compEdgeMed = i_median_edge_length(vertices, faces);

    if ~isfinite(compEdgeMed)
        compEdgeMed = 1e-3 * max(bboxDiag, 1);
    end
    if ~isfinite(mesh2EdgeMed)
        mesh2EdgeMed = compEdgeMed;
    end

    % raw = max(1.5 * compEdgeMed, 1.0 * mesh2EdgeMed);
    raw = max(3 * compEdgeMed, 2 * mesh2EdgeMed);
    minThr = max(1e-12, 1e-4 * max(bboxDiag, 1));
    maxThr = max(minThr, 5e-3 * max(bboxDiag, 1));
    thr = min(max(raw, minThr), maxThr);
end

function d = i_nearest_distances(queryPoints, refPoints)
    % Chunked distance computation to avoid large temporary matrices.
    n = size(queryPoints, 1);
    d2min = inf(n, 1);
    block = 2000;

    for s = 1:block:size(refPoints, 1)
        e = min(s + block - 1, size(refPoints, 1));
        refBlock = refPoints(s:e, :);
        d2 = pdist2(queryPoints, refBlock, 'squaredeuclidean');
        d2min = min(d2min, min(d2, [], 2));
    end

    d = sqrt(d2min);
end

function idx = i_pick_representative_point(points)
    if size(points, 1) == 1
        idx = 1;
        return;
    end
    d = pdist2(points, points, 'euclidean');
    [~, idx] = min(sum(d, 2));
end

function n = i_get_inward_normal(vertices, faces, vertexNormals, vertexIdx)
    if ~isempty(vertexNormals) && size(vertexNormals, 1) >= vertexIdx
        n = vertexNormals(vertexIdx, :);
    else
        incident = any(faces == vertexIdx, 2);
        if any(incident)
            fn = i_face_normals(vertices, faces(incident, :));
            n = mean(fn, 1, 'omitnan');
        else
            n = [nan nan nan];
        end
    end

    n = i_safe_unit(n);
    if all(isfinite(n))
        c = mean(vertices, 1, 'omitnan');
        toInside = c - vertices(vertexIdx, :);
        if dot(n, toInside) < 0
            n = -n;
        end
    end
end

function fn = i_face_normals(vertices, faces)
    v1 = vertices(faces(:, 1), :);
    v2 = vertices(faces(:, 2), :);
    v3 = vertices(faces(:, 3), :);
    fn = cross(v2 - v1, v3 - v1, 2);
    for i = 1:size(fn, 1)
        fn(i, :) = i_safe_unit(fn(i, :));
    end
end

function v = i_safe_unit(v)
    nv = norm(v);
    if nv <= 1e-12
        v = [nan nan nan];
    else
        v = v ./ nv;
    end
end