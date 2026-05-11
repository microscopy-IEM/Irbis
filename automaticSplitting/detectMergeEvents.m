function mergeEvents = detectMergeEvents(tableArray, distanceThreshold)

%DETECTMERGEEVENTS Detect temporal merge/split/complex events between consecutive timepoints.
%
%   mergeEvents = detectMergeEvents(tableArray)
%   mergeEvents = detectMergeEvents(tableArray, distanceThreshold)
%
%   This function scans consecutive entries in tableArray (timepoint i and
%   i+1) and reports *non-trivial temporal events* in object identity:
%     - 'merge'   : multiple objects at time i link to one at time i+1
%     - 'split'   : one object at time i links to multiple at time i+1
%     - 'complex' : multiple-to-multiple connected component
%
%   Simple continuations (1-to-1 links) are intentionally NOT returned,
%   because downstream analysis typically focuses on topological changes.
%
%   INPUTS
%     tableArray         1xN cell array of tables (one per timepoint).
%                        Each table must contain a variable 'Mesh' where
%                        each entry has a .Vertices field.
%                        RowNames must be numeric object IDs (as strings).
%
%     distanceThreshold  Optional scalar centroid-distance gating threshold
%                        (same units as the mesh vertex coordinates). If NaN,
%                        a per-timepoint-pair threshold is estimated from
%                        nearest-neighbour centroid distances and a bbox
%                        size scale.
%
%   OUTPUT
%     mergeEvents        Struct array with fields describing each event and
%                        the participating source/target indices/IDs.
%
%   DESIGN RATIONALE (high level)
%     1) Build a conservative candidate set using simple geometric gates
%        (centroid distance, bbox containment, and optional volume filter).
%     2) Keep more than just the best link per object (relativeThreshold)
%        to preserve split/merge topology.
%     3) Use connected components of a bipartite graph to classify event
%        topology robustly without solving a full assignment problem.
%     4) For complex components, greedily remove very obvious 1-to-1
%        continuations so remaining nodes better reflect true events.
%     5) If a tracked groupId is present on the merged/split object, expand
%        the event to matching groupId occurrences in later/earlier
%        timepoints. If a groupId lies between a merge and a later split,
%        assign each occurrence to the closer event anchor.

    arguments
        tableArray (1,:) cell
        distanceThreshold (1,1) double = NaN
    end

    % relativeThreshold:
    %   Keep candidates within (bestScore * relativeThreshold) for each
    %   source object. This intentionally keeps multiple plausible edges so
    %   later graph topology can detect splits/merges.
    relativeThreshold = 1.3;

    % minimumVolume:
    %   Optional filter if a 'volume' column exists. Small objects can be
    %   noisy segmentations that otherwise create spurious events.
    minimumVolume = 0.01;

    % minimumContainment:
    %   Intersection / bbox volume heuristic to avoid linking objects that
    %   are close in centroid distance but do not spatially overlap.
    minimumContainment = 0.2;

    % sameObjectVolumeTolerance:
    %   Used only when pruning obvious continuations inside complex
    %   components (relative volume difference).
    sameObjectVolumeTolerance = 0.35;

    if numel(tableArray) < 2
        mergeEvents = struct( ...
            'type', {}, ...
            'timePoint1', {}, ...
            'timePoint2', {}, ...
            'sourceIndexes', {}, ...
            'targetIndexes', {}, ...
            'sourceObjectIds', {}, ...
            'targetObjectIds', {}, ...
            'removedContinuationSourceIndexes', {}, ...
            'removedContinuationTargetIndexes', {});
        return
    end

    mergeEvents = struct( ...
        'type', {}, ...
        'timePoint1', {}, ...
        'timePoint2', {}, ...
        'sourceIndexes', {}, ...
        'targetIndexes', {}, ...
        'sourceObjectIds', {}, ...
        'targetObjectIds', {}, ...
        'removedContinuationSourceIndexes', {}, ...
        'removedContinuationTargetIndexes', {});

    eventCounter = 1;

    for i = 1:(numel(tableArray)-1)

        currentTPList = tableArray{i};
        nextTPList = tableArray{i+1};

        nCurrentObjects = height(currentTPList);
        nNextObjects = height(nextTPList);

        if nCurrentObjects == 0 || nNextObjects == 0
            continue
        end

        % Object IDs are taken from RowNames so we can report stable IDs
        % independent of row ordering.
        currentObjectIds = rowNamesToNumericIds(currentTPList);
        nextObjectIds = rowNamesToNumericIds(nextTPList);

        % -------------------------------------------------------------
        % Centroids
        % -------------------------------------------------------------
        % Centroids are used for a fast distance gate and for scoring.
        currentTPCentre = computeObjectCentres(currentTPList);
        nextTPCentre = computeObjectCentres(nextTPList);

        % -------------------------------------------------------------
        % Bounding boxes and containment
        % -------------------------------------------------------------
        % Axis-aligned bounding boxes (AABB) are cheap to compute and give a
        % coarse overlap signal (containmentMatrix) that is robust to minor
        % mesh irregularities.
        currentBBox = computeObjectBoundingBoxes(currentTPList);
        nextBBox = computeObjectBoundingBoxes(nextTPList);

        containmentMatrix = boundingBoxContainmentMatrix(currentBBox, nextBBox);

        % -------------------------------------------------------------
        % Volume-based filtering (optional)
        % -------------------------------------------------------------
        % Volume is not required for matching. If present, it is used as a
        % simple reliability filter.
        [hasCurrentVolume, currentVolumes] = getNumericColumnForMatching(currentTPList, {'volume'});
        [hasNextVolume, nextVolumes] = getNumericColumnForMatching(nextTPList, {'volume'});

        currentAllowed = true(nCurrentObjects, 1);
        nextAllowed = true(nNextObjects, 1);

        if hasCurrentVolume
            currentAllowed = currentVolumes >= minimumVolume;
        end

        if hasNextVolume
            nextAllowed = nextVolumes >= minimumVolume;
        end

        % -------------------------------------------------------------
        % Pairwise centroid distances
        % -------------------------------------------------------------
        % pdist2 creates an nCurrent x nNext matrix.
        centroidDistanceMatrix = pdist2(currentTPCentre, nextTPCentre);

        % -------------------------------------------------------------
        % Distance threshold (manual or auto-estimated)
        % -------------------------------------------------------------
        % distanceThreshold is treated as a gating parameter only.
        % If not provided (NaN), we infer a conservative threshold per
        % timepoint pair to avoid requiring manual tuning.
        localDistanceThreshold = distanceThreshold;
        if isnan(localDistanceThreshold)
            localDistanceThreshold = estimateDistanceThreshold(centroidDistanceMatrix, currentBBox, nextBBox);
        end
        localSameObjectDistanceThreshold = localDistanceThreshold * 0.35;

        % -------------------------------------------------------------
        % Candidate pair gate
        % -------------------------------------------------------------
        % We only consider pairs that are:
        %   - close in centroid distance,
        %   - sufficiently overlapping in AABB terms,
        %   - above optional volume thresholds.
        validPairMask = ...
            centroidDistanceMatrix <= localDistanceThreshold & ...
            containmentMatrix >= minimumContainment & ...
            currentAllowed & ...
            nextAllowed.';

        if ~any(validPairMask, 'all')
            continue
        end

        % -------------------------------------------------------------
        % Candidate scoring
        % -------------------------------------------------------------
        % Score is currently distance-only (normalized to [0,1] over valid
        % pairs). Using normalization makes relativeThreshold meaningful
        % across timepoints.
        distanceNorm = normalizeMatrixToUnitInterval(centroidDistanceMatrix, validPairMask);

        combinedCost = inf(size(centroidDistanceMatrix));
        combinedCost(validPairMask) = distanceNorm(validPairMask);

        % -------------------------------------------------------------
        % Build candidate edges (bipartite graph)
        % -------------------------------------------------------------
        % For each current object, keep all targets within a factor of the
        % best score for that source. This preserves split/merge topology
        % while still limiting combinatorial growth.
        maxEdges = nnz(validPairMask);
        edgeCurrent = zeros(maxEdges, 1);
        edgeNext = zeros(maxEdges, 1);
        edgeCount = 0;

        for currentIdx = 1:nCurrentObjects

            candidateIdx = find(validPairMask(currentIdx,:));
            if isempty(candidateIdx)
                continue
            end

            candidateScores = combinedCost(currentIdx, candidateIdx);
            bestScore = min(candidateScores);
            keepMask = candidateScores <= bestScore * relativeThreshold;
            keptCandidates = candidateIdx(keepMask);

            for k = 1:numel(keptCandidates)
                edgeCount = edgeCount + 1;
                edgeCurrent(edgeCount) = currentIdx;
                edgeNext(edgeCount) = keptCandidates(k);
            end
        end

        if edgeCount == 0
            continue
        end

        edgeCurrent = edgeCurrent(1:edgeCount);
        edgeNext = edgeNext(1:edgeCount);

        % -------------------------------------------------------------
        % Connected components define event topology
        % -------------------------------------------------------------
        % We treat edges as a bipartite graph. Each connected component is a
        % self-contained "event candidate":
        %   (nCurrent,nNext) == (1,1) -> continuation (ignored)
        %   (nCurrent,nNext) == (>1,1) -> merge
        %   (nCurrent,nNext) == (1,>1) -> split
        %   (nCurrent,nNext) == (>1,>1) -> complex
        %
        % We build a compact node mapping so MATLAB doesn't create large
        % numbers of isolated nodes.
        allEndpoints = [edgeCurrent; nCurrentObjects + edgeNext];
        [usedNodeIds, ~, remappedEndpoints] = unique(allEndpoints);
        remappedCurrent = remappedEndpoints(1:edgeCount);
        remappedNext = remappedEndpoints(edgeCount+1:end);

        G = graph(remappedCurrent, remappedNext);
        bins = conncomp(G);
        uniqueBins = unique(bins);

        % -------------------------------------------------------------
        % Classify connected components
        % -------------------------------------------------------------
        for binIdx = 1:numel(uniqueBins)

            nodeIds = usedNodeIds(bins == uniqueBins(binIdx));

            currentIndexes = nodeIds(nodeIds <= nCurrentObjects);
            nextIndexes = nodeIds(nodeIds > nCurrentObjects) - nCurrentObjects;

            removedSource = [];
            removedTarget = [];

            % ---------------------------------------------------------
            % Complex-component cleanup: remove obvious 1-to-1 continuations
            % ---------------------------------------------------------
            % If both sides have multiple nodes, it's often a "complex"
            % component because one or more objects continue normally while
            % another split/merge is nearby. We greedily peel off these very
            % obvious continuations so the remaining subgraph better
            % represents the non-trivial event.
            if numel(currentIndexes) > 1 && numel(nextIndexes) > 1

                [currentIndexes, nextIndexes, removedSource, removedTarget] = ...
                    removeObviousContinuationsFromComplexMatch( ...
                        currentIndexes, ...
                        nextIndexes, ...
                        centroidDistanceMatrix, ...
                        currentVolumes, ...
                        nextVolumes, ...
                        hasCurrentVolume && hasNextVolume, ...
                        localSameObjectDistanceThreshold, ...
                        sameObjectVolumeTolerance);
            end

            nCurrent = numel(currentIndexes);
            nNext = numel(nextIndexes);

            if nCurrent == 0 || nNext == 0
                continue
            elseif nCurrent == 1 && nNext == 1
                % 1-to-1 links are treated as continuations and not stored.
                continue
            elseif nCurrent > 1 && nNext == 1
                eventType = 'merge';
            elseif nCurrent == 1 && nNext > 1
                eventType = 'split';
            else
                eventType = 'complex';
            end

            event = createEmptyMergeEvent();

            event.type = eventType;
            event.timePoint1 = i;
            event.timePoint2 = i + 1;

            event.sourceIndexes = currentIndexes(:);
            event.targetIndexes = nextIndexes(:);

            event.sourceObjectIds = currentObjectIds(event.sourceIndexes);
            event.targetObjectIds = nextObjectIds(event.targetIndexes);

            event.removedContinuationSourceIndexes = removedSource(:);
            event.removedContinuationTargetIndexes = removedTarget(:);

            mergeEvents(eventCounter) = event;
            eventCounter = eventCounter + 1;

        end
    end

    mergeEvents = expandMergeSplitEventsByGroupId(tableArray, mergeEvents);

