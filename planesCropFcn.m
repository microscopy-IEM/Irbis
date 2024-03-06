% clear all
% 
% load planes3.mat
% zstack = planes3.zstack;

function zstackCropped = planesCropFcn(zstack,ch)

    h = findall(0, 'type', 'figure','Name','CropPlanes');
    close(h)
    zstackCropped = [];

    nTimePoints = size(zstack,4);
    nChannels = size(zstack,5);
    nPlanes = size(zstack,3);
    
    currentTimePoint = 1;

    %% GUI
    fig = uifigure("Name",'CropPlanes','Position',[100 100 800 800],'Icon',[]);

    fig.UserData.cropRect2D = [];
    
    customGrid = uigridlayout(fig,[2 3]);
    customGrid.RowHeight = {'1x','fit'};
    customGrid.ColumnWidth = {'1x','fit','fit'};
    
    ax = uiaxes(customGrid);
    
    ax.Layout.Row = 1;
    ax.Layout.Column = [1 3];
    applyb = uibutton(customGrid, ...
        "Text","Crop", ...
        "ButtonPushedFcn", @(src,event) cropButtonPushed(ax));
    applyb.Layout.Row = 2;
    applyb.Layout.Column = 2;
    
    cancelb = uibutton(customGrid, ...
        "Text","Cancel", ...
        "ButtonPushedFcn", @(src,event) cancelButtonPushed(fig));
    cancelb.Layout.Row = 2;
    cancelb.Layout.Column = 3;
    

    %% Plot part
    
    preview = max(zstack(:,:,:,currentTimePoint,ch),[],3);
    
    preview = imadjust(preview);
    
    imshow(preview,'Parent',ax);
    % set(ax,'YDir','normal')
    
    initPos = [1 1 size(preview,2), size(preview,1)];
    
    r1 = drawrectangle(ax,'Label','Crop area','Color',[1 0 0],'Rotatable',1,'Position',initPos,'Tag','CropArea');
    r1.DrawingArea = initPos;
    r1.FaceAlpha = 0.05;
    r1.Deletable = 0;

    % Wait for button press
    uiwait(fig)

    if ~isvalid(fig)
         return
    end


    wb = uiprogressdlg(fig,'Title','Cropping','Indeterminate','on');
        
    
    %% Cropping part

   
    cropRect2D = fig.UserData.cropRect2D;
    
    cropRect3D = [cropRect2D(1) cropRect2D(2) 1 cropRect2D(3)-1 cropRect2D(4)-1 nPlanes-1];
    
    initCrop = imcrop3(zstack(:,:,:,1,1), cropRect3D);
    zstackCropped = uint16(zeros(size(initCrop,1),size(initCrop,2),size(initCrop,3),nTimePoints,nChannels));
    
    for tp = 1:nTimePoints
        for currentCh = 1:nChannels
    
            zstackCropped(:,:,:,tp,currentCh) = imcrop3(zstack(:,:,:,tp,currentCh),cropRect3D);
    
        end
    end
    
    % size(zstackCropped)
    
    % preview = max(zstackCropped(:,:,:,currentTimePoint,ch),[],3);
    % figure
    % imshow(preview,[])

    disp('Cropping done')

    close(wb)
    close(fig)

end


function cropButtonPushed(ax)
  
    fig = ax.Parent.Parent;

    rect = findobj(ax,'Tag','CropArea');
    cropRect2D = round(rect.Position);
    
    if abs(rect.RotationAngle) > 0

        disp('has rotation - to be implemented')

    else

       
        cropRect2D = round(cropRect2D);
        fig.UserData.cropRect2D = cropRect2D;
                  
        uiresume(fig)

    end


end


function cancelButtonPushed(fig)
    close(fig)
end