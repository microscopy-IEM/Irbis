% Provided vertices and faces
vertices = [
    -0.5, -0.5, -0.005;  % Vertex 0
     0.5, -0.5, -0.005;  % Vertex 1
    -0.5,  0.5, -0.005;  % Vertex 2
     0.5,  0.5, -0.005;  % Vertex 3
    -0.5, -0.5,  0.005;  % Vertex 4
     0.5, -0.5,  0.005;  % Vertex 5
    -0.5,  0.5,  0.005;  % Vertex 6
     0.5,  0.5,  0.005   % Vertex 7
];

faces = [
    2, 1, 0;
    1, 2, 3;
    4, 2, 0;
    2, 4, 6;
    1, 4, 0;
    4, 1, 5;
    6, 5, 7;
    5, 6, 4;
    3, 6, 7;
    6, 3, 2;
    5, 3, 7;
    3, 5, 1
];
faces = faces+1;

% Adjust the Z-coordinates to make the cuboid very thin
% thin_factor = 0.01;  % Adjust this to control the thinness of the cuboid
% vertices(:, 3) = vertices(:, 3) * thin_factor;

% Create a new figure
figure;

% Create a patch object for the thin cuboid
p = patch('Vertices', vertices, 'Faces', faces, ...
      'FaceColor', 'cyan', 'EdgeColor', 'black');

% Set axes properties
xlabel('X-axis');
ylabel('Y-axis');
zlabel('Z-axis');
grid on;
axis equal;
view(3);  % 3D view

mesh = surfaceMesh(vertices,faces);
writeSurfaceMesh(mesh,'thinCuboid.stl')

p.XData = p.XData + 10;


