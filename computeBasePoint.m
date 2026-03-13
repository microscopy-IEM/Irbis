function attachedPoint = computeBasePoint(patchVertices, patchFaces)
% Compute the patch centroid projected onto the closest point on the patch.
%
% attachedPoint = computeBasePoint(patchVertices, patchFaces)
%
% Inputs
%   patchVertices : (N,3) patch vertices
%   patchFaces    : (M,3) patch triangle indices (1-based)
%
% Output
%   attachedPoint : (1,3) closest point on the patch to its centroid

    validateattributes(patchVertices, {'numeric'}, {'2d', 'ncols', 3, 'nonempty'}, mfilename, 'patchVertices', 1);
    validateattributes(patchFaces, {'numeric'}, {'2d', 'ncols', 3, 'nonempty', 'integer', 'positive'}, mfilename, 'patchFaces', 2);

    centroidPoint = mean(patchVertices, 1);
    numberOfFaces = size(patchFaces, 1);

    closestPoints = zeros(numberOfFaces, 3);
    distancesSquared = zeros(numberOfFaces, 1);

    for faceIndex = 1:numberOfFaces
        triangleVertices = patchVertices(patchFaces(faceIndex, :), :);
        triangleVertexA = triangleVertices(1, :);
        triangleVertexB = triangleVertices(2, :);
        triangleVertexC = triangleVertices(3, :);

        closestPoints(faceIndex, :) = closestPointOnTriangle(centroidPoint, triangleVertexA, triangleVertexB, triangleVertexC);

        offsetFromCentroid = centroidPoint - closestPoints(faceIndex, :);
        distancesSquared(faceIndex) = sum(offsetFromCentroid .* offsetFromCentroid);
    end

    [~, nearestTriangleIndex] = min(distancesSquared);
    attachedPoint = closestPoints(nearestTriangleIndex, :);
end



function closestPoint = closestPointOnTriangle(queryPoint, triangleVertexA, triangleVertexB, triangleVertexC)
% Closest point on triangle ABC to point P (Ericson's method).

    edgeAB = triangleVertexB - triangleVertexA;
    edgeAC = triangleVertexC - triangleVertexA;
    vectorAtoQuery = queryPoint - triangleVertexA;
    dotEdgeABWithAtoQuery = dot(edgeAB, vectorAtoQuery);
    dotEdgeACWithAtoQuery = dot(edgeAC, vectorAtoQuery);
    if dotEdgeABWithAtoQuery <= 0 && dotEdgeACWithAtoQuery <= 0
        closestPoint = triangleVertexA;
        return;
    end

    vectorBtoQuery = queryPoint - triangleVertexB;
    dotEdgeABWithBtoQuery = dot(edgeAB, vectorBtoQuery);
    dotEdgeACWithBtoQuery = dot(edgeAC, vectorBtoQuery);
    if dotEdgeABWithBtoQuery >= 0 && dotEdgeACWithBtoQuery <= dotEdgeABWithBtoQuery
        closestPoint = triangleVertexB;
        return;
    end

    determinantVC = dotEdgeABWithAtoQuery * dotEdgeACWithBtoQuery - dotEdgeABWithBtoQuery * dotEdgeACWithAtoQuery;
    if determinantVC <= 0 && dotEdgeABWithAtoQuery >= 0 && dotEdgeABWithBtoQuery <= 0
        barycentricWeightV = dotEdgeABWithAtoQuery / (dotEdgeABWithAtoQuery - dotEdgeABWithBtoQuery);
        closestPoint = triangleVertexA + barycentricWeightV * edgeAB;
        return;
    end

    vectorCtoQuery = queryPoint - triangleVertexC;
    dotEdgeABWithCtoQuery = dot(edgeAB, vectorCtoQuery);
    dotEdgeACWithCtoQuery = dot(edgeAC, vectorCtoQuery);
    if dotEdgeACWithCtoQuery >= 0 && dotEdgeABWithCtoQuery <= dotEdgeACWithCtoQuery
        closestPoint = triangleVertexC;
        return;
    end

    determinantVB = dotEdgeABWithCtoQuery * dotEdgeACWithAtoQuery - dotEdgeABWithAtoQuery * dotEdgeACWithCtoQuery;
    if determinantVB <= 0 && dotEdgeACWithAtoQuery >= 0 && dotEdgeACWithCtoQuery <= 0
        barycentricWeightW = dotEdgeACWithAtoQuery / (dotEdgeACWithAtoQuery - dotEdgeACWithCtoQuery);
        closestPoint = triangleVertexA + barycentricWeightW * edgeAC;
        return;
    end

    determinantVA = dotEdgeABWithBtoQuery * dotEdgeACWithCtoQuery - dotEdgeABWithCtoQuery * dotEdgeACWithBtoQuery;
    if determinantVA <= 0 && (dotEdgeACWithBtoQuery - dotEdgeABWithBtoQuery) >= 0 && (dotEdgeABWithCtoQuery - dotEdgeACWithCtoQuery) >= 0
        edgeBC = triangleVertexC - triangleVertexB;
        barycentricWeightW = (dotEdgeACWithBtoQuery - dotEdgeABWithBtoQuery) / ...
            ((dotEdgeACWithBtoQuery - dotEdgeABWithBtoQuery) + (dotEdgeABWithCtoQuery - dotEdgeACWithCtoQuery));
        closestPoint = triangleVertexB + barycentricWeightW * edgeBC;
        return;
    end

    inverseDeterminantSum = 1 / (determinantVA + determinantVB + determinantVC);
    barycentricWeightV = determinantVB * inverseDeterminantSum;
    barycentricWeightW = determinantVC * inverseDeterminantSum;
    barycentricWeightU = 1 - barycentricWeightV - barycentricWeightW;
    closestPoint = barycentricWeightU * triangleVertexA + barycentricWeightV * triangleVertexB + barycentricWeightW * triangleVertexC;
end
