function [outputImages, numLabels] = splitMasksDynamic(image, bufferDistance)
    % Label connected components
    labeledImage = bwlabel(image > 0, 8);
    numLabels = max(labeledImage(:));
    
    % Get mask properties (bounding boxes)
    props = regionprops(image > 0, 'BoundingBox');
    
    % Expand bounding boxes by bufferDistance
    expandedBoxes = cell(numLabels, 1);
    for i = 1:numLabels
        bbox = props(i).BoundingBox;
        expandedBoxes{i} = [
            bbox(1) - bufferDistance, ...
            bbox(2) - bufferDistance, ...
            bbox(3) + 2 * bufferDistance, ...
            bbox(4) + 2 * bufferDistance
        ];
    end
    
    % Initialize adjacency matrix
    adjacency = false(numLabels, numLabels);
    for i = 1:numLabels
        box_i = expandedBoxes{i};
        for j = i+1:numLabels
            box_j = expandedBoxes{j};
            if boxesOverlap(box_i, box_j)
                adjacency(i, j) = true;
                adjacency(j, i) = true;
            end
        end
    end
    
    % Assign groups using graph coloring
    groupAssignment = zeros(numLabels, 1); % Initialize group assignments
    for i = 1:numLabels
        % Find groups of adjacent masks
        neighbors = adjacency(i, :);
        neighborGroups = unique(groupAssignment(neighbors));
        neighborGroups(neighborGroups == 0) = []; % Exclude unassigned neighbors
        
        % Assign the smallest available group
        availableGroups = setdiff(1:numLabels, neighborGroups);
        groupAssignment(i) = availableGroups(1);
    end
    
    % Number of groups used
    numGroups = max(groupAssignment);
    
    % Create output images
    outputImages = cell(numGroups, 1);
    for g = 1:numGroups
        outputImages{g} = zeros(size(image));
        for i = 1:numLabels
            if groupAssignment(i) == g
                outputImages{g}(labeledImage == i) = image(labeledImage == i);
            end
        end
    end
end

function overlap = boxesOverlap(box1, box2)
    % Check if two bounding boxes overlap
    overlap = ~(...
        box1(1) + box1(3) < box2(1) || ... % box1 right < box2 left
        box2(1) + box2(3) < box1(1) || ... % box2 right < box1 left
        box1(2) + box1(4) < box2(2) || ... % box1 bottom < box2 top
        box2(2) + box2(4) < box1(2));      % box2 bottom < box1 top
end
