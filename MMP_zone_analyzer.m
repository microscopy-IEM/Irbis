% Script imports data from MMP_app batch processing and clasiffy
% trajectories into user defined zones

clc; close all; clear all

%% Select data

% filename = 'MMP_results_2A2B3A_rat.mat'


% filename = 'MMP_results_QD_probes_rat.mat'
% filename = 'MMP_results_2A2B3A_mice_cre_r1.mat'

% filename = 'MMP_results_2A2B3A_mice_cre_r2.mat'

% filename = 'MMP_results_2A2B3A_mice_cre_r2_complete2.mat'
% filename = 'MMP_results_2A2B3A_mice_cre_r2_complete3.mat'

filename  = 'MMP_results_QD_probes_rat_R2.mat'


%% Import data

[filepath,name,ext] = fileparts(filename);

savename = [name '_edited.mat'];

MMP_results = importdata(filename);



%% define zones (distances from synaptic ROI)
zone0_range = 0;        % in nm
zone1_range = 120;      % in nm
zone2_range = 500;      % in nm
circZone_range = 550;   % in nm

minZonePerc = 0.35;

% converrt to um
zone0_range = zone0_range/1000;
zone1_range = zone1_range/1000;
zone2_range = zone2_range/1000;
circZone_range = circZone_range/1000;

% sort zonse to vector
zoneRanges = [zone0_range zone1_range zone2_range circZone_range];


% create emtpy variable
alldist2zone0 = [];


T = MMP_results.T;

% Correct for systematic error of all localizations shifted by half size of
% the pixel
% Pixel shift correction !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

pixelSize = 0.08;  % um
corr = 0.5*pixelSize;
%_________________________________________________________________________

for cond = 1:size(MMP_results.groupNames,1)

    actualGroup = MMP_results.groupNames{cond}

    ids = (MMP_results.T.group == actualGroup);
    ids_ = find(prod(ids,2) == 1);

    alldist2zone0 = [];
        
    
    for tr = ids_' %1:size(T,1)
    

        % recreate reference ROI
        ref_points = T.nearestRef{tr};

        zones = makeZones(ref_points,zoneRanges);

        zone0_ROI = zones{1};
        zone1_ROI = zones{2};
        zone2_ROI = zones{3};
        circle_ROI = zones{4};

        % refROI stats
        refROI = polyshape(ref_points,'Simplify',false);
        refROI = simplify(refROI);
        
        [ROI_centre(1),ROI_centre(2)] = centroid(refROI);
        ROI_area = area(refROI);
        ROI_perim = perimeter(refROI);
        ROI_circularity = 4*pi*ROI_area/ROI_perim^2;
        ROI_zones = [zone0_range zone1_range zone2_range]; 

        dist2refCentre = pdist2([T.meanX(tr),T.meanY(tr)],[ROI_centre(1),ROI_centre(2)]);

   
        %% Measure percentual appearance in defined zones       

        % Asign localization to variable and correct for pixel shift
        xpoints = T.xyz{tr}(:,1) + corr;
        ypoints = T.xyz{tr}(:,2) + corr;

        % calculate number of (non empty) localizations in trajectory
        nOfPoints = sum(~isnan(xpoints));

        inZone = cell(1,3);
        zonePercentages = nan(1,4);

        for zone_n = 1:3
            
            inZone{zone_n} = inpolygon(xpoints,ypoints,zones{zone_n}.Vertices(:,1),zones{zone_n}.Vertices(:,2));
            zonePercentages(zone_n) = sum(inZone{zone_n})/nOfPoints;

        end

        % all other localization into zone 4
        zonePercentages(4) = 1 - sum(zonePercentages,'omitnan');

        % circle roi (measured form centre of synapse)
        inZoneCirc = inpolygon(xpoints,ypoints,zones{4}.Vertices(:,1),zones{4}.Vertices(:,2));

        circZonePerc(1) = sum(inZoneCirc)/nOfPoints;
        circZonePerc(2) = 1 - circZonePerc(1);


        %% Clasiffy localizations into zones  

        % Define minimal percentage to asign localization into given zone
        % To asign trajectory into zone, it must have the highest percentage of localizations in the zone and also must have at least minZonePerc
        

        % get index if zone with highrst percentage of localizations
         [~,mxi] = max(zonePercentages);

         if mxi == 1 && zonePercentages(1) > minZonePerc
            
            T.zone(tr) = 0;
            T.type(tr) = 'syn';

        elseif mxi == 2 && zonePercentages(2) > minZonePerc

            T.zone(tr) = 1;
            T.type(tr) = 'per';

        elseif mxi == 3 && zonePercentages(3) > minZonePerc
            
            T.zone(tr) = 2;
            T.type(tr) = 'ext';

         elseif zonePercentages(4) > minZonePerc
            
            T.zone(tr) = 3;
            T.type(tr) = 'srf';

         else
            
            T.zone(tr) = nan;
            T.type(tr) = 'nan';

        end



        
        %% Measure distance of all positions to edge of synapse 
        
