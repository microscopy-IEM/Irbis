function tableArray = assignGroupIdsGreedily(tableArray, distanceThreshold)
    % This function performs a greedy matching of objects across consecutive time points based on spatial proximity and volume similarity.
    % 
    % Inputs:
    %   tableArray: a cell array of tables, each containing object data for a specific time point. Each table must have a 'Mesh' column with 3D meshes of the objects, and may optionally have a 'volume' column.
    %   distanceThreshold: a scalar value specifying the maximum allowed distance between object centers for them to be considered a valid match.
    % 
    % Output:
    %   tableArray: the input cell array of tables, but with an calculated 'groupId' column in each table. Objects that are matched across time points will have the same groupId.
    % 
    % The matching is done in the following way: 
    %   1) For each pair of consecutive time points, compute the distance between the centers of all objects in the current time point and all objects in the next time point.
    %   2) Apply the distance threshold to find valid candidate matches.
    %   3) If volume data is available, compute a combined cost that incorporates both distance and volume difference (normalized to [0,1]) for the valid candidates.
    %   4) For each object in the current time point, identify the best candidate match
    %   5) Since multiple objects in the current time point may prefer the same next object as their best match, assign the next object to the current object with the best (lowest) combined cost, and mark that pair as a winner.
    %   6) Assign groupIds to the winning pairs, ensuring that matched objects across time points receive the same groupId.
    % 
    % The other objects that do not have valid matches will retain a groupId of 0.

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
            if currentGroupId == 0
                currentGroupId = uniqueGroupId;
                currentTPList{currentRowName, 'groupId'} = currentGroupId;
                uniqueGroupId = uniqueGroupId + 1;
            end

            nextTPList{nextRowName, 'groupId'} = currentGroupId;
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