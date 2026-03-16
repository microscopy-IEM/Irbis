function rgbMatrix = precalculatePlanePlotAll(zstack,activeChannels,planesLimits,projectionDepth,colormaps,mode,mappingToolboxYes)

    % zstack dimensions: x - y - z - t - ch
    % rgbMatrix dimensions: x - y - 3 (RGB) - z - t
    % rgbPlane dimensions: x - y - 3 (RGB) - ch - z - t

    xdim = size(zstack,1);
    ydim = size(zstack,2);
    minUsed = planesLimits(1);
    maxUsed = planesLimits(2);
    nPlanes = size(zstack,3);
    nTimePoints = size(zstack,4);

    nChannels = length(activeChannels);
    cmap = colormaps;

    if ~isequal(maxUsed,nPlanes)
        focalRange = projectionDepth;
    else
        mode = 'zstack';
        focalRange = 0;
    end            

    % Initialize rgbPlane
    if mappingToolboxYes
        rgbPlane = uint8.empty(xdim, ydim, 3, 0, nPlanes,nTimePoints);  
        % fill the low numbers with zeros
        rgbPlane(:,:,:,1:nChannels,1:minUsed-1,:) = zeros(xdim, ydim, 3, nChannels, length(1:minUsed-1),nTimePoints); 
        % fill the high numbers with zeros
        rgbPlane(:,:,:,1:nChannels,maxUsed+1:nPlanes,:) = zeros(xdim, ydim, 3, nChannels, length(maxUsed+1:nPlanes),nTimePoints);                     
    else
        rgbPlane = double.empty(xdim, ydim, 3, 0, nPlanes, nTimePoints);
        % fill the low numbers with zeros
        rgbPlane(:,:,:,1:nChannels,1:minUsed-1,:) = zeros(xdim, ydim, 3, nChannels, length(1:minUsed-1),nTimePoints); 
        % fill the high numbers with zeros
        rgbPlane(:,:,:,1:nChannels,maxUsed+1:nPlanes,:) = zeros(xdim, ydim, 3, nChannels, length(maxUsed+1:nPlanes),nTimePoints);                   
    end

    for currentTimePoint = 1:nTimePoints
        for currentPlane = minUsed:maxUsed
    
            Z_Range = currentPlane-focalRange:currentPlane+focalRange;   
            % Zprojection = squeeze(getZProjection(zstack,activeChannels,Z_Range,currentTimePoint,mode));
            Zprojection = (getZProjection(zstack,activeChannels,Z_Range,currentTimePoint,mode));
            Zprojection = permute(Zprojection,[1,2,5,3,4,6]);
    
            if mappingToolboxYes
                for ch_ind = 1:nChannels
                    rgbPlane(:,:,:,ch_ind,currentPlane,currentTimePoint) = ind2rgb8(Zprojection(:,:,ch_ind),cmap{activeChannels(ch_ind)});
                end
            else
                for ch_ind = 1:nChannels
                    rgbPlane(:,:,:,ch_ind,currentPlane,currentTimePoint) = ind2rgb(Zprojection(:,:,ch_ind),cmap{activeChannels(ch_ind)});
                end
        
            end           
        end
    end
    if ~mappingToolboxYes
        rgbPlane = uint8(rgbPlane*255);     % uint8 maps the value to 0-255 range and rounds it, if decimal
    end

    temp = (sum(rgbPlane,4,"native"));

    temp = permute(temp,[1 2 3 5 6 4]);
    rgbMatrix = temp;

end