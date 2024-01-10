% Function import widefield type of images to MMP software
% The input image should be first saved by imageJ
% Supports up to three color channels
% Supports Zstack
% Supports timepoints


% Script reads general info (num of channles, planes etc.) from the image metadata

function planes = importPlanes3(figureH,varargin)

    wb = uiprogressdlg(figureH,'Title','Importing file','Message','Importing file...','Cancelable','on');
    wb.Value = 0;
    
      % select files
    [fileName,path] = uigetfile('*.tif','MultiSelect','off');

    
    if isequal(fileName,0)
        disp('User selected Cancel');
        planes = [];
        return;
    end
        
        % get tiff info from file
        info = imfinfo([path fileName]);
     
        % read volumt tiff with support of >4GB images
        V = tiffreadVolume([path fileName]);

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
        % unit = 'µm';
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
        
        if nargin == 2
            colors = varargin{1};
        else
            % Save default colors to channels
            colors = [{[1 0 0]}    {[0 1 0]}    {[0 0 1]}];
        end

        channelColors = cell(1,numOfChannels);
        channels_desc = cell(1,numOfChannels);
        
        for i = 1:numOfChannels

            channelColors{i} = colors{i};
            channels_desc{i} = ['ch' num2str(i)];

        end
  
        % Save default ranges for histogram
        channel_ranges = repmat({[0 1]},1,numOfChannels);

        % save resolition in pixels    
        yres = info(1).Width;
        xres = info(1).Height;
              
        % create empty uint16 array without specified number of channels (one dimension must be 0)
        zstack = uint16.empty(xres,yres,numOfZPlanes,numOfTimePoints,0);
        
        % First run cycle for each channel
        frameNum = 0;
             
        for channelNum = 1:numOfChannels
           for timePoint = 1:numOfTimePoints
               for slice = 1:numOfZPlanes
                                                        
                        tiffID = channelNum+numOfChannels*(slice-1)+numOfFramesPerTimepoint*(timePoint-1);                
                        zstack(:,:,slice,timePoint,channelNum) = uint16(V(:,:,tiffID));
                        frameNum = frameNum+1;
            
               end
               
                wb.Value = frameNum/numOfTiffs;

           end
        end

            
        % Set default z-projection depth
        actualPlane = round(numOfZPlanes/2); % in default, the middle plane of z-stack is seelcted
        if numOfZPlanes >= 7 
            refDepth = 1;   % default number of planes fot z-projection (number of planes above end below the selected middle plane)
        else
            refDepth = 0;
        end
        
        % Sort data for the MMpack format
        
        planes.refOrigFileName = fileName;
        planes.zstack = zstack;                                      % raw image data (multiple tiff of zstack or single tiff per channel)
        planes.pixel_size = pixelSize;                               % pixel size in defined units (micrometeres)
        planes.z_spacing = z_spacing;                                % step in Z-stack data
        planes.channel_names = channels_desc;                        % channel specification {'GFP','Homer','DIC'}
        planes.channelColors = channelColors;
        planes.channel_ranges = channel_ranges;                      % histogram ranges for plotting
        planes.imSize = [xres,yres];                                 % single plane xy size in pixels 
        planes.nPlanes = numOfZPlanes;
        planes.nChannels = numOfChannels;
        planes.nTimePoints = numOfTimePoints;
        
        % reference image default settings
        planes.refImParam.plane = actualPlane;
        planes.refImParam.depth = refDepth;
        planes.refImParam.channel = referenceChannel;                % channel used as reference image (synaptic marker, membrane marker...)
    
  
    
    wb.Value = 1;
    pause(0.1)
    close(wb)

end


