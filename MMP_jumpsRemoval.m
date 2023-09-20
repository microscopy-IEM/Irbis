function tracks = MMP_jumpsRemoval(tracks,w)

tracks

    for TrackNum = 1:tracks.numOfTracks

       b = ~isnan(tracks.tracksList.xyz{TrackNum}(:,1));
    
       % detect separated single NaN values
        ind = findstr(b',[0 1 0])+1;
        
        tracks.tracksList.xyz{TrackNum}(ind,:) = nan;
        
        coor = tracks.tracksList.xyz{TrackNum}(:,1:2);
        
    %     disp = sqrt(sum(diff(coor).^2,2));
       
        
    
        outX = isoutlier(coor(:,1),'movmean',w);
        outY = isoutlier(coor(:,2),'movmean',w);
                 
        out = outX | outY;
    
    
%          outXY = isoutlier(coor,'movmean',w)
        
        tracks.tracksList.xyz{TrackNum}(out,:) = nan;
    
    
    
    
    end

end