% Function for import of images to Irbis
% Script reads general info (num of channels, planes etc.) from the image metadata

function planes = importPlanesNew(fig, wb)

    arguments
        fig 
        wb = uiprogressdlg(fig, 'Title', 'Importing file', 'Message', 'Importing file...', 'Cancelable', 'on');
    end

    addpath(genpath('BioformatsToolbox')); % Ensure BioformatsToolbox is in the path
    
     % select files
    [fileName, path] = uigetfile('*');

    if isequal(fileName, 0)
        disp('User selected Cancel');
        planes = [];
        return;
    end
    
    fullPath = fullfile(path, fileName);

    try
        reader = BioformatsImage(fullPath);
        % assignin('base', 'reader', reader); % Assign to base workspace for debugging
    catch ME
        disp(ME.message);
        disp(ME.stack)
        planes = [];
        uialert(fig, 'Error reading file with BioformatsImage. Please convert it to tiff first in ImageJ.', 'Loading unsuccessful');
        return
    end

    % Initialize planes structure with all default fields:
    planes = getBaseStruct('planes').planes; 
    % Initializing it here will ensure that all fields are present and that I don't need to define the default ones here
    
    planes.refOrigFileName = fileName;
    zstack = getAllImageData(reader); % Dimensions: x*y*z*t*ch
    planes.zstack = zstack;           % raw image data - dimensions x*y*z*t*ch
    
    % Number of elements in each dimension
    planes.imSize = [reader.height, reader.width];       % single plane xy size in pixels 
    nPlanes = reader.sizeZ;          % number of planes in z-stack
    planes.nPlanes = nPlanes;
    nChannels = reader.sizeC;       % number of channels
    planes.nChannels = nChannels;
    planes.nTimePoints = reader.sizeT;

    missingInfo = [];

    % Information about individual pixel/voxel
    try
        planes.pixel_size = reader.pxSize(1);                               % pixel size in defined units (micrometeres)
    catch
        planes.pixel_size = 1; % default pixel size
        % uialert(figureH, ...
        %     'Pixel size not available in metadata. Please set it manually.', ...
        %     'Warning', 'Icon', 'warning');
        missingInfo = [missingInfo; "pixel size"];
    end

    % if the zSpacing has not been loaded correctly and the data is a z-stack, display an uialert and set it to 1
    if (nPlanes > 1) && isequal(reader.zSpacing, 0)
        planes.z_spacing = 1; 
        % uialert(figureH, ...
        %     'Z-spacing not available in metadata. Please set it manually.', ...
        %     'Warning', 'Icon', 'warning');
        missingInfo = [missingInfo; "z-spacing"];
    elseif isequal(nPlanes, 1)
        planes.z_spacing = 0; % if the image is single plane, we want to have zSpacing = 0 (this would probably be the default anyway)
        % this is to avoid problems with the plane not being visualized at z=0
    else
        planes.z_spacing = reader.zSpacing;
    end

    % Save channel information
    channelColors = config.GUI.getChannelColors(nChannels);   % Default channel colors from config file
    planes.channelColors = channelColors;

    channelColormaps = config.GUI.getChannelColormaps(nChannels);
    planes.channelColormaps = channelColormaps;

    if isempty(reader.channelNames)
        channelNames = config.GUI.getChannelNames(nChannels); % Default channel names from config file
    else
        channelNames = reader.channelNames;
    end
    planes.channelNames = matlab.lang.makeValidName(channelNames);  % Validation added because some channel names may contain invalid characters for field names (such as -)

    bitDepth = reader.bitDepth;
    planes.bitDepth = bitDepth;
    if isequal(bitDepth, 8) || isequal(bitDepth, 16)
        upperLimit = (2^bitDepth) - 1;
    else
        % TO OPTIMIZE: decide what to do with 32-bit data
        upperLimit = (2^16) - 1;
    end
    channelRanges = repelem({[0 upperLimit]}, nChannels);
    planes.channel_ranges = channelRanges;


    % Set reference settings
    if reader.sizeZ >= 7 
        refDepth = 1;   % default number of planes fot z-projection (number of planes above end below the selected middle plane)
    else
        refDepth = 0;
    end
    planes.refImParam.depth = refDepth;
    planes.spacialRef = calculateSpacialReference(planes.imSize, planes.pixel_size);    % TO FIX: spatial instead of spacial

    if ~isempty(missingInfo)
        % Display alert if some information is missing
        uialert(fig, ...
            sprintf('The following information is missing: %s. Please set it manually.', strjoin(missingInfo, ', ')), ...
            'Missing metadata', 'Icon', 'warning');
    end

    if nargin < 2
        wb.Value = 1;
        close(wb)
    end
