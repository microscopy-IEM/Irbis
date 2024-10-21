% Example columnTypes array
columnTypes = {'numeric', 'logical', 'categorical', 'categorical', 'numeric'};

% Step 1: Find the position of the last 'categorical'
categoricalPos = find(strcmp(columnTypes, 'categorical'), 1, 'last');

% Step 2: Get all positions except the one found for 'categorical'
allPositions = 1:length(columnTypes);
nonCategoricalPositions = setdiff(allPositions, categoricalPos);

% Step 3: Sort non-categorical positions to get the closest to the end
% (in reverse order, i.e., closest to the end)
[~, sortedIdx] = sort(nonCategoricalPositions, 'descend');
closestTwoNonCategoricalPos = nonCategoricalPositions(sortedIdx(1:2));

% Output the positions
disp(['Position of last "categorical": ', num2str(categoricalPos)]);
disp(['Positions of the two closest non-categorical: ', num2str(closestTwoNonCategoricalPos)]);
