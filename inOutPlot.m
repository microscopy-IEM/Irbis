function inOutPlot(xpoints,ypoints,zone0_ROI)


synMin = 0.1;
extMin = 0.1;

maxNanPerc = 0.3;

minDur = 0.3;
% minDur = 1;
% minDur = 0.15;

xlim_ = [0,40];

 %% Measure distance of all positions to edge of zone0
        
    
zone0_ROI
        xv = zone0_ROI.Position(:,1);
        yv = zone0_ROI.Position(:,2);

        dist2zone0edge = [];
        inoutVector = dist2zone0edge;

        Ts = 0.05;
        time = 0:Ts:length(xpoints)*Ts-Ts;
        
        for i = 1:length(xpoints)
        
            [dist2zone0edge(i),x_poly,y_poly] = p_poly_dist(xpoints(i), ypoints(i), xv, yv);

            if dist2zone0edge(i)>0
                    
                     inoutVector(i) = 0;

            elseif dist2zone0edge(i) <= 0
                    
                     inoutVector(i) = 1;
            else
                     inoutVector(i) = nan;
            end

        end

        exVect = inoutVector';


        size(time)

        size(exVect)

        
       
        duration = sum(~isnan(exVect))*Ts;
        
        w = minDur/Ts;
        
        M = exVect;
        % M = movmedian(exVect,w,'omitnan');
        
        M = fillmissing(M,'movmean',w);
        
        % M = fillmissing(exVect,'linear');
        M = movmedian(M,w,'omitnan');
        
        % M = fillmissing(M,'movmedian',w);
        % M = movmean(exVect,w);
       
        
        Mrounded = round(M);
        
        Mrounded = movmedian(Mrounded,5,'omitnan');
        
        Mdiff = diff(Mrounded);

        Mrounded = fillmissing(Mrounded,'previous');
            
        rt = find(Mdiff == 1);
        ft = find(Mdiff == -1);
            
        
        if ~isempty(rt) && ~isempty(ft)
        
            if rt(1) > ft(1)
            
                rt = [0; rt];
            
            end
            
            if length(rt) > length(ft)
            
                rt = rt(1:length(ft));
        
            elseif length(rt) < length(ft)
            
                ft = ft(1:end-1);
        
            end
    
            InDurVect = (ft-rt).*Ts
            InDurVect = InDurVect(InDurVect >= minDur)
            
            nOfChanges = sum(abs(Mdiff),'omitnan')
            exRate = nOfChanges/duration
            
            residencyTime = mean(InDurVect)
        
        end
        
        % PLot
        figure    
        subplot(311)
        stairs(time,exVect)
        ylim([-0.1,1.2])
        xlim(xlim_);
        ax = gca;
        ax.TickDir = 'out';
        ax.Box = 'off';
            
        subplot(312)
        stairs(time,M)
        ylim([-0.1,1.2])
        xlim(xlim_);
         ax = gca;
        ax.TickDir = 'out';
        ax.Box = 'off';
        
        subplot(313)
        stairs(time,Mrounded)
        ylim([-0.1,1.2])
        xlim(xlim_);
         ax = gca;
        ax.TickDir = 'out';
        ax.Box = 'off';

        text(10,1,['exchange rate = ' num2str(exRate) ' Hz'])
        text(10,1.2,['res. time = ' num2str(residencyTime) ' s'])
% 



end