end


function [imgStack, timestamps] = getAllImageData(bioformatsReader, wb)
    %GETALLIMAGEDATA  Get complete image stack with all channels, z-planes, and timepoints
    %
    %  [IMGSTACK, TIMESTAMPS] = GETALLIMAGEDATA(BFOBJ) returns a 5D array
    %  containing all image data with dimensions:
    %  [HEIGHT x WIDTH x Z-PLANES x TIMEPOINTS x CHANNELS]

    %  TIMESTAMPS is a 3D array with dimensions [CHANNELS x Z-PLANES x TIMEPOINTS]
    %  containing timestamp information for each plane (if available).
    %
    %  Example:
    %    bfr = BioformatsImage('myimage.tif');
    %    [allData, ts] = getAllImageData(bfr);
    %    
    %    % Access specific plane: allData(:,:,z,time,channel)
    %    channel1_z1_t1 = allData(:,:,1,1,1);

    % Input validation
    if ~isa(bioformatsReader, 'BioformatsImage')
        error('getAllImageData:InvalidInput', 'First argument must be a BioformatsImage object');
    end
    samplePlane = bioformatsReader.getPlane(1, 1, 1);

    % Initialize 5D array
    imgStack = zeros(bioformatsReader.height, bioformatsReader.width, bioformatsReader.sizeZ, bioformatsReader.sizeT, bioformatsReader.sizeC, class(samplePlane));

    % Initialize timestamps array if requested
    if nargout > 1
        timestamps = cell(bioformatsReader.sizeC, bioformatsReader.sizeZ, bioformatsReader.sizeT);
    end

    % Display progress information
    fprintf('Loading image stack: %d channels, %d z-planes, %d timepoints...\n', ...
        bioformatsReader.sizeC, bioformatsReader.sizeZ, bioformatsReader.sizeT);

    % Loop through all dimensions
    totalPlanes = bioformatsReader.sizeC * bioformatsReader.sizeZ * bioformatsReader.sizeT;
    planeCount = 0;

    for iT = 1:bioformatsReader.sizeT
        for iC = 1:bioformatsReader.sizeC
            for iZ = 1:bioformatsReader.sizeZ
                planeCount = planeCount + 1;
                
                if nargout > 1
                    try
                        [imgStack(:,:,iZ,iT,iC), timestamps{iC,iZ,iT}] = ...
                            bioformatsReader.getPlane(iZ, iC, iT);
                    catch
                        % If timestamps not available, just get the image
                        imgStack(:,:,iZ,iT,iC) = bioformatsReader.getPlane(iZ, iC, iT);
                        timestamps{iC,iZ,iT} = NaN;
                    end
                else
                    imgStack(:,:,iZ,iT,iC) = bioformatsReader.getPlane(iZ, iC, iT);
                end
                
                % Display progress every 10% or every 100 planes
                if mod(planeCount, max(1, floor(totalPlanes/10))) == 0 || mod(planeCount, 100) == 0
                    wb.Value = planeCount/totalPlanes;
                    wb.Message = sprintf('Loading plane %d/%d (%.1f%%)', planeCount, totalPlanes, 100*planeCount/totalPlanes);
                end
            end
        end
    end
end


