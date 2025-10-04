
%% Read data and properties from boxChart

function exportEvalFigFcn(sourceAx)

    boxCharts = findobj(sourceAx,'Type','BoxChart');
    if isempty(boxCharts)
        disp('nob box plot found')
        return
    end
    
    % clc
    
    parentFigure = ancestor(sourceAx,'figure','toplevel');
    
    
    f = figure;
    f.Theme = parentFigure.Theme;
    ax = copyobj(sourceAx,f);

    get(sourceAx)
    55


    % origLegend = findobj(parentFigure,'Type','Legend')

    % cGroupLabel = origLegend.Title.String
    groupLabel = ax.XLabel;
    % get(ax)
    
    ax.Position(1) = 50;
    ax.Position(2) = 50;
    
    ax.Units = 'normalized';
    
    ax.Position(3) = 0.9;
    ax.Position(4) = 0.9;
    
    % Add button
    btn = uibutton(f,'ButtonPushedFcn',@(src,evt)figStats(src,evt,ax),'Text','Anova','Position',[20 20 100 22]);
    cb = uicheckbox(f,"ValueChangedFcn",@(src,evt)violinCheckBox(src,evt,ax),'Value',1,'Text','Violin','Position',[140 20 100 22]);
    
    % detect boxCharts in figure
    boxCharts = findobj(ax,'Type','BoxChart')
    
    delete(findobj(ax,'Type','ViolinPlot'))
    
    get(boxCharts(1))
    
    cWidth = boxCharts(1).ColorGroupWidth;
    
    % read data from axes
    [T,cGroupNames,groupNames] = readBoxChartData(boxCharts);
    assignin("base","T",T)
    assignin("base","b",boxCharts(1))
    
    nColorGroups = size(cGroupNames,1)
    nGroups = size(groupNames,1)
    nBoxCharts = nColorGroups;
    
    w = 1/nBoxCharts;
    
    ax.NextPlot = 'add';
    
    xv = -1:1/((nBoxCharts-1)/2):1;
    
        for groupInd = 1:nGroups
    
            group = groupNames(groupInd);
            
            for cGroupInd = 1:nColorGroups
                
                currentBoxChartObj = boxCharts(cGroupInd);
                
                colorGroup = cGroupNames(cGroupInd);
                % get(currentBoxChartObj)
                        
                xMain = groupInd;
                sectionWidth = 1/nBoxCharts;
                nSections = (nBoxCharts-1)*0.5;
    
                % relGroupWidth = boxCharts(groupInd).ColorGroupWidth;
                relGroupWidth = boxCharts(cGroupInd).ColorGroupWidth;
                absGroupWidth = relGroupWidth * sectionWidth * nSections;
    
                % use seriesIndex to identify current chart position
                seriesIndex = currentBoxChartObj.SeriesIndex;
                xPos = xv(seriesIndex)*absGroupWidth+xMain;
                
                % get data of current group
                data = currentBoxChartObj.YData(currentBoxChartObj.XData == group);
    
                % calculate stats
                dataMean = mean(data);
                dataSTD = std(data);
           
                         
                % line(ax,[xPos-w,xPos+w],[dataMean dataMean],'LineStyle',':','Color',currentBoxChartObj.BoxMedianLineColor,'LineWidth',currentBoxChartObj.LineWidth)
                sc = scatter(ax,xPos,dataMean,20,'Marker','o','MarkerEdgeColor',currentBoxChartObj.BoxMedianLineColor,'LineWidth',currentBoxChartObj.LineWidth);
                % line(ax,[xPos-w,xPos+w],[dataMean dataMean],'LineStyle',':','Color','r','LineWidth',currentBoxChartObj.LineWidth)
    
                % sc.DataTipTemplate.DataTipRows(3:end) = [];
    
                sc.DataTipTemplate.DataTipRows(1).Label = 'Group';
                sc.DataTipTemplate.DataTipRows(1).Value = {group};         
    
                sc.DataTipTemplate.DataTipRows(2).Label = 'Color group';
                sc.DataTipTemplate.DataTipRows(2).Value = {currentBoxChartObj.DisplayName};
                sc.DataTipTemplate.DataTipRows(3).Label = "Mean"; 
                sc.DataTipTemplate.DataTipRows(3).Value = dataMean;
                sc.DataTipTemplate.DataTipRows(4).Label = "STD"; 
                sc.DataTipTemplate.DataTipRows(4).Value = dataSTD;
    
                
    
                v = violinplot(data,DensityDirection="positive",FaceColor=[0.3 0.3 0.3],DensityWidth=0.2);
    
                % get(v)
    
                % vshift = 0.05;
    
                if nBoxCharts == 1
    
                    vshift = currentBoxChartObj.BoxWidth/2 +  currentBoxChartObj.BoxWidth/2*0.2;
                else
    
                    vshift = currentBoxChartObj.BoxWidth*absGroupWidth*1.5;
                    densitiWidth = absGroupWidth*0.8;
    
                    % v.DensityWidth = densitiWidth;
                end
                v.XData = xPos*ones(size(data))+vshift;
    
    
    
            end
    
        end
    
        % get(ax)
    
        % get(v)
    
        % ax.XTick = ax.XTick(1:end-1);
    
    
        % v = violinplot(groupdata,data,'GroupByColor', cGroupData,'ButtonDownFcn',@normTest,DensityDirection="positive",FaceColor=[0.2 0.2 0.2],DensityWidth=0.8);
    
        % cGrupes = unique(T{:,2})
    
        % T = sortrows(T,1,'descend');
    
        % T
    
        % vshift = 0.05;
    
        l = legend(boxCharts);
        get(l)
        % l.Title.String = origLegend.Title.String;
        % l.Title.Interpreter = 'none';
        l.Box = 'off';
        % get(l)
        % % cGroupNames{i} = boxCharts(i).DisplayName;
        % 
        % G = findgroups(T{:,1});
        % cG = categorical(T{:,2});
        % v = violinplot(ax,G,T{:,3},'GroupByColor',cG,DensityDirection="positive",FaceColor=[0.5 0.5 0.5],DensityWidth=0.8);
        % % v = violinplot(ax,T{:,1},T{:,3},'GroupByColor',T{:,2},DensityDirection="positive",FaceColor=[0.5 0.5 0.5],DensityWidth=0.8);
        % % v = violinplot(groupdata,data)
        % 
        % for i = 1:length(v)
        %     % v(i).YData
        %     v(i).XData =  v(i).XData + vshift;
        % end
        % 
        % get(v(1))
