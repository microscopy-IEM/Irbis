        function matchObjectsInTime(app,branch,varargin)

            % TO OPTIMIZE - make sure that the same groupId is not assigned to multiple objects

            nTPs = app.timeline.nTimePoints;

            if nargin == 3
                distanceThreshold = varargin{1};
            else
                distanceThreshold = 0.5; % in micrometers
            end

            if nargin == 4
                distanceThreshold = varargin{1};
                timePoints = varargin{2};
            else 
                timePoints = 1:nTPs;
            end

            % Single pass over consecutive time points:
            % 1) find nearest candidates, 2) keep only the closest winner per next object,
            % 3) assign groupId immediately.
            uniqueGroupId = 1;
            distanceWeight = 0.7;
            volumeWeight = 0.3;

            % Load selected time points and initialize groupId once.
            fullList = cell(1, nTPs);
            for tp = timePoints
                modelId = app.timeline.currentIndex.model.(branch)(tp);
                if ~modelId
                    uialert(app.IrbisMainFig,['Objects are not generated for time point ' num2str(tp)],'Warning','Icon','warning');
                    return
                end
                tpList = app.model.(branch).List{modelId};
                tpList.groupId(:) = 0;
                fullList{tp} = tpList;
            end

            for currentTimePoint = timePoints(1):timePoints(end-1)

                currentTPList = fullList{currentTimePoint};
                nextTPList = fullList{currentTimePoint+1};

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
                            uialert(app.IrbisMainFig,'3D objects are not generated.','Warning');
                            return
                        end
                        currentTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
                    end

                    % calculate centres of objects in next time point
                    for objectRowNum = 1:nNextObjects
                        currentObject = nextTPList(objectRowNum,:);
                        objectMesh = currentObject.Mesh{1};
                        if isempty(objectMesh)
                            uialert(app.IrbisMainFig,'3D objects are not generated.','Warning');
                            return
                        end
                        nextTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
                    end

                    distanceMatrix = pdist2(currentTPcentre, nextTPcentre);
                    validPairMask = distanceMatrix <= distanceThreshold;

                    if any(validPairMask, 'all')
                        distanceNorm = normalizeMatrixToUnitInterval(distanceMatrix, validPairMask);
                        combinedCost = inf(size(distanceMatrix));
                        combinedCost(validPairMask) = distanceNorm(validPairMask);

                        if hasCurrentVolume && hasNextVolume
                            volumeAvailableMask = isfinite(currentVolumes) & isfinite(nextVolumes.');
                            volumeDifference = abs(currentVolumes - nextVolumes.') ./ max(max(abs(currentVolumes), abs(nextVolumes.')), eps);
                            volumeMask = validPairMask & volumeAvailableMask;

                            if any(volumeMask, 'all')
                                volumeNorm = normalizeMatrixToUnitInterval(volumeDifference, volumeMask);
                                combinedCost(volumeMask) = distanceWeight * distanceNorm(volumeMask) + volumeWeight * volumeNorm(volumeMask);
                            end
                        end

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

                fullList{currentTimePoint} = currentTPList;
                fullList{currentTimePoint+1} = nextTPList;
            end

            for tp = timePoints
                app.setModelTable(fullList{tp}, tp, branch);
            end

            app.InfoGraphicText.Text = '';  

            % update groupIds in the graphics objects group for current timePoint
            % important for showing label correctly and for selecting correct objects when time point changes
            objectsGroup = app.branchGraphicsManagerHandle.getExistingGroup(branch);
            T = app.getModelTable(app.appData.currentTimePoint, branch);
            groupIds = T.groupId;
            objectsGroup.updateGroupIdArray(groupIds);
            
        end

        function [hasColumn, columnData] = getNumericColumnForMatching(objectTable, candidateNames)
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