function [tracks] = MMP_MSD_analysis(tracks)

% default parameters
conf_thres = 0.7;

% number of fitting points
% fit_points = 5;
fit_points = 0.25;

%% Prepare format of trajectories for MSDanalyzer tool
coordinates = tracks.tracksList.xyz;
frame_indexes = tracks.tracksList.frame_i;

% default parameteres
dt = round(tracks.frame_interval,3);

% pixel_size = TRS.info.pixel_size;
pixel_size = 1;

% get ids of tracks to be analyzed
ids = tracks.ids;


% format trajectories for MSDtool
for i = 1:size(ids,2)

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
tracks.tracksList.MSD5(ids) = tracks.MSD.MSD5;
tracks.tracksList.MSDr2(ids) = MSD.MSD5_r2;
tracks.tracksList.MSDcurve(ids) = ma.msd;

end