end



function objectIds = rowNamesToNumericIds(objectTable)

    % Convert RowNames into numeric IDs.
    % Rationale: the row index is timepoint-local, while RowNames can be
    % a stable identifier across operations and saves.

    rowNames = objectTable.Properties.RowNames;
    objectIds = str2double(string(rowNames));
    if any(isnan(objectIds))
        error('ObjectMatching:NonNumericObjectId', ...
            'RowNames must be numeric object IDs for matching.');
    end

end



function threshold = estimateDistanceThreshold(centroidDistanceMatrix, currentBBox, nextBBox)

    % Estimate a reasonable matching gate when the user does not provide one.
    %
    % Rationale:
    %   - Using the median nearest-neighbour distance is robust to outliers
    %     (objects appearing/disappearing).
    %   - Incorporating a bbox size scale prevents the threshold from
    %     collapsing to near-zero when motion is small.

    if isempty(centroidDistanceMatrix)
        threshold = 0;
        return
    end

    minPerCurrent = min(centroidDistanceMatrix, [], 2);
    minPerNext = min(centroidDistanceMatrix, [], 1).';
    typicalMotion = median([minPerCurrent; minPerNext], 'omitnan');
    if ~isfinite(typicalMotion)
        typicalMotion = 0;
    end

    currentDiag = bboxDiagonalLengths(currentBBox);
    nextDiag = bboxDiagonalLengths(nextBBox);
    sizeScale = median([currentDiag; nextDiag], 'omitnan');
    if ~isfinite(sizeScale)
        sizeScale = 0;
    end

    % Conservative defaults: allow a few "typical motion" steps, but
    % never smaller than a fraction of typical object size.
    threshold = max(3 * typicalMotion, 0.75 * sizeScale);

    % If everything is tiny/zero, fall back to a small positive epsilon.
    if threshold < eps
        threshold = eps;
    end

    % Avoid absurdly large thresholds in case of outliers.
    if sizeScale > eps
        threshold = min(threshold, 10 * sizeScale);
    end

