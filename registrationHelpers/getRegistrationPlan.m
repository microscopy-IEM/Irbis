function registrationPlan = getRegistrationPlan(nTimePoints, referenceMode, selectedTimePoint)
    %GETREGISTRATIONPLAN Build moving/reference timepoint pairs for drift registration.
    %
    % Outputs a struct with:
    %   defaultTimePoint    - the fixed reference point used for the non-Previous modes
    %   movingTimePoints    - time points that should be registered
    %   referenceTimePoints - matching reference time points for each moving time point

    arguments
        nTimePoints (1,1) double {mustBeInteger, mustBePositive}
        referenceMode
        selectedTimePoint = []
    end

    referenceMode = string(referenceMode);
    isReferenceChanging = false;

    switch referenceMode
        case "First"
            defaultTimePoint = 1;
            movingTimePoints = setdiff(1:nTimePoints, defaultTimePoint);
            referenceTimePoints = repmat(defaultTimePoint, size(movingTimePoints));

        case "Last"
            defaultTimePoint = nTimePoints;
            movingTimePoints = setdiff(1:nTimePoints, defaultTimePoint);
            referenceTimePoints = repmat(defaultTimePoint, size(movingTimePoints));

        case "Current"
            defaultTimePoint = selectedTimePoint;
            movingTimePoints = setdiff(1:nTimePoints, defaultTimePoint);
            referenceTimePoints = repmat(defaultTimePoint, size(movingTimePoints));

        case "Previous"
            defaultTimePoint = 1;
            movingTimePoints = 2:nTimePoints;
            referenceTimePoints = movingTimePoints - 1;
            isReferenceChanging = true;

        otherwise
            error('getRegistrationPlan:UnsupportedReferenceMode', 'Unsupported reference mode: %s', referenceMode);
    end

    if defaultTimePoint < 1 || defaultTimePoint > nTimePoints || defaultTimePoint ~= fix(defaultTimePoint)
        error('getRegistrationPlan:InvalidReferenceTimePoint', 'The selected reference time point is out of range.');
    end

    registrationPlan = struct();
    registrationPlan.defaultTimePoint = defaultTimePoint;
    registrationPlan.movingTimePoints = movingTimePoints;
    registrationPlan.referenceTimePoints = referenceTimePoints;
    registrationPlan.referenceMode = referenceMode;
    registrationPlan.isReferenceChanging = isReferenceChanging;
end