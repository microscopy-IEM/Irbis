function singleTrackMSD(tracks,tr)

% default parameters
conf_thres = 0.7;
fit_points = 10;

coordinates = tracks.tracksList.xyz;
frame_indexes = tracks.tracksList.frame_i;

% default parameteres
dt = round(tracks.frame_interval,3);

% pixel_size = TRS.info.pixel_size;
pixel_size = 1;

% 
% T = tracks.tracksList;




% format trajectories for MSDtool

    ind = ~isnan(coordinates{tr}(:,1));
       
    time_vect = (frame_indexes{tr}(ind)).*dt;
    TRStrack = coordinates{tr}(ind,1:2)./pixel_size;
    
    time_vect = time_vect - time_vect(1);
    
    TRStracks{1,1} = [time_vect, TRStrack];
        


%% MSDtool part

% initiate MSD tool 
ma = msdanalyzer(2, 'um', 's');

ma = ma.addAll(TRStracks);

ma = ma.computeMSD;

ma = ma.fitMSD(fit_points);

good_enough_fit = ma.lfit.r2fit > conf_thres;
Dmean = mean( ma.lfit.a(good_enough_fit) ) / 2 / ma.n_dim;
Dstd  =  std( ma.lfit.a(good_enough_fit) ) / 2 / ma.n_dim;

%% Output




disp("single track msd")

figure(17)
axis image
cla
ma.plotTracks;

figure(18)
ma.plotMSD;


cla
ma.plotMeanMSD(gca, true)

mmsd = ma.getMeanMSD;
t = mmsd(:,1);
x = mmsd(:,2);
dx = mmsd(:,3) ./ sqrt(mmsd(:,4));
errorbar(t, x, dx, 'k')

% figure(19)
ma.labelPlotMSD;


fprintf('Estimation of the diffusion coefficient from linear fit of the MSD curves:\n')
fprintf('D = %.3g ± %.3g (mean ± std, N = %d)\n', ...
    Dmean, Dstd, sum(good_enough_fit));


ma.lfit

x = [0,60];

a = ma.lfit.a;
b = ma.lfit.b;

y = a.*x + b;

hold on
line(x,y)

end