end



function diagLengths = bboxDiagonalLengths(bboxes)

    % Compute diagonal lengths of axis-aligned bounding boxes.
    % Used only for a scale estimate in automatic distance thresholding.

    n = numel(bboxes);
    diagLengths = nan(n, 1);

    for idx = 1:n
        d = bboxes(idx).maxPoint - bboxes(idx).minPoint;
        diagLengths(idx) = norm(d);
    end

end



function centres = computeObjectCentres(objectTable)

    % Compute per-object centroids from meshes.
    % This is separated for clarity; if performance becomes an issue,
    % centres and bounding boxes could be computed in a single pass.

    nObjects = height(objectTable);
    centres = zeros(nObjects, 3);

    for objectRowNum = 1:nObjects

        objectMesh = objectTable.Mesh{objectRowNum};

        if isempty(objectMesh)
            error('ObjectMatching:MissingMesh', ...
                '3D objects are not generated.');
        end

        centres(objectRowNum,:) = vertexCenter(objectMesh);

    end

end



function [hasColumn, columnData] = getNumericColumnForMatching(objectTable, candidateNames)

    % Look for a numeric column matching one of the candidate names
    % (e.g. 'volume') and return its data as a vector.
    %
    % Rationale: input tables can come from different pipelines with
    % slightly different column naming.

    nObjects = height(objectTable);
    columnData = nan(nObjects, 1);
    hasColumn = false;

    variableNames = objectTable.Properties.VariableNames;

    for candidateIndex = 1:numel(candidateNames)
        matchedIndex = find(strcmpi(variableNames, candidateNames{candidateIndex}), 1);
        if isempty(matchedIndex)
            continue
        end

        candidateColumn = objectTable.(variableNames{matchedIndex});
        if isnumeric(candidateColumn) && isvector(candidateColumn) && numel(candidateColumn) == nObjects
            columnData = candidateColumn(:);
            hasColumn = true;
            return
        end
    end

