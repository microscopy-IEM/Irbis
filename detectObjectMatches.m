function matchEvents = detectObjectMatches(tableArray, distanceThreshold)

distanceWeight = 0.7;
volumeWeight = 0.3;

relativeThreshold = 1.3;

matchEvents = struct([]);
eventCounter = 1;

for i = 1:(numel(tableArray)-1)

    currentTPList = tableArray{i};
    nextTPList = tableArray{i+1};

    nCurrentObjects = height(currentTPList);
    nNextObjects = height(nextTPList);

    if nCurrentObjects == 0 || nNextObjects == 0
        continue
    end

    % -------------------------------------------------------------
    % Centres
    % -------------------------------------------------------------
    currentTPCentre = computeObjectCentres(currentTPList);
    nextTPCentre = computeObjectCentres(nextTPList);

    % -------------------------------------------------------------
    % Optional volume
    % -------------------------------------------------------------
    [hasCurrentVolume, currentVolumes] = ...
        getNumericColumnForMatching(currentTPList, {'volume'});

    [hasNextVolume, nextVolumes] = ...
        getNumericColumnForMatching(nextTPList, {'volume'});

    % -------------------------------------------------------------
    % Distance matrix
    % -------------------------------------------------------------
    distanceMatrix = ...
        pdist2(currentTPCentre, nextTPCentre);

    validPairMask = ...
        distanceMatrix <= distanceThreshold;

    if ~any(validPairMask, 'all')
        continue
    end

    % -------------------------------------------------------------
    % Combined score
    % -------------------------------------------------------------
    distanceNorm = ...
        normalizeMatrixToUnitInterval( ...
        distanceMatrix, validPairMask);

    combinedCost = inf(size(distanceMatrix));

    combinedCost(validPairMask) = ...
        distanceNorm(validPairMask);

    volumeDifference = nan(size(distanceMatrix));

    if hasCurrentVolume && hasNextVolume

        volumeAvailableMask = ...
            isfinite(currentVolumes) & ...
            isfinite(nextVolumes.');

        volumeDifference = ...
            abs(currentVolumes - nextVolumes.') ./ ...
            max(max(abs(currentVolumes), ...
            abs(nextVolumes.')), eps);

        volumeMask = ...
            validPairMask & volumeAvailableMask;

        if any(volumeMask,'all')

            volumeNorm = ...
                normalizeMatrixToUnitInterval( ...
                volumeDifference, volumeMask);

            combinedCost(volumeMask) = ...
                distanceWeight * distanceNorm(volumeMask) + ...
                volumeWeight * volumeNorm(volumeMask);
        end
    end

    % -------------------------------------------------------------
    % Generate candidate edges
    % -------------------------------------------------------------
    edgeList = [];

    for currentIdx = 1:nCurrentObjects

        candidateIdx = find(validPairMask(currentIdx,:));

        if isempty(candidateIdx)
            continue
        end

        candidateScores = ...
            combinedCost(currentIdx, candidateIdx);

        bestScore = min(candidateScores);

        keepMask = ...
            candidateScores <= ...
            bestScore * relativeThreshold;

        keptCandidates = candidateIdx(keepMask);

        for k = 1:numel(keptCandidates)

            nextIdx = keptCandidates(k);

            edge.currentIndex = currentIdx;
            edge.nextIndex = nextIdx;

            edge.currentObjectId = ...
                str2double( ...
                currentTPList.Properties.RowNames{currentIdx});

            edge.nextObjectId = ...
                str2double( ...
                nextTPList.Properties.RowNames{nextIdx});

            edge.score = ...
                combinedCost(currentIdx, nextIdx);

            edge.distanceScore = ...
                distanceMatrix(currentIdx, nextIdx);

            if ~isempty(volumeDifference)
                edge.volumeScore = ...
                    volumeDifference(currentIdx, nextIdx);
            else
                edge.volumeScore = NaN;
            end

            edgeList = [edgeList; edge];
        end
    end

    if isempty(edgeList)
        continue
    end

    % -------------------------------------------------------------
    % Build graph topology
    % -------------------------------------------------------------
    currentNodes = [edgeList.currentIndex];
    nextNodes = [edgeList.nextIndex];

    G = graph();

    currentNodeNames = ...
        "C_" + string(currentNodes);

    nextNodeNames = ...
        "N_" + string(nextNodes);

    G = addedge( ...
        G, ...
        currentNodeNames, ...
        nextNodeNames);

    bins = conncomp(G);

    uniqueBins = unique(bins);

    % -------------------------------------------------------------
    % Classify connected components
    % -------------------------------------------------------------
    for binIdx = 1:numel(uniqueBins)

        nodeMask = bins == uniqueBins(binIdx);

        nodeNames = G.Nodes.Name(nodeMask);

        currentMask = startsWith(nodeNames, "C_");
        nextMask = startsWith(nodeNames, "N_");

        currentIndexes = ...
            str2double(extractAfter( ...
            nodeNames(currentMask), 2));

        nextIndexes = ...
            str2double(extractAfter( ...
            nodeNames(nextMask), 2));

        event.timePoint1 = i;
        event.timePoint2 = i + 1;

        event.sourceIndexes = unique(currentIndexes);
        event.targetIndexes = unique(nextIndexes);

        event.sourceObjectIds = ...
            str2double( ...
            currentTPList.Properties.RowNames( ...
            event.sourceIndexes));

        event.targetObjectIds = ...
            str2double( ...
            nextTPList.Properties.RowNames( ...
            event.targetIndexes));

        % ---------------------------------------------------------
        % Event type
        % ---------------------------------------------------------
        nCurrent = numel(event.sourceIndexes);
        nNext = numel(event.targetIndexes);

        if nCurrent == 1 && nNext == 1

            event.type = 'continuation';

        elseif nCurrent > 1 && nNext == 1

            event.type = 'merge';

        elseif nCurrent == 1 && nNext > 1

            event.type = 'split';

        else

            event.type = 'complex';

        end

        matchEvents(eventCounter) = event;

        eventCounter = eventCounter + 1;
    end
end