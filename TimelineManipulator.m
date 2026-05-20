classdef TimelineManipulator 
    methods (Static)
        function dataStruct = runDeletionWithShift(timePointsToDelete, timeline, planes, tracks, points, model, tools)
            % deletes specified time points from the timeline and all branches, shifts all following time points and their indices accordingly
            % this should lead to deletion/dereferencing of all data for those specific time points

            % clean the input time points vector
            timePointsToDelete = TimelineManipulator.cleanTimePointsToDelete(timePointsToDelete, timeline.nTimePoints);
            if isempty(timePointsToDelete)
                ME = MException('TimelineManipulator:NoValidTimePoints', 'No valid time points to delete. Please provide a vector of positive integers within the bounds of the number of time points in the timeline.');
                throw(ME)
            end

            % delete time points from all modalities and get updated indices
            if ~isempty(planes)
                [planes, planesIndices] = TimelineManipulator.deleteTimePointsInPlanes(planes, timePointsToDelete, timeline.currentIndex.planes);
                timeline.currentIndex.planes = planesIndices;
            end

            if ~isempty(tracks)
                [tracks, tracksIndices] = TimelineManipulator.deleteTimePointsInTracks(tracks, timePointsToDelete, timeline.currentIndex.tracks);
                timeline.currentIndex.tracks = tracksIndices;
            end

            if ~isempty(points)
                [points, pointsIndices] = TimelineManipulator.deleteTimePointsInPoints(points, timePointsToDelete, timeline.currentIndex.points);
                timeline.currentIndex.points = pointsIndices;
            end

            if ~isempty(model)
                [model, modelIndices] = TimelineManipulator.deleteTimePointsInModel(model, timePointsToDelete, timeline.currentIndex.model);
                timeline.currentIndex.model = modelIndices;
            end

            if ~isempty(tools)
                [tools, toolsIndices] = TimelineManipulator.deleteTimePointsInTools(tools, timePointsToDelete, timeline.currentIndex.tools);
                timeline.currentIndex.tools = toolsIndices;
            end

            % delete time points from timeline and update currentTimePoint
            modifiedTimeline = TimelineManipulator.deleteTimePointsFromTimeline(timeline, timePointsToDelete);

            dataStruct.timeline = modifiedTimeline;
            dataStruct.planes = planes;
            dataStruct.tracks = tracks;
            dataStruct.points = points;
            dataStruct.model = model;
            dataStruct.tools = tools;
        end



        function timePointsToDelete = generateTimePointSelectionUI(timeline)
            % generates a UI dialog for selecting time points to delete from the timeline
            % 
            % inputs:
            %   timeline - the timeline structure containing information about current time points

            arguments
                timeline struct
            end

            nTimePoints = timeline.nTimePoints;
            timePoints = 1:nTimePoints;
            timePointsToDelete = [];
            
            % Adjust figure height based on number of time points
            figureHeight = max(200, 100 + nTimePoints * 20);
            d = uifigure('Name', 'Select time points to delete', 'Position', [100 100 240 figureHeight], 'WindowStyle', 'modal');
            d.CloseRequestFcn = @(~,~) onCancel();

            uilabel(d, 'Text', 'Select time points to delete:', 'Position', [20 figureHeight - 30 200 22]);

            % Create a grid layout for checkboxes
            checkboxes = gobjects(1, nTimePoints);
            for tp = 1:nTimePoints
                yPos = figureHeight - 60 - (tp - 1) * 20;
                checkboxes(tp) = uicheckbox(d, 'Text', num2str(timePoints(tp)), 'Position', [20 yPos 50 20]);
            end

            uibutton(d, 'Text', 'Delete selected time points', ...
                'Position', [20 20 170 30], ...
                'ButtonPushedFcn', @(~,~) onConfirm());

            uiwait(d);

            function onConfirm()
                selected = [];
                for i = 1:nTimePoints
                    if checkboxes(i).Value
                        selected = [selected, i];
                    end
                end
                timePointsToDelete = selected;
                if isvalid(d)
                    uiresume(d);
                    delete(d);
                end
            end

            function onCancel()
                timePointsToDelete = [];
                if isvalid(d)
                    uiresume(d);
                    delete(d);
                end
            end
        end



        function timePointsToDelete = cleanTimePointsToDelete(timePointsToDelete, nTimePoints)
            % checks that timePointsToDelete is a vector of positive integers within the bounds of nTimePoints
            timePointsToDelete = unique(timePointsToDelete);
            timePointsToDelete = timePointsToDelete(timePointsToDelete >= 1 & timePointsToDelete <= nTimePoints);
        end



        function [modifiedModel, modifiedIndices] = deleteTimePointsInModel(model, timePointsToDelete, indices, doShift)
            % deletes specified time points in the supplied model structure
            % removes time points positions and shifts if doShift is true, otherwise replaces values with 0
            % 
            % inputs: 
            %   model - the model structure from which to delete time points
            %   timePointsToDelete - vector of time points to delete
            %   indices - structure containing the current index for each branch
            % 
            % outputs:
            %   modifiedModel - the model structure with specified time points deleted
            %   modifiedIndices - the updated current index structure after deletion - replaces deleted time points with 0
            %

            arguments
                model struct
                timePointsToDelete (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                indices struct
                doShift logical = true  % if true, the following time points will be shifter
                    % if false, the values will be replaced by 0/empty values
            end

            branches = model.branches;
            for branchIdx = 1:numel(branches)
                branchName = branches{branchIdx};
                branchData = model.(branchName);
                [modifiedBranchData, modifiedBranchIndices] = TimelineManipulator.deleteTimePointsInModelBranch(branchData, timePointsToDelete, indices.(branchName), doShift);
                modifiedModel.(branchName) = modifiedBranchData;
                modifiedIndices.(branchName) = modifiedBranchIndices;

                if ~isempty(timePointsToDelete)
                    % assignin("base", "model", modifiedModel);
                    if isfield(modifiedModel, 'timeDrift')
                        if doShift
                            modifiedModel.timeDrift(timePointsToDelete) = [];
                        else
                            modifiedModel.timeDrift(timePointsToDelete) = repmat([0 0 0], numel(timePointsToDelete), 1);
                        end
                    end
                end
            end
        end



        function [modifiedBranchData, modifiedBranchIndices] = deleteTimePointsInModelBranch(branchData, timePointsToDelete, branchIndices, doShift)
            % deletes specified time points in the supplied branch data structure, leaves 0 in the current index list for deleted time points
            % 
            % inputs: 
            %   branchData - the data structure of the branch from which to delete time points
            %   timePointsToDelete - vector of time points to delete, should be already cleaned to contain unique values within range
            %   branchIndices - list containing the current index for the branch
            % 
            % outputs:
            %   modifiedBranchData - the branch data structure with specified time points deleted
            %   modifiedBranchIndices - the updated current index list after deletion - replaces deleted time points with 0

            modifiedBranchData = branchData;

            if isempty(timePointsToDelete)
                modifiedBranchIndices = branchIndices;
                return
            end

            % clear any currentIndex entries that point to deleted time points
            % since we check before that tps are in range, it should not happen that the branchIndices would be shorter
            if doShift
                branchIndices(timePointsToDelete) = [];
            else
                branchIndices(timePointsToDelete) = 0;
            end

            List = TimelineManipulator.removeUnreferencedCells(branchData.List, branchIndices);
            if doShift
                modifiedBranchData.List = TimelineManipulator.updateTimePointValues(List, branchIndices);
            else
                modifiedBranchData.List = List;
            end
            if isfield(modifiedBranchData, 'reconstructionParameters')
                modifiedBranchData.reconstructionParameters = TimelineManipulator.removeUnreferencedCells(branchData.reconstructionParameters, branchIndices);
            end
            modifiedBranchIndices = TimelineManipulator.shiftIndices(branchIndices);
        end



        function [modifiedTracks, modifiedIndices] = deleteTimePointsInTracks(tracks, timePointsToDelete, indices, doShift)
            % deletes specified time points in the supplied tracks structure
            % removes time points positions and shifts if doShift is true, otherwise replaces values with 0
            % 
            % inputs: 
            %   tracks - the tracks structure from which to delete time points
            %   timePointsToDelete - vector of time points to delete
            %   indices - list containing the current index for the tracks
            % 
            % outputs:
            %   modifiedTracks - the tracks structure with specified time points deleted
            %   modifiedIndices - the updated current index list after deletion - replaces deleted time points with 0

            arguments
                tracks struct
                timePointsToDelete (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                indices (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                doShift logical = true  % if true, the following time points will be shifter
                    % if false, the values will be replaced by 0/empty values
            end

            modifiedTracks = tracks;

            if isempty(timePointsToDelete)
                modifiedIndices = indices;
                return
            end

            % clear any currentIndex entries that point to deleted time points
            if doShift
                indices(timePointsToDelete) = [];
            else
                indices(timePointsToDelete) = 0;
            end

            if doShift
                tracks.tracksOrigFileName(timePointsToDelete) = [];
                tracks.nTracks(timePointsToDelete) = [];
                tracks.nFrames(timePointsToDelete) = [];
                tracks.frameInterval(timePointsToDelete) = [];
                tracks.group(timePointsToDelete) = [];
                tracks.description(timePointsToDelete) = [];
                tracks.driftCorrection(timePointsToDelete) = [];
                tracks.timeRange(timePointsToDelete) = [];
            end

            List = TimelineManipulator.removeUnreferencedCells(tracks.tracksList, indices);
            if doShift
                modifiedTracks.tracksList = TimelineManipulator.updateTimePointValues(List, indices);
            else
                modifiedTracks.tracksList = List;
            end
            modifiedIndices = TimelineManipulator.shiftIndices(indices);
        end



        function [modifiedPoints, modifiedIndices] = deleteTimePointsInPoints(points, timePointsToDelete, indices, doShift)
            % deletes specified time points in the supplied points structure
            % removes time points positions and shifts if doShift is true, otherwise replaces values with 0
            % 
            % inputs: 
            %   points - the points structure from which to delete time points
            %   timePointsToDelete - vector of time points to delete
            %   indices - list containing the current index for the points
            % 
            % outputs:
            %   modifiedPoints - the points structure with specified time points deleted
            %   modifiedIndices - the updated current index list after deletion - replaces deleted time points with 0

            arguments
                points struct
                timePointsToDelete (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                indices (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                doShift logical = true  % if true, the following time points will be shifter
                    % if false, the values will be replaced by 0/empty values
            end

            modifiedPoints = points;

            if isempty(timePointsToDelete)
                modifiedIndices = indices;
                return
            end

            % clear any currentIndex entries that point to deleted time points
            if doShift
                indices(timePointsToDelete) = [];
            else
                indices(timePointsToDelete) = 0;
            end

            List = TimelineManipulator.removeUnreferencedCells(points.pointsList, indices);
            if doShift
                modifiedPoints.pointsList = TimelineManipulator.updateTimePointValues(List, indices);
            else
                modifiedPoints.pointsList = List;
            end
            modifiedIndices = TimelineManipulator.shiftIndices(indices);
        end



        function [modifiedPlanes, modifiedIndices] = deleteTimePointsInPlanes(planes, timePointsToDelete, indices, doShift)
            % deletes specified time points in the supplied planes structure, leaves 0 in the current index list for deleted time points
            % 
            % inputs: 
            %   planes - the planes structure from which to delete time points
            %   timePointsToDelete - vector of time points to delete
            %   indices - list containing the current index for the planes
            % 
            % outputs:
            %   modifiedPlanes - the planes structure with specified time points deleted
            %   modifiedIndices - the updated current index list after deletion - replaces deleted time points with 0

            arguments
                planes struct
                timePointsToDelete (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                indices (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                doShift logical = true  % if true, the following time points will be shifter
                    % if false, the values will be replaced by 0/empty values
            end

            modifiedPlanes = planes;

            if isempty(timePointsToDelete)
                modifiedIndices = indices;
                return
            end

            % clear any currentIndex entries that point to deleted time points
            if doShift
                indices(timePointsToDelete) = [];
            else
                indices(timePointsToDelete) = 0;
            end

            if doShift
                modifiedPlanes.zstack(:, :, :, timePointsToDelete, :) = [];
                modifiedPlanes.timeDrift(:, timePointsToDelete) = [];
                modifiedPlanes.nTimePoints = modifiedPlanes.nTimePoints - numel(timePointsToDelete);
            else
                nanMatrix = NaN(size(modifiedPlanes.zstack, 1), size(modifiedPlanes.zstack, 2), size(modifiedPlanes.zstack, 3), numel(timePointsToDelete), size(modifiedPlanes.zstack, 5));
                modifiedPlanes.zstack(:, :, :, timePointsToDelete, :) = nanMatrix;
                modifiedPlanes.timeDrift(:, timePointsToDelete) = repmat([NaN NaN NaN], numel(timePointsToDelete), 1);
            end
            modifiedIndices = TimelineManipulator.shiftIndices(indices);
        end



        function [modifiedTools, modifiedIndices] = deleteTimePointsInTools(tools, timePointsToDelete, indices, doShift)
            % deletes specified time points in the supplied tools structure
            % removes time points positions and shifts if doShift is true, otherwise replaces values with 0
            % 
            % inputs: 
            %   tools - the tools structure from which to delete time points
            %   timePointsToDelete - vector of time points to delete
            %   indices - struct containing the current index for the tools
            % 
            % outputs:
            %   modifiedTools - the tools structure with specified time points deleted
            %   modifiedIndices - the updated current index struct after deletion

            arguments
                tools struct
                timePointsToDelete (1,:) {mustBeNumeric, mustBePositive, mustBeInteger}
                indices struct
                doShift logical = true  % if true, the following time points will be shifter
                    % if false, the values will be replaced by 0/empty values
            end

            modifiedTools = tools;
            toolNames = fieldnames(tools);
            for toolIdx = 1:numel(toolNames)
                toolName = toolNames{toolIdx};
                toolData = tools.(toolName);
                toolIndices = indices.(toolName);
                % clear any currentIndex entries that point to deleted time points
                % since we check before that tps are in range, it should not happen that the branchIndices would be shorter
                if doShift
                    toolIndices(timePointsToDelete) = [];
                else
                    toolIndices(timePointsToDelete) = 0;
                end

                toolData.List = TimelineManipulator.removeUnreferencedCells(toolData.List, toolIndices);

                modifiedToolIndices = TimelineManipulator.shiftIndices(toolIndices);
                modifiedTools.(toolName) = toolData;
                modifiedIndices.(toolName) = modifiedToolIndices;
            end
        end


        
        function modifiedTimeline = deleteTimePointsFromTimeline(timeline, timePointsToDelete)
            % deletes specified time points from the supplied timeline, updates all following time points and their indices accordingly
            % this should lead to deletion/dereferencing of all data for those specific time points
            % to delete the data instead of just dereferencing, the corresponding deleteTimePointsIn... functions should be used first
            % 
            % inputs:
            %   timeline - the timeline structure
            %   timePointsToDelete - vector of time points to delete
            %
            % outputs:
            %   modifiedTimeline - the timeline structure with specified time points deleted and all following time points updated accordingly

            modifiedTimeline = timeline;
            modifiedTimeline.nTimePoints = timeline.nTimePoints - numel(timePointsToDelete);
            modifiedTimeline.currentTimePoint = modifiedTimeline.currentTimePoint - sum(timePointsToDelete < modifiedTimeline.currentTimePoint);
        end
    end




    methods (Static, Access = private)
        function branchIndices = shiftIndices(branchIndices)
            % adjust index values in branchIndices, so that they cover values from 1 up to the number of unique non-zero values in the original branchIndices
            % has to maintain the relative order of indices
            if isempty(branchIndices)
                return
            end

            % find unique non-zero indices and sort them
            uniqueIndices = unique(branchIndices);
            branchIndicesSorted = sort(uniqueIndices(uniqueIndices > 0));
            for i = 1:numel(branchIndices)
                if branchIndices(i) == 0
                    continue
                else
                    oldIndex = branchIndices(i);
                    newIndex = find(branchIndicesSorted == oldIndex);
                    branchIndices(i) = newIndex;
                end
            end
        end



        function cellArray = removeUnreferencedCells(cellArray, indices)
            % remove any cells in branchData that are not referenced in branchIndices
            cellIndices = 1:numel(cellArray);
            referencedCells = unique(indices(indices > 0));
            cellIndicesToDelete = cellIndices(~ismember(cellIndices, referencedCells));

            % remove any unreferenced cells and update indices accordingly
            if ~isempty(cellIndicesToDelete)
                cellArray(cellIndicesToDelete) = [];
            end
        end



        function tableArray = updateTimePointValues(tableArray, updatedIndices)
            % updates the timePoint values in individual tables to match the currentIndex values
            for i = 1:numel(tableArray)
                if ~isempty(tableArray{i})
                    tp = find(updatedIndices == i);
                    if ~isempty(tp)
                        tableArray{i}.timePoint(:) = categorical(string(tp));
                    else
                        tableArray{i}.timePoint(:) = categorical("0");
                    end
                end
            end
        end
    end
end