end

function [T,cGroupNames,groupNames] = readBoxChartData(boxCharts)

    if isempty(boxCharts)
        disp('No boxCharts found')
        return
    end

    T = [];
    nBoxCharts = length(boxCharts)
    
    % extract color group names
    cGroupNames = cell([nBoxCharts,1]);

    for i = 1:nBoxCharts
              
        cGroupNames{i} = boxCharts(i).DisplayName;

        if isempty(boxCharts(i).DisplayName)
            cGroupNames{i} = 'nan';
        end
        
    end

    cGroupNames

    % get(boxCharts)

    % isempty(cGroupNames)

    % cGroupNames{1} = 'none';

        % create combined label for cGroup
        cGroupNamesStr = strjoin(string(cGroupNames),'_');


    for i = 1:length(boxCharts)
    
        % major group
        group = boxCharts(i).XData';

        % extract color group names
        groupNames = unique(group);        
        % create combined label for cGroup
        groupNamesStr = strjoin(string(groupNames),'_');
        
        % secondary group (color group)
        cGroupName = boxCharts(i).DisplayName;
        cGroupName = categorical({cGroupName});
        cGroup = repmat(cGroupName,size(group,1),1);
        
        % numerical data
        data = boxCharts(i).YData';          
        
        T_temp = table(group,cGroup,data,VariableNames=[groupNamesStr cGroupNamesStr "data"]);
        
        T = [T;T_temp];
    
    end

    cGroupNames = categorical(cGroupNames);

    % cGroupNames = reordercats(cGroupNames)
 % 555
    
end