end



function normalizedMatrix = normalizeMatrixToUnitInterval(inputMatrix, validMask)

    % Normalize values to [0,1] using min/max over validMask.
    % Rationale: this makes scoring comparable across timepoints.

    normalizedMatrix = inf(size(inputMatrix));

    validValueMask = validMask & isfinite(inputMatrix);
    if ~any(validValueMask, 'all')
        return
    end

    validValues = inputMatrix(validValueMask);
    minValue = min(validValues);
    maxValue = max(validValues);

    if maxValue - minValue < eps
        normalizedMatrix(validValueMask) = 0;
    else
        normalizedMatrix(validValueMask) = (inputMatrix(validValueMask) - minValue) ./ (maxValue - minValue);
    end

end



function containmentMatrix = boundingBoxContainmentMatrix(bboxA, bboxB)

    % Compute a coarse overlap measure between AABBs.
    %
    % containmentMatrix(i,j) is the maximum of:
    %   intersectionVolume / volume(A_i)
    %   intersectionVolume / volume(B_j)
    % This is symmetric-ish and tolerates size changes.

    nA = numel(bboxA);
    nB = numel(bboxB);

    containmentMatrix = zeros(nA, nB);

    for i = 1:nA
        for j = 1:nB

            minIntersect = max(bboxA(i).minPoint, bboxB(j).minPoint);
            maxIntersect = min(bboxA(i).maxPoint, bboxB(j).maxPoint);

            intersectionSize = max(maxIntersect - minIntersect, 0);
            intersectionVolume = prod(intersectionSize);

            bboxASize = bboxA(i).maxPoint - bboxA(i).minPoint;
            bboxAVolume = prod(bboxASize);

            bboxBSize = bboxB(j).maxPoint - bboxB(j).minPoint;
            bboxBVolume = prod(bboxBSize);

            if bboxAVolume < eps
                containment = 0;
            else
                containmentInA = intersectionVolume / bboxAVolume;
                containmentInB = intersectionVolume / bboxBVolume;
                containment = max(containmentInA, containmentInB);
            end

            containmentMatrix(i,j) = containment;

        end
    end

