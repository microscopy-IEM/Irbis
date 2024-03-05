% clear all
% 
% load planes3.mat
% zstack = planes3.zstack;

function zstackCropped = planesCropFcn(zstack,ch)


    nTimePoints = size(zstack,4);
    nChannels = size(zstack,5);
    nPlanes = size(zstack,3);
    
    currentTimePoint = 1;
    
    
    preview = max(zstack(:,:,:,currentTimePoint,ch),[],3);
    
    % imshow(preview,[])
    
    preview = imadjust(preview);
    
   % ax = axes
    % set(ax,'YDir','normal')
% 
    imS = imshow(preview);
    set(gca,'YDir','normal')

    drawnow

    [J,cropRect2D] = imcrop(imS);
     

    cropRect2D = round(cropRect2D)
    
    
    
    cropRect3D = [cropRect2D(1) cropRect2D(2) 1 cropRect2D(3) cropRect2D(4) nPlanes-1];
    
    initCrop = imcrop3(zstack(:,:,:,1,1), cropRect3D);
    zstackCropped = uint16(zeros(size(initCrop,1),size(initCrop,2),size(initCrop,3),nTimePoints,nChannels));
    
    for tp = 1:nTimePoints
        for currentCh = 1:nChannels
    
            zstackCropped(:,:,:,tp,currentCh) = imcrop3(zstack(:,:,:,tp,currentCh),cropRect3D);
    
        end
    end
    
    size(zstackCropped)
    
    preview = max(zstackCropped(:,:,:,currentTimePoint,ch),[],3);
    figure
    imshow(preview,[])

end