function figStats(src,evt,ax)
clc
    % get(src)
    % evt

    Tall = [];

    boxCharts = findobj(ax,'Type','BoxChart');


    g1Name = ax.UserData.groupLabel
    g2Name = ax.UserData.cGroupLabel

    twoWay = ~isempty(g2Name);

    if isempty(boxCharts)
        return
    end

    for i = 1:length(boxCharts)
    
        g1 = boxCharts(i).XData';
        
        name = boxCharts(i).DisplayName;
        name = categorical({name});
        g2 = repmat(name,size(g1,1),1);
        
        d1 = boxCharts(i).YData';
    
        % [d1, TF] = rmoutliers(d1,"quartiles");
        % 
        % g1 = g1(~TF);
        % g2 = g2(~TF);
        
      
        if twoWay
            T = table(g1,g2,d1,VariableNames=[g1Name g2Name "data"]);
        else
            T = table(g1,d1,VariableNames=[g1Name "data"]);
        end
        
        Tall = [Tall;T];

        % get(boxCharts(i))
    
    end

    % Tall

    aov = anova(Tall,"data",'ModelSpecification','full')

    assignin("base","aov",aov)
    
    % m = multcompare(aov,["subunit" "cTerm" ])

    results = multcompare(aov,aov.FactorNames)

    % stats(aov,'summary')

    s = stats(aov,'component')
    s.MeanSquares = double(s.MeanSquares);
    s.F = double(s.F);
    % s.F(isnan(s.F)) = ' ';
    s.pValue = double(s.pValue);

    % s.(aov.FactorNames{1}).SumOfSquares

    nFactors = length(aov.FactorNames);
    if twoWay
        nFactors = nFactors+1;
    end

    totalErr = s.SumOfSquares(end)


    s.EffectSize = nan(height(s),1);
    s.EffectSizeSummary = cell(height(s),1)
    % s.EffectSizeSummary = nan(height(s),1);

    for factorInd = 1:nFactors

        factorErr = s.SumOfSquares(factorInd);
        EffectSize = factorErr/totalErr;

        s.EffectSize(factorInd) = EffectSize;

        

        if EffectSize < 0.01
            effectSizeDesc = 'no effect';
        elseif EffectSize < 0.06
            effectSizeDesc = 'small';
        elseif EffectSize < 0.14
            effectSizeDesc = 'medium';
        elseif EffectSize > 0.14
            effectSizeDesc = 'large';
        end

        s.EffectSizeSummary(factorInd) = {effectSizeDesc};


    end

    EffectSize

    
    s
    % if two way anova was done, convert interaction columns from table to
    % array 
    if ~iscategorical(results.Group1)
    
        results.Group1 = table2array(results.Group1);
        results.Group2 = table2array(results.Group2);

    end

    assignin("base","s",s)
    assignin("base","results",results)

    h = height(results)*12;
    if h > 800
        h = 800;
    elseif h < 100
        h = 100;
    end

    f = figure(2);
    clf(f);
    f.Name = 'Anova summary';
    f.Position = [100,100,850,240];
    t = uitable;
    t.Position = [20,20,800,200];
    t.Data = s;
    t.Units = 'normalized';

    f1 = figure(3);
    clf(f1);
    f.Name = 'Multiple comparison test';
    f1.Position = [100,400,850,h+40];
    t = uitable;
    t.Position = [20,20,800,h];
    t.Data = results;
    % get(t)
    t.Units = 'normalized';

    % disp(s)
    
    % figure
    % plotComparisons(aov,["subunit" "cTerm" ]);
    % 
    % figure
    % boxchart(aov,["subunit" "cTerm" ])

end


