
function [tracks] = tracksProcessing(tracks,currentTimePoint)

    T = tracks.tracksList{currentTimePoint};
    
    % calculate length of each trajectory
    lengthsOfTrajectories = cell2mat(cellfun(@size, T.xyz, 'UniformOutput', false));
    lengthsOfTrajectories = lengthsOfTrajectories(:,1);

    % T.xyz
    % array = T.xyz{1}
    % array(:,1:2)


    nOfTracks = height(T);

     for TrackNum = 1:nOfTracks
    
        % length of trajectory
        TrLength = lengthsOfTrajectories(TrackNum);
        
        % get coordinates
        coor_nan = T.xyz{TrackNum};
        % coor_nan = coor_nan(:,1:2);

        coor_nan = coor_nan(:,1:3);
        
        % count Nan values
        Nan_values = (isnan(coor_nan(:,1)))'; % find NaN values
        nOfNaN = sum(Nan_values); % num of nan in trajectory
        
        % gap analysis
        valid_frame_ind = T.frame_i{TrackNum};
        valid_frame_ind = valid_frame_ind(~Nan_values);
        
        TrDuration = valid_frame_ind(end)-valid_frame_ind(1)+1;
        
        gaps = diff(valid_frame_ind)-1;
        gap_ind = find(gaps > 0);
        gap_lengths = gaps(gap_ind);
    
        if isempty(gap_lengths)
            gap_lengths = 0;
        end
    
        % find the longest gap
        if nOfNaN == 0
            maxGap = 0; % num of missing frames in longest gap
            % numOfGaps = 0; % number of gaps    
        else
            maxGap = max(gap_lengths); % num of missing frames in longest gap
            % numOfGaps = size(gap_ind,1);
        end
           
    
        % tracks witnout NaN
        coor = coor_nan(~isnan(coor_nan(:,1)),:);
        
         % calculate overall velocity
        if size(coor,1) >= 10
           % size(coor)
           % coor
            beginning = mean(coor(1:3,:));
            ending = mean(coor(end-4:end,:),'omitnan');

            ovDist = sqrt(sum((beginning - ending).^2,2));
        else
            ovDist = nan;
        end
        
        % calculate mean displacement
                  
        disp = sqrt(sum(diff(coor).^2,2));

        
        
        mean_disp = mean(disp);  
        
        
        disp = sqrt(sum(diff(coor_nan).^2,2));

        % calculate cumulative distance to origin
        % dist2origin = cumsum(disp);

        D = pdist(coor);
        Z = squareform(D);
        temp = Z(:,1);
        
        dist2origin(:,1) = 1:length(temp);
        dist2origin(:,2) = temp


        % calculate instanetaneous velocity
        dT = tracks.frameInterval{1};
        % w = 10;
        % velocity = movmean(disp,w,'omitnan')/dT;          
        % 
        % % calculate mean velocity
        % mean_vel = mean(velocity,'omitnan');

        delay = 15;

        if size(coor,1) >= delay + 2

            for i = 1:length(coor)-delay
    
                idx = [i,i+delay];
            
                disp(i) = sqrt(sum(diff(coor(idx,:)).^2,2));
                
            end
    
            velocity = disp/(delay*dT);
            mean_vel = mean(velocity,'omitnan');
        else

            % beginning = coor(1,:);
            % ending = mean(coor(end,:),'omitnan');

            mean_vel = 0;
            velocity = 0;

        end
        
        % 2D area
        [~,area] = boundary(coor(:,1),coor(:,2));
                
        % XY centres
        XYmean(TrackNum,:) = mean(coor_nan,'omitnan');
            
        % Add attributes to list
        T.length(TrackNum) = TrDuration;
        T.nOfNaN(TrackNum) = nOfNaN;
        T.maxGap(TrackNum) = maxGap;
        
        T.meanDisp(TrackNum) = mean_disp;
        
        T.meanVelocity(TrackNum) = mean_vel;
                        
        T.ovArea(TrackNum) = area;
        T.ovDist(TrackNum) = ovDist;
        
        T.meanX(TrackNum) = XYmean(TrackNum,1);
        T.meanY(TrackNum) = XYmean(TrackNum,2);
        T.meanZ(TrackNum) = XYmean(TrackNum,3);
           
        T.disp(TrackNum) = {disp};
        T.velocity(TrackNum) = {velocity};
        T.dist2origin(TrackNum) = {dist2origin};

        % T.runMean_disp(TrackNum) = {runMean_disp};
    
    end
          
    tracks.tracksList{currentTimePoint} = T;
    
    [tracks] = tracksMSDanalysis(tracks,currentTimePoint);

end








