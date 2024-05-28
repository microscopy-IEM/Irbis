

function [registeredZstack, driftVect] = preRegisterPlanesFcn(zstack,ch)

    %% GUI
    h = findall(0, 'type', 'figure','Name','Estimate drift in planes');
    close(h)
    
    fig = uifigure("Name",'Estimate drift in planes','Position',[100 100 800 800],'Icon',[]);

    
    customGrid = uigridlayout(fig,[2 9]);
    customGrid.RowHeight = {'1x','fit'};
    customGrid.ColumnWidth = {'1x','fit','fit','fit','fit','fit','fit','fit','fit'};
    
    pan = uipanel(customGrid);
        
    t = tiledlayout(pan,'flow');
    t.Tag = 'figLayout';
    t.TileSpacing = 'compact';
    t.Padding = 'compact';
    
    pan.Layout.Row = 1;
    pan.Layout.Column = [1 9];

    methodDropDown = uidropdown(customGrid,"Items",["first","previous"],'Tag','targetTimePoint');
    methodDropDown.ValueChangedFcn = @(~,~)updatePlot(fig);
    methodDropDown.Value = 'previous';
    methodDropDown.Layout.Row = 2;
    methodDropDown.Layout.Column =  2;
    
     sliderLabel = uilabel(customGrid, ...
        "Text","Sigma");
    sliderLabel.Layout.Row = 2;
    sliderLabel.Layout.Column = 3;
    
    sensSlider = uislider(customGrid,"ValueChangedFcn", [],'Tag','sensSlider');
    sensSlider.Limits = [0 10];
    sensSlider.MajorTicks = [];
    sensSlider.MinorTicks = [];
    sensSlider.Value = 2;
    sensSlider.Layout.Row = 2;
    sensSlider.Layout.Column = 4;
    
   
    methodDropDown = uidropdown(customGrid,"Items",["Cross-correlation","Intensity"],'Tag','regMethod');
    methodDropDown.Layout.Row = 2;
    methodDropDown.Layout.Column = 5;

    registb = uibutton(customGrid, ...
    "Text","Register", ...
    "ButtonPushedFcn", @(src,event) runRegistration(fig));
    registb.Layout.Row = 2;
    registb.Layout.Column = 6;

    resetb = uibutton(customGrid, ...
    "Text","Reset", ...
    "ButtonPushedFcn", @(src,event) resetButtonPushed(fig));
    resetb.Layout.Row = 2;
    resetb.Layout.Column = 7;
    
    applyb = uibutton(customGrid, ...
    "Text","Accept", ...
    "ButtonPushedFcn", @(src,event) acceptButtonPushed(fig));
    applyb.Layout.Row = 2;
    applyb.Layout.Column = 8;
    
    cancelb = uibutton(customGrid, ...
    "Text","Cancel", ...
    "ButtonPushedFcn", @(src,event) cancelButtonPushed(fig));
    cancelb.Layout.Row = 2;
    cancelb.Layout.Column = 9;

    
    %% Prepare z projections
    
    nTimePoints = size(zstack,4);
    
    % Calcultate z projections
    zProjections = uint16(zeros(size(zstack,1),size(zstack,2),nTimePoints));
    
    for currentTimePoint = 1:nTimePoints
    
        zProjections(:,:,currentTimePoint) = max(zstack(:,:,:,currentTimePoint,ch),[],3);
          
    end

    zProjectionsRegistered = zProjections;

    % targetTimePoint

    % 2D cropp rectangle for preview
    xsize = size(zProjections,2);
    ysize = size(zProjections,1);
    cropRect2D = [0 0 xsize ysize];

    fig.UserData.cropRect2D = cropRect2D;
    
    fig.UserData.zProjections = zProjections;
    fig.UserData.zProjectionsRegistered = zProjectionsRegistered;
    fig.UserData.zstack = zstack;
    fig.UserData.ch = ch;
    fig.UserData.targetTimePoint = 1;
    fig.UserData.tforms = [];

    for currentTimePoint = 1:nTimePoints   
        driftVect{currentTimePoint} = [0,0,0];
    end
    
    fig.UserData.driftVect = driftVect;

    updatePlot(fig)
    
    %% wait for the "Acctept buttun pushed"
    uiwait(fig)
    
    if ~isvalid(fig)
        registeredZstack = [];
        driftVect = [];
        return
    end
    
        
    registeredZstack = fig.UserData.registeredZstack;
    driftVect = fig.UserData.driftVect;
    cropRect2D = fig.UserData.cropRect2D;

    xCropOffset = cropRect2D(1);
    yCropOffset = cropRect2D(2);

    for currentTimePoint = 1:nTimePoints
        
        driftVect{currentTimePoint}(1) = driftVect{currentTimePoint}(1) - xCropOffset;
        driftVect{currentTimePoint}(2) = driftVect{currentTimePoint}(2) - yCropOffset;

    end
    
    disp('Registration done')

    close(fig)

