function dist2zone0edge = dist2ROI(xpoints,ypoints,zone0_ROI)



 %% Measure distance of all positions to edge of zone
%         get(zone0_ROI)
    
% zone0_ROI

plotLines = 0;
        
        xv = zone0_ROI.Position(:,1);
        yv = zone0_ROI.Position(:,2);

        dist2zone0edge = nan(size(xpoints));
       
        centre = mean([xv,yv]);
        
        for i = 1:length(xpoints)
        
            [dist2zone0edge(i),x_poly,y_poly] = p_poly_dist(xpoints(i), ypoints(i), xv, yv);

            if plotLines == 1
                if dist2zone0edge(i)>0
                        c = 'r';
                else
                        c = 'g';
                end
                
                    line(zone0_ROI.Parent,[xpoints(i), x_poly],[ypoints(i),y_poly],'Color',c,'Tag','DistLines')

            end

          
        end

        
       
end
