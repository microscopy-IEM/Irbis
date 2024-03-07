

function registeredZstack = preRegisterPlanesFcn(zstack,ch)

targetTimePoint = 1;

%% GUI
h = findall(0, 'type', 'figure','Name','Estimate drift in planes');
close(h)

fig = uifigure("Name",'Estimate drift in planes','Position',[100 100 800 800],'Icon',[]);

% fig.UserData.cropRect2D = [];

customGrid = uigridlayout(fig,[2 3]);
customGrid.RowHeight = {'1x','fit'};
customGrid.ColumnWidth = {'1x','fit','fit'};

pan = uipanel(customGrid);
% ax = uiaxes(customGrid);

t = tiledlayout(pan,'flow');
t.TileSpacing = 'compact';
t.Padding = 'compact';

pan.Layout.Row = 1;
pan.Layout.Column = [1 3];
applyb = uibutton(customGrid, ...
"Text","Accept", ...
"ButtonPushedFcn", @(src,event) acceptButtonPushed(fig));
applyb.Layout.Row = 2;
applyb.Layout.Column = 2;

cancelb = uibutton(customGrid, ...
"Text","Cancel", ...
"ButtonPushedFcn", @(src,event) cancelButtonPushed(fig));
cancelb.Layout.Row = 2;
cancelb.Layout.Column = 3;

wb = uiprogressdlg(fig,'Title','Registrating plane ','Indeterminate','off');
wb.Value = 0; 

%% Prepare z projections

nTimePoints = size(zstack,4);
nChannels = size(zstack,5);
nPlanes = size(zstack,3);

% Calcultate z projections
zProjections = uint16(zeros(size(zstack,1),size(zstack,2),nTimePoints));

for currentTimePoint = 1:nTimePoints

    zProjections(:,:,currentTimePoint) = max(zstack(:,:,:,currentTimePoint,ch),[],3);
    % saturate contrast
    % zProjections(:,:,currentTimePoint) = imadjustn(zProjections(:,:,currentTimePoint),stretchlim(zProjections(:),0.0001));

end


%% Estimate drift
resizeFactor = 4;
% reducedZprojections = imresize(zProjections(:,:,targetTimePoint),1/f)
FIXED = imresize(zProjections(:,:,targetTimePoint),1/resizeFactor);
tforms = cell(1,nTimePoints);

for currentTimePoint = 1:nTimePoints

    % currentTimePoint
    MOVING = imresize(zProjections(:,:,currentTimePoint),1/resizeFactor);
    tforms{currentTimePoint} = preRegister(FIXED, MOVING);

end

%% Calculate Crop area
i = 1;

FIXED_ = zProjections(:,:,targetTimePoint);

% find biggest shifts
for currentTimePoint = 2:nTimePoints

    tforms{currentTimePoint}.Translation(1) = tforms{currentTimePoint}.Translation(1)*resizeFactor;
    tforms{currentTimePoint}.Translation(2) = tforms{currentTimePoint}.Translation(2)*resizeFactor;
 
    xt(i) = tforms{currentTimePoint}.Translation(1);
    yt(i) = tforms{currentTimePoint}.Translation(2);
    i = i+1;

end

xsize = size(zstack,2);
ysize = size(zstack,1);

% Find cropping boundaries 

if max(xt) > 0
    x0 = ceil(max(xt));
else
    x0 = 1;
end

if min(xt) < 0
    xt = floor(min(xt));
else
    xt = 0;
end

if max(yt) > 0
    y0 = ceil(max(yt));
else
    y0 = 1;
end

if min(yt) < 0
    yt = floor(min(yt));
else
    yt = 0;
end

% 2D cropr ectangle for preview
cropRect2D = [x0 y0 xsize-x0+xt ysize-y0+yt];


%% Visual control
zProjectionsRegistered = zProjections;
for currentTimePoint = 2:nTimePoints

    wb.Value = 0; 
    wb.Message = ['Registrating time point ' num2str(currentTimePoint)];
 
    tform = tforms{currentTimePoint};

    zProjectionsRegistered(:,:,currentTimePoint) = imwarp(zProjections(:,:,currentTimePoint),tform,"OutputView",imref2d(size(FIXED_)));

    % zProjectionsRegistered(:,:,currentTimePoint) = imadjustn(zProjectionsRegistered(:,:,currentTimePoint),stretchlim(zProjectionsRegistered(:),0.0001));

    ax1 = nexttile(t);
        
    imshowpair(zProjections(:,:,targetTimePoint),zProjectionsRegistered(:,:,currentTimePoint),"Scaling","joint","Parent",ax1)
    ax1.Title.String = ['Time point ' num2str(currentTimePoint) ' vs. ' num2str(targetTimePoint)];

    roi = drawrectangle(ax1,'Position',cropRect2D,'Color','r','FaceAlpha',0.1);
    addlistener(roi,'ROIMoved',@roiMoved);