function normTest(src,evt)

    clc
    point = evt.IntersectionPoint(1);

    labels = unique(src.XData);
    get(src)

    cGroup = src.DisplayName
        
    groupInd = round(evt.IntersectionPoint(1))
            
    group = labels(groupInd)
    
  
    % number of BoxCharts
    nBoxes = length(findobj(src.Parent,'Type','BoxChart'))

    if nBoxes == 1
        selectedBoxPositionX = groupInd

        relGroupWidth = src.ColorGroupWidth;
        absGroupWidth = relGroupWidth    
    else

        % calculate positon of selected box on x axis
        sectionWidth = 1/nBoxes;
        nSections = (nBoxes-1)*0.5;
        
        relGroupWidth = src.ColorGroupWidth;
        absGroupWidth = relGroupWidth * sectionWidth * nSections    
        distToGroupCentre = point - groupInd;
        boxIndWithinGroup = round(distToGroupCentre/absGroupWidth);
    
        selectedBoxPositionX = groupInd+absGroupWidth*boxIndWithinGroup;
    end
    

    ydata = src.YData(src.XData == group);


    % outliers
    % ydata = rmoutliers(ydata,"quartiles");
      
    
    delete(findobj(gca,'Type','Stem'))
    delete(findobj(gca,'Type','Scatter'))
    

    % x = src.YData;
    [H, pValue, W] = swtest(ydata, 0.05);
    
    % src.XData
        if H 
            marker = 'x';
            c = 'r';
        else
            marker = 'v';
            c = 'g';
    
        end

        mxy = max(ydata);
        mny = min(ydata);
        mn = mean(ydata);
    
        d = abs(mxy-mny)*0.2;
        yPosiiton = mxy+d;
        scatter(selectedBoxPositionX,yPosiiton,c,marker)

        % scatter(selectedBoxPositionX,mn,c,marker)

        bw = src.BoxWidth;
        w = bw*absGroupWidth/2*0.95;
        line([selectedBoxPositionX-w,selectedBoxPositionX+w],[mn mn],'LineStyle',':','Color',src.BoxMedianLineColor,'LineWidth',src.LineWidth)
        
        n = length(ydata);
        text(selectedBoxPositionX,yPosiiton,['n = ' num2str(n)],'HorizontalAlignment','center')


        % src.DataTipTemplate
        % row = dataTipTextRow('Mean',mn);
        % src.DataTipTemplate.DataTipRows(end+1) = row;

        
end

function violinCheckBox(src,evt,ax)


        yl = ax.YLim;
        xl = ax.XLim;

        v = findobj(ax,'Type','violinplot');

        % v.Visible = 'off';

        if evt.PreviousValue
            set(v,'Visible','off')
        else
            set(v,'Visible','on')
        end

        ax.YLim = yl;
        ax.XLim = xl;


end





