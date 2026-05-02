function [tform, movingRegisteredCloud, driftVector] = registerPointClouds(fixedCloud, movingCloud, options)
    %REGISTERPOINTCLOUDS Register two point clouds (already downsampled) and return the rigid transform.
    %
    % Inputs:
    %   fixedCloud  - point cloud object representing the fixed reference
    %   movingCloud - point cloud object representing the moving point cloud
    %   options    - optional registration settings
    %
    % Outputs:
    %   tform                 - rigid transform from moving to fixed
    %   movingRegisteredCloud - moving point cloud transformed into fixed space
    %   driftVector           - translation component of the transform

    arguments
        fixedCloud
        movingCloud
        options.registrationMethod (1,:) char {mustBeMember(options.registrationMethod, {'ndt', 'icp'})} = 'ndt'
        options.gridStep (1,1) double {mustBePositive} = 1
    end

    switch lower(options.registrationMethod)
        case 'ndt'
            tform = pcregisterndt(movingCloud, fixedCloud, options.gridStep);
        case 'icp'
            tform = pcregistericp(movingCloud, fixedCloud);
    end

    movingRegisteredCloud = pctransform(movingCloud, tform);
    driftVector = tform.Translation;
end
