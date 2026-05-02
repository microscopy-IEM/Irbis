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

            volumeChangeThreshold = inf;
            surfaceChangeThreshold = inf;

            if nargin >= 5
                volumeChangeThreshold = varargin{3};
            end

            if nargin >= 6
                surfaceChangeThreshold = varargin{4};
            end

            %% first part


            for currentTimePoint = timePoints(1):timePoints(end-1)
                
                currentModelId = app.timeline.currentIndex.model.(branch)(currentTimePoint);
                currentTPList = app.model.(branch).List{currentModelId};            
                currentTPList.groupId(:) = nan;
                nextModelId = app.timeline.currentIndex.model.(branch)(currentTimePoint+1);
                if ~nextModelId
                    uialert(app.IrbisMainFig,['Objects are not generated for time point ' num2str(currentTimePoint+1)],'Warning','Icon','warning')
                    return
                end
                nextTPList = app.model.(branch).List{nextModelId};

                % calculate centres of objects in current time point
                currentTPcentre = [];
                nextTPcentre = [];

                [hasCurrentBasePoints, currentBasePoints] = getBasePointsForMatching(currentTPList);
                [hasNextBasePoints, nextBasePoints] = getBasePointsForMatching(nextTPList);
                [hasCurrentVolume, currentVolumes] = getNumericColumnForMatching(currentTPList, {'volume'});
                [hasNextVolume, nextVolumes] = getNumericColumnForMatching(nextTPList, {'volume'});
                [hasCurrentSurface, currentSurfaces] = getNumericColumnForMatching(currentTPList, {'surface'});
                [hasNextSurface, nextSurfaces] = getNumericColumnForMatching(nextTPList, {'surface'});

                for objectRowNum = 1:size(currentTPList,1)
                    
                    currentObject = currentTPList(objectRowNum,:);
                    objectMesh = currentObject.Mesh{1};
                    if isempty(objectMesh)
                        uialert(app.IrbisMainFig,'3D objects are not generated.','Warning')
                        return
                    end

                    % get centre of object mesh
                    currentTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
    
                end
    
                % calculate centres of objects in next time point
                for objectRowNum = 1:size(nextTPList,1)
                    
                    currentObject = nextTPList(objectRowNum,:);
                    objectMesh = currentObject.Mesh{1};
                    if isempty(objectMesh)
                        uialert(app.IrbisMainFig,'3D objects are not generated.','Warning')
                        return
                    end
    
                    % get centre of object mesh
                    nextTPcentre(objectRowNum,:) = vertexCenter(objectMesh);
             
                end
                
                centreDistances = pdist2(currentTPcentre, nextTPcentre);
                matchingCost = centreDistances;

                maxDist = distanceThreshold;
                validPairMask = (centreDistances <= maxDist);

                if hasCurrentBasePoints && hasNextBasePoints
                    % base point is an independent metric
                    basePointDistances = pdist2(currentBasePoints, nextBasePoints);
                    validCurrentBasePoints = all(isfinite(currentBasePoints), 2);
                    validNextBasePoints = all(isfinite(nextBasePoints), 2);
                    basePointAvailableMask = validCurrentBasePoints & validNextBasePoints.';

                    validPairMask(basePointAvailableMask) = validPairMask(basePointAvailableMask) & (basePointDistances(basePointAvailableMask) <= maxDist);
                    matchingCost(basePointAvailableMask) = matchingCost(basePointAvailableMask) + basePointDistances(basePointAvailableMask);
                end

                if hasCurrentVolume && hasNextVolume
                    volumeChangeMatrix = abs(currentVolumes - nextVolumes.') ./ max(abs(currentVolumes), eps);
                    validPairMask = validPairMask & (volumeChangeMatrix <= volumeChangeThreshold);
                end

                if hasCurrentSurface && hasNextSurface
                    surfaceChangeMatrix = abs(currentSurfaces - nextSurfaces.') ./ max(abs(currentSurfaces), eps);
                    validPairMask = validPairMask & (surfaceChangeMatrix <= surfaceChangeThreshold);
                end

                % reset assignments
                currentTPList.nextTPid(:) = 0;
                currentTPList.groupId(:) = 0;

                if any(validPairMask, 'all')
                    if exist('matchpairs', 'file') ~= 2
                        uialert(app.IrbisMainFig,'Global assignment requires MATLAB function matchpairs.','Warning','Icon','warning')
                        return
                    end

                    rowNamesAll = str2double(nextTPList.Properties.RowNames);
                    % allow objects to remain unmatched instead of forcing weak assignments
                    nonAssignmentCost = maxDist;
                    invalidPairCost = nonAssignmentCost * 10;

                    assignmentCost = matchingCost;
                    assignmentCost(~validPairMask) = invalidPairCost;
                    matchedPairs = matchpairs(assignmentCost, nonAssignmentCost);

                    if ~isempty(matchedPairs)
                        currentRows = matchedPairs(:, 1);
                        nextRows = matchedPairs(:, 2);
                        currentTPList.nextTPid(currentRows) = rowNamesAll(nextRows);
                    end
                end

                % assign detected indexes into objectlist
                app.setModelTable(currentTPList, currentTimePoint, branch);

            end
        
            %% Second part - asignment of group ID to corresponding objects

            for i = timePoints
                % i
                id = app.timeline.currentIndex.model.(branch)(i);
                fullList{i} = app.model.(branch).List{id};
            end
            
            uniqueGroupId = 1;

            for tp = timePoints(1):timePoints(end-1)

                currentTPList = fullList{tp};
                nextTPList = fullList{tp+1};
    
                % cycle trough all object in current list
                for objectRowNum = 1:size(currentTPList,1)
    
                    % get object form current row
                    currentObject = currentTPList(objectRowNum,:);
        
                    % get row name of current object
                    currentRowName = currentObject.Properties.RowNames; % String
                    nextRowId = currentObject.nextTPid;   % Double
    
                    % convert row id into string
                    nextRowName = num2str(nextRowId); % String
        
                    if nextRowId>0
        
                        % if object has no unique id asisgned
                        if currentTPList(objectRowNum,:).groupId == 0
                            
                            % assign object chain id to current object and its consequentor
                            
                            % identify current object by row name and assign
                            % chain id
                            currentTPList(currentRowName,:).groupId = uniqueGroupId;
                            
                            % identify current object by next row name and assign
                            % chain id
                            % nextTPList(nextRowName,:).groupId = uniqueGroupId;
                            nextTPList{nextRowName, "groupId"} = uniqueGroupId;
        
                            % increment chain id for next object chain
                            uniqueGroupId = uniqueGroupId+1;
    
                        else % if object already has a unique id, just pass it to next object
                            
                            % inherit unique chaind id from parent object
                            % nextTPList(nextRowName,:).groupId = currentTPList(currentRowName,:).groupId;
                            nextTPList{nextRowName, "groupId"} = currentTPList{currentRowName, "groupId"};
                        end 
                        
        
                    end
    
                end
    
                fullList{tp} = currentTPList;
                fullList{tp+1} = nextTPList;

            end

            for tp = timePoints
                app.setModelTable(fullList{tp}, tp, branch);
            end
            % TO OPTIMIZE - check whether the indexes are handled correctly

            % delete(findobj(app.UIAxes,'Tag','objectIDText'))
            app.InfoGraphicText.Text = '';  

            % update groupIds in the graphics objects group for current timePoint
            % important for showing label correctly and for selecting correct objects when time point changes
            objectsGroup = app.branchGraphicsManagerHandle.getExistingGroup(branch);
            T = app.getModelTable(app.appData.currentTimePoint, branch);
            groupIds = T.groupId;
            objectsGroup.updateGroupIdArray(groupIds);
            
        end

        function [hasBasePoints, basePoints] = getBasePointsForMatching(objectTable)
            nObjects = height(objectTable);
            basePoints = nan(nObjects, 3);
            hasBasePoints = false;

            candidateNames = {'basePoint', 'basePoints', 'cuttingPlaneCentre'};
            variableNames = objectTable.Properties.VariableNames;

            for candidateIndex = 1:numel(candidateNames)
                matchedIndex = find(strcmpi(variableNames, candidateNames{candidateIndex}), 1);
                if isempty(matchedIndex)
                    continue
                end

                candidateColumn = objectTable.(variableNames{matchedIndex});

                if isnumeric(candidateColumn) && size(candidateColumn, 1) == nObjects && size(candidateColumn, 2) >= 3
                    basePoints = candidateColumn(:, 1:3);
                    hasBasePoints = true;
                    return
                end

                if iscell(candidateColumn) && numel(candidateColumn) == nObjects
                    for objectIndex = 1:nObjects
                        currentPoint = candidateColumn{objectIndex};
                        if isnumeric(currentPoint) && numel(currentPoint) >= 3
                            currentPoint = currentPoint(:).';
                            basePoints(objectIndex, :) = currentPoint(1:3);
                        end
                    end
                    hasBasePoints = true;
                    return
                end
            end
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