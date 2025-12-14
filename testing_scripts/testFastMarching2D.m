
% --- Load your 3D image ---
volume = middlePlane; % Replace with your 3D data

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

start_pts = [startX, startY, startZ]';
if size(volume, 3) == 1
    start_pts = start_pts(1:2, :); % 2D case
end
disp('Start points (ROI 1):');
disp(start_pts);
disp(size(start_pts));
assignin("base", "start_pts", start_pts)
end_pts   = [endX,   endY,   endZ]';
if size(volume, 3) == 1
    end_pts = end_pts(1:2, :); % 2D case
end
assignin("base", "end_pts", end_pts)

% --- Compute cost map (speed function) ---
W = volume;
W = W - min(W(:));
W = W / max(W(:));
W = 1e-5 + W;
F = 1 ./ W;

assert(isfloat(W) && (ndims(W) == 3 || ndims(W) == 2));
assert(isfloat(start_pts) && (size(start_pts,1) == 3 || size(start_pts,1) == 2) && ~isempty(start_pts));
assert(all(isfinite(W(:))) && all(W(:) > 0));


% --- Run Fast Marching (high-level wrapper) ---
options.nb_iter_max = Inf;
options.end_points = end_pts;  % <<-- specify end points for early stopping
[D, S] = perform_fast_marching(F, start_pts, options);

% --- Find best path from the ROI to start ---
min_val = inf;
best_idx = 1;
for i = 1:size(end_pts, 2)
    v = D(end_pts(1,i), end_pts(2,i));
    if v < min_val
        min_val = v;
        best_idx = i;
    end
end

% --- Backtrack shortest path ---
path = compute_geodesic(D, end_pts(:, best_idx));

% --- Visualize the volume and path ---
figure;
% isosurface(volume, 0.05); % adjust threshold
imshow(volume(:,:), []);
hold on;
plot(path(1,:), path(2,:), 'r-', 'LineWidth', 2);
scatter(start_pts(1,:), start_pts(2,:), 10, 'g', 'filled');
scatter(end_pts(1,:),   end_pts(2,:),   10, 'b', 'filled');
title('3D shortest path using Fast Marching');
xlabel('X'); ylabel('Y'); axis equal;
view(3); camlight; lighting gouraud;

figure('Name','Distance Map Viewer','NumberTitle','off');
h = imshow(D(:,:), []);
colormap('hot'); colorbar;
impixelinfo(h);

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