end



function bboxes = computeObjectBoundingBoxes(objectTable)

    % Compute per-object axis-aligned bounding boxes from mesh vertices.

    nObjects = height(objectTable);

    bboxes = struct('minPoint', cell(nObjects,1), 'maxPoint', cell(nObjects,1));

    for objectRowNum = 1:nObjects

        objectMesh = objectTable.Mesh{objectRowNum};

        if isempty(objectMesh)
            error('ObjectMatching:MissingMesh', ...
                '3D objects are not generated.');
        end

        vertices = objectMesh.Vertices;

        bboxes(objectRowNum).minPoint = min(vertices, [], 1);
        bboxes(objectRowNum).maxPoint = max(vertices, [], 1);

    end

end



function [currentIndexes, nextIndexes, removedSource, removedTarget] = removeObviousContinuationsFromComplexMatch( ...
    currentIndexes, ...
    nextIndexes, ...
    centroidDistanceMatrix, ...
    currentVolumes, ...
    nextVolumes, ...
    hasVolume, ...
    sameObjectDistanceThreshold, ...
    sameObjectVolumeTolerance)

    % Greedily remove the most obvious continuation pair (closest centroid,
    % and optionally volume-consistent) until the component is no longer
    % many-to-many.

    removedSource = [];
    removedTarget = [];

    keepSearching = true;

    while keepSearching

        keepSearching = false;

        bestCurrent = [];
        bestNext = [];

        bestDistance = inf;

        for cIdx = 1:numel(currentIndexes)
            c = currentIndexes(cIdx);
            for nIdx = 1:numel(nextIndexes)
                n = nextIndexes(nIdx);

                centroidDistance = centroidDistanceMatrix(c,n);

                if centroidDistance > sameObjectDistanceThreshold
                    continue
                end

                if hasVolume
                    denom = max([abs(currentVolumes(c)), abs(nextVolumes(n)), eps]);
                    volumeDifference = abs(currentVolumes(c) - nextVolumes(n)) / denom;

                    if volumeDifference > sameObjectVolumeTolerance
                        continue
                    end
                end

                if centroidDistance < bestDistance
                    bestDistance = centroidDistance;
                    bestCurrent = c;
                    bestNext = n;
                end

            end
        end

        if ~isempty(bestCurrent)

            removedSource(end+1,1) = bestCurrent; %#ok<AGROW>
            removedTarget(end+1,1) = bestNext; %#ok<AGROW>

            currentIndexes(currentIndexes == bestCurrent) = [];
            nextIndexes(nextIndexes == bestNext) = [];

            keepSearching = numel(currentIndexes) > 1 && numel(nextIndexes) > 1;

        end
    end

