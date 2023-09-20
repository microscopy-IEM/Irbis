% Function import widefield type of images to MMP software
% The input image should be first saved by imageJ
% Supports up to three color channels
% Supports Zstack
% Supports timepoints

% Script reads general info (num of channles, planes etc.) from the image metadata

function wf = importWF()

  % select files
[fileName,path] = uigetfile('*.tif','MultiSelect','off');

if isequal(fileName,0)
                   disp('User selected Cancel');
                   wf = [];
else


     % get tiff info from file
    info = imfinfo([path fileName]);
    
    % get number of tiffs in multiple tiff file
    numOfTiffs = size(info,1);
    desc = info(1).ImageDescription;
    
    % read pixel size
    x_size = info(1).XResolution;
    
    if isempty(x_size)
        
        x_size = 1;
    
    end
    
    pixelSize = round(1/x_size,5);
    
    
    % User defined
    unit = 'µm';
    referenceChannel = 1;
    
    
    % one image case
    if numOfTiffs == 1
        
        numOfChannels = 1;
        numOfTimePoints = 1;
        numOfZPlanes = 1;
        z_spacing = 1;
    
    else
            
        % find information about number of channels in tiff info
        TextInd = strfind(desc,'channels=');
        if ~isempty(TextInd)
            numOfChannels = str2double(desc(TextInd+9));
        else
            numOfChannels=1;
        end
    
    
        % find spacing for Z-dimension
        Key   = 'spacing=';
        Index = strfind(desc, Key);
        if ~isempty(Index)
              z_spacing = sscanf(desc(Index(1) + length(Key):end), '%g', 1);
        else
              z_spacing = 0.1;
        end
    
    
        % find number of frames (time points)  
        Key = 'frames=';
        Index = strfind(desc, Key);
    
        if ~isempty(Index)
            numOfTimePoints = sscanf(desc(Index(1) + length(Key):end), '%g', 1);
        else
            numOfTimePoints=1;
        end
    
    
        % find number of z planes
        Key = 'slices=';
        Index = strfind(desc, Key);
        
        if ~isempty(Index)
            numOfZPlanes = sscanf(desc(Index(1) + length(Key):end), '%g', 1);
        else
            numOfZPlanes=1;
        end
        
    end
    
    numOfFramesPerTimepoint = numOfZPlanes*numOfChannels;
    
    % Save default description to channels
    channels_desc{1} = 'R'; % Homer
    channels_desc{2} = 'G'; % GFP
    channels_desc{3} = 'B'; %
         
    % Save default colors to channels
    channelColors = [{[1 0 0]}    {[0 1 0]}    {[0 0 1]}];
    
    % Save ranges for histogram
    channel_ranges = [{[0 1]}    {[0 1]}    {[0 1]}];
    
    yres = info(1).Width;
    xres = info(1).Height;
    
    zstack = nan(xres,yres,numOfZPlanes,3,numOfTimePoints,'single');
    
    % First run cycle for each channel
    for timePoint = 1:numOfTimePoints
    
        for channelNum = 1:numOfChannels
           
            for slice = 1:numOfZPlanes
            % Second run inner loop for each z-plane of the actual channel 
                
                    % v = channelNum+nPerTimepoint*(timePoint-1):numOfChannels:nPerTimepoint*timePoint
    
                    tiffID = channelNum+numOfChannels*(slice-1)+numOfFramesPerTimepoint*(timePoint-1);
                                    
                    % for tiffID = channelNum+nPerTimepoint*(timePoint-1):numOfChannels:nPerTimepoint*timePoint
                
                        % tiffID
                        % read specific tiff from file
                        im1 = imread([path fileName],tiffID);
                
                        % convert to douple
                        im1 = im2double(im1);    
                
                        % slice
                        zstack(:,:,slice,channelNum,timePoint) = im1;
                
                    % end
        
             end
    
        end
    end
    
    % reduce to 3 channels in bigger
    if numOfZPlanes > 3
    
        zstack = zstack(:,:,:,1:3,:);
    
    end
    
    
    % Set default z-projection depth
    actualPlane = round(numOfZPlanes/2); % in default, the middle plane of z-stack is seelcted
    if numOfZPlanes >= 7 
        refDepth = 3;   % default number of planes fot z-projection (number of planes above end below the selected middle plane)
    else
        refDepth = 0;
    end
    
    % Sort data for the MMpack format
    
    wf.refOrigFileName = fileName;
    wf.pixel_size = pixelSize;                               % pixel size in defien units (micrometeres)
    wf.z_spacing = z_spacing;                                % step in Z-stack data
    wf.zstack = zstack;                                      % raw image data (multiple tiff of zstack or single tiff per channel)
    wf.channel_names = channels_desc;                        % channel specification {'GFP','Homer','DIC'}
    wf.channelColors = channelColors;
    wf.channel_ranges = channel_ranges;                      % histogram ranges for plotting
    wf.nChannels = numOfChannels;
    
    % reference image default settings
    wf.refImParam.plane = actualPlane;
    wf.refImParam.depth = refDepth;
    wf.refImParam.channel = referenceChannel;                % channel used as reference image (synaptic marker, membrane marker...)

end

end


