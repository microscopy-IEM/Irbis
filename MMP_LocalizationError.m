

function MMP_LocalizationError(x,y)
 
%     TRS.coordinates
     allSigma = [];
    
%     for i = 1:TRS.numOfTrajectories
       
               
     
%      x = TRS.coordinates{i}(:,1)'; 
%      y = TRS.coordinates{i}(:,2)'; 
     

     x = x.*1000;
     y = y.*1000;
     
      
     X0 = mean(x,'omitnan');
     Y0 = mean(y,'omitnan');
     
     
     x = x'-X0;
     y = y'-Y0;
     
     X0 = mean(x,'omitnan');
     Y0 = mean(y,'omitnan');
     
     
     
     n = length(x);
    
     
     if n >= 300
    
%          vect = [x; y]';
    
         X0 = repmat([X0],1,n);
         Y0 = repmat([Y0],1,n);
    
        %  dist = sqrt((X0-x).^2 +(Y0-y).^2)';
    
    
         distx = X0-x;
         disty = Y0-y;
    
         
    %      mean(distx,'omitnan')-mean(disty,'omitnan')
         
         
         dist = [distx disty];
         
            pdx = fitdist(distx','Normal')
            pdy = fitdist(disty','Normal')
         
%             i
            
            sigmaDIff = pdx.sigma-pdy.sigma
            
            if abs(pdx.sigma-pdy.sigma) <= 20
            
                 pd = fitdist(dist','Normal');
                 sigma0 = pd.sigma;
    
                 xmin = 0-5*sigma0;
                 xmax = 0+5*sigma0;

%                  xmin = -75;
%                  xmax = 75;
% 
%                  x_values = xmin:2:xmax;
    
    
                 x_values = xmin:0.001:xmax;
                y_val = pdf(pd,x_values);
    
    
                allSigma = [allSigma sigma0];

                close(figure(5))
                close(figure(6))
    
                %%
    
                lim = 75;
                step = 25;
    
                f = figure(5);
                f.Units = 'centimeters';
                f.Position = [40 10 6 6];

    
                scatter(x,y);
    
                axis ij
    
                hold on
                scatter(X0,Y0,'r+');
                axis image;
                xlim([0-5*sigma0,0+5*sigma0]);
                ylim([0-5*sigma0,0+5*sigma0]);
    
                xlim([-lim ,lim ]);
                ylim([-lim ,lim ]);
    
                ylabel('x (nm)');
                xlabel('y (nm)');
    
    
                ax = gca;
                ax.XTick = -lim :step:lim ;
                ax.YTick = -lim :step:lim ;
                ax.LineWidth = 1;
                ax.Box = 'off';
                ax.TickDir = 'out';
                
                ax.XColor = [0 0 0];
                ax.YColor = [0 0 0];
%                 ax.Units = 'pixels';
                ax.TickLength = [0.02 0.05];
                % ax.Position = [10 10 5 5]

                figure(5)
                print(figure(5),'LocErrScatter','-dmeta')
    
    
                %%
                f2 = figure(6);
    
                edges = -75:2:75;
    
                f2.Units = 'centimeters';
                f2.Position = [50 10 10 6];
    
    
                %  histogram(distx,30,'Normalization','probability')
%                 h = histogram(distx,20,'Normalization','pdf','FaceColor',[0 0.4470 0.7410],'FaceAlpha',1);
                h = histogram(distx,edges,'Normalization','pdf','FaceColor',[0 0.4470 0.7410],'FaceAlpha',1);
%                 h = histogram(distx,edges,'Normalization','probability','FaceColor',[0 0.4470 0.7410],'FaceAlpha',1);
    
                
    
                ci = paramci(pd);
                err = ci(2,2)-sigma0;
    
    
                hold on
                plot(x_values,y_val,'LineWidth',2);
    
%                 xlim([xmin, xmax]);
                xlim([-lim, lim]);
                ylabel('Probability');
                xlabel('distance to center of mass (nm)');
    
                ax = gca;
                ax.LineWidth = 1;
                ax.Box = 'off';
                ax.TickDir = 'out';
                ax.TickLength = [0.013 0.025];
%                 ax.Units = 'centimeters';
                ax.YLim = [0 0.101;]
                ax.YTick = 0:0.05:0.2;
                ax.XColor = [0 0 0];
                ax.YColor = [0 0 0];

                ax.XTick = -lim :step:lim ;
%                 ax.YTick = -lim :step:lim ;


                yl = ax.YLim(2);
    
                text(15,yl*0.8,['\sigma = ' num2str(round(sigma0,1)) ' ± ' num2str(round(err,1)) ' nm']);

                figure(6)
                print( figure(6),'LocErrHist','-dmeta')

            end
     end
    
%     end
    
    allSigma'
    
    meanSigma = mean(allSigma);
    stdSigma = std(allSigma);
    
    disp(['\sigma = ' num2str(round(meanSigma,1)) ' ± ' num2str(round(stdSigma,1)) ' nm'])
end