end



function mergeEvents = expandMergeSplitEventsByGroupId(tableArray, mergeEvents)

    % Expand merge/split anchors along tracked groupId continuations.
    %
    % Merge anchor:
    %   source TP stays fixed, target TP walks forward through same groupId.
    % Split anchor:
    %   target TP stays fixed, source TP walks backward through same groupId.
    %
    % Candidate occurrences that could belong to both a prior merge and a
    % later split are assigned to the closer anchor in time.

    if isempty(mergeEvents) || ~anyTableHasGroupId(tableArray)
        return
    end

    candidates = createEmptyGroupExpansionCandidate();
    candidateCounter = 1;

    for eventIndex = 1:numel(mergeEvents)

        event = mergeEvents(eventIndex);
        eventType = string(event.type);

        if eventType == "merge" && isscalar(event.targetIndexes)

            anchorTimePoint = event.timePoint2;
            anchorIndex = event.targetIndexes(1);

            [hasGroupKey, groupKey] = trackedGroupKeyForRow( ...
                tableArray{anchorTimePoint}, anchorIndex);

            if ~hasGroupKey
                continue
            end

            for timePoint = anchorTimePoint:numel(tableArray)

                occurrenceIndexes = rowIndexesForGroupKey( ...
                    tableArray{timePoint}, groupKey);

                for occurrenceIndex = occurrenceIndexes(:).'

                    candidates(candidateCounter) = createGroupExpansionCandidate( ...
                        eventIndex, ...
                        eventType, ...
                        groupKey, ...
                        timePoint, ...
                        occurrenceIndex, ...
                        timePoint - anchorTimePoint, ...
                        timePoint == anchorTimePoint && occurrenceIndex == anchorIndex);

                    candidateCounter = candidateCounter + 1;

                end
            end

        elseif eventType == "split" && isscalar(event.sourceIndexes)

            anchorTimePoint = event.timePoint1;
            anchorIndex = event.sourceIndexes(1);

            [hasGroupKey, groupKey] = trackedGroupKeyForRow( ...
                tableArray{anchorTimePoint}, anchorIndex);

            if ~hasGroupKey
                continue
            end

            for timePoint = 1:anchorTimePoint

                occurrenceIndexes = rowIndexesForGroupKey( ...
                    tableArray{timePoint}, groupKey);

                for occurrenceIndex = occurrenceIndexes(:).'

                    candidates(candidateCounter) = createGroupExpansionCandidate( ...
                        eventIndex, ...
                        eventType, ...
                        groupKey, ...
                        timePoint, ...
                        occurrenceIndex, ...
                        anchorTimePoint - timePoint, ...
                        timePoint == anchorTimePoint && occurrenceIndex == anchorIndex);

                    candidateCounter = candidateCounter + 1;

                end
            end
        end
    end

    if isempty(candidates)
        return
    end

    keepCandidate = chooseClosestGroupExpansionCandidates(candidates);
    additionalEvents = repmat(createEmptyMergeEvent(), 1, numel(candidates));
    additionalEventCounter = 0;

    for candidateIndex = 1:numel(candidates)

        if ~keepCandidate(candidateIndex) || candidates(candidateIndex).isBaseOccurrence
            continue
        end

        baseEvent = mergeEvents(candidates(candidateIndex).eventIndex);
        additionalEventCounter = additionalEventCounter + 1;
        additionalEvents(additionalEventCounter) = createExpandedGroupEvent( ...
            baseEvent, ...
            tableArray, ...
            candidates(candidateIndex));

    end

    if additionalEventCounter == 0
        return
    end

    additionalEvents = additionalEvents(1:additionalEventCounter);

    mergeEvents = [mergeEvents additionalEvents];
    mergeEvents = sortMergeEventsByTime(mergeEvents);