function [H, pValue, W] = swtest(x, alpha)
    %SWTEST Shapiro-Wilk parametric hypothesis test of composite normality.
    %   [H, pValue, SWstatistic] = SWTEST(X, ALPHA) performs the
    %   Shapiro-Wilk test to determine if the null hypothesis of
    %   composite normality is a reasonable assumption regarding the
    %   population distribution of a random sample X. The desired significance 
    %   level, ALPHA, is an optional scalar input (default = 0.05).
    %
    %   The Shapiro-Wilk and Shapiro-Francia null hypothesis is: 
    %   "X is normal with unspecified mean and variance."
    %
    %   This is an omnibus test, and is generally considered relatively
    %   powerful against a variety of alternatives.
    %   Shapiro-Wilk test is better than the Shapiro-Francia test for
    %   Platykurtic sample. Conversely, Shapiro-Francia test is better than the
    %   Shapiro-Wilk test for Leptokurtic samples.
    %
    %   When the series 'X' is Leptokurtic, SWTEST performs the Shapiro-Francia
    %   test, else (series 'X' is Platykurtic) SWTEST performs the
    %   Shapiro-Wilk test.
    % 
    %    [H, pValue, SWstatistic] = SWTEST(X, ALPHA)
    %
    % Inputs:
    %   X - a vector of deviates from an unknown distribution. The observation
    %     number must exceed 3 and less than 5000.
    %
    % Optional inputs:
    %   ALPHA - The significance level for the test (default = 0.05).
    %  
    % Outputs:
    %  SWstatistic - The test statistic (non normalized).
    %
    %   pValue - is the p-value, or the probability of observing the given
    %     result by chance given that the null hypothesis is true. Small values
    %     of pValue cast doubt on the validity of the null hypothesis.
    %
    %     H = 0 => Do not reject the null hypothesis at significance level ALPHA.
    %     H = 1 => Reject the null hypothesis at significance level ALPHA.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                Copyright (c) 17 March 2009 by Ahmed Ben Sa�da          %
    %                 Department of Finance, IHEC Sousse - Tunisia           %
    %                       Email: ahmedbensaida@yahoo.com                   %
    %                    $ Revision 3.0 $ Date: 18 Juin 2014 $               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % References:
    %
    % - Royston P. "Remark AS R94", Applied Statistics (1995), Vol. 44,
    %   No. 4, pp. 547-551.
    %   AS R94 -- calculates Shapiro-Wilk normality test and P-value
    %   for sample sizes 3 <= n <= 5000. Handles censored or uncensored data.
    %   Corrects AS 181, which was found to be inaccurate for n > 50.
    %   Subroutine can be found at: http://lib.stat.cmu.edu/apstat/R94
    %
    % - Royston P. "A pocket-calculator algorithm for the Shapiro-Francia test
    %   for non-normality: An application to medicine", Statistics in Medecine
    %   (1993a), Vol. 12, pp. 181-184.
    %
    % - Royston P. "A Toolkit for Testing Non-Normality in Complete and
    %   Censored Samples", Journal of the Royal Statistical Society Series D
    %   (1993b), Vol. 42, No. 1, pp. 37-43.
    %
    % - Royston P. "Approximating the Shapiro-Wilk W-test for non-normality",
    %   Statistics and Computing (1992), Vol. 2, pp. 117-119.
    %
    % - Royston P. "An Extension of Shapiro and Wilk's W Test for Normality
    %   to Large Samples", Journal of the Royal Statistical Society Series C
    %   (1982a), Vol. 31, No. 2, pp. 115-124.
    %
    %
    % Ensure the sample data is a VECTOR.
    %
    if numel(x) == length(x)
        x  =  x(:);               % Ensure a column vector.
    else
        error(' Input sample ''X'' must be a vector.');
    end
    %
    % Remove missing observations indicated by NaN's and check sample size.
    %
    x  =  x(~isnan(x));
    if length(x) < 3
       error(' Sample vector ''X'' must have at least 3 valid observations.');
    end
    if length(x) > 5000
        warning('Shapiro-Wilk test might be inaccurate due to large sample size ( > 5000).');
    end
    %
    % Ensure the significance level, ALPHA, is a 
    % scalar, and set default if necessary.
    %
    if (nargin >= 2) && ~isempty(alpha)
       if ~isscalar(alpha)
          error(' Significance level ''Alpha'' must be a scalar.');
       end
       if (alpha <= 0 || alpha >= 1)
          error(' Significance level ''Alpha'' must be between 0 and 1.'); 
       end
    else
       alpha  =  0.05;
    end
    % First, calculate the a's for weights as a function of the m's
    % See Royston (1992, p. 117) and Royston (1993b, p. 38) for details
    % in the approximation.
    x       =   sort(x); % Sort the vector X in ascending order.
    n       =   length(x);
    mtilde  =   norminv(((1:n)' - 3/8) / (n + 1/4));
    weights =   zeros(n,1); % Preallocate the weights.
    if kurtosis(x) > 3
        
        % The Shapiro-Francia test is better for leptokurtic samples.
        
        weights =   1/sqrt(mtilde'*mtilde) * mtilde;
        %
        % The Shapiro-Francia statistic W' is calculated to avoid excessive
        % rounding errors for W' close to 1 (a potential problem in very
        % large samples).
        %
        W   =   (weights' * x)^2 / ((x - mean(x))' * (x - mean(x)));
        % Royston (1993a, p. 183):
        nu      =   log(n);
        u1      =   log(nu) - nu;
        u2      =   log(nu) + 2/nu;
        mu      =   -1.2725 + (1.0521 * u1);
        sigma   =   1.0308 - (0.26758 * u2);
        newSFstatistic  =   log(1 - W);
        %
        % Compute the normalized Shapiro-Francia statistic and its p-value.
        %
        NormalSFstatistic =   (newSFstatistic - mu) / sigma;
        
        % Computes the p-value, Royston (1993a, p. 183).
        pValue   =   1 - normcdf(NormalSFstatistic, 0, 1);
        
    else
        
        % The Shapiro-Wilk test is better for platykurtic samples.
        c    =   1/sqrt(mtilde'*mtilde) * mtilde;
        u    =   1/sqrt(n);
        % Royston (1992, p. 117) and Royston (1993b, p. 38):
        PolyCoef_1   =   [-2.706056 , 4.434685 , -2.071190 , -0.147981 , 0.221157 , c(n)];
        PolyCoef_2   =   [-3.582633 , 5.682633 , -1.752461 , -0.293762 , 0.042981 , c(n-1)];
        % Royston (1992, p. 118) and Royston (1993b, p. 40, Table 1)
        PolyCoef_3   =   [-0.0006714 , 0.0250540 , -0.39978 , 0.54400];
        PolyCoef_4   =   [-0.0020322 , 0.0627670 , -0.77857 , 1.38220];
        PolyCoef_5   =   [0.00389150 , -0.083751 , -0.31082 , -1.5861];
        PolyCoef_6   =   [0.00303020 , -0.082676 , -0.48030];
        PolyCoef_7   =   [0.459 , -2.273];
        weights(n)   =   polyval(PolyCoef_1 , u);
        weights(1)   =   -weights(n);
        
        if n > 5
            weights(n-1) =   polyval(PolyCoef_2 , u);
            weights(2)   =   -weights(n-1);
        
            count  =   3;
            phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2 - 2 * mtilde(n-1)^2) / ...
                    (1 - 2 * weights(n)^2 - 2 * weights(n-1)^2);
        else
            count  =   2;
            phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2) / ...
                    (1 - 2 * weights(n)^2);
        end
            
        % Special attention when n = 3 (this is a special case).
        if n == 3
            % Royston (1992, p. 117)
            weights(1)  =   1/sqrt(2);
            weights(n)  =   -weights(1);
            phi = 1;
        end
        %
        % The vector 'WEIGHTS' obtained next corresponds to the same coefficients
        % listed by Shapiro-Wilk in their original test for small samples.
        %
        weights(count : n-count+1)  =  mtilde(count : n-count+1) / sqrt(phi);
        %
        % The Shapiro-Wilk statistic W is calculated to avoid excessive rounding
        % errors for W close to 1 (a potential problem in very large samples).
        %
        W   =   (weights' * x) ^2 / ((x - mean(x))' * (x - mean(x)));
        %
        % Calculate the normalized W and its significance level (exact for
        % n = 3). Royston (1992, p. 118) and Royston (1993b, p. 40, Table 1).
        %
        newn    =   log(n);
        if (n >= 4) && (n <= 11)
        
            mu      =   polyval(PolyCoef_3 , n);
            sigma   =   exp(polyval(PolyCoef_4 , n));    
            gam     =   polyval(PolyCoef_7 , n);
        
            newSWstatistic  =   -log(gam-log(1-W));
        
        elseif n > 11
        
            mu      =   polyval(PolyCoef_5 , newn);
            sigma   =   exp(polyval(PolyCoef_6 , newn));
        
            newSWstatistic  =   log(1 - W);
        
        elseif n == 3
            mu      =   0;
            sigma   =   1;
            newSWstatistic  =   0;
        end
        %
        % Compute the normalized Shapiro-Wilk statistic and its p-value.
        %
        NormalSWstatistic   =   (newSWstatistic - mu) / sigma;
        
        % NormalSWstatistic is referred to the upper tail of N(0,1),
        % Royston (1992, p. 119).
        pValue       =   1 - normcdf(NormalSWstatistic, 0, 1);
        
        % Special attention when n = 3 (this is a special case).
        if n == 3
            pValue  =   6/pi * (asin(sqrt(W)) - asin(sqrt(3/4)));
            % Royston (1982a, p. 121)
        end
        
    end
    %
    % To maintain consistency with existing Statistics Toolbox hypothesis
    % tests, returning 'H = 0' implies that we 'Do not reject the null 
    % hypothesis at the significance level of alpha' and 'H = 1' implies 
    % that we 'Reject the null hypothesis at significance level of alpha.'
    %
    H  = (alpha >= pValue);

end