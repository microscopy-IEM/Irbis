function tryAdaptiveShaftParameters(centreLine, parentMesh)
    disp('in tryAdaptiveShaft');

    % Initial parameter values
    initialParams = struct(...
        'RadiusScaling', {1.2}, ...
        'Iterations', {300}, ...
        'ContractionBias', {-0.5}, ...
        'SmoothFactor', {1}, ...
        'sizeIm', {100}, ...
        'realCenterDim', {2}, ...
        'initialRadius', {[8, 10]} ...
    );

    % Create a figure for the UI
    hFig = uifigure('Name', 'Adaptive Shaft Parameters');

    % Positioning variables for UI elements
    labelX = 20;
    dropdownX = 130;
    buttonAddX = 240;
    buttonRemoveX = 270;
    dropdownY = 370;
    spacingY = 40;

    % Initialize results storage
    guiData.results = struct('RadiusScaling', {}, 'Iterations', {}, 'ContractionBias', {}, ...
                             'SmoothFactor', {}, 'sizeIm', {}, 'realCenterDim', {}, ...
                             'initialRadius', {}, 'contours', {}, 'middlePoints', {}, 'shaftNorms', {}, 'mesh', {});
    
    % Create UI elements for each parameter
    params = fieldnames(initialParams);
    dropdowns = cell(1, length(params));
    
    for i = 1:length(params)
        % Add labels and dropdowns
        uilabel(hFig, 'Position', [labelX, dropdownY, 100, 22], 'Text', params{i});
        initialItems = initialParams.(params{i});
        dropdowns{i} = uidropdown(hFig, 'Position', [dropdownX, dropdownY, 100, 22], ...
            'Items', unique(arrayfun(@num2str, initialItems, 'UniformOutput', false)), ...
            'Value', num2str(initialItems(1)));
        
        % Add '+' button for adding values
        uibutton(hFig, 'Position', [buttonAddX, dropdownY, 22, 22], 'Text', '+', ...
            'ButtonPushedFcn', @(btn, event) addValueToDropdown(dropdowns{i}, params{i}));
        
        % Add '-' button for removing values
        uibutton(hFig, 'Position', [buttonRemoveX, dropdownY, 22, 22], 'Text', '-', ...
            'ButtonPushedFcn', @(btn, event) removeValueFromDropdown(dropdowns{i}));
        
        % Update Y position for the next dropdown
        dropdownY = dropdownY - spacingY;
    end
    
    % Create a dropdown to select whether to plot Mesh or Point Cloud with Normals
    uilabel(hFig, 'Position', [labelX, dropdownY, 100, 22], 'Text', 'Plot Type');
    ddPlotType = uidropdown(hFig, 'Position', [dropdownX, dropdownY, 100, 22], 'Items', {'Mesh', 'Point Cloud with Normals'});
    
    % Button to run calculations
    btnCalculate = uibutton(hFig, 'Position', [labelX, dropdownY - 40, 210, 22], 'Text', 'Run Calculations', ...
        'ButtonPushedFcn', @(btn, event) runCalculations(centreLine, parentMesh, dropdowns, params, guiData, hFig));
    
    % Button to plot the results based on selected parameters
    btnPlot = uibutton(hFig, 'Position', [labelX, dropdownY - 80, 210, 22], 'Text', 'Plot', ...
        'ButtonPushedFcn', @(btn, event) plotResults(ddPlotType, dropdowns, params, guiData));
    
    % Button to save the results
    btnSave = uibutton(hFig, 'Position', [labelX, dropdownY - 120, 210, 22], 'Text', 'Save Results', ...
        'ButtonPushedFcn', @(btn, event) saveResults(guiData));

    % Axes for plotting
    % ax = uiaxes(hFig, 'Position', [300, 50, 500, 400]);

    % Store the results in the figure's UserData
    hFig.UserData.guiData = guiData;

function addValueToDropdown(dropdown, paramName)
    % Prompt the user for a new value
    newValue = inputdlg(['Enter new value for ', paramName], 'Add Value');
    
    if ~isempty(newValue)
        % Convert the input to a string and add to the dropdown
        items = dropdown.Items;
        class(newValue)
        items{end+1} = num2str(newValue{1});
        dropdown.Items = items;
    end