end

%% Estimate ragistration tform
function tform = preRegister(FIXED, MOVING,sigma,method)

    FIXED = imgaussfilt(FIXED,sigma);
    MOVING = imgaussfilt(MOVING,sigma);

    switch method
        
        case 'Cross-correlation'
            % Cross-correlation method
            FIXED = imadjust(FIXED);
            MOVING = imadjust(MOVING);
        
            c = normxcorr2(FIXED,MOVING);
            % figure
            % surf(c) 
            % shading flat
        
            % offset found by correlation
            [~,imax] = max(abs(c(:)));
            [ypeak,xpeak] = ind2sub(size(c),imax(1));
            corr_offset = [(xpeak-size(MOVING,2)) 
                           (ypeak-size(MOVING,1))];
        
            % total offset
            translationX = -corr_offset(1);
            translationY = -corr_offset(2);
        
            tform = transltform2d(translationX,translationY);

        case 'Intensity'
            % Default spatial referencing objects
            fixedRefObj = imref2d(size(FIXED));
            movingRefObj = imref2d(size(MOVING));
    
            % Intensity-based registration
            [optimizer, metric] = imregconfig('monomodal');
            optimizer.GradientMagnitudeTolerance = 1.00000e-04;
            optimizer.MinimumStepLength = 1.00000e-03;
            optimizer.MaximumStepLength = 1.00000e-01;
            optimizer.MaximumIterations = 1000;
            optimizer.RelaxationFactor = 0.200000;
    
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
    
            % tform

    end
end

