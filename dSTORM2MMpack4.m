% Script defining data structure for handling moltimodal microscopy data
% Author: Stepan Kortus, stepan.kortus@iem.cas.cz
% Version 0.4
% 
% Version 0.3
% Last modification 17.05.2022
% Last modification 13.05.2022
% Version 0.1
% Last modification 19.04.2022


clc; clear all;

%% load TRS
% load RatE18_DIV14_Homer_GFP2B_ECSMG_1518_QD605_01_ALX_crop_0_rotAngle_106.8157_TRS_REF_DC_MSD_edited.mat
% 
% TRS

 
[stormfileName,stormpath] = uigetfile({'*.mat'},'Select a dSTORMpack file',pwd);
       

if isequal(stormfileName,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(stormpath,stormfileName)]);

   
   dSTORMpack = importdata([stormpath stormfileName]);

end

[RefFileName,RefPath] = uigetfile([stormpath '*.tif'],'Select a Z-stack file',pwd);

if isequal(stormfileName,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(stormpath,stormfileName)]);

    % get tiff info from file
    info = imfinfo([RefPath RefFileName]);
    desc = info(1).ImageDescription;
    
    % find information about number of channels in tiff info
    TextInd = strfind(desc,'channels=');
    numOfChannels = str2double(desc(TextInd+9));
    if isnan(numOfChannels)
        numOfChannels = 1;
    end
    
    % get number of tiffs in multiple tiff file
    numOfTiffs = size(info,1);

    % calculate number of tiffs per channel (number of planes)
    numOfZPlanes = numOfTiffs/numOfChannels;

    if numOfChannels == 2
        
        channels_desc{1} = 'GFP';
        channels_desc{2} = 'dTomato';
    
    elseif numOfChannels == 3

        channels_desc{1} = 'GFP';
        channels_desc{2} = 'dTomato';
        channels_desc{3} = 'A647';

    end

    % find spacing for Z-dimension
    TextInd = strfind(desc,'spacing=');
    Z_spacing = round(str2double(desc(TextInd+8:TextInd+10)),2);
    unit = 'µm';

      %% Create structurad array containing all images organized to separated
            % channels and Z-planes:

            % Create an empty arraye with size [numOfPlanes X numOfChannels]
            refImageData = cell(numOfZPlanes,numOfChannels);

            % first run cycle for each channel
            for channelNum = 1:numOfChannels

                slice = 0;
               % run inner loop for each z-plane of the actual channel 
                for tiffID = channelNum:numOfChannels:numOfTiffs

                    % read specific tiff from file
                    im1 = imread([RefPath RefFileName],tiffID);
                    slice = slice+1;
                    % save image to structured array
                    refImageData{slice,channelNum} = im1;

                end
            end

end


%% Create MMPack structure

dSTORMpack

MMpack_version = '0.3';

description = 'Storm_test';   % Description of the experiment ('Mobility_2Avs2Bvs3A')
groupName = 'ctrl';               % Name of the experimental condition ('2A_cre' or '3A_wt'...)
roundN = 1;                      % Number of round

referenceChannel = 1;           % number of channel with reference signal (Homer for synaptic marker)


%% Commont information
info = [];

info.groupName = groupName;                                                       % for xample: 'round 1', 'mutation XX'...
info.description = description;                                            % general description of the experiment
info.MMpack_version = MMpack_version;                                      % version od MMpack 
info.spaceUnits = 'µm';                                                    % space units um, nm common for all modalities
info.timeUnits = 'sec';                                                    % time units 'sec','min' common for all modalitioes


%% WF data

wf.pixel_size = dSTORMpack.pixelSize;                                      % pixel size in defined units (micrometeres)
wf.z_spacing = Z_spacing;                                                         % step in Z-stack data
wf.refImageData = refImageData;
wf.channel_names = {'Homer'};                                              % channel specification {'GFP','Homer','DIC'}
wf.refOrigFileName = RefFileName;

% reference image
wf.refIm = dSTORMpack.refIm;
wf.refImParam.plane = round(numOfZPlanes/2);
wf.refImParam.depth = 3;
wf.refImParam.channel = referenceChannel;                                                 % channel used as reference image (synaptic marker, membrane marker...)

%% dSTORM data

storm.origFileName = dSTORMpack.origName;
storm.origLocalizations = dSTORMpack.origLocalizations;
storm.correctedLocalizations = dSTORMpack.correctedLocalizations;


%% Mobility data

tracks = [];


%% SIM data

sim = [];

%% Archiv

archiv = [];

%% Results

results.areas = [];
results.peaks = [];
results.masks = [];
results.ROIs = [];

%% Modality registration

% reference A
% reference B
% modalReg.storm2wf.tform = [];


%% Compose structured file

MMpack.info = info;
MMpack.wf = wf;
MMpack.storm = storm;
MMpack.tracks = tracks;
MMpack.sim = sim;
MMpack.results = results;
MMpack.archiv = archiv;

MMpack

[~,name,~] = fileparts(stormfileName);
saveName = [stormpath,name,'_MMpack.mat'];
save(saveName,'MMpack');






















