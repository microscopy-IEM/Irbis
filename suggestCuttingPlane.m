function [center, normal] = suggestCuttingPlane(V, F)
%SUGGESTCUTTINGPLANE Estimate a separating plane between two mesh regions.
%   [CENTER, NORMAL, STATS] = SUGGESTCUTTINGPLANE(V, F) computes a plane
%   that slices the mesh defined by vertices V (n-by-3) and triangular
%   faces F (m-by-3). The plane center and unit normal are returned in the
%   original coordinate system. STATS contains diagnostics about the fit.

    if size(V, 1) < 3
        error('suggestCuttingPlane:InsufficientVertices', ...
            'At least three vertices are required.');
    end

    nVertices = size(V, 1);
    if any(F(:) < 1 | F(:) > nVertices)
        error('suggestCuttingPlane:InvalidFaces', ...
            'Face indices must reference rows of V.');
    end

    meshCentroid = mean(V, 1);
    centeredV = V - meshCentroid;
    F = double(F);

    W = meshSimilarityMatrix(centeredV, F);

    clusterLabels = spectralcluster(W, 2, 'Distance', 'precomputed');
    if numel(unique(clusterLabels)) < 2
        error('suggestCuttingPlane:SingleCluster', ...
            'Spectral clustering failed to produce two distinct regions.');
    end

    cutPointsCentered = cutInterfacePoints(centeredV, F, clusterLabels);
    if size(cutPointsCentered, 1) < 3
        error('suggestCuttingPlane:InsufficientCutPoints', ...
            'Need at least three cut-point samples to fit a plane.');
    end

    [centerLocal, normal] = fitPlanePCA(cutPointsCentered);
    center = centerLocal + meshCentroid;

    % figure 
    % for i = 1:2
    %     scatter3(centeredV(clusterLabels==i,1),centeredV(clusterLabels==i,2),centeredV(clusterLabels==i,3))
    %     hold on 
    % end
    % % scatter3(cutPointsCentered(:,1), cutPointsCentered(:,2), cutPointsCentered(:,3), 10, 'k', 'filled');
    % % quiver3(center(1), center(2), center(3), normal(1), normal(2), normal(3), ...
    % %         1, 'LineWidth', 2);
    % axis equal
end


function W = meshSimilarityMatrix(V, F)
%MESHSIMILARITYMATRIX Build a symmetric similarity matrix for mesh edges.

    TR = triangulation(F, V);
    edges = TR.edges;
    if isempty(edges)
        error('suggestCuttingPlane:NoEdges', ...
            'Mesh must contain at least one edge.');
    end
    i = edges(:, 1);
    j = edges(:, 2);

    % Mahalanobis distance used to compute similarity weights
    C = cov(V);
    if any(isnan(C), 'all') || rank(C) < 2
        C = diag(max(var(V, 0, 1), eps));
    end
    Ci = pinv(C);

    delta = V(i, :) - V(j, :);
    dM = sqrt(sum((delta * Ci) .* delta, 2));

    sigma = median(dM);
    if ~isfinite(sigma) || sigma <= 0
        sigma = max(std(dM), eps);
    end
    weights = exp(-(dM .^ 2) / (2 * sigma ^ 2));

    n = size(V, 1);
    W = sparse([i; j], [j; i], [weights; weights], n, n, 2 * numel(weights));
end

function P = cutInterfacePoints(V, F, labels)
%CUTINTERFACEPOINTS Sample vertices lying on the interface between clusters.

    TR = triangulation(F, V);
    allEdges = TR.edges;
    cutMask = labels(allEdges(:, 1)) ~= labels(allEdges(:, 2));
    cutEdges = allEdges(cutMask, :);

    if isempty(cutEdges)
        error('cutInterfacePoints:NoInterface', ...
            'Clustering produced no interface edges.');
    end

    verticesOnCut = unique(cutEdges(:));
    P = V(verticesOnCut, :);

    edgeMidpoints = 0.5 * (V(cutEdges(:, 1), :) + V(cutEdges(:, 2), :));
    P = [P; edgeMidpoints]; %#ok<AGROW>
end


function [center, normal] = fitPlanePCA(P)
%FITPLANEPCA Fit a plane to point cloud P via principal component analysis.

    center = mean(P, 1);
    X = P - center;

    [~, S, V] = svd(X, 0);
    singularValues = diag(S);

    if numel(singularValues) < 2 || singularValues(2) < eps(max(singularValues))
        error('fitPlanePCA:DegenerateGeometry', ...
            'Point cloud is degenerate; cannot fit a reliable plane.');
    end

    normal = V(:, 3);
    if normal(3) < 0
        normal = -normal;
    end
end

