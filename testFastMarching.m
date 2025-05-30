
% --- Load your 3D image ---
volume = myStack; % Replace with your 3D data

% set everything lower than median to 0 
volume(volume < (median(volume(:))+100)) = 0;

% Normalize to [0,1] and enhance contrast
volume = double(volume)./(2^16);
volume = volume.^2;

% Final normalization
imMax = max(volume(:));
imMin = min(volume(:));
volume = imadjustn(volume, [imMin imMax], []);

midZ = round(size(volume,3)/2);

% --- Select ROIs on mid-slice ---
figure;
imshow(volume(:,:,midZ), []);
title('Draw ROI 1 (start region), then double-click to finish');
h1 = drawfreehand;

title('Draw ROI 2 (end region), then double-click to finish');
h2 = drawfreehand;

% --- Convert ROI masks to full 3D logical masks ---
mask_start = false(size(volume));
mask_end   = false(size(volume));

roi_mask1 = createMask(h1);  % 2D logical mask
roi_mask2 = createMask(h2);  % 2D logical mask

mask_start(:,:,midZ) = roi_mask1;
mask_end(:,:,midZ)   = roi_mask2;

% --- Extract coordinates from masks ---
[startY, startX, startZ] = ind2sub(size(volume), find(mask_start));
[endY, endX, endZ]       = ind2sub(size(volume), find(mask_end));

start_pts = [startY, startX, startZ]';
disp('Start points (ROI 1):');
disp(start_pts);
disp(size(start_pts));
assignin("base", "start_pts", start_pts)
end_pts   = [endY,   endX,   endZ]';
assignin("base", "end_pts", end_pts)

% --- Compute cost map (speed function) ---
W = volume;
W = W - min(W(:));
W = W / max(W(:));
W = 1e-5 + W;
% F = 1 ./ W;
F = W*100;  % Use W directly as the speed function

assert(isfloat(W) && ndims(W) == 3);
assert(isfloat(start_pts) && size(start_pts,1) == 3 && ~isempty(start_pts));
assert(all(isfinite(W(:))) && all(W(:) > 0));


% --- Run Fast Marching (high-level wrapper) ---
options.nb_iter_max = Inf;
options.end_points = end_pts;  % <<-- specify end points for early stopping
[D, S] = perform_fast_marching(F, start_pts, options);

% --- Find best path from the ROI to start ---
min_val = inf;
best_idx = 1;
for i = 1:size(end_pts, 2)
    v = D(end_pts(1,i), end_pts(2,i), end_pts(3,i));
    if v < min_val
        min_val = v;
        best_idx = i;
    end
end

% --- Backtrack shortest path ---
pathInSwappedCoordinates = compute_geodesic(D, end_pts(:, best_idx));

path = pathInSwappedCoordinates([2 1 3], :); % Swap coordinates to match original system

% path = path([2 1 3], :); % Reorder to match original coordinate system
start_pts = start_pts([2 1 3], :);
end_pts   = end_pts([2 1 3], :);



% --- Visualize the volume and path ---
figure;
isosurface(volume, 0.05); % adjust threshold
hold on;
plot3(path(1,:), path(2,:), path(3,:), 'r-', 'LineWidth', 2);
scatter3(start_pts(1,:), start_pts(2,:), start_pts(3,:), 10, 'g', 'filled');
scatter3(end_pts(1,:),   end_pts(2,:),   end_pts(3,:),   10, 'b', 'filled');
title('3D shortest path using Fast Marching');
xlabel('X'); ylabel('Y'); zlabel('Z'); axis equal;
view(3); camlight; lighting gouraud;

figure('Name','Distance Map Viewer','NumberTitle','off');
h = imshow(D(:,:,midZ), []);
colormap('hot'); colorbar;
impixelinfo(h);

hold on;
roi1 = bwperim(mask_start(:,:,midZ));
roi2 = bwperim(mask_end(:,:,midZ));
plot(find(roi1), 'g', 'LineWidth', 1.5); % fallback if bwboundaries fails

% Overlay ROI 1 (start, green)
[B1,~] = bwboundaries(mask_start(:,:,midZ), 'noholes');
for k = 1:length(B1)
    boundary = B1{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end

% Overlay ROI 2 (end, blue)
[B2,~] = bwboundaries(mask_end(:,:,midZ), 'noholes');
for k = 1:length(B2)
    boundary = B2{k};
    plot(boundary(:,2), boundary(:,1), 'b', 'LineWidth', 2);
end
hold off;

% % --- Interactive 2D visualization of the distance map ---
% figure('Name','Distance Transform Viewer','NumberTitle','off');
% hAx = axes('Position', [0.1 0.2 0.85 0.75]);
% hImg = imagesc(D(:,:,midZ)); colormap('hot'); colorbar;
% axis image off;
% title(['Z-plane: ' num2str(midZ)]);

% % Create slider
% hSlider = uicontrol('Style', 'slider', ...
%     'Min', 1, 'Max', size(D,3), ...
%     'Value', midZ, 'SliderStep', [1 1]/(size(D,3)-1), ...
%     'Units', 'normalized', ...
%     'Position', [0.1 0.05 0.8 0.05]);

% % Slider callback
% addlistener(hSlider, 'Value', 'PostSet', @(src,evt) updateSlice());

%     function updateSlice()
%         z = round(hSlider.Value);
%         set(hImg, 'CData', D(:,:,z));
%         title(hAx, ['Z-plane: ' num2str(z)]);
%     end