%         xpoints = T.xyz{tr}(:,1) + corr;
%         ypoints = T.xyz{tr}(:,2) + corr;

        xv = zone0_ROI.Vertices(:,1);
        yv = zone0_ROI.Vertices(:,2);

        dist2zone0edge = [];
        inoutVector = dist2zone0edge;
        
        for i = 1:length(xpoints)
        
            [dist2zone0edge(i),x_poly,y_poly] = p_poly_dist(xpoints(i), ypoints(i), xv, yv);

            
            % create a vector of 1 when insize zone and 0 when outside for
            % each trajectory 

            if dist2zone0edge(i)>0
                    
                inoutVector(i) = 0;

            elseif dist2zone0edge(i) <= 0
                    
                inoutVector(i) = 1;

            else
                     
                inoutVector(i) = nan;

            end

        end

        

        alldist2zone0 = [alldist2zone0 dist2zone0edge];

        %% Add stats to table
        
        T.zone0InOutVect(tr) = {inoutVector'};
        T.ditt2refCentre(tr) = dist2refCentre;
        T.zonePerc{tr} = zonePercentages;
        T.circZonePerc(tr) = circZonePerc(1);
        T.ROI_area(tr) = ROI_area;
        T.ROI_perim(tr) = ROI_perim;
        T.ROI_circularity(tr) = ROI_circularity;
        T.dist2zone0edge{tr} = dist2zone0edge';
             


        %% PLOTs

% 
%         figure
%         plot(zone0_ROI,'FaceColor','r','FaceAlpha',0.4)
%         hold on
%         plot(zone1_ROI,'FaceColor',[0.4660 0.6740 0.1880],'FaceAlpha',0.7)
%         plot(zone2_ROI,'FaceColor',[0.3010 0.7450 0.9330],'FaceAlpha',0.6)
%         hold on
%         axis equal
% 
%         plot(xpoints(inZone1),ypoints(inZone1),'+g')
%         plot(xpoints(~inZone1),ypoints(~inZone1),'+b')
% 
%         legend('zone0 (+0nm)','zone1 (+100nm)','zone2 (+500nm)','trajectory')
% 
%         
% 
%         figure
%         [N,~] = histcounts(dist2zone0,'BinWidth',0.005);
%         histMax = max(N)*1.2;
%         xmin = -0.25;
% 
%         x = [xmin 0 0 xmin];
%         y = [0 0 histMax histMax];
%         patch(x,y,[0.8500 0.3250 0.0980],'FaceAlpha',.4)
% 
%         x = [0 zone1_range zone1_range 0];
%         y = [0 0 histMax histMax];
%         patch(x,y,[0.4660 0.6740 0.1880],'FaceAlpha',.4)
% 
%         x = [zone1_range zone2_range zone2_range zone1_range];
%         y = [0 0 histMax histMax];
%         patch(x,y,[0 0.4470 0.7410],'FaceAlpha',.4)
% 
%         hold on
% 
%         histogram(dist2zone0,'BinWidth',0.005,'FaceColor',[0.2 0.2 0.2],'FaceAlpha',0.8)
%         xlim([xmin 0.5])
%         ylim([0,histMax])
% 
%         hold on
%         legend('zone0','zone1','zone2','positions')


        
    end
    
    if cond == 1

        figure(5)
        [N,edges] = histcounts(alldist2zone0,'BinWidth',0.005);
        histMax = max(N)*2;
        xmin = -0.25;

        x = [xmin 0 0 xmin];
        y = [0 0 histMax histMax];
        patch(x,y,[0.8500 0.3250 0.0980],'FaceAlpha',.4)

        x = [0 zone1_range zone1_range 0];
        y = [0 0 histMax histMax];
        patch(x,y,[0.4660 0.6740 0.1880],'FaceAlpha',.4)

        x = [zone1_range zone2_range zone2_range zone1_range];
        y = [0 0 histMax histMax];
        patch(x,y,[0 0.4470 0.7410],'FaceAlpha',.4)

        xlim([xmin 2])
        ylim([0,histMax])
    end

%     figure(5)
        hold on

%         histogram(alldist2zone0,'BinWidth',0.005,'FaceColor',[0.2 0.2 0.2],'FaceAlpha',0.8)

        histogram(alldist2zone0,'BinWidth',0.005)
        

        legend('zone0','zone1','zone2','positions')

end

MMP_results.zoneRanges = zoneRanges;
MMP_results.T_edited = T;

save(savename,"MMP_results")




