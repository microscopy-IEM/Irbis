function cloud = subsampleVertices(vertices, randomSeed, vertexKeepFraction, minSampleCount)
%subsampleVertices Convert vertices into a downsampled pointCloud.

    arguments
        vertices (:,3) double
        randomSeed = []
        vertexKeepFraction (1,1) double {mustBeGreaterThan(vertexKeepFraction, 0), mustBeLessThanOrEqual(vertexKeepFraction, 1)} = []
        minSampleCount (1,1) double {mustBePositive, mustBeInteger} = 5000
    end

    if ~isempty(randomSeed)
        oldRng = rng;
        rng(randomSeed, 'twister');
        restoreRng = true;
    else
        restoreRng = false;
    end

    nVerts = size(vertices, 1);

    if ~isempty(vertexKeepFraction)
        keepCount = max(1, round(vertexKeepFraction * nVerts));
    else
        keepCount = min(minSampleCount, nVerts);
    end

    if keepCount < nVerts
        sampledIndices = randperm(nVerts, keepCount);
        sampledPoints = vertices(sampledIndices, :);
    else
        sampledPoints = vertices;
    end

    cloud = pointCloud(sampledPoints);
    if restoreRng
        rng(oldRng);
    end
end