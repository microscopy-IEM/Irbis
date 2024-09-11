close all
% Parameters for the column
nSides = 20; % Number of sides for the circular base (higher gives smoother column)
nLayers = 4; % Number of vertical subdivisions (higher value adds more vertices)
radius = 1; % Radius of the column
height = 5; % Height of the cylinder's central part
capRadius = 1; % Radius of the spherical caps (should match the cylinder's radius)

% Define the angular positions for the circular base
theta = linspace(0, 2*pi, nSides+1);
x = radius * cos(theta(1:end-1));  % X-coordinates of the circle (excluding duplicate)
y = radius * sin(theta(1:end-1));  % Y-coordinates of the circle (excluding duplicate)

% Z-coordinates for each layer (evenly spaced along the height)
zLayers = linspace(0, height, nLayers);

% Create the vertices for the cylindrical part
vertices = [];
for i = 1:nLayers
    z = zLayers(i);  % Z-coordinate for this layer
    vertices = [vertices; x', y', z * ones(nSides, 1)];
end

% Number of layers for spherical caps
nCapLayers = 5;

% Top cap vertices (spherical cap)
phi_top = linspace(0, pi/2, nCapLayers); % Elevation angles for the top spherical cap
for i = 2:nCapLayers % Start at 2 to avoid duplicating the top center point
    r = capRadius * sin(phi_top(i));  % Radial distance from the center
    z = height + capRadius * cos(phi_top(i)); % Z-coordinate for the top spherical cap
    vertices = [vertices; r * cos(theta(1:end-1))', r * sin(theta(1:end-1))', z * ones(nSides, 1)];
end
centerTop = [0, 0, height + capRadius]; % Center of the spherical top
vertices = [vertices; centerTop]; % Append the center of the top cap

% Bottom cap vertices (spherical cap)
phi_bottom = linspace(pi/2, pi, nCapLayers); % Elevation angles for the bottom spherical cap
for i = 2:nCapLayers % Start at 2 to avoid duplicating the bottom center point
    r = capRadius * sin(phi_bottom(i));  % Radial distance from the center
    z = capRadius * cos(phi_bottom(i)); % Z-coordinate for the bottom spherical cap
    vertices = [vertices; r * cos(theta(1:end-1))', r * sin(theta(1:end-1))', z * ones(nSides, 1)];
end
centerBottom = [0, 0, 0]; % Center of the spherical bottom (aligned with the base)
vertices = [vertices; centerBottom]; % Append the center of the bottom cap

% Compute total number of vertices
nVertices = size(vertices, 1);

% Correct face indexing for the top and bottom caps:
% The bottom cap needs clockwise face orientation, the top cap needs counterclockwise.

% Bottom cap faces (clockwise)
faces_bottom = [];
startIdx_bottom = nLayers * nSides + (nCapLayers - 1) * nSides;
for i = 1:nSides
    nextIdx = mod(i, nSides) + 1;  % Circular wrapping index
    faces_bottom = [faces_bottom; startIdx_bottom + i, startIdx_bottom + nextIdx, nVertices - 1];  % Clockwise to ensure outward orientation
end

% Top cap faces (counterclockwise)
faces_top = [];
startIdx_top = (nLayers - 1) * nSides;
for i = 1:nSides
    nextIdx = mod(i, nSides) + 1;
    faces_top = [faces_top; startIdx_top + i, nVertices, startIdx_top + nextIdx];  % Counterclockwise to ensure outward orientation
end

% Create triangular faces for the cylindrical sides
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

% Plot the mesh
figure;
h = patch('Vertices', vertices, 'Faces', faces, ...
          'FaceColor', 'cyan', 'EdgeColor', 'black', 'FaceAlpha', 0.7);
axis equal;
xlabel('X');
ylabel('Y');
zlabel('Z');
view(3);

figure;

h = plot3(vertices(:,1),vertices(:,2),vertices(:,3));

mesh = pc2surfacemesh(pointCloud(vertices),"poisson")
surfaceMeshShow(mesh)