function runRegistration(fig)

    resetButtonPushed(fig)
    
    wb = uiprogressdlg(fig,'Title','Registrating plane ','Indeterminate','off');
    wb.Value = 0; 

    zstack = fig.UserData.zstack;
    ch = fig.UserData.ch;
    targetTimePoint = fig.UserData.targetTimePoint;

    

    %% Prepare z projections

    nTimePoints = size(zstack,4);

    % Calcultate z projections
    zProjections = uint16(zeros(size(zstack,1),size(zstack,2),nTimePoints));

    for currentTimePoint = 1:nTimePoints

        wb.Value = currentTimePoint/nTimePoints;
        wb.Message = 'Z projections... ';

        zProjections(:,:,currentTimePoint) = max(zstack(:,:,:,currentTimePoint,ch),[],3);
      
    end    

    %% Method of pairing target and registering time points
    tragetDropDownH = findobj(fig,'Tag','targetTimePoint');
    targetMethod = tragetDropDownH.Value;

     % create vector to pair target and resgistrating time points
    switch targetMethod
        
        case 'first'

            TPvect = ones(1,nTimePoints);
            toPrevious = 0;

        case 'previous'

            TPvect = (1:nTimePoints)-1;
            toPrevious = 1;

    end

    %% Estimate drift
    
    resizeFactor = 2;
    % FIXED = imresize(zProjections(:,:,targetTimePoint),1/resizeFactor);
    tforms = cell(1,nTimePoints);

    sliderH = findobj(fig,'Tag','sensSlider');
    sigma = sliderH.Value;

    methodH = findobj(fig,'Tag','regMethod');
    method = methodH.Value;

    % set zero shift for target timePoint
    tforms{targetTimePoint} = transltform2d(0,0);
    

    temp = zProjections;
    FIXED_ = zProjections(:,:,targetTimePoint);

    driftVect = fig.UserData.driftVect;


    for currentTimePoint = 2:nTimePoints

        targetTimePoint = TPvect(currentTimePoint);

        disp(['Registering TP ' num2str(currentTimePoint) ' to TP ' num2str(targetTimePoint)])

        wb.Value = currentTimePoint/nTimePoints;
        % wb.Message = ['Registrating time point ' num2str(currentTimePoint)];
        wb.Message = ['Registering TP ' num2str(currentTimePoint) ' to TP ' num2str(targetTimePoint)];
        FIXED = imresize(temp(:,:,targetTimePoint),1/resizeFactor);
        MOVING = imresize(temp(:,:,currentTimePoint),1/resizeFactor);

        tform = preRegister(FIXED, MOVING, sigma, method);

        tforms{currentTimePoint} = tform;
        
        tform.A = round(tform.A);
        % temp(:,:,currentTimePoint) = imwarp(temp(:,:,currentTimePoint),tform,"OutputView",imref2d(size(FIXED_)));

        xt = tform.Translation(1);
        yt = tform.Translation(2);

        % adding zero z component;
        zt = 0;

        driftVect{currentTimePoint} = [xt,yt,zt];

    end

    fig.UserData.driftVect = driftVect;

    %% Calculate Crop area
    i = 1;

    wb.Message = 'Crop area... ';

    
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
    cropRect2D = [x0 y0 xsize-x0+xt ysize-y0+yt]

    xCropOffset = cropRect2D(1);
    yCropOffset = cropRect2D(2);

    % driftVect

    fig.UserData.cropRect2D = cropRect2D;


    wb.Message = 'Preview results... ';
    %% Apply tform to zProjections and plot result
    zProjectionsRegistered = zProjections;

    
    transSum = tforms{1}.Translation;
    finalTforms = tforms;

    for currentTimePoint = 2:nTimePoints

        % wb.Value = 0; 
        % wb.Message = ['Registrating time point ' num2str(currentTimePoint)];

        % creare trsnformation matrix based on targeting method
        if toPrevious
                    
            % sum translations from previous time points and 
            transSum = transSum + tforms{currentTimePoint}.Translation;
            
            %create new transformation matrix                
            tform = transltform2d(transSum(1),transSum(2));

        else

           tform = tforms{currentTimePoint};

        end


        finalTforms{currentTimePoint} = tform;

        zProjectionsRegistered(:,:,currentTimePoint) = imwarp(zProjections(:,:,currentTimePoint),tform,"OutputView",imref2d(size(FIXED_)));

    end

    

    % zProjectionsRegistered = temp;

    fig.UserData.tforms = finalTforms;
    fig.UserData.zProjectionsRegistered = zProjectionsRegistered;

    updatePlot(fig)  

    disp('done')

    close(wb)

end


