function importedTracks = importTracksNew(figH)

[fileName,path] = uigetfile('*.xml','MultiSelect','on');

if ~iscell(fileName)
    fileName = {fileName};
end

if ~fileName{1}
    importedTracks = [];
    return
end

% Reorder the filenames and get time points using the GUI
fileNameWithTimePoints = reorderFileNames(fileName);

% profile on
% tic

nOfFiles = numel(fileNameWithTimePoints(:, 1));
importedTracks = dictionary();

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

    tracks.tracksOrigFileName = fileNameWithTimePoints{currentFile, 2};
    tracks.nTracks = nTracks;
    tracks.nFrames = maxFrameIndex;
    tracks.frameInterval = frameInterval;                         % frame interval in defined units (sec)
    tracks.group = '';
    tracks.description = '';
    tracks.driftCorrection = zeros(1,maxFrameIndex);
    tracks.timeRange = [0 frameInterval*maxFrameIndex];

    % Define table
    varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
    varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
    sz = [nTracks numel(varNames)];
    T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

    % Assign values to the table
    T.id = (1:nTracks)';
    T.xyz = coordinates;
    T.frame_i = frameIndexes;
    T.color = num2cell(rand(nTracks, 3), 2);
    T.length = cellfun(@(x) size(x, 1), coordinates);

    tracks.tracksList = T;
    importedTracks(tp) = tracks;

    % add other components - previously in sortData
    tracks.storedFilters = FilteringStorage();

    % Update progress bar value
    wb.Value = currentFile / nOfFiles;
end

close(wb);

% disp(['time to run importTracks new: ' num2str(toc)])
% profile off

end