end

function removeValueFromDropdown(dropdown)
    % Get the currently selected value
    selectedIndex = dropdown.Value;
    
    if ~isempty(selectedIndex)
        % Remove the selected item from the dropdown
        dropdown.Items(dropdown.ValueIndex) = [];
    end
end

function runCalculations(centreLine, parentMesh, dropdowns, params, guiData, hFig)
    % Retrieve current dropdown values
    ranges = cell(1, length(dropdowns));
    for i = 1:length(dropdowns)
        ranges{i} = str2double(dropdowns{i}.Items);
    end
    
    % Generate all combinations of parameters
    [RadiusScalingGrid, IterationsGrid, ContractionBiasGrid, SmoothFactorGrid, ...
     sizeImGrid, realCenterDimGrid, initialRadiusGrid] = ndgrid(ranges{:});
    
    % Flatten the grids to create arrays of parameter combinations
    combinations = [RadiusScalingGrid(:), IterationsGrid(:), ContractionBiasGrid(:), ...
                    SmoothFactorGrid(:), sizeImGrid(:), realCenterDimGrid(:), initialRadiusGrid(:)];
    
    % Initialize results storage
    guiData.results = struct('RadiusScaling', {}, 'Iterations', {}, 'ContractionBias', {}, ...
                             'SmoothFactor', {}, 'sizeIm', {}, 'realCenterDim', {}, ...
                             'initialRadius', {}, 'contours', {}, 'middlePoints', {}, 'shaftNorms', {}, 'mesh', {});
    
    % Loop through all combinations and run the calculations
    for i = 1:size(combinations, 1)
        % Extract current parameter combination
        params = num2cell(combinations(i, :));
        [RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius] = deal(params{:});
        
        % Call the generateAdaptiveShaft function
        [contours, middlePoints, shaftNorms, mesh] = generateAdaptiveShaft(centreLine, parentMesh, ...
            RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius);
        
        % Store the results
        guiData.results(i).RadiusScaling = RadiusScaling;
        guiData.results(i).Iterations = Iterations;
        guiData.results(i).ContractionBias = ContractionBias;
        guiData.results(i).SmoothFactor = SmoothFactor;
        guiData.results(i).sizeIm = sizeIm;
        guiData.results(i).realCenterDim = realCenterDim;
        guiData.results(i).initialRadius = initialRadius;
        guiData.results(i).contours = contours;
        guiData.results(i).middlePoints = middlePoints;
        guiData.results(i).shaftNorms = shaftNorms;
        guiData.results(i).mesh = mesh;
    end
    
    % Store the updated results in the figure's UserData
    hFig.UserData.guiData = guiData;
    
    % Notify the user that calculations are done
    uialert(hFig, 'Calculations completed successfully!', 'Success');
end

function plotResults(ddPlotType, dropdowns, params, guiData)
    get(hFig)
    assignin('base',"guiData",hFig.UserData.guiData)
    % Access the results stored in the GUI
    results = hFig.UserData.guiData.results;
    
    % Retrieve the selected parameter values from the dropdowns
    selectedValues = zeros(1, length(params));
    for i = 1:length(params)
        selectedValues(i) = str2double(dropdowns{i}.Value);
    end

    selectedValues
    results
    
    % Set a tolerance for floating-point comparisons
    tolerance = 1e-6;
    
    % Find the result with the selected parameters using tolerance
    idx = find(...
        abs([results.RadiusScaling] - selectedValues(1)) < tolerance & ...
        abs([results.Iterations] - selectedValues(2)) < tolerance & ...
        abs([results.ContractionBias] - selectedValues(3)) < tolerance & ...
        abs([results.SmoothFactor] - selectedValues(4)) < tolerance & ...
        abs([results.sizeIm] - selectedValues(5)) < tolerance & ...
        abs([results.realCenterDim] - selectedValues(6)) < tolerance & ...
        abs([results.initialRadius] - selectedValues(7)) < tolerance);
    
    if isempty(idx)
        uialert(uifigure, 'No matching result found.', 'Error');
        return;
    end
    
    % Retrieve the corresponding result
    mesh = results(idx).mesh;
    contours = results(idx).contours;
    middlePoints = results(idx).middlePoints;
    shaftNorms = results(idx).shaftNorms;
    
    plotType = ddPlotType.Value;
    
    if strcmp(plotType, 'Mesh')
        % Plot the mesh
        figure;
        patch('Vertices', mesh.vertices, 'Faces', mesh.faces, ...
              'FaceVertexCData', mesh.vertexNormals, 'FaceColor', 'interp', 'EdgeColor', 'none');
        axis equal;
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Generated Mesh');
        camlight; lighting phong;
    elseif strcmp(plotType, 'Point Cloud with Normals')
        % Plot the point cloud with normals
        figure;
        pcshow(contours);
        hold on;
        quiver3(contours(:,1), contours(:,2), contours(:,3), ...
                shaftNorms(:,1), shaftNorms(:,2), shaftNorms(:,3), 0.5, 'r');
        axis equal;
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Point Cloud with Normals');
        hold off;
    end
