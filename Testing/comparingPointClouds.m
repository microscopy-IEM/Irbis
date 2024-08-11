% Assuming pc1 and pc2 are the two pointCloud objects you want to compare

pc1 = movingVerticesOrig;
pc2 = movingVertices;

areEqual = true;
% 
% % Step 1: Compare the number of points
% if pc1.Count ~= pc2.Count
%     disp('Point clouds do not have the same number of points.');
%     areEqual = false;
% else
%     areEqual = true;
% end

% Step 2: Compare the coordinates of the points
if areEqual
    % Sort the points based on their coordinates (in case they are unordered)
    sortedPC1 = sortrows(pc1);
    sortedPC2 = sortrows(pc2);

    % Define a tolerance level
    tolerance = 1e-6;

    % Step 3: Compare the sorted point clouds with tolerance
    if max(abs(sortedPC1(:) - sortedPC2(:))) < tolerance
        disp('The point clouds are the same within the specified tolerance.');
    else
        disp('The point clouds differ beyond the specified tolerance.');
        areEqual = false;
    end
end

disp(max(abs(sortedPC1(:) - sortedPC2(:))))

% Final output
if areEqual
    disp('The point clouds are identical.');
else
    disp('The point clouds are not identical.');
end
