% function creates concentric zones around defined polygone.
% author Stepan Kortus
% Version 1.1
% Last update 20.07.2022
% Version 1.0
% Last update 16.06.2022

% Example
% % define zones (distances from synaptic ROI)
% zone0_range = 0; % in nm
% zone1_range = 120;
% zone2_range = 250;
% circZone_range = 550;
% 
% zone0_range = zone0_range/1000;
% zone1_range = zone1_range/1000;
% zone2_range = zone2_range/1000;
% circZone_range = circZone_range/1000;
% 
% zoneRanges = [zone0_range zone1_range zone2_range circZone_range];
% 
% % recreate reference ROI
% ref_points = T.nearestRef{tr};
% 
% zones = makeZones(ref_points,zoneRanges);


function zones = makeZones(ref_points,zoneRanges)

    zone0_range = zoneRanges(1);
    zone1_range = zoneRanges(2);
    zone2_range = zoneRanges(3);
    zone3_range = zoneRanges(4);

    refROI = polyshape(ref_points,'Simplify',false);
    refROI = simplify(refROI);
        
        %% zone0 based on refZone (homer)
        
    if zone0_range > 0

        xy = ref_points;
        xy_shifted =  circshift(xy,5,1);

        % create two polyshapes, one with shifted joint point   
        poly_tempA = polybuffer(xy,'lines',zone0_range,'JointType','square');
        poly_tempB = polybuffer(xy_shifted,'lines',zone0_range,'JointType','square');

        % merge two polyshapes to one and get rid of the joint hole
        poly_temp = union(poly_tempB,poly_tempA);
        zone0_ROI = rmholes(poly_temp);

    else

        zone0_ROI = refROI;

    end


    %% zone1 
   
    if zone1_range > 0
        
        xy = ref_points;
        xy_shifted =  circshift(xy,5,1);
        
        % create two polyshapes, one with shifted joint point   
        poly_tempA = polybuffer(xy,'lines',zone1_range,'JointType','square');
        poly_tempB = polybuffer(xy_shifted,'lines',zone1_range,'JointType','square');
    
        % merge two polyshapes to one and get rid of the joint hole
        poly_temp = union(poly_tempB,poly_tempA);
        poly_temp = rmholes(poly_temp);
    
        zone1_ROI = subtract(poly_temp,zone0_ROI);
    else
        zone1_ROI = [];
    end

    %% zone2

    if zone2_range > 0

        % create two polyshapes, one with shifted joint point   
        poly_tempA = polybuffer(xy,'lines',zone2_range,'JointType','square');
        poly_tempB = polybuffer(xy_shifted,'lines',zone2_range,'JointType','square');
    
        % merge two polyshapes to one and get rid of the joint hole
        poly_temp = union(poly_tempB,poly_tempA);
        poly_temp = rmholes(poly_temp);
    
        poly_temp = subtract(poly_temp,zone0_ROI);
    
        zone2_ROI = subtract(poly_temp,zone1_ROI);
    else
        zone2_ROI = [];
    end

    %% Zone3 - from centre

    centre = mean(xy);
    radius = zone3_range;
    n = 100;

    theta = (0:n-1)*(2*pi/n);
    x = centre(1) + radius*cos(theta);
    y = centre(2) + radius*sin(theta);
    CircleRoi = polyshape(x,y);


    % Output
    zones{1} = zone0_ROI;
    zones{2} = zone1_ROI;
    zones{3} = zone2_ROI;
    zones{4} = CircleRoi;

end
