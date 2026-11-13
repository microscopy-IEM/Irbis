function drift = cameraShiftEstimator(synapseList,tracksList,radius)

    % tp = 1;
    % synapses = model.synapses;
    % tracks = tracks;
    
    % Parameters
    % radius = 0.5;
    step = 0.025;
    validationRange = -radius:step:radius;
    
    % 1. Extract the Meshes and its centre points
    % meshes = model.synapses.List{tp}.Mesh;
    meshes = synapseList.Mesh;
    numSynapses = numel(meshes);
    
    centrePoints = zeros(numSynapses, 2);
    
    % 2. Extract xy points from tracks
    for i = 1:numSynapses
        center = vertexCenter(meshes{i});
        centrePoints(i, :) = double(center(1:2));
    end
    
    xyzMat = vertcat(tracksList.xyz{:});
    points = xyzMat(:, 1:2);
    
    
    %% 1. Figure and tiledlayout for pltotting
    figure('Name','Shift optimizer','Position',[100 100 1000 500]);
    t = tiledlayout(2,4);
    
    ax1 = nexttile(t,[1 2]);
    ax2 = nexttile(t,[2,2]);
    ax3 = nexttile(t);
    ax4 = nexttile(t);
    
    % Pre-configure Tile 1 for the live Eval plot
    hLine = animatedline(ax1, 'Marker', 'o', 'MarkerFaceColor', [1 0 1], ...
        'Color', 'k', 'LineStyle', 'none'); % Matches MATLAB's @optimplotfval style
    xlabel(ax1, 'Iteration');
    ylabel(ax1, 'Function value');
    title(ax1, 'Current Function Value: ...');
    grid(ax1, 'on');
    
    % Pre compute search tree
    Mdl = KDTreeSearcher(points);
    
    % Run the optimization to find optimal shift
    options = optimset('OutputFcn', @(x, optimValues, state) updateEvalPlot(x, optimValues, state, hLine, ax1),'TolFun',10e-6,'TolX',10e-6,'Display','iter');
    % costFcn = @(shift) meanDist(shift(1), shift(2), centrePoints, radius, Mdl);

    costFcn = @(shift) smoothCostFcn(shift(1), shift(2), centrePoints, radius, Mdl);

    

    [bestShift, fval,exitflag,output] = fminsearch(costFcn, [0, 0], options)

% [x,fval,exitflag,output]

    drift = bestShift;
    
    numSteps = numel(validationRange);
    meanDistX = nan(1, numSteps);
    meanDistY = nan(1, numSteps);
    
    % Calculate mead distance in defined intervals - for visualisation purpose
    % only - no optimalization here
    for k = 1:numSteps
     
        % meanDistX(k) = meanDist(validationRange(k), 0 , centrePoints, radius, Mdl);
        % meanDistY(k) = meanDist(0, validationRange(k) , centrePoints, radius, Mdl);

        meanDistX(k) = smoothCostFcn(validationRange(k), 0 , centrePoints, radius, Mdl);
        meanDistY(k) = smoothCostFcn(0, validationRange(k) , centrePoints, radius, Mdl);

        % smoothCostFcn
        
    
    end
    
    %% Plots 
    
    plot(ax2, points(:,1), points(:,2), '.', 'Color', [0.7 0.7 0.7]);
    hold(ax2, 'on');
    shiftedCentres = centrePoints - bestShift;
    plot(ax2, centrePoints (:,1), centrePoints (:,2), 'ro', 'MarkerFaceColor', 'g');
    plot(ax2, shiftedCentres(:,1), shiftedCentres(:,2), 'ro', 'MarkerFaceColor', 'r');
    title(ax2, sprintf('Optimal Shift: dx = %.3f, dy = %.3f', bestShift(1), bestShift(2)));
    legend(ax2, 'Points', 'Original Centres', 'Shifted Centres');
    grid(ax2, 'on');

    ax2.YDir ="reverse";
    
    plot(ax3, validationRange, meanDistX, '-o');
    xlabel(ax3, 'xShift \mum');
    ylabel(ax3, 'meanDist');
    title(ax3, 'Xshift');
    grid(ax3, 'on');
    
    plot(ax4, validationRange, meanDistY, '-o');
    xlabel(ax4, 'yShift \mum');
    ylabel(ax4, 'meanDist');
    title(ax4, 'Yshift');
    grid(ax4, 'on');
    
    %% Live plot fonction
    function stop = updateEvalPlot(~, optimValues, state, hLine, ax)
        stop = false;
        if strcmp(state, 'iter')
            % Append the new iteration point to the existing line
            addpoints(hLine, optimValues.iteration, optimValues.fval);
            ax.Title.String = sprintf('Current Function Value: %g', optimValues.fval);
      
            drawnow limitrate; 
        elseif strcmp(state, 'done')
            ax.Title.String = sprintf('Final Function Value: %g', optimValues.fval);
            drawnow; % Force final graphical update
        end
    end
    
    %% Eval function
    function meanDist = meanDist(xShift, yShift, centrePoints, radius, Mdl)
        % Shift the query points in the opposite direction
        shiftedCentres = centrePoints - [xShift, yShift];
    
        % Search within range and measure distances beteween centres and points
        [~, distVect] = rangesearch(Mdl, shiftedCentres, radius, 'SortIndices', false);
    
        allDists = [distVect{:}];
        if isempty(allDists)
            meanDist = radius;
        else
            meanDist = mean(allDists);
        end
    end

    function cost = smoothCostFcn(xShift, yShift, centrePoints, radius, Mdl)
        shiftedCentres = centrePoints - [xShift, yShift];
        
        % Search within radius
        [~, distVect] = rangesearch(Mdl, shiftedCentres, radius, 'SortIndices', false);
        
        % Continuous Gaussian-like score (Maximize alignment -> Minimize negative score)
        % Every point inside radius contributes smoothly; points at the boundary contribute 0
        sigma = radius / 2;
        totalScore = 0;
        
        for i = 1:numel(distVect)
            d = distVect{i};
            if ~isempty(d)
                % Subtracting the boundary value makes the transition at d = radius perfectly continuous (0)
                weights = exp(-(d.^2) / (2 * sigma^2)) - exp(-(radius^2) / (2 * sigma^2));
                totalScore = totalScore + sum(weights);
            end
        end
        
        % We want to maximize totalScore, so minimize its negative
        % If no points are found, return a flat high penalty (0) instead of NaN
        cost = -totalScore;
    end

end