end

close(wb)

uiwait(fig)

if ~isvalid(fig)
    registeredZstack = [];
    return
end

wb = uiprogressdlg(fig,'Title','Processing... ','Indeterminate','on');

%% Register all planes

wb.Message = 'Registering...';

registeredZstack = zstack;
for currentTimePoint = 1:nTimePoints   

    tform = tforms{currentTimePoint};
    movingZstack = zstack(:,:,:,currentTimePoint,:);
    movingRegistered = imwarp(movingZstack,tform,"OutputView",imref2d(size(FIXED_)));
    registeredZstack(:,:,:,currentTimePoint,:) = movingRegistered;

end

 
%% Cropping
% [xmin ymin zmin width height depth]
cropRect3D = [cropRect2D(1) cropRect2D(2) 1 cropRect2D(3) cropRect2D(4) nPlanes-1];
initCrop = imcrop3(registeredZstack(:,:,:,1,1), cropRect3D);
registeredZstackCropped = uint16(zeros(size(initCrop,1),size(initCrop,2),size(initCrop,3),nTimePoints,nChannels));

wb.Message = 'Cropping...';

for currentTimePoint = 1:nTimePoints
    for ch = 1:nChannels

        temp = registeredZstack(:,:,:,currentTimePoint,ch);
        registeredZstackCropped(:,:,:,currentTimePoint,ch) = imcrop3(temp, cropRect3D);

    end

end

registeredZstack = registeredZstackCropped;

disp('Registration done')

    close(wb)
    close(fig)


end

%% Estimate ragistration tform
function tform = preRegister(FIXED, MOVING)

    % sigma = 1;
    % gaussFilter = 0;


   % Default spatial referencing objects
    fixedRefObj = imref2d(size(FIXED));
    movingRefObj = imref2d(size(MOVING));
    
    % Intensity-based registration
    [optimizer, metric] = imregconfig('monomodal');
    optimizer.GradientMagnitudeTolerance = 1.00000e-04;
    optimizer.MinimumStepLength = 1.00000e-03;
    optimizer.MaximumStepLength = 1.00000e-01;
    optimizer.MaximumIterations = 500;
    optimizer.RelaxationFactor = 0.100000;
    
    % Align centers
    [xFixed,yFixed] = meshgrid(1:size(FIXED,2),1:size(FIXED,1));
    [xMoving,yMoving] = meshgrid(1:size(MOVING,2),1:size(MOVING,1));
    sumFixedIntensity = sum(FIXED(:));
    sumMovingIntensity = sum(MOVING(:));
    fixedXCOM = (fixedRefObj.PixelExtentInWorldX .* (sum(xFixed(:).*double(FIXED(:))) ./ sumFixedIntensity)) + fixedRefObj.XWorldLimits(1);
    fixedYCOM = (fixedRefObj.PixelExtentInWorldY .* (sum(yFixed(:).*double(FIXED(:))) ./ sumFixedIntensity)) + fixedRefObj.YWorldLimits(1);
    movingXCOM = (movingRefObj.PixelExtentInWorldX .* (sum(xMoving(:).*double(MOVING(:))) ./ sumMovingIntensity)) + movingRefObj.XWorldLimits(1);
    movingYCOM = (movingRefObj.PixelExtentInWorldY .* (sum(yMoving(:).*double(MOVING(:))) ./ sumMovingIntensity)) + movingRefObj.YWorldLimits(1);
    translationX = fixedXCOM - movingXCOM;
    translationY = fixedYCOM - movingYCOM;
    
    % Coarse alignment
    initTform = affinetform2d();
    initTform.A(1:2,3) = [translationX ; translationY];
    
    % Apply transformation
    tform = imregtform(MOVING,movingRefObj,FIXED,fixedRefObj,'translation',optimizer,metric,'PyramidLevels',4,'InitialTransformation',initTform);

    % tform = imregcorr(movingInit,movingRefObj,fixedInit,fixedRefObj,'transformtype','translation','Window',false);


end


function acceptButtonPushed(fig)
  
uiresume(fig)
    % fig
    % fig = ax.Parent.Parent;
    % 
    % rect = findobj(ax,'Tag','CropArea');
    % cropRect2D = round(rect.Position);
    % 
    % if abs(rect.RotationAngle) > 0
    % 
    %     disp('has rotation - to be implemented')
    % 
    % else
    % 
    % 
    %     cropRect2D = round(cropRect2D);
    %     fig.UserData.cropRect2D = cropRect2D;
    % 
    %     uiresume(fig)
    % 
    % end


end


function cancelButtonPushed(fig)
    close(fig)
end

function roiMoved(src,evt)

    evt.CurrentPosition

end