function [tracks,currentIndex,nTimePoints] = importTracksNew(figH,existingTracks,nTimePoints,currentIndex)

    [fileName,path] = uigetfile('*.xml','MultiSelect','on');
    
    if ~iscell(fileName)
        fileName = {fileName};
    end
    
    if ~fileName{1}
        tracks = [];
        return
    end

    % Reorder the filenames and get time points using the GUI
    fileNameWithTimePoints = reorderFileNames(fileName);


    if isempty(existingTracks)
        timePointsToGenerate = max(nTimePoints,max(cell2mat(fileNameWithTimePoints(:, 1))));
        currentIndex = zeros(1,timePointsToGenerate);
        baseStruct = getBaseStruct('tracks',{'timeDependent','timeIndependent'},timePointsToGenerate);
        tracks = baseStruct.tracks;
        assignin('base',"tracks",tracks)
    else
        tracks = existingTracks;
    end

    % profile on    
    % tic
    
    nOfFiles = numel(fileNameWithTimePoints(:, 1));
    % importedTracks = dictionary();

    
    nextEmptyIndex = max(currentIndex) + 1;

    for currentFile = 1:nOfFiles
    
        tp = fileNameWithTimePoints{currentFile, 1};
    
        if isnan(tp)
            continue;
        end
    
        % Update progress bar
        wb = uiprogressdlg(figH, 'Title', 'Importing TrackMate tracks', ...
            'Message', sprintf('Importing file %d of %d', currentFile, nOfFiles), ...
            'Cancelable', 'off');
        wb.Value = (currentFile - 1) / nOfFiles;
    
        % import TrackMate XML
        % IS 240722: readstruct implemented instead of xmlread 
            % it allows looping just over each trajectory instead of each frame index in each trajectory
            % -> results in cca 10x speed optimization
            
        currentXML = [path fileNameWithTimePoints{currentFile, 2}];
        try
            currentTrackStruct = readstruct(currentXML);
        catch
            uialert(figH,sprintf('Failed to read XML file %s.',currentXML),'XML file loading error.')
            return
        end
    
        % Initialize variables
        nTracks = numel(currentTrackStruct.particle);
        coordinates = cell(nTracks,1);
        frameIndexes = cell(nTracks,1);
        maxFrameIndex = 0;
    
        % Extract data from testTracks.particle
        for trackId = 1:nTracks
            particle = currentTrackStruct.particle(trackId);
            t = [particle.detection.tAttribute];
            x = [particle.detection.xAttribute];
            y = [particle.detection.yAttribute];
            z = [particle.detection.zAttribute];
    
            % Combine x, y, z coordinates into one array
            rawCoordinates = [x(:), y(:), z(:)];
            rawFrameIndexes = t(:);
        
            % Create a continuous array of frame indexes and initialize coordinates with NaN
            continuousFrameIndexes = (rawFrameIndexes(1):rawFrameIndexes(end))';
            numFrames = numel(continuousFrameIndexes);
            filledCoordinates = nan(numFrames, 3);
            filledCoordinates(rawFrameIndexes - rawFrameIndexes(1) + 1, :) = rawCoordinates;
            
            % Store the filled coordinates and continuous frame indexes
            coordinates{trackId} = filledCoordinates;
            frameIndexes{trackId} = continuousFrameIndexes;
    
            % find the maximum frame index by comparing the last frame index and teh last frame indexes from previous tracks
            maxFrameIndex = max(maxFrameIndex,rawFrameIndexes(end));
        end
    
        frameInterval = currentTrackStruct.frameIntervalAttribute;
    
        %% Organize trajectories into structure 
        cellArrayIndex = currentIndex(tp);
        if isequal(cellArrayIndex,0)

            indexToWriteTo = nextEmptyIndex;

        else
            % ask for replacement
            figure(figH)
            response = uiconfirm(figH,['Time point ' num2str(tp) ' is already populated. Do you want to replace the current tracks?'], ...
                    ['Replace tracks in time point ' num2str(tp)],'Icon','question', ...
                    'Options',{'Yes','No'}, ...
                    'DefaultOption','Yes');
            if strcmp(response,'Yes')
                indexToWriteTo = cellArrayIndex;
                disp(['time point ' num2str(tp) ' replace'])
            else
                disp(['time point ' num2str(tp) ' skipped'])
                continue
            end

        end
            
            currentIndex(tp) = indexToWriteTo;

            % add it to the i-th position
    
            tracks.tracksOrigFileName{indexToWriteTo} = fileNameWithTimePoints{currentFile, 2};
            tracks.nTracks{indexToWriteTo} = nTracks;
            tracks.nFrames{indexToWriteTo} = maxFrameIndex;
            tracks.frameInterval{indexToWriteTo} = frameInterval;                         % frame interval in defined units (sec)
            tracks.group{indexToWriteTo} = '';
            tracks.description{indexToWriteTo} = '';
            tracks.driftCorrection{indexToWriteTo} = zeros(1,maxFrameIndex);
            tracks.timeRange{indexToWriteTo} = [0 frameInterval*maxFrameIndex];
        
            T = tracks.tracksList{indexToWriteTo};
            if ~istable(T)
                T = tracks.tracksList{1};
            end

            % 
            % % Define table
            % varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
            % varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
            % sz = [nTracks numel(varNames)];
            % T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
        
            % Retrieve variable types and names from the existing table
            existingVarNames = T.Properties.VariableNames;
            existingVarTypes = varfun(@class, T, 'OutputFormat', 'cell');
            
            % Number of empty rows to add
            numRowsToAdd = nTracks;
            
            % Create an empty table with the same variable types and names
            newRows = table('Size', [numRowsToAdd, numel(existingVarNames)], 'VariableTypes', existingVarTypes, 'VariableNames', existingVarNames);
            
            % Concatenate the existing table with the new empty rows
            T = newRows;
        
            % Assign values to the table
            T.id = (1:nTracks)';
            T.xyz = coordinates;
            T.frame_i = frameIndexes;
            T.color = num2cell(rand(nTracks, 3), 2);
            T.length = cellfun(@(x) size(x, 1), coordinates);
            T.timePoint = categorical(tp);
        
            tracks.tracksList{indexToWriteTo} = T;

            if isequal(cellArrayIndex,0)
                nextEmptyIndex = nextEmptyIndex + 1;
            end

        % Update progress bar value
        wb.Value = currentFile / nOfFiles;

    end

    nTimePoints = numel(currentIndex);

    close(wb);
    
    % disp(['time to run importTracks new: ' num2str(toc)])
    % profile off

end