function acceptButtonPushed(fig)

    targetTimePoint = fig.UserData.targetTimePoint;

    wb = uiprogressdlg(fig,'Title','Processing... ','Indeterminate','on');

    zstack = fig.UserData.zstack;
    % ch = fig.UserData.ch;
    tforms = fig.UserData.tforms;

    nTimePoints = size(zstack,4);
    nPlanes = size(zstack,3);
    nChannels = size(zstack,5);

    zProjections = fig.UserData.zProjections;
    cropRect2D = fig.UserData.cropRect2D;

    FIXED_ = zProjections(:,:,targetTimePoint);
    
    %% Register all planes
    
    wb.Message = 'Registering...';
    
    registeredZstack = zstack;

    for currentTimePoint = 1:nTimePoints   
    
        tform = tforms{currentTimePoint};
        movingZstack = zstack(:,:,:,currentTimePoint,:);
        movingRegistered = imwarp(movingZstack,tform,"OutputView",imref2d(size(FIXED_)));
        registeredZstack(:,:,:,currentTimePoint,:) = movingRegistered;

        xt = tform.Translation(1);
        yt = tform.Translation(2);

        % adding zero z component;
        zt = 0;

        driftVect{currentTimePoint} = [xt,yt,zt];

    end

    fig.UserData.driftVect = driftVect;
         
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

    fig.UserData.registeredZstack = registeredZstack;
    fig.UserData.driftVect = driftVect;
    
    disp('Registration done')

    close(wb)
    uiresume(fig)

end

function resetButtonPushed(fig)
    
    fig.UserData.zProjectionsRegistered = fig.UserData.zProjections;

    % 2D cropp rectangle for preview
    xsize = size(fig.UserData.zProjections,2);
    ysize = size(fig.UserData.zProjections,1);
    cropRect2D = [0 0 xsize ysize];

    fig.UserData.cropRect2D = cropRect2D;

    % reset the calculated drift correction
    zstack = fig.UserData.zstack;
    nTimePoints = size(zstack,4);
    for currentTimePoint = 1:nTimePoints
        driftVect{currentTimePoint} = [0,0,0];
    end
    fig.UserData.driftVect = driftVect;
  
    updatePlot(fig)

end

function updatePlot(fig)

    t = findobj(fig,'Tag','figLayout');
    delete(t.Children)
    

    % targetTimePoint = fig.UserData.targetTimePoint;

    zProjections = fig.UserData.zProjections;
    zProjectionsRegistered = fig.UserData.zProjectionsRegistered;
    zstack = fig.UserData.zstack;

    nTimePoints = size(zstack,4);

     % create vector to pair target and resgistrating time points
     tragetDropDownH = findobj(fig,'Tag','targetTimePoint');
    targetMethod = tragetDropDownH.Value;
    switch targetMethod
        
        case 'first'

            TPvect = ones(1,nTimePoints);
            % toPrevious = 0;

        case 'previous'

            TPvect = (1:nTimePoints)-1;
            % toPrevious = 1;

    end
    % TPvect = (1:nTimePoints)-1;
    
    allAx = [];

    cropRect2D = fig.UserData.cropRect2D;

    driftVect = fig.UserData.driftVect;
    
    for currentTimePoint = 2:nTimePoints

        targetTimePoint = TPvect(currentTimePoint);
       
        ax1 = nexttile(t);

        allAx = [allAx ax1];

        % orig = zProjections(:,:,targetTimePoint);
        orig = zProjectionsRegistered(:,:,targetTimePoint);
        registered = zProjectionsRegistered(:,:,currentTimePoint);
        
        registered = imadjust(registered);
        orig = imadjust(orig);

        imshowpair(orig,registered,"Scaling","joint","Parent",ax1)
        ax1.Title.String = ['Time point ' num2str(currentTimePoint) ' vs. ' num2str(targetTimePoint)];
        ax1.XLabel.String = ['correction [pix] = x: ' num2str(driftVect{currentTimePoint}(1)), ' , y: ' num2str(driftVect{currentTimePoint}(2))];


        roi = drawrectangle(ax1,'Position',cropRect2D,'Color','r','FaceAlpha',0.05);
        roi.InteractionsAllowed = 'none';
        addlistener(roi,'ROIMoved',@roiMoved);

    end

    linkaxes(allAx,'xy')

end

function cancelButtonPushed(fig)
    close(fig)
end

function roiMoved(src,evt)

    evt.CurrentPosition

end