function tableArray = assignGroupIdsGreedily(tableArray, distanceThreshold)
    %DOC_PAGE greedyObjectTracking; Title: Greedy object connection in time; 
    % Description: This page describes the greedy matching procedure used to assign group IDs to model objects across consecutive time points.
    %
    %DOC_SECTION overview; Title: Purpose
    % Description: `assignGroupIdsGreedily` connects reconstructed objects in time by assigning the same group ID to objects that are likely to represent the same structure in consecutive time points.
    % The function works on a cell array of object tables, where each table represents one time point.
    % It updates the `groupId` column so downstream tools can follow objects through time.
    %
    %DOC_SECTION matching; Title: Matching strategy
    % Description: The algorithm compares each pair of consecutive time points.
    % For every object, it calculates the centre of the object's mesh and measures distances to objects in the next time point.
    % Candidate matches are limited by the distance threshold selected in the user interface.
    % If object volume is available, the matching cost combines centre distance and relative volume difference.
    %
    %DOC_SECTION conflicts; Title: Conflict handling
    % Description: Each object in the current time point chooses its best candidate in the next time point.
    % If several current objects prefer the same next object, only the pair with the lowest cost is accepted.
    % Accepted pairs receive the same group ID.
    % Objects without a valid accepted match remain untracked.
    %
    %DOC_SECTION limitations; Title: Practical limitations
    % Description: This is a greedy local matching method, not a global optimization over the whole time series.
    % It works best when objects move gradually between consecutive time points and when the distance threshold is large enough to cover expected motion but small enough to reject unrelated nearby objects.
    % Large movements, object merges, object splits, missing objects, or very crowded reconstructions may require manual correction.
    %

    uniqueGroupId = 1;
    distanceWeight = 0.7;
    volumeWeight = 0.3;

    for i = 1:(numel(tableArray)-1)

        currentTPList = tableArray{i};
        nextTPList = tableArray{i+1};

        nCurrentObjects = height(currentTPList);
        nNextObjects = height(nextTPList);
        winnerMask = false(nCurrentObjects, 1);
        winnerNextRowIds = zeros(nCurrentObjects, 1);

        if nCurrentObjects > 0 && nNextObjects > 0
            currentTPcentre = zeros(nCurrentObjects, 3);
            nextTPcentre = zeros(nNextObjects, 3);
            [hasCurrentVolume, currentVolumes] = getNumericColumnForMatching(currentTPList, {'volume'});
            [hasNextVolume, nextVolumes] = getNumericColumnForMatching(nextTPList, {'volume'});

            % calculate centres of objects in current time point
            for objectRowNum = 1:nCurrentObjects
                currentObject = currentTPList(objectRowNum,:);
                objectMesh = currentObject.Mesh{1};
                if isempty(objectMesh)
                    ME = MException('ObjectMatching:MissingMesh', '3D objects are not generated.');
                    throw(ME)
                end
                currentTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
            end

            % calculate centres of objects in next time point
            for objectRowNum = 1:nNextObjects
                currentObject = nextTPList(objectRowNum,:);
                objectMesh = currentObject.Mesh{1};
                if isempty(objectMesh)
                    ME = MException('ObjectMatching:MissingMesh', '3D objects are not generated.');
                    throw(ME)
                end
                nextTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
            end

            % compute distance matrix and apply threshold
            distanceMatrix = pdist2(currentTPcentre, nextTPcentre);
            validPairMask = distanceMatrix <= distanceThreshold;

            % if there are any valid pairs, compute combined cost and greedily assign winners
            % both distance and volume difference (if available) are normalized to [0,1] before combining
            if any(validPairMask, 'all')
                distanceNorm = normalizeMatrixToUnitInterval(distanceMatrix, validPairMask);
                combinedCost = inf(size(distanceMatrix));
                combinedCost(validPairMask) = distanceNorm(validPairMask);

                % if volume data is available, incorporate it into the cost
                if hasCurrentVolume && hasNextVolume
                    volumeAvailableMask = isfinite(currentVolumes) & isfinite(nextVolumes.');
                    volumeDifference = abs(currentVolumes - nextVolumes.') ./ max(max(abs(currentVolumes), abs(nextVolumes.')), eps);
                    volumeMask = validPairMask & volumeAvailableMask;

                    if any(volumeMask, 'all')
                        volumeNorm = normalizeMatrixToUnitInterval(volumeDifference, volumeMask);
                        combinedCost(volumeMask) = distanceWeight * distanceNorm(volumeMask) + volumeWeight * volumeNorm(volumeMask);
                    end
                end

                % for each object in the current time point, find the best candidate in the next time point
                currentPreferredNextIndex = zeros(nCurrentObjects, 1);
                currentPreferredScore = inf(nCurrentObjects, 1);

                for objectRowNum = 1:nCurrentObjects
                    candidateIndexes = find(validPairMask(objectRowNum, :));
                    if isempty(candidateIndexes)
                        continue
                    end

                    [bestCost, localBestIndex] = min(combinedCost(objectRowNum, candidateIndexes));
                    currentPreferredNextIndex(objectRowNum) = candidateIndexes(localBestIndex);
                    currentPreferredScore(objectRowNum) = bestCost;
                end

                % some next objects may be the preferred candidate for multiple current objects; find the best among those and assign as winner
                uniqueNextIndexes = unique(currentPreferredNextIndex(currentPreferredNextIndex > 0));
                nextRowIdsAll = str2double(nextTPList.Properties.RowNames);

                for nextIndexNum = 1:numel(uniqueNextIndexes)
                    contenderCurrentIndexes = find(currentPreferredNextIndex == uniqueNextIndexes(nextIndexNum));
                    [~, bestContenderLocalIndex] = min(currentPreferredScore(contenderCurrentIndexes));
                    winnerCurrentIndex = contenderCurrentIndexes(bestContenderLocalIndex);
                    winnerMask(winnerCurrentIndex) = true;
                    winnerNextRowIds(winnerCurrentIndex) = nextRowIdsAll(uniqueNextIndexes(nextIndexNum));
                end
            end
        end

        % assign groupIds to winners (objects that are matched across time points get the same groupId)
        winnerCurrentIndexes = find(winnerMask);
        for winnerNum = 1:numel(winnerCurrentIndexes)
            objectRowNum = winnerCurrentIndexes(winnerNum);
            currentRowName = currentTPList.Properties.RowNames{objectRowNum};
            nextRowName = num2str(winnerNextRowIds(objectRowNum));

            currentGroupId = currentTPList{currentRowName, 'groupId'};
            if ~GroupIdHandler.isTracked(currentGroupId)
                currentGroupId = uniqueGroupId;
                currentTPList{currentRowName, 'groupId'} = GroupIdHandler.correctType(currentGroupId);
                uniqueGroupId = uniqueGroupId + 1;
            end

            % correct type is added here in case we decide to change the class of groupId 
            nextTPList{nextRowName, 'groupId'} = GroupIdHandler.correctType(currentGroupId);
        end

        tableArray{i} = currentTPList;
        tableArray{i+1} = nextTPList;
    end
end



function [hasColumn, columnData] = getNumericColumnForMatching(objectTable, candidateNames)
    % Look for a numeric column matching one of the candidate names (e.g. 'volume') and return its data as a vector.
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
    % Normalize values in inputMatrix to the [0,1] range based on the min and max of the valid values (as indicated by validMask).
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