end



function keepCandidate = chooseClosestGroupExpansionCandidates(candidates)

    candidateKeys = strings(numel(candidates), 1);

    for candidateIndex = 1:numel(candidates)
        candidateKeys(candidateIndex) = groupOccurrenceKey(candidates(candidateIndex));
    end

    uniqueCandidateKeys = unique(candidateKeys, 'stable');
    keepCandidate = false(numel(candidates), 1);

    for keyIndex = 1:numel(uniqueCandidateKeys)

        matchingCandidateIndexes = find(candidateKeys == uniqueCandidateKeys(keyIndex));

        distances = [candidates(matchingCandidateIndexes).distanceToAnchor].';
        eventIndexes = [candidates(matchingCandidateIndexes).eventIndex].';

        % eventIndex is only a deterministic tie-breaker when two anchors
        % are exactly equally close.
        [~, bestOrder] = sortrows([distances eventIndexes], [1 2]);
        keepCandidate(matchingCandidateIndexes(bestOrder(1))) = true;

    end

end



function key = groupOccurrenceKey(candidate)

    key = candidate.groupKey + "|" + ...
        string(candidate.occurrenceTimePoint) + "|" + ...
        string(candidate.occurrenceIndex);

end



function expandedEvent = createExpandedGroupEvent(baseEvent, tableArray, candidate)

    expandedEvent = baseEvent;
    occurrenceTable = tableArray{candidate.occurrenceTimePoint};
    occurrenceObjectIds = rowNamesToNumericIds(occurrenceTable);

    if string(candidate.eventType) == "merge"

        expandedEvent.timePoint2 = candidate.occurrenceTimePoint;
        expandedEvent.targetIndexes = candidate.occurrenceIndex;
        expandedEvent.targetObjectIds = occurrenceObjectIds(candidate.occurrenceIndex);

    else

        expandedEvent.timePoint1 = candidate.occurrenceTimePoint;
        expandedEvent.sourceIndexes = candidate.occurrenceIndex;
        expandedEvent.sourceObjectIds = occurrenceObjectIds(candidate.occurrenceIndex);

    end

    expandedEvent.removedContinuationSourceIndexes = [];
    expandedEvent.removedContinuationTargetIndexes = [];

end



function sortedEvents = sortMergeEventsByTime(events)

    sortedEvents = events;

    if numel(events) < 2
        return
    end

    sortKeys = zeros(numel(events), 3);

    for eventIndex = 1:numel(events)
        sortKeys(eventIndex,:) = [ ...
            events(eventIndex).timePoint1, ...
            events(eventIndex).timePoint2, ...
            eventIndex];
    end

    [~, sortOrder] = sortrows(sortKeys, [1 2 3]);
    sortedEvents = events(sortOrder);

end



function candidate = createGroupExpansionCandidate( ...
    eventIndex, ...
    eventType, ...
    groupKey, ...
    occurrenceTimePoint, ...
    occurrenceIndex, ...
    distanceToAnchor, ...
    isBaseOccurrence)

    candidate = struct( ...
        'eventIndex', eventIndex, ...
        'eventType', eventType, ...
        'groupKey', groupKey, ...
        'occurrenceTimePoint', occurrenceTimePoint, ...
        'occurrenceIndex', occurrenceIndex, ...
        'distanceToAnchor', distanceToAnchor, ...
        'isBaseOccurrence', isBaseOccurrence);

end



function candidates = createEmptyGroupExpansionCandidate()

    candidates = struct( ...
        'eventIndex', {}, ...
        'eventType', {}, ...
        'groupKey', {}, ...
        'occurrenceTimePoint', {}, ...
        'occurrenceIndex', {}, ...
        'distanceToAnchor', {}, ...
        'isBaseOccurrence', {});

end



function tf = anyTableHasGroupId(tableArray)

    tf = false;

    for timePoint = 1:numel(tableArray)
        if hasGroupIdColumn(tableArray{timePoint})
            tf = true;
            return
        end
    end

end



function [hasGroupKey, groupKey] = trackedGroupKeyForRow(objectTable, rowIndex)

    hasGroupKey = false;
    groupKey = "";

    groupIdColumnName = findGroupIdColumnName(objectTable);

    if groupIdColumnName == "" || rowIndex < 1 || rowIndex > height(objectTable)
        return
    end

    groupId = objectTable{rowIndex, groupIdColumnName};

    if ~isTrackedGroupId(groupId)
        return
    end

    groupKey = string(groupId);
    hasGroupKey = true;

end



function rowIndexes = rowIndexesForGroupKey(objectTable, groupKey)

    rowIndexes = [];
    groupIdColumnName = findGroupIdColumnName(objectTable);

    if groupIdColumnName == ""
        return
    end

    groupIds = objectTable.(groupIdColumnName);

    if isempty(groupIds)
        return
    end

    groupIdStrings = string(groupIds);
    trackedMask = isTrackedGroupIdArray(groupIds);

    rowIndexes = find(trackedMask & groupIdStrings == groupKey);

end



function tf = hasGroupIdColumn(objectTable)

    tf = findGroupIdColumnName(objectTable) ~= "";

end



function groupIdColumnName = findGroupIdColumnName(objectTable)

    groupIdColumnName = "";
    variableNames = objectTable.Properties.VariableNames;

    matchedIndex = find(strcmpi(variableNames, 'groupId'), 1);

    if ~isempty(matchedIndex)
        groupIdColumnName = string(variableNames{matchedIndex});
    end

end



function trackedMask = isTrackedGroupIdArray(groupIds)

    trackedMask = true(size(groupIds));

    if iscategorical(groupIds)
        trackedMask = trackedMask & ~isundefined(groupIds);
    end

    groupIdStrings = string(groupIds);

    trackedMask = trackedMask & ...
        strlength(groupIdStrings) > 0 & ...
        groupIdStrings ~= "0" & ...
        groupIdStrings ~= "<undefined>";

end



function tf = isTrackedGroupId(groupId)

    if isempty(groupId)
        tf = false;
        return
    end

    tf = all(isTrackedGroupIdArray(groupId));

end



function event = createEmptyMergeEvent()

    event = struct( ...
        'type', '', ...
        'timePoint1', [], ...
        'timePoint2', [], ...
        'sourceIndexes', [], ...
        'targetIndexes', [], ...
        'sourceObjectIds', [], ...
        'targetObjectIds', [], ...
        'removedContinuationSourceIndexes', [], ...
        'removedContinuationTargetIndexes', []);

end
