function [registeredZstack, driftVect] = registerPlanesDefault(zstack, ch)
    %REGISTERPLANESDEFAULT  Register all time-points of a 5-D stack.
    %
    %   [registeredZstack, driftVect] = registerPlanesDefault(zstack, ch)
    %
    %   INPUTS
    %     zstack   – 5-D array organised Y-X-Z-T-C (uint16 or single/double)
    %     ch       – index of the channel used to estimate the drift
    %
    %   OUTPUTS
    %     registeredZstack – zstack after XY-registration and automatic cropping
    %     driftVect        – 1×T cell array with [Δx Δy Δz] (pixels) **after**
    %                        cropping has been applied
    %
    %   Default parameters are identical to the GUI defaults of
    %   preRegisterPlanesFcn:
    %       • target reference  : previous time-point
    %       • registration mode : Cross-correlation
    %       • Gaussian σ        : 2  (pre-filtering)
    %       • resizeFactor      : 1  (no down-scaling, keeps logic simple)
    %
    %   Requires: Image Processing Toolbox  (imgaussfilt, imregtform, imwarp …)

    % -------------------------------------------------------------------------
    %% 1) Basic settings
    sigma        = 2;              % Gaussian pre-filter σ
    regMethod    = 'Cross-correlation';
    targetMethod = 'previous';     % 'first'  |  'previous'
    resizeFactor = 1;              % keep full resolution for clarity
    nT           = size(zstack, 4);
    nZ           = size(zstack, 3);
    nC           = size(zstack, 5);

    % -------------------------------------------------------------------------
    %% 2) Build Z-projections that will be aligned
    proj = zeros(size(zstack,1), size(zstack,2), nT, 'like', zstack);
    for t = 1:nT
        proj(:,:,t) = max(zstack(:,:,:,t,ch),[],3);  % MIP for speed & SNR
    end

    % -------------------------------------------------------------------------
    %% 3) Estimate transforms for each time-point
    tforms     = cell(1,nT);
    tforms{1}  = transltform2d(0,0);               % reference frame
    driftVect  = cell(1,nT); driftVect(:) = {[0 0 0]};

    for t = 2:nT
        % Choose reference (previous or first)
        if strcmp(targetMethod,'previous')
            refIdx = t-1;
        else
            refIdx = 1;
        end

        FIXED  = imresize(proj(:,:,refIdx), 1/resizeFactor);
        MOVING = imresize(proj(:,:,t     ), 1/resizeFactor);

        % --- registration of the pair ---------------------------------------
        tform = localPreRegister(FIXED, MOVING, sigma, regMethod);

        % store raw transform (still in down-scaled space if resizeFactor>1)
        tforms{t} = tform;
    end

    % -------------------------------------------------------------------------
    %% 4) Convert to **cumulative** transforms if we used the 'previous' scheme
    if strcmp(targetMethod,'previous')
        cumXY = [0 0];
        for t = 2:nT
            cumXY      = cumXY + tforms{t}.Translation;   % accumulate
            tforms{t}  = transltform2d(cumXY(1), cumXY(2));
        end
    end

    % -------------------------------------------------------------------------
    %% 5) Crop rectangle that is inside the FOV for every warped frame
    xsz = size(zstack,2); ysz = size(zstack,1);
    allDx = cellfun(@(tf) tf.Translation(1)*resizeFactor, tforms); % px in full res
    allDy = cellfun(@(tf) tf.Translation(2)*resizeFactor, tforms);

    x0 = max( ceil( max(allDx) ), 1);         % left margin to keep inside FOV
    xN = min( floor( min(allDx) ), 0);        % right “negative” margin
    y0 = max( ceil( max(allDy) ), 1);
    yN = min( floor( min(allDy) ), 0);

    cropRect2D = [ x0 , y0 , xsz - x0 + xN , ysz - y0 + yN ];   % [xmin ymin w h]

    % -------------------------------------------------------------------------
    %% 6) Apply transforms to the full 5-D stack
    registeredZstack = zeros( cropRect2D(4)+1 , cropRect2D(3)+1 , ...
                            nZ , nT , nC , 'like', zstack );

    for t = 1:nT
        tf = tforms{t};

        % imwarp the whole (Y-X-Z-C) block of the current time-point
        moved = imwarp( zstack(:,:,:,t,:) , tf , ...
                        "OutputView", imref2d([ysz xsz]) );

        % Crop to the common area
        roi   = imcrop3( moved , [cropRect2D(1) cropRect2D(2) 1 ...
                                cropRect2D(3) cropRect2D(4) nZ-1] );
        registeredZstack(:,:,:,t,:) = roi;

        xCropOffset = cropRect2D(1) - 1;    % -1 because the rectangle is 1-based, but if there is no drift, the offset should be 0
        yCropOffset = cropRect2D(2) - 1;

        % Store drift after cropping correction
        driftVect{t} = [ tf.Translation(1) - xCropOffset, ...
                        tf.Translation(2) - yCropOffset, ...
                        0 ];
    end

    disp('Registration finished (default parameters).');

end  % --------------------------------------------------------------------
%                                                                         %
%                       ---  Helper function  ---                         %
%                                                                         %
% ------------------------------------------------------------------------
function tform = localPreRegister(FIXED, MOVING, sigma, method)
    % A compact version of the original preRegister() that supports the
    % two default modes: 'Cross-correlation' (default) and 'Intensity'.

    % Light Gaussian smoothing improves SNR
    FIXED  = imgaussfilt(FIXED , sigma);
    MOVING = imgaussfilt(MOVING, sigma);

    switch method
        case 'Cross-correlation'          % --- fast, translation-only
            % Normalised cross-corr. between equal-sized images
            c      = normxcorr2(imadjust(FIXED), imadjust(MOVING));
            [~,im] = max(abs(c(:)));
            [y,x]  = ind2sub(size(c), im);
            offs   = [ (x-size(MOVING,2)) , (y-size(MOVING,1)) ];
            tform  = transltform2d(-offs(1), -offs(2));

        case 'Intensity'                  % --- slower but more robust
            [opt,metric] = imregconfig('monomodal');
            opt.MaximumIterations = 1000;
            tform = imregtform(MOVING, FIXED, 'translation', opt, metric, ...
                            'PyramidLevels',4);
        otherwise
            error('Unknown registration method: %s', method);
    end
end
