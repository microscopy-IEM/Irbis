function importedTracks = importTracks(figH)

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

profile on
tic

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
    testTracks = readstruct("C:\Users\iva.svecova\OneDrive - Ústav experimentální medicíny AV ČR, v. v. i\uPaint_data\Dish 1_GFP-GluN2A_done\01_ATTO-647N_video_Tracks.xml");
    
    % Initialize variables
    nTracks = numel(testTracks.particle);
    coordinates = cell(nTracks,1);
    frameIndexes = cell(nTracks,1);
    
    % Extract data from testTracks.particle
    for trackId = 1:nTracks
        particle = testTracks.particle(trackId);
        nSpots = particle.nSpotsAttribute;
        t = [particle.detection.tAttribute];
        x = [particle.detection.xAttribute];
        y = [particle.detection.yAttribute];
        z = [particle.detection.zAttribute];
        
        % Combine x, y, z coordinates into one array
        coordinates{trackId} = [x(:), y(:), z(:)];
        frameIndexes{trackId} = t(:);
    end
    
    size(coordinates)
    size((1:nTracks)')
    
    % Create the table
    varNames = {'id', 'xyz', 'frame_i', 'color', 'length'};
    varTypes = {'double', 'cell', 'cell', 'cell', 'double'};
    sz = [nTracks, numel(varNames)];
    T = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
    
    % Assign values to the table
    T.id = (1:nTracks)';
    T.xyz = coordinates;
    T.frame_i = frameIndexes;
    T.color = num2cell(rand(nTracks, 3), 2);
    T.length = cellfun(@(x) size(x, 1), coordinates);
    
    % Display the table
    disp(T);


    [imported_tracks, md] = importTrackMateTracks([path fileNameWithTimePoints{currentFile, 2}], figH);

    % Process the imported tracks
    frameInterval = md.frameInterval;
    nTracks = size(imported_tracks, 1);
    stat = cell2mat(cellfun(@max, imported_tracks, 'UniformOutput', false));
    nFrames = max(stat(:, 1));
    
    coordinates = cell(nTracks, 1);
    frameIndexes = cell(nTracks, 1);
        
    for trackID = 1:nTracks
        coordinates{trackID, 1} = imported_tracks{trackID}(:, 2:4);
        frameIndexes{trackID, 1} = imported_tracks{trackID}(:, 1);
        
        % Fill gaps with NaN
        coor = coordinates{trackID, 1};
        fi = frameIndexes{trackID, 1};
        
        new_fi = (fi(1):fi(end))';
        duration = fi(end) - fi(1);
        new_coor = nan(duration, 3);
        new_coor(fi - fi(1) + 1, :) = coor;
        
        coordinates{trackID, 1} = new_coor;
        frameIndexes{trackID, 1} = new_fi;
    end
    
    
     %% Organize trajectories into structure

        
        tracks.tracksOrigFileName = fileNameWithTimePoints{currentFile, 2};
    %     tracks.spots = TRS.spots;                                               % localizations of particles (QDs) without linking them to trajectories
        tracks.nTracks = nTracks;
        tracks.nFrames = nFrames;
        tracks.frameInterval = frameInterval;                         % frame interval in defined units (sec)
        tracks.group = '';
        tracks.description = '';
        tracks.driftCorrection = zeros(1,nFrames);
        tracks.timeRange = [0 frameInterval*nFrames];
    
        % Define table
        varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
        varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
            
        
        % get size of the table
        sz = [nTracks size(varTypes,2)];
    
        % create table
        T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

        T.id = 1:nTracks;
        T.xyz = coordinates;
        T.frame_i = frameIndexes;
        T.color = num2cell(rand(nTracks, 3), 2);
        T.length = cellfun(@(x) size(x, 1), coordinates);
     
        % for trackId = 1:nTracks
        %     T.id(trackId) = trackId;
        %     T.xyz(trackId) = coordinates(trackId); 
        %     T.frame_i(trackId) = frameIndexes(trackId);
        %     T.color(trackId) = {rand(1,3)};
        %     T.length(trackId) = size(coordinates{trackId},1);
        % end
    
        tracks.tracksList = T;
        importedTracks(tp) = tracks;
        % allTracks{currentFile} = tracks;

        % Update progress bar value
        wb.Value = currentFile / nOfFiles;
end

close(wb);

disp(['time to run importTracks old: ' num2str(toc)])
profile off

end
