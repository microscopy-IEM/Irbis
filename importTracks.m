function tracks = importTracks(figH)

[fileName,path] = uigetfile('*.xml','MultiSelect','on');

if ~iscell(fileName)
    
    fileName = {fileName};

end

if ~fileName{1}
     
         tracks = [];
         return
end

nOfFiles = size(fileName,2)

for currentFile = 1:nOfFiles
 % import TrackMate XML
 
 % figH = uifigure;
 cf = currentFile

    [imported_tracks, md] = importTrackMateTracks([path fileName{currentFile}],figH);


     % read frame interval
    frameInterval = md.frameInterval;
    
    % get number of tracks
    nTracks = size(imported_tracks,1);
    
    % get number of frames
    stat = cell2mat(cellfun(@max, imported_tracks, 'UniformOutput', false));
    nFrames = max(stat(:,1));
    
    % create arrays for trajectory coordinates 
    coordinates = cell(nTracks,1);
    frameIndexes = cell(nTracks,1);
        
    % convert to Irbis tracks format
    for trackID = 1:nTracks
    
        coordinates{trackID,1} = imported_tracks{trackID}(:,2:4);
        frameIndexes{trackID,1} = imported_tracks{trackID}(:,1);
    
        % fill gaps with nan
        coor = coordinates{trackID,1};
        fi = frameIndexes{trackID,1};
        
        new_fi = (fi(1):fi(end))';
        duration = fi(end)-fi(1);
        new_coor = nan(duration,3);
        new_coor(fi-fi(1)+1,:) = coor;
    
        coordinates{trackID,1} = new_coor;
        frameIndexes{trackID,1} = new_fi;
                       
    
    end
    
    
     %% Organize trajectories into structuret file

        
        tracks.tracksOrigFileName = fileName;
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
     
        for trackId = 1:nTracks
    
            T.id(trackId) = trackId;
            T.xyz(trackId) = coordinates(trackId); 
            T.frame_i(trackId) = frameIndexes(trackId);
            T.color(trackId) = {rand(1,3)};
            T.length(trackId) = size(coordinates{trackId},1);

    
        end
    
        tracks.tracksList = T;
        allTracks{currentFile} = tracks;


end

% if nOfFiles > 1
    tracks = allTracks;
% end





    %  % select files
    %  [fileName,path] = uigetfile('*.xml','MultiSelect','off');
    % 
    %  if ~fileName
    % 
    %      tracks = [];
    %      return
    %  end
    % 
    % % import TrackMate XML
    % [imported_tracks, md] = importTrackMateTracks([path fileName],figH);
    % 
    % % read frame interval
    % frameInterval = md.frameInterval;
    % 
    % % get number of tracks
    % nTracks = size(imported_tracks,1);
    % 
    % % get number of frames
    % stat = cell2mat(cellfun(@max, imported_tracks, 'UniformOutput', false));
    % nFrames = max(stat(:,1));
    % 
    % % create arrays for trajectory coordinates 
    % coordinates = cell(nTracks,1);
    % frameIndexes = cell(nTracks,1);
    % 
    % % convert to Irbis tracks format
    % for trackID = 1:nTracks
    % 
    %     coordinates{trackID,1} = imported_tracks{trackID}(:,2:4);
    %     frameIndexes{trackID,1} = imported_tracks{trackID}(:,1);
    % 
    %     % fill gaps with nan
    %     coor = coordinates{trackID,1};
    %     fi = frameIndexes{trackID,1};
    % 
    %     new_fi = (fi(1):fi(end))';
    %     duration = fi(end)-fi(1);
    %     new_coor = nan(duration,3);
    %     new_coor(fi-fi(1)+1,:) = coor;
    % 
    %     coordinates{trackID,1} = new_coor;
    %     frameIndexes{trackID,1} = new_fi;
    % 
    % 
    % end
    % 
    % 
    %  %% Organize trajectories into structuret file
    % 
    % 
    %     tracks.tracksOrigFileName = fileName;
    % %     tracks.spots = TRS.spots;                                               % localizations of particles (QDs) without linking them to trajectories
    %     tracks.nTracks = nTracks;
    %     tracks.nFrames = nFrames;
    %     tracks.frameInterval = frameInterval;                         % frame interval in defined units (sec)
    %     tracks.group = '';
    %     tracks.description = '';
    %     tracks.driftCorrection = zeros(1,nFrames);
    %     tracks.timeRange = [0 frameInterval*nFrames];
    % 
    %     % Define table
    %     varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
    %     varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
    % 
    % 
    %     % get size of the table
    %     sz = [nTracks size(varTypes,2)];
    % 
    %     % create table
    %     T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    % 
    %     for trackId = 1:nTracks
    % 
    %         T.id(trackId) = trackId;
    %         T.xyz(trackId) = coordinates(trackId); 
    %         T.frame_i(trackId) = frameIndexes(trackId);
    %         T.color(trackId) = {rand(1,3)};
    %         T.length(trackId) = size(coordinates{trackId},1);
    % 
    % 
    %     end
    % 
    %     tracks.tracksList = T;

end

%% Function importing TrackMate trajectories

