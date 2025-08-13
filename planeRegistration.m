%% Estimate ragistration tform
classdef planeRegistration < handle

properties
    zstack
    registeredZstack
    ch
    targetTimePoint = 1
    resizeFactor = 1

    reference = 'previous'
    sigma = 2
    registrationMethod = 'Cross-correlation'

    driftVect
    tforms
    zProjections
    zProjectionsRegistered
    cropRect2D

    GUIfig
    showWaitbar = false

end

    methods
        function [registeredZstack, driftVector] = run(obj, zstack, ch)
            % Main function, to be called when running the registration headless with default parameters
            obj.prepareParameters(zstack, ch);
            obj.runRegistration();
            obj.acceptButtonPushed();
            obj.processOutput();

            registeredZstack = obj.registeredZstack;
            driftVector = obj.driftVect;
        end


        function [registeredZstack, driftVector] = runGUI(obj, zstack, ch)
            % Main function, to be called when running the registration with GUI
            obj.generateGUI();
            obj.prepareParameters(zstack, ch);
            obj.updatePlot();
            uiwait(obj.GUIfig);

            obj.processOutput();
            if ~isvalid(obj.GUIfig)
                registeredZstack = [];
                driftVector = [];
                return
            end   

            close(obj.GUIfig);

            registeredZstack = obj.registeredZstack;
            driftVector = obj.driftVect;
        end


        function prepareParameters(obj, zstack, ch)
            % Prepare parameters
            obj.zstack = zstack;
            obj.ch = ch;

            % set target time point
            nTimePoints = size(zstack,4);
            obj.targetTimePoint = 1; % default first time point

            % set drift vector
            obj.driftVect = cell(1,nTimePoints);
            obj.driftVect(:) = {[0,0,0]};  

            obj.tforms = cell(1,nTimePoints);
            obj.tforms(:) = {transltform2d(0,0)};

            obj.zProjections = uint16(zeros(size(zstack,1),size(zstack,2),nTimePoints));
            
            for timePoint = 1:nTimePoints
                obj.zProjections(:,:,timePoint) = max(zstack(:,:,:,timePoint,ch),[],3);
            end

            obj.zProjectionsRegistered = obj.zProjections;

            xsize = size(obj.zProjections,2);
            ysize = size(obj.zProjections,1);
            obj.cropRect2D = [1 1 xsize-1 ysize-1];  

        end


        function processOutput(obj)
            
            % BUGFIX 250722 - added -1 - if there was no drift, the resulting drift was -1.
            xCropOffset = obj.cropRect2D(1) - 1;
            yCropOffset = obj.cropRect2D(2) - 1;
        
            nTimePoints = size(obj.zstack,4);
            for currentTimePoint = 1:nTimePoints
                
                obj.driftVect{currentTimePoint}(1) = obj.driftVect{currentTimePoint}(1) - xCropOffset;
                obj.driftVect{currentTimePoint}(2) = obj.driftVect{currentTimePoint}(2) - yCropOffset;

            end
        end


        function generateGUI(obj)
            h = findall(0, 'type', 'figure','Name','Estimate drift in planes');
            close(h)
            
            fig = uifigure("Name",'Estimate drift in planes','Position',[100 100 800 800],'Icon',[]);
            obj.GUIfig = fig;
            
            customGrid = uigridlayout(fig, [2 9]);
            customGrid.RowHeight = {'1x','fit'};
            customGrid.ColumnWidth = {'1x','fit','fit','fit','fit','fit','fit','fit','fit'};
            
            pan = uipanel(customGrid);
                
            t = tiledlayout(pan,'flow');
            t.Tag = 'figLayout';
            t.TileSpacing = 'tight';
            t.Padding = 'tight';
            
            pan.Layout.Row = 1;
            pan.Layout.Column = [1 9];

            referenceDropDown = uidropdown(customGrid,"Items",["first","previous"],'Tag','reference');
            referenceDropDown.ValueChangedFcn = @(~,~) obj.updatePlot();
            referenceDropDown.Value = obj.reference;
            referenceDropDown.Layout.Row = 2;
            referenceDropDown.Layout.Column =  2;
            
            sliderLabel = uilabel(customGrid,"Text","Sigma");
            sliderLabel.Layout.Row = 2;
            sliderLabel.Layout.Column = 3;
            
            sensSlider = uislider(customGrid,"ValueChangedFcn", @(src,~)obj.setSigma(src),'Tag','sensSlider');
            sensSlider.Limits = [0 10];
            sensSlider.MajorTicks = [];
            sensSlider.MinorTicks = [];
            sensSlider.Value = obj.sigma;
            sensSlider.Layout.Row = 2;
            sensSlider.Layout.Column = 4;
            
            registrationMethodDropDown = uidropdown(customGrid,"Items",["Cross-correlation","Intensity"],'Tag','regMethod');
            registrationMethodDropDown.ValueChangedFcn = @(src,~) obj.setRegistrationMethod(src);
            registrationMethodDropDown.Layout.Row = 2;
            registrationMethodDropDown.Layout.Column = 5;

            registb = uibutton(customGrid, ...
            "Text","Register", ...
            "ButtonPushedFcn", @(~,~) obj.runRegistration());
            registb.Layout.Row = 2;
            registb.Layout.Column = 6;

            resetb = uibutton(customGrid, ...
            "Text","Reset", ...
            "ButtonPushedFcn", @(~,~) obj.resetButtonPushed());
            resetb.Layout.Row = 2;
            resetb.Layout.Column = 7;
            
            applyb = uibutton(customGrid, ...
            "Text","Accept", ...
            "ButtonPushedFcn", @(~,~) obj.acceptButtonPushed());
            applyb.Layout.Row = 2;
            applyb.Layout.Column = 8;
            
            cancelb = uibutton(customGrid, ...
            "Text","Cancel", ...
            "ButtonPushedFcn", @(~,~) obj.cancelButtonPushed(fig));
            cancelb.Layout.Row = 2;
            cancelb.Layout.Column = 9;

            obj.showWaitbar = true;
        end



        function runRegistration(obj)

            if obj.showWaitbar
                wb = uiprogressdlg(obj.GUIfig,'Title','Registrating plane ','Indeterminate','off');
                wb.Value = 0; 
                obj.resetButtonPushed();
            end

            % Prepare z-projections
            nTimePoints = size(obj.zstack,4);

            % Calcultate z projections
            obj.zProjections = uint16(zeros(size(obj.zstack,1),size(obj.zstack,2),nTimePoints));

            for timePoint = 1:nTimePoints

                if obj.showWaitbar
                    wb.Value = timePoint/nTimePoints;
                    wb.Message = 'Z projections... ';
                end

                obj.zProjections(:,:,timePoint) = max(obj.zstack(:,:,:,timePoint,obj.ch),[],3);
            end    

            % Method of pairing target and registering time points
            % create vector to pair target and resgistrating time points
            switch obj.reference
                
                case 'first'
                    TPvect = ones(1,nTimePoints);
                    toPrevious = 0;

                case 'previous'
                    TPvect = (1:nTimePoints)-1;
                    toPrevious = 1;

                case 'specific'
                    specificTimePoint = 2;
                    TPvect = specificTimePoint.*ones(1,nTimePoints);
                    toPrevious = 0;

            end

            % Estimate drift

            % set zero shift for target timePoint
            obj.tforms = cell(1,nTimePoints);
            obj.tforms{obj.targetTimePoint} = transltform2d(0,0);

            temp = obj.zProjections;
            FIXED_ = obj.zProjections(:,:,obj.targetTimePoint);

            for timePoint = 2:nTimePoints

                currentTargetTimePoint = TPvect(timePoint);

                disp(['Registering TP ' num2str(timePoint) ' to TP ' num2str(currentTargetTimePoint)])

                if obj.showWaitbar
                    wb.Value = timePoint/nTimePoints;
                    wb.Message = ['Registering TP ' num2str(timePoint) ' to TP ' num2str(currentTargetTimePoint)];
                end

                FIXED = imresize(temp(:,:,currentTargetTimePoint),1/obj.resizeFactor);
                MOVING = imresize(temp(:,:,timePoint),1/obj.resizeFactor);

                tform = planeRegistration.preRegister(FIXED, MOVING, obj.sigma, obj.registrationMethod);
        
                % revert resizing
                tform.Translation(1) = tform.Translation(1)*obj.resizeFactor;
                tform.Translation(2) = tform.Translation(2)*obj.resizeFactor;

                % FIX better round after reverting the resizing step
                tform.A = round(tform.A); % allow only shifts by full pixel

                obj.tforms{timePoint} = tform;
            
                % xt = tform.Translation(1)*resizeFactor;
                % yt = tform.Translation(2)*resizeFactor;

                xt = tform.Translation(1);
                yt = tform.Translation(2);

                % adding zero z component;
                zt = 0;

                obj.driftVect{timePoint} = [xt,yt,zt];

            end

            % Calculate Crop area
            
            if obj.showWaitbar
                wb.Message = 'Crop area... ';
            end
            
            % find biggest shifts
            % for currentTimePoint = 2:nTimePoints
            xTranslations = zeros(1,nTimePoints);
            yTranslations = zeros(1,nTimePoints);

            for timePoint = 1:nTimePoints

                % revert resizing
                % tforms{currentTimePoint}.Translation(1) = tforms{currentTimePoint}.Translation(1)*resizeFactor;
                % tforms{currentTimePoint}.Translation(2) = tforms{currentTimePoint}.Translation(2)*resizeFactor;
                
                xTranslations(timePoint) = obj.tforms{timePoint}.Translation(1);
                yTranslations(timePoint) = obj.tforms{timePoint}.Translation(2);
                % i = i+1;

            end
        
            % Find cropping boundaries 

            % this works for first time point as a reference

            % BUGFIX 250806: there has to be +1 for x0 and y0, if there is some drift
            % example: 
                % if the max(xTranslations) = 1, then the unshifted reference timepoint will not be cropped at all,
                % because the xMin is included in the cropped area
                % however, the reference should be cropped by 1 pixel from the left, to match the other timepoint 
            if isequal(obj.reference,'first')
                if max(xTranslations) > 0
                    % x0 = ceil(max(xt));
                    x0 = 1 + max(xTranslations);     % ADDED +1
                else
                    x0 = 1;
                end
            
                if min(xTranslations) < 0
                    xt = min(xTranslations);
                else
                    xt = 0;
                end
            
                if max(yTranslations) > 0
                    % y0 = ceil(max(yt));
                    y0 = 1 + max(yTranslations);     % ADDED +1
                else
                    y0 = 1;
                end
            
                if min(yTranslations) < 0
                    yt = min(yTranslations);
                else
                    yt = 0;
                end

            % using previous time point as a reference requires looking at summed shift
            elseif isequal(obj.reference,'previous')
                xtPartialSum = cumsum(xTranslations);
                ytPartialSum = cumsum(yTranslations);

                if max(xtPartialSum) > 0
                    % x0 = ceil(max(xtPartialSum));
                    x0 = 1 + max(xtPartialSum);   % ADDED +1
                else
                    x0 = 1;
                end
            
                if min(xtPartialSum) < 0
                    xt = min(xtPartialSum);
                else
                    xt = 0;
                end
            
                if max(ytPartialSum) > 0
                    % y0 = ceil(max(ytPartialSum));
                    y0 = 1 + max(ytPartialSum);   % ADDED +1
                else
                    y0 = 1;
                end
            
                if min(ytPartialSum) < 0
                    yt = min(ytPartialSum);
                else
                    yt = 0;
                end
            end

            % 2D crop rectangle for preview
            xsize = size(obj.zstack,2);
            ysize = size(obj.zstack,1);
            obj.cropRect2D = [x0 y0 xsize-x0+xt ysize-y0+yt];    

            if obj.showWaitbar
                wb.Message = 'Preview results... ';
            end
            
            % Apply tform to zProjections and plot result
            obj.zProjectionsRegistered = obj.zProjections;
            
            transSum = obj.tforms{1}.Translation;
            finalTforms = obj.tforms;

            for timePoint = 2:nTimePoints

                % create transformation matrix based on targeting method
                if toPrevious
                            
                    % sum translations from previous time points and apply
                    transSum = transSum + obj.tforms{timePoint}.Translation;
                    
                    % create new transformation matrix                
                    tform = transltform2d(transSum(1),transSum(2));

                else

                    tform = obj.tforms{timePoint};
                end

                finalTforms{timePoint} = tform;        

                obj.zProjectionsRegistered(:,:,timePoint) = imwarp(obj.zProjections(:,:,timePoint),tform,"OutputView",imref2d(size(FIXED_)));

            end

            obj.tforms = finalTforms;

            if obj.showWaitbar
                obj.updatePlot();
                wb.Message = 'Registration finished (default parameters).';
                close(wb)
            end

        end



        function acceptButtonPushed(obj)

            if obj.showWaitbar
                wb = uiprogressdlg(obj.GUIfig,'Title','Processing... ','Indeterminate','on');
            end

            nTimePoints = size(obj.zstack,4);
            nPlanes = size(obj.zstack,3);
            nChannels = size(obj.zstack,5);

            FIXED_ = obj.zProjections(:,:,obj.targetTimePoint);
            
            % Register all planes
            
            if obj.showWaitbar
                wb.Message = 'Registering...';
            end
            
            obj.registeredZstack = obj.zstack;

            for currentTimePoint = 1:nTimePoints   
            
                tform = obj.tforms{currentTimePoint};
                movingZstack = obj.zstack(:,:,:,currentTimePoint,:);
                movingRegistered = imwarp(movingZstack,tform,"OutputView",imref2d(size(FIXED_)));
                obj.registeredZstack(:,:,:,currentTimePoint,:) = movingRegistered;

                xt = tform.Translation(1);
                yt = tform.Translation(2);

                % adding zero z component;
                zt = 0;

                obj.driftVect{currentTimePoint} = [xt,yt,zt];

            end

            % Cropping
            % [xmin ymin zmin width height depth]
            cropRect3D = [obj.cropRect2D(1) obj.cropRect2D(2) 1 obj.cropRect2D(3) obj.cropRect2D(4) nPlanes-1];
            initCrop = imcrop3(obj.registeredZstack(:,:,:,1,1), cropRect3D);
            registeredZstackCropped = uint16(zeros(size(initCrop,1),size(initCrop,2),size(initCrop,3),nTimePoints,nChannels));
            
            if obj.showWaitbar
                wb.Message = 'Cropping...';
            end

            for currentTimePoint = 1:nTimePoints
                for channel = 1:nChannels
            
                    temp = obj.registeredZstack(:,:,:,currentTimePoint,channel);
                    registeredZstackCropped(:,:,:,currentTimePoint,channel) = imcrop3(temp, cropRect3D);
            
                end
            
            end
            
            obj.registeredZstack = registeredZstackCropped;

            obj.registeredZstack = obj.registeredZstack;
            obj.driftVect = obj.driftVect;
            
            disp('Registration done')

            if obj.showWaitbar
                close(wb)
                uiresume(obj.GUIfig)
            end

        end


        function resetButtonPushed(obj)
            
            obj.zProjectionsRegistered = obj.zProjections;

            % 2D cropp rectangle for preview
            xsize = size(obj.zProjections,2);
            ysize = size(obj.zProjections,1);
            obj.cropRect2D = [1 1 xsize-1 ysize-1];

            % reset the calculated drift correction
            nTimePoints = size(obj.zstack,4);
            obj.driftVect = cell(1,nTimePoints);
            for currentTimePoint = 1:nTimePoints
                obj.driftVect{currentTimePoint} = [0,0,0];
            end

            obj.updatePlot()
        end


        function updatePlot(obj)

            referenceDropDown = findobj(obj.GUIfig,'Tag','reference');
            obj.reference = referenceDropDown.Value;

            t = findobj(obj.GUIfig,'Tag','figLayout');
            delete(t.Children)

            nTimePoints = size(obj.zstack,4);

            % create vector to pair target and resgistrating time points
            switch obj.reference
                
                case 'first'

                    TPvect = ones(1,nTimePoints);
                    % toPrevious = 0;

                case 'previous'

                    TPvect = (1:nTimePoints)-1;
                    % toPrevious = 1;

            end
            % TPvect = (1:nTimePoints)-1;
        
            cropRect2Dplot = obj.cropRect2D;
            
            % align edges of rectangle with edges of image pixels (applies only for
            % plotting, not for cropping)
            cropRect2Dplot(1) = cropRect2Dplot(1)-0.4;
            cropRect2Dplot(2) = cropRect2Dplot(2)-0.4;
            cropRect2Dplot(3) = cropRect2Dplot(3)+0.9;
            cropRect2Dplot(4) = cropRect2Dplot(4)+0.9;

            obj.driftVect = obj.driftVect;
            
            % tforms = obj.tforms;
            % transSum = tforms{1}.Translation;

            for currentTimePoint = 2:nTimePoints

                currentTargetTimePoint = TPvect(currentTimePoint);

                ax1 = nexttile(t);
                ax1.Interactions = [zoomInteraction panInteraction]; % enable only two interactions
                
                % orig = zProjections(:,:,targetTimePoint);
                orig = obj.zProjectionsRegistered(:,:,currentTargetTimePoint);
                registered = obj.zProjectionsRegistered(:,:,currentTimePoint);
                
                registered = imadjust(registered);
                orig = imadjust(orig);

                imshowpair(orig,registered,"Scaling","joint","Parent",ax1)
                ax1.Title.String = ['Time point ' num2str(currentTimePoint) ' vs. ' num2str(currentTargetTimePoint)];
                
                xDrift = obj.driftVect{currentTimePoint}(1);
                yDrift = obj.driftVect{currentTimePoint}(2);
                ax1.XLabel.String = ['correction [pix] = x: ' num2str(xDrift), ' , y: ' num2str(yDrift)];
                % ax1.XLabel.String = {['correction [pix] = x: ' num2str(xDrift), ' , y: ' num2str(yDrift)];['Total correction = x: ' num2str(transSum(1)) ' 0']};
                % ax1.XLabel.String = ['correction [pix] = x: ' num2str(xt), ' , y: ' num2str(yt)];
                
                roi = drawrectangle(ax1,'Position',cropRect2Dplot,'Color','r','FaceAlpha',0.05);
                roi.InteractionsAllowed = 'none';

            end
                
            allAx = t.Children;
            linkaxes(allAx,'xy')

        end


        function cancelButtonPushed(~, fig)
            close(fig)
        end


        function setSigma(obj, src)
            % Set sigma value from slider
            obj.sigma = src.Value;
        end


        function setReference(obj, src)
            % Set target method from dropdown
            obj.reference = src.Value;
        end


        function setRegistrationMethod(obj, src)
            % Set correlation method from dropdown
            obj.registrationMethod = src.Value;
        end

    end  % methods


    methods (Static)
        function tform = preRegister(FIXED, MOVING, sigma, method)

            FIXED = imgaussfilt(FIXED,sigma);
            MOVING = imgaussfilt(MOVING,sigma);

            switch method
                
                case 'Cross-correlation'
                    % Cross-correlation method
                    FIXED = imadjust(FIXED);
                    MOVING = imadjust(MOVING);
                
                    c = normxcorr2(FIXED,MOVING);
                
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
            
            end
        end
    end
end

