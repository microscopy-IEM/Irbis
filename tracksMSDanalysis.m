function [tracks] = tracksMSDanalysis(tracks,currentTimePoint)

T = tracks.tracksList{currentTimePoint};

% default parameters
conf_thres = 0.7;

% number of fitting points
fit_points = 5;
% fit_points = 0.25;

%% Prepare format of trajectories for MSDanalyzer tool
coordinates = T.xyz;
frame_indexes = T.frame_i;

% default parameteres
dt = round(tracks.frameInterval{currentTimePoint},3);

% pixel_size = TRS.info.pixel_size;
pixel_size = 1;

% get ids of tracks to be analyzed
% ids = T.id;

ids = 1:height(T);


% format trajectories for MSDtool
for i = 1:numel(ids)

    tr = ids(i);
    ind = ~isnan(coordinates{tr}(:,1));
       
    time_vect = (frame_indexes{tr}(ind)).*dt;
    TRStrack = coordinates{tr}(ind,1:2)./pixel_size;
    
    time_vect = time_vect - time_vect(1);
    
    TRStracks{i,1} = [time_vect, TRStrack];
        
end


%% MSDanalyzer part

% initiate MSD tool 
ma = msdanalyzer(2, 'um', 's');

% add tracks
ma = ma.addAll(TRStracks);

% compute MSD
ma = ma.computeMSD;

% linear fit of first n points of the MSD curve
ma = ma.fitMSD(fit_points);

% % calculate velocities 
% v = ma.getVelocities; %#ok<NOPTS>
% 
% ma = ma.computeVCorr;
% % v_ = ma.vcorr
% vcorr = ma.vcorr;

% v = [];
% for i = 1:size(vcorr,1)
% 
%     % v{i} = mean(vcorr{i}(6:end,2),'omitmissing');
%     v(i) = mean(vcorr{i}(6:15,2),'omitmissing');
% 
% end

% v(isnan)

% 
% assignin("base","v",v)
% assignin("base","v_",v_)
% assignin("base","ma",ma)

% Select well fitted tajectories and calculate mean D
good_enough_fit = ma.lfit.r2fit > conf_thres;
Dmean = mean( ma.lfit.a(good_enough_fit) ) / 2 / ma.n_dim;
Dstd  =  std( ma.lfit.a(good_enough_fit) ) / 2 / ma.n_dim;

%% Output

MSD.DC.DCmean = Dmean;
MSD.DC.SCstd = Dstd;
MSD.allMSD = ma.msd;
MSD.MSD5 = ma.lfit.a;
MSD.MSD5_r2 = ma.lfit.r2fit;
MSD.ma = ma;

% save complete MSD analysis 
% tracks.MSD = MSD;

% add crucial numbers to tracksList
T.MSD5(ids) = MSD.MSD5;
T.MSDr2(ids) = MSD.MSD5_r2;
T.MSDcurve(ids) = ma.msd;
% T.Velocity(ids) = [];

% T.newVelocity(ids) = v;

tracks.tracksList{currentTimePoint} = T;

end