function [tracks, metadata] = importTrackMateTracks(file, figH)
%%IMPORTTRACKMATETRACKS Import linear tracks from TrackMate
%
% This function reads a XML file that contains linear tracks generated by
% TrackMate (http://fiji.sc/TrackMate). Careful: it does not open the XML
% TrackMate session file, but the track file exported in TrackMate using
% the action 'Export tracks to XML file'. This file format contains less
% information than the whole session file, but is enough for linear tracks
% (tracks that do not branch nor fuse).
%
% SYNTAX
%
% tracks = IMPORTTRACKMATETRACKS(file) opens the track file 'file' and
% returns the tracks in the variable 'tracks'. 'tracks' is a cell array,
% one cell per track. Each cell is made of 4xN double array, where N is the
% number of spots in the track. The double array is organized as follow: 
% [ Ti, Xi, Yi, Zi ; ...] where T is the index of the frame the spot has been
% detected in. T is always an integer. X, Y, Z are the spot spatial 
% coordinates in physical units.
%
% [tracks, metadata] = IMPORTTRACKMATETRACKS(file) also returns 'metadata',
% a struct that contains the metadata that could be retrieved from the XML
% file. It is made of the following fields:
%   - 'spaceUnits': a string containing the name of the physical spatial unit.
%   - 'timeUnits': a string containing the name of the physical temporal unit.
%   - 'frameInterval': a double whose value is the frame interval.
%   - 'date': a string representation of the date the XML file has been generated.
%   - 'source': a string representation of the TrackMate version this file
%     has been generated with.
%
% OUTPUT
%
% The function offers two flags to change how the output is returned. As
% stated above, by default, it is returned as [ Ti, Xi, Yi, Zi ; ...] where
% T is the frame as an integer.
%
%  tracks = IMPORTTRACKMATETRACKS(file, clipZ) allows specifying whether to
%  remove the Z coordinate entirely or not. TrackMate always return 3D
%  coordinates, even for 2D motion. In the latter case, the Z coordinate is
%  always 0. If 'clipZ' is set to true AND if all the particles have their
%  Z coordinate to 0, then 'tracks' will be made of [ Ti, Xi, Yi ] arrays.
%
%  tracks = IMPORTTRACKMATETRACKS(file, clipZ, scaleT) allows specifying
%  whether to scale the T coordinate by physical units. If scaleT is set to
%  true AND if the frame interval metadata value could be retrieved, then
%  the time will be returned in physical units, not in integer frame
%  number.
%
%
% FILE FORMAT
% 
% The XML file is expected to be formatted as follow:
% 
% <?xml version="1.0" encoding="UTF-8"?>
% <Tracks nTracks="39" spaceUnits="pixel" frameInterval="5.0" timeUnits="s" generationDateTime="Thu, 8 Aug 2013 13:33:23" from="TrackMate v2.1.0">
%   <particle nSpots="125">
%       <detection t="0" x="69.3" y="151.0" z="0.0" />
%       <detection t="1" x="70.0" y="153.0" z="0.0" />
%           ... etc...
%   </particle>
%   <particle nSpots="99">
%       ...
%   </particle>
%   ...
% </Tracks>
%
%
% Jean-Yves Tinevez <jeanyves.tinevez@gmail.com> - 2013

  

    %% Load and Test compliance

    try
        doc = xmlread(file);
    catch %#ok<CTCH>
        error('Failed to read XML file %s.',file);
    end
    
    root = doc.getDocumentElement;
    
    if ~strcmp(root.getTagName, 'Tracks')
        error('MATLAB:importTrackMateTracks:BadXMLFile', ...
            'File does not seem to be a proper track file.')
    end
    
    %% Get metadata
    metadata.spaceUnits     = char( root.getAttribute('spaceUnits') );
    metadata.timeUnits      = char( root.getAttribute('timeUnits') );
    metadata.frameInterval  = str2double( root.getAttribute('frameInterval') );
    metadata.date           = char( root.getAttribute('generationDateTime') );
    metadata.source         = char( root.getAttribute('from') );
    
    
    %% Parse 
    
    nTracks = str2double( root.getAttribute('nTracks') );
    tracks = cell(nTracks, 1);
    trackNodes = root.getElementsByTagName('particle');

    % Update progress bar
    wb = uiprogressdlg(figH,'Title','Importing TrackMate tracks','Message','Sorting data...','Cancelable','off');
    wb.Value = 0/nTracks;
    wb.Message = sprintf(['Importing track ' num2str(1) '/' num2str(nTracks)]);    
    
    for i = 1 : nTracks

        wb.Value = i/nTracks;
        wb.Message = sprintf(['Importing track ' num2str(i) '/' num2str(nTracks)]); 
        % drawnow
       
        trackNode = trackNodes.item(i-1);
        nSpots = str2double( trackNode.getAttribute('nSpots') );
        A = NaN( nSpots, 4); % T, X, Y, Z
        
        detectionNodes = trackNode.getElementsByTagName('detection');
        
        for j = 1 : nSpots
            
            detectionNode = detectionNodes.item(j-1);
            t = str2double(detectionNode.getAttribute('t'));
            x = str2double(detectionNode.getAttribute('x'));
            y = str2double(detectionNode.getAttribute('y'));
            z = str2double(detectionNode.getAttribute('z'));
            A(j, :) = [ t x y z ];
            
        end
        
        tracks{i} = A;
        
    end

    % close progress bar
    close(wb)

end
    
  







