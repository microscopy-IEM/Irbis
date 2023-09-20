% Script defining data structure for handling moltimodal microscopy data
% Author: Stepan Kortus, stepan.kortus@iem.cas.cz
% Version 0.3
% Last modification 08.06.2022
% Last modification 13.05.2022
% Version 0.1
% Last modification 19.04.2022


function MMpack = TRS2MMpack03(path,fileName)

    %% load TRS
    % load RatE18_DIV14_Homer_GFP2B_ECSMG_1518_QD605_01_ALX_crop_0_rotAngle_106.8157_TRS_REF_DC_MSD_edited.mat
    % 
    % TRS
    if nargin > 0
       
        disp('read file')

        TRS = importdata([path fileName]);

    else
     
    [fileName,path] = uigetfile({'*.mat'},'Select a TRS file',pwd);
          
    
    
        if isequal(fileName,0)
           disp('User selected Cancel');
        else
           disp(['User selected ', fullfile(path,fileName)]);
        
           
           TRS = importdata([path fileName]);
        
        end

    end
    
    %% 
    
    TRS
    
    % USER INPUT    

    MMpack_version = '0.3';
    
%     description = '2A2B3A_mice_cre';             % Description of the experiment ('Mobility_2Avs2Bvs3A')
%     groupName = '2B_mice'; %TRS.groupName;          % Name of the experimental condition ('2A_cre' or '3A_wt'...)

%     description = '3A_rat_coagonists';             % Description of the experiment ('Mobility_2Avs2Bvs3A')
%     groupName = '3A_Ctrl'; %TRS.groupName;          % Name of the experimental condition ('2A_cre' or '3A_wt'...)
%     groupName = '3A_Gly30'; %TRS.groupName;          % Name of the experimental condition ('2A_cre' or '3A_wt'...)
%     groupName = '3A_Dser30'; %TRS.groupName;          % Name of the experimental condition ('2A_cre' or '3A_wt'...)

    description = 'QD_probes_rat_fix';
    groupName = 'nGFP_QD525_fix';

    roundN = 1;                          % Number of round
    
    [numOfPlanes, numOFChannels] = size(TRS.reference.refImageData);

    referenceChannel = 3;               % number of channel with reference signal (Homer for synaptic marker)

    if referenceChannel > numOFChannels
        referenceChannel = numOFChannels;
    end

    
    refPlane = round(numOfPlanes/2); % in default, the middle plane of z-stack is seelcted
    refDepth = 3;   % defeult number of planes fot z-projection (number of planes above end below the selected middle plane)

    if refDepth*2+1 >= numOfPlanes
        refDepth = 0;
    end
    
        
    %% Commont information
    info = [];
    
    info.groupName = groupName;                                            % for xample: 'round 1', 'mutation XX'...
    info.description = description;                                        % general description of the experiment
    info.round = roundN;                                                    % round number
    info.MMpack_version = MMpack_version;                                  % version od MMpack 
    info.spaceUnits = TRS.reference.unit;                                  % space units um, nm common for all modalities
    info.timeUnits = 'sec';                                                % time units 'sec','min' common for all modalitioes
    
    
    %% WF data
    
    wf.pixel_size = TRS.reference.pixelSize;                               % pixel size in defien units (micrometeres)
    wf.z_spacing = TRS.reference.Z_spacing;                                % step in Z-stack data
    wf.refImageData = TRS.reference.refImageData;                          % raw image data (multiple tiff of zstack or single tiff per channel)
    wf.channel_names = TRS.reference.channels_desc;                        % channel specification {'GFP','Homer','DIC'}
    wf.refOrigFileName = TRS.origFileName;

    % assign default colors to channels (grey, green, red)
    wf.channelColors = [{[1 1 1]}    {[0 1 0]}    {[1 0 0]}];
    if numOFChannels == 2
        wf.channelColors = [{[0 1 0]}    {[1 0 0]}];
    end


    % reference image
    wf.refIm = TRS.reference.refIm;   
    wf.refImParam.plane = refPlane;
    wf.refImParam.depth = refDepth;
    wf.refImParam.channel = referenceChannel;                              % channel used as reference image (synaptic marker, membrane marker...)
    
    
    %% dSTORM data
    storm = [];
    % storm.origFileName = [];
    % storm.origLocalizations = [];
    % storm.correctedLocalizations = [];
    
    
    %% Mobility data
    
    % need for good definiton usable for both 2D and 3D
    
    tracks.tracksOrigFileName = TRS.origFileName;
    tracks.spots = TRS.spots;                                               % localization of particles (QDs) without linking htem to trajectories
    tracks.numOfTracks = TRS.numOfTrajectories;
    tracks.numOfFrames = TRS.numOfFrames;
    tracks.frame_interval = TRS.info.frameInterval;                         % frame interval in defined units (sec)
    
    if isfield(tracks,'driftCorrection')
        tracks.driftCorrection = TRS.driftCorrection;                           % drift correction metedata
    end

    % Define table
    varNames = {'id';'group';'roundN';'xyz';'frame_i';'length';'numOfNaN';'longestGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
    varTypes = {'double','string','double','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
        
    
    % get size of the table
    sz = [TRS.numOfTrajectories size(varTypes,2)];

    % create table
    T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
 
    for tr = 1:TRS.numOfTrajectories

        T.id(tr) = tr;
        T.group(tr) = groupName;
        T.roundN(tr) = roundN;
        T.xyz(tr) = TRS.coordinates(tr); 
        T.frame_i(tr) = TRS.frame_indexes(tr);
        T.length(tr) = size(TRS.coordinates{tr},1);

    end

    tracks.tracksList = T;
    
      
    
    %% SIM data
    
    sim = [];
    
    %% Archiv
    
    archiv = TRS.archiv;
    
    %% Results
    
    results.areas = [];
    results.peaks = [];
    results.masks = [];
    results.ROIs = [];
    
    
    %% Compose structured file
    
    MMpack.info = info;
    MMpack.wf = wf;
    MMpack.storm = storm;
    MMpack.tracks = tracks;
    MMpack.sim = sim;
    MMpack.results = results;
    MMpack.archiv = archiv;
    
    MMpack
    
    [~,name,~] = fileparts(fileName);
    saveName = [path,name,'_MMpack.mat']
    save(saveName,'MMpack');


end























