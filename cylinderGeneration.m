function dynamic_transform_column
    % Parameters for the column
    nSides = 20; % Number of sides for the circular base (higher gives smoother column)
    nLayers = 10; % Number of vertical subdivisions (higher value adds more vertices)
    radius = 1; % Radius of the column
    height = 5; % Height of the column

    % Define the angular positions for the circular base
    theta = linspace(0, 2*pi, nSides+1);
    x = radius * cos(theta(1:end-1));  % X-coordinates of the circle (excluding duplicate)
    y = radius * sin(theta(1:end-1));  % Y-coordinates of the circle (excluding duplicate)

    % Z-coordinates for each layer (evenly spaced along the height)
    zLayers = linspace(0, height, nLayers);

    % Create the vertices for all layers (circular slices along the height)
    vertices = [];
    for i = 1:nLayers
        z = zLayers(i);  % Z-coordinate for this layer
        vertices = [vertices; x', y', z * ones(nSides, 1)];
    end

    % Center points for the bottom and top faces for triangulation
    centerBottom = [0, 0, 0];  % Center of the bottom face
    centerTop = [0, 0, height];  % Center of the top face

    % Append the center points to the vertices list
    vertices = [vertices; centerBottom; centerTop];

    % Index of the center points in the vertices list
    centerBottomIdx = size(vertices, 1) - 1;
    centerTopIdx = size(vertices, 1);

    % Create triangular faces for the bottom face
    faces_bottom = zeros(nSides, 3);
    for i = 1:nSides
        nextIdx = mod(i, nSides) + 1;  % Circular wrapping index
        faces_bottom(i, :) = [i, nextIdx, centerBottomIdx];  % Triangle connecting to center
    end

    % Create triangular faces for the top face
    faces_top = zeros(nSides, 3);
    for i = 1:nSides
        nextIdx = mod(i, nSides) + 1;
        topLayerStartIdx = (nLayers - 1) * nSides;
        faces_top(i, :) = [topLayerStartIdx + i, topLayerStartIdx + nextIdx, centerTopIdx];
    end

    % Create triangular faces for the sides (between layers)
    faces_sides = [];
    for layer = 1:(nLayers - 1)
        layerStartIdx = (layer - 1) * nSides;  % Starting index of the current layer
        nextLayerStartIdx = layer * nSides;  % Starting index of the next layer
        for i = 1:nSides
            nextIdx = mod(i, nSides) + 1;
            % First triangle for this side face
            faces_sides = [faces_sides; layerStartIdx + i, nextLayerStartIdx + i, nextLayerStartIdx + nextIdx];
            % Second triangle for this side face
            faces_sides = [faces_sides; layerStartIdx + i, nextLayerStartIdx + nextIdx, layerStartIdx + nextIdx];
        end
    end

    % Combine all faces (bottom, top, and sides)
    faces = [faces_bottom; faces_top; faces_sides];

    % Create the figure and UIAxes for the column
    f = figure('Position', [100, 100, 800, 600]);
    ax = uiaxes(f, 'Position', [50, 150, 600, 400]);
    hold(ax, 'on');

    % Draw the column using patch
    h = patch(ax, 'Faces', faces, 'Vertices', vertices, 'FaceColor', 'cyan', 'EdgeColor', 'black');
    view(ax, 3);  % 3D view
    axis(ax, 'equal');

    % Initial transformation parameters
    scale_factor = 1;
    rotation_angles = [0, 0, 0];  % Rotation around X, Y, Z
    translation_vec = [0, 0, 0];   % Translation along X, Y, Z

    % Create the slider for scaling the column
    uicontrol('Style', 'slider', 'Min', 0.5, 'Max', 2, 'Value', 1, ...
              'Position', [200, 100, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'scale'));

    % Create the sliders for rotation (X, Y, Z axes)
    uicontrol('Style', 'slider', 'Min', -180, 'Max', 180, 'Value', 0, ...
              'Position', [50, 50, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'rotateX'));
    uicontrol('Style', 'slider', 'Min', -180, 'Max', 180, 'Value', 0, ...
              'Position', [300, 50, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'rotateY'));
    uicontrol('Style', 'slider', 'Min', -180, 'Max', 180, 'Value', 0, ...
              'Position', [550, 50, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'rotateZ'));

    % Create the sliders for translation (X, Y, Z axes)
    uicontrol('Style', 'slider', 'Min', -5, 'Max', 5, 'Value', 0, ...
              'Position', [50, 20, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'translateX'));
    uicontrol('Style', 'slider', 'Min', -5, 'Max', 5, 'Value', 0, ...
              'Position', [300, 20, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'translateY'));
    uicontrol('Style', 'slider', 'Min', -5, 'Max', 5, 'Value', 0, ...
              'Position', [550, 20, 200, 20], ...
              'Callback', @(src, event) update_transform(src, 'translateZ'));

    % Nested function to update the transformation dynamically
    function update_transform(slider, transformType)
        value = slider.Value;  % Get the slider value
        switch transformType
            case 'scale'
                scale_factor = value;
            case 'rotateX'
                rotation_angles(1) = deg2rad(value);  % Convert to radians
            case 'rotateY'
                rotation_angles(2) = deg2rad(value);
            case 'rotateZ'
                rotation_angles(3) = deg2rad(value);
            case 'translateX'
                translation_vec(1) = value;
            case 'translateY'
                translation_vec(2) = value;
            case 'translateZ'
                translation_vec(3) = value;
        end
        apply_transform();
    end

    % Apply the scaling, rotation, and translation to the column
    function apply_transform()
        % Start with the original vertices
        transformedVertices = vertices;

        % Apply scaling
        transformedVertices = transformedVertices * scale_factor;

        % Apply rotation (X, Y, Z axes)
        R_x = [1 0 0; 0 cos(rotation_angles(1)) -sin(rotation_angles(1)); 0 sin(rotation_angles(1)) cos(rotation_angles(1))];
        R_y = [cos(rotation_angles(2)) 0 sin(rotation_angles(2)); 0 1 0; -sin(rotation_angles(2)) 0 cos(rotation_angles(2))];
        R_z = [cos(rotation_angles(3)) -sin(rotation_angles(3)) 0; sin(rotation_angles(3)) cos(rotation_angles(3)) 0; 0 0 1];
        rotationMatrix = R_z * R_y * R_x;  % Combined rotation matrix
        transformedVertices = (rotationMatrix * transformedVertices')';

        % Apply translation
        transformedVertices = transformedVertices + translation_vec;

        % Update the patch object with the transformed vertices
        set(h, 'Vertices', transformedVertices);

        % Ensure axes remain fixed
        axis(ax, 'equal');
    end
end