end


function saveResults(guiData)
    % Access the results stored in the GUI
    results = guiData.results;
    
    % Open a save dialog
    [file, path] = uiputfile('adaptive_shaft_results.mat', 'Save Results As');
    
    if ischar(file)
        save(fullfile(path, file), 'results');
        uialert(uifigure, 'Results saved successfully!', 'Success');
    end
end

end

% function tryAdaptiveShaftParameters(centreLine, parentMesh)
% 
%     disp('in tryAdaptiveShaft')
%     % Create a figure for the UI
%     hFig = uifigure('Name', 'Adaptive Shaft Parameters');
% 
%     % Positioning variables for UI elements
%     labelX = 20;
%     dropdownX = 130;
%     buttonAddX = 240;
%     buttonRemoveX = 270;
%     dropdownY = 370;
%     spacingY = 40;
% 
%     % Initialize results storage
%     results = struct('RadiusScaling', {1.3}, 'Iterations', {300}, 'ContractionBias', {-0.5}, ...
%                      'SmoothFactor', {1}, 'sizeIm', {100}, 'realCenterDim', {2}, ...
%                      'initialRadius', {10}, 'contours', {}, 'middlePoints', {}, 'mesh', {});
% 
%     % Create UI elements for each parameter
%     params = {'RadiusScaling', 'Iterations', 'ContractionBias', 'SmoothFactor', 'sizeIm', 'realCenterDim', 'initialRadius'};
%     dropdowns = cell(1, length(params));
% 
%     for i = 1:length(params)
%         % Add labels and dropdowns
%         uilabel(hFig, 'Position', [labelX, dropdownY, 100, 22], 'Text', params{i});
%         dropdowns{i} = uidropdown(hFig, 'Position', [dropdownX, dropdownY, 100, 22], ...
%             'Items', unique(arrayfun(@num2str, [results.(params{i})], 'UniformOutput', false)));
% 
%         % Add '+' button for adding values
%         uibutton(hFig, 'Position', [buttonAddX, dropdownY, 22, 22], 'Text', '+', ...
%             'ButtonPushedFcn', @(btn, event) addValueToDropdown(dropdowns{i}, params{i}));
% 
%         % Add '-' button for removing values
%         uibutton(hFig, 'Position', [buttonRemoveX, dropdownY, 22, 22], 'Text', '-', ...
%             'ButtonPushedFcn', @(btn, event) removeValueFromDropdown(dropdowns{i}));
% 
%         % Update Y position for the next dropdown
%         dropdownY = dropdownY - spacingY;
%     end
% 
%     % Create a dropdown to select whether to plot Mesh or Point Cloud with Normals
%     uilabel(hFig, 'Position', [labelX, dropdownY, 100, 22], 'Text', 'Plot Type');
%     ddPlotType = uidropdown(hFig, 'Position', [dropdownX, dropdownY, 100, 22], 'Items', {'Mesh', 'Point Cloud with Normals'});
% 
%     % Button to run calculations
%     btnCalculate = uibutton(hFig, 'Position', [labelX, dropdownY - 40, 210, 22], 'Text', 'Run Calculations', ...
%         'ButtonPushedFcn', @(btn, event) runCalculations(centreLine, parentMesh, dropdowns, params));
% 
%     % Button to plot the results based on selected parameters
%     btnPlot = uibutton(hFig, 'Position', [labelX, dropdownY - 80, 210, 22], 'Text', 'Plot', ...
%         'ButtonPushedFcn', @(btn, event) plotResults(ddPlotType));
% 
%     % Axes for plotting
%     ax = uiaxes(hFig, 'Position', [300, 50, 500, 400]);
% end
% 
% function addValueToDropdown(dropdown, paramName)
%     % Prompt the user for a new value
%     newValue = inputdlg(['Enter new value for ', paramName], 'Add Value');
% 
%     if ~isempty(newValue)
%         % Convert the input to a string and add to the dropdown
%         dropdown.Items = [dropdown.Items; newValue];
%     end
% end
% 
% function removeValueFromDropdown(dropdown)
%     % Get the currently selected value
%     selectedIndex = dropdown.Value;
% 
%     if ~isempty(selectedIndex)
%         % Remove the selected item from the dropdown
%         dropdown.Items(dropdown.ValueIndex) = [];
%     end
% end
% 
% function runCalculations(centreLine, parentMesh, dropdowns, params)
%     % Retrieve current dropdown values
%     ranges = cell(1, length(dropdowns));
%     for i = 1:length(dropdowns)
%         ranges{i} = str2double(dropdowns{i}.Items);
%     end
% 
%     % Generate all combinations of parameters
%     [RadiusScalingGrid, IterationsGrid, ContractionBiasGrid, SmoothFactorGrid, ...
%      sizeImGrid, realCenterDimGrid, initialRadiusGrid] = ndgrid(ranges{:});
% 
%     % Flatten the grids to create arrays of parameter combinations
%     combinations = [RadiusScalingGrid(:), IterationsGrid(:), ContractionBiasGrid(:), ...
%                     SmoothFactorGrid(:), sizeImGrid(:), realCenterDimGrid(:), initialRadiusGrid(:)];
% 
%     % Initialize results storage
%     results = struct('RadiusScaling', {}, 'Iterations', {}, 'ContractionBias', {}, ...
%                      'SmoothFactor', {}, 'sizeIm', {}, 'realCenterDim', {}, ...
%                      'initialRadius', {}, 'contours', {}, 'middlePoints', {}, 'mesh', {});
% 
%     % Loop through all combinations and run the calculations
%     for i = 1:size(combinations, 1)
%         % Extract current parameter combination
%         params = num2cell(combinations(i, :));
%         [RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius] = deal(params{:});
% 
%         % Call the generateAdaptiveShaft function
%         [contours, middlePoints, mesh] = generateAdaptiveShaft(centreLine, parentMesh, ...
%             RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius);
% 
%         % Store the results
%         results(i).RadiusScaling = RadiusScaling;
%         results(i).Iterations = Iterations;
%         results(i).ContractionBias = ContractionBias;
%         results(i).SmoothFactor = SmoothFactor;
%         results(i).sizeIm = sizeIm;
%         results(i).realCenterDim = realCenterDim;
%         results(i).initialRadius = initialRadius;
%         results(i).contours = contours;
%         results(i).middlePoints = middlePoints;
%         results(i).mesh = mesh;
%     end
% 
%     % Save results to a .mat file
%     save('adaptive_shaft_results.mat', 'results');
% 
%     % Notify the user that calculations are done
%     uialert(uifigure, 'Calculations completed successfully!', 'Success');
% end
% 
% function plotResults(ddPlotType)
%     % Load the results from the file
%     load('adaptive_shaft_results.mat', 'results');
% 
%     % If no results were found, display a message
%     if isempty(results)
%         uialert(uifigure, 'No results available. Run calculations first.', 'Error');
%         return;
%     end
% 
%     % For simplicity, plot the first result found
%     mesh = results(1).mesh;
%     contours = results(1).contours;
%     middlePoints = results(1).middlePoints;
% 
%     plotType = ddPlotType.Value;
% 
%     if strcmp(plotType, 'Mesh')
%         % Plot the mesh
%         figure;
%         patch('Vertices', mesh.vertices, 'Faces', mesh.faces, ...
%               'FaceVertexCData', mesh.vertexNormals, 'FaceColor', 'interp', 'EdgeColor', 'none');
%         axis equal;
%         xlabel('X');
%         ylabel('Y');
%         zlabel('Z');
%         title('Generated Mesh');
%         camlight; lighting phong;
%     elseif strcmp(plotType, 'Point Cloud with Normals')
%         % Plot the point cloud with normals
%         figure;
%         pcshow(contours);
%         hold on;
%         quiver3(contours(:,1), contours(:,2), contours(:,3), ...
%                 middlePoints(:,1), middlePoints(:,2), middlePoints(:,3), 0.5, 'r');
%         axis equal;
%         xlabel('X');
%         ylabel('Y');
%         zlabel('Z');
%         title('Point Cloud with Normals');
%         hold off;
%     end
% end


% function tryAdaptiveShaftParameters(centreLine, parentMesh)
% 
%     % Define parameter ranges
%     % RadiusScalingRange = [0.8, 1.0, 1.2];
%     RadiusScalingRange = 1.2;
%     % IterationsRange = [100, 200, 300];
%     IterationsRange = 300;
%     % ContractionBiasRange = [-0.1, -0.3, -0.5];
%     ContractionBiasRange = -0.5;
%     % SmoothFactorRange = [0.5, 1, 1.5];
%     SmoothFactorRange = 1;
%     % sizeImRange = [100, 150, 200];
%     sizeImRange = 100;
%     % realCenterDimRange = [50, 75, 100];
%     realCenterDimRange = 2;
%     % initialRadiusRange = [5, 7, 10];
%     initialRadiusRange = [8, 10];
% 
%     % Generate grids of parameter combinations
%     [RadiusScalingGrid, IterationsGrid, ContractionBiasGrid, SmoothFactorGrid, ...
%      sizeImGrid, realCenterDimGrid, initialRadiusGrid] = ndgrid( ...
%         RadiusScalingRange, IterationsRange, ContractionBiasRange, ...
%         SmoothFactorRange, sizeImRange, realCenterDimRange, initialRadiusRange);
% 
%     % Flatten the grids to create arrays of parameter combinations
%     RadiusScalingArray = RadiusScalingGrid(:);
%     IterationsArray = IterationsGrid(:);
%     ContractionBiasArray = ContractionBiasGrid(:);
%     SmoothFactorArray = SmoothFactorGrid(:);
%     sizeImArray = sizeImGrid(:);
%     realCenterDimArray = realCenterDimGrid(:);
%     initialRadiusArray = initialRadiusGrid(:);
% 
%     % Initialize results storage
%     results = struct('RadiusScaling', {}, 'Iterations', {}, 'ContractionBias', {}, ...
%                      'SmoothFactor', {}, 'sizeIm', {}, 'realCenterDim', {}, ...
%                      'initialRadius', {}, 'contours', {}, 'middlePoints', {}, 'mesh', {});
% 
%     % Loop through parameter combinations
%     for i = 1:length(RadiusScalingArray)
%         RadiusScaling = RadiusScalingArray(i);
%         Iterations = IterationsArray(i);
%         ContractionBias = ContractionBiasArray(i);
%         SmoothFactor = SmoothFactorArray(i);
%         sizeIm = sizeImArray(i);
%         realCenterDim = realCenterDimArray(i);
%         initialRadius = initialRadiusArray(i);
% 
%         % Call the generateAdaptiveShaft function with the current parameters
%         [contours, middlePoints, mesh] = generateAdaptiveShaft(centreLine, parentMesh, ...
%             RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius);
% 
%         disp(['shaft run for i ' num2str(i)])
% 
%         % Store the results
%         results(i).RadiusScaling = RadiusScaling;
%         results(i).Iterations = Iterations;
%         results(i).ContractionBias = ContractionBias;
%         results(i).SmoothFactor = SmoothFactor;
%         results(i).sizeIm = sizeIm;
%         results(i).realCenterDim = realCenterDim;
%         results(i).initialRadius = initialRadius;
%         results(i).contours = contours;
%         results(i).middlePoints = middlePoints;
%         results(i).mesh = mesh;
%     end
% 
%     % Save the results
%     save('adaptive_shaft_results.mat', 'results');
% 
%     % Create UI for selecting parameters and plotting
%     createUI(results);
% end
% 
function [contours, middlePoints, shaftNorms, mesh] = generateAdaptiveShaft(centreLine, parentMesh, RadiusScaling, Iterations, ContractionBias, SmoothFactor, sizeIm, realCenterDim, initialRadius)

    % Calculate mean distance between consecutive points in centre line
    distVect = sqrt(sum(abs(diff(centreLine)).^2, 2));
    meanDist = mean(distVect);

    % Input ROI cube size
    ROIsize = 2; % You can change this as needed
    ROIdepth = 0.8; % You can change this as needed

    % Step as number of position on centre line
    ROIstep = ROIdepth * 0.5; % micrometers
    step = round(ROIstep / meanDist);

    contours = [];
    middlePoints = [];

    endsBuffer = 30;
    pos = (endsBuffer + 1):step:(size(centreLine, 1) - endsBuffer);

    pointsInROI = cell(length(pos), 1);
    A = cell(length(pos), 1);
    B = cell(length(pos), 1);

    for currentPos = 1:length(pos)
        pointA = centreLine(pos(currentPos) - 5, :);
        pointB = centreLine(pos(currentPos) + 5, :);

        A{currentPos} = pointA;
        B{currentPos} = pointB;

        normV = (pointB - pointA) / norm(pointB - pointA);
        vX = [1, 0, 0];

        % Rotation around z
        normVZ = [normV(1), normV(2), 0];
        cosThetaZ = dot(vX, normVZ) / (norm(vX) * norm(normVZ));
        crossProductZ = cross(vX, normVZ);
        thetaZ = sign(crossProductZ(3)) * acos(cosThetaZ);

        % Rotation around y
        normVY = [norm([normV(1), normV(2)]), 0, normV(3)];
        cosThetaY = dot(vX, normVY) / (norm(vX) * norm(normVY));
        crossProductY = cross(vX, normVY);
        thetaY = sign(crossProductY(2)) * acos(cosThetaY);

        xmin = pointA(1) - ROIdepth / 2;
        ymin = pointA(2) - ROIsize / 2;
        zmin = pointA(3) - ROIsize / 2;

        rotation = [0, rad2deg(thetaY), rad2deg(thetaZ)];

        % Create an ROI
        roi = images.roi.Cuboid('Position', [xmin, ymin, zmin, ROIdepth, ROIsize, ROIsize], 'RotationAngle', rotation, 'Visible', 'off');

        tf = inROI(roi, parentMesh.Vertices(:, 1), parentMesh.Vertices(:, 2), parentMesh.Vertices(:, 3));
        pointsInROI{currentPos} = parentMesh.Vertices(tf, :);
    end

    tic
    contourR = cell(length(pos), 1);
    for currentPos = 1:length(pos)
        contourR{currentPos} = IS_active_contour(A{currentPos}, B{currentPos}, pointsInROI{currentPos}, ...
            'RadiusScaling', RadiusScaling, 'Iterations', Iterations, 'ContractionBias', ContractionBias, ...
            'SmoothFactor', SmoothFactor, 'sizeIm', sizeIm, 'realCenterDim', realCenterDim, 'initialRadius', initialRadius);
    end

    disp(['Execution time for active contours: ' num2str(toc)])

    for currentPos = 1:length(pos)
        contours = [contours; contourR{currentPos}];
        middlePoints = [middlePoints; repmat(A{currentPos}, size(contourR{currentPos}, 1), 1)];
    end

    % Calculate mean radius of the shaft
    unq = unique(middlePoints(:, 1));
    middlePointsIdx = 1:length(unq);

    radii = [];
    for r = 2:5:max(middlePointsIdx - 5)
        Idx = find(middlePoints(:, 1) == unq(r), 1);
        [~, radius] = knnsearch(middlePoints(Idx, :), contours(Idx, :));
        radii = [radii; radius(1)];
    end

    meanRadius = mean(radii);
    disp(['Mean radius: ' num2str(meanRadius)])

    numOfCentrePoints = length(contours);
    shaftNorms = nan(size(contours));

    % calculate normals for each point pointing outwards the shaft surface
    for i=1:numOfCentrePoints
        k = middlePoints(i,:);
        n0 = -k + contours(i,:);   % calculate direction vector from center point to contour point
        n0 = n0/norm(n0); % normalize vecor
        shaftNorms(i,:) = n0;
    end

    % Prepare points and normals for Poisson surface reconstruction
    ptVertices = py.numpy.array(contours);
    ptNormals = py.numpy.array(shaftNorms); % Simplified normals

    % Generate mesh using Python Poisson surface reconstruction
    depth = 9; % Adjust as needed
    mesh_data{1} = struct('vertices', ptVertices, ...
                            'vertexNormals', ptNormals);
    [~, meshCell, ~] = reconstruct_mesh_python(depth,mesh_data,0);
    % [~, vertices, faces, vertex_normals,face_normals] = reconstruct_mesh_python(depth, ptVertices, ptNormals, 0);

    % % Convert Python arrays to MATLAB arrays
    % regionID = 1;
    % verticesDict = dictionary(vertices);
    % facesDict = dictionary(faces);
    % vertexNormalsDict = dictionary(vertex_normals);
    % faceNormalsDict = dictionary(face_normals);
    % 
    % vertices = double(verticesDict(py.int(regionID)));
    % faces = double(facesDict(py.int(regionID)))+1;
    % vertexNormals = double(vertexNormalsDict(py.int(regionID)));
    % faceNormals = double(faceNormalsDict(py.int(regionID)));
    % 
    % % Create mesh structure
    % mesh = struct('vertices', vertices, 'faces', faces, 'vertexNormals', vertexNormals, 'faceNormals', faceNormals);

    mesh = meshCell{1};

    % Return results
    contours = contours;
    middlePoints = middlePoints;
end
% 
% function createUI(results)
% 
%     % Create a figure for the UI
%     hFig = uifigure('Name', 'Adaptive Shaft Parameters');
% 
%     % Create dropdowns for selecting parameters
%     uilabel(hFig, 'Position', [20, 370, 100, 22], 'Text', 'Radius Scaling');
%     ddRadiusScaling = uidropdown(hFig, 'Position', [130, 370, 100, 22], 'Items', unique(arrayfun(@num2str, [results.RadiusScaling], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 330, 100, 22], 'Text', 'Iterations');
%     ddIterations = uidropdown(hFig, 'Position', [130, 330, 100, 22], 'Items', unique(arrayfun(@num2str, [results.Iterations], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 290, 100, 22], 'Text', 'Contraction Bias');
%     ddContractionBias = uidropdown(hFig, 'Position', [130, 290, 100, 22], 'Items', unique(arrayfun(@num2str, [results.ContractionBias], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 250, 100, 22], 'Text', 'Smooth Factor');
%     ddSmoothFactor = uidropdown(hFig, 'Position', [130, 250, 100, 22], 'Items', unique(arrayfun(@num2str, [results.SmoothFactor], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 210, 100, 22], 'Text', 'Size Im');
%     ddSizeIm = uidropdown(hFig, 'Position', [130, 210, 100, 22], 'Items', unique(arrayfun(@num2str, [results.sizeIm], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 170, 100, 22], 'Text', 'Real Center Dim');
%     ddRealCenterDim = uidropdown(hFig, 'Position', [130, 170, 100, 22], 'Items', unique(arrayfun(@num2str, [results.realCenterDim], 'UniformOutput', false)));
% 
%     uilabel(hFig, 'Position', [20, 130, 100, 22], 'Text', 'Initial Radius');
%     ddInitialRadius = uidropdown(hFig, 'Position', [130, 130, 100, 22], 'Items', unique(arrayfun(@num2str, [results.initialRadius], 'UniformOutput', false)));
% 
%     % Create a button to plot the mesh
%     btnPlot = uibutton(hFig, 'Position', [20, 80, 210, 22], 'Text', 'Plot Mesh', ...
%         'ButtonPushedFcn', @(btn, event) plotMesh(results, ddRadiusScaling, ddIterations, ddContractionBias, ddSmoothFactor, ddSizeIm, ddRealCenterDim, ddInitialRadius));
% 
%     % Axes for plotting the mesh
%     axMesh = uiaxes(hFig, 'Position', [250, 50, 500, 400]);
% end
% 
% function plotMesh(results, ddRadiusScaling, ddIterations, ddContractionBias, ddSmoothFactor, ddSizeIm, ddRealCenterDim, ddInitialRadius)
% 
%     % Get selected parameters
%     RadiusScaling = str2double(ddRadiusScaling.Value);
%     Iterations = str2double(ddIterations.Value);
%     ContractionBias = str2double(ddContractionBias.Value);
%     SmoothFactor = str2double(ddSmoothFactor.Value);
%     sizeIm = str2double(ddSizeIm.Value);
%     realCenterDim = str2double(ddRealCenterDim.Value);
%     initialRadius = str2double(ddInitialRadius.Value);
% 
%     % Find the result with the selected parameters
%     idx = find([results.RadiusScaling] == RadiusScaling & ...
%                [results.Iterations] == Iterations & ...
%                [results.ContractionBias] == ContractionBias & ...
%                [results.SmoothFactor] == SmoothFactor & ...
%                [results.sizeIm] == sizeIm & ...
%                [results.realCenterDim] == realCenterDim & ...
%                [results.initialRadius] == initialRadius);
% 
%     if ~isempty(idx)
%         mesh = results(idx).mesh;
% 
%         % Plot the mesh using patch
%         figure;
%         patch('Vertices', mesh.vertices, 'Faces', mesh.faces, ...
%               'FaceVertexCData', mesh.vertexNormals, 'FaceColor', 'interp', 'EdgeColor', 'none');
%         axis equal;
%         xlabel('X');
%         ylabel('Y');
%         zlabel('Z');
%         title('Resulting Mesh');
%         camlight; lighting phong;
%     else
%         disp('No matching result found.');
%     end
% end
% 
% 
% % function plotMesh(results, ddRadiusScaling, ddIterations, ddContractionBias, ddSmoothFactor, ddSizeIm, ddRealCenterDim, ddInitialRadius)
% % 
% %     % Get selected parameters
% %     RadiusScaling = str2double(ddRadiusScaling.Value);
% %     Iterations = str2double(ddIterations.Value);
% %     ContractionBias = str2double(ddContractionBias.Value);
% %     SmoothFactor = str2double(ddSmoothFactor.Value);
% %     sizeIm = str2double(ddSizeIm.Value);
% %     realCenterDim = str2double(ddRealCenterDim.Value);
% %     initialRadius = str2double(ddInitialRadius.Value);
% % 
% %     % Find the result with the selected parameters
% %     idx = find([results.RadiusScaling] == RadiusScaling & ...
% %                [results.Iterations] == Iterations & ...
% %                [results.ContractionBias] == ContractionBias & ...
% %                [results.SmoothFactor] == SmoothFactor & ...
% %                [results.sizeIm] == sizeIm & ...
% %                [results.realCenterDim] == realCenterDim & ...
% %                [results.initialRadius] == initialRadius);
% % 
% %     if ~isempty(idx)
% %         mesh = results(idx).mesh;
% % 
% %         % Plot the mesh
% %         trisurf(mesh.faces, mesh.vertices(:, 1), mesh.vertices(:, 2), mesh.vertices(:, 3), 'FaceAlpha', 0.8);
% %         axis equal;
% %         xlabel('X');
% %         ylabel('Y');
% %         zlabel('Z');
% %         title('Resulting Mesh');
% %     else
% %         disp('No matching result found.');
% %     end
% % end
