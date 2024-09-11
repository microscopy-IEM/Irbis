fig = figure;

% Create axes for the figure
ax = axes;
hold(ax, 'on');

% Generate random vertices (e.g., 8 random points in 3D space)
nVertices = 8;  % Number of vertices
vertices = rand(nVertices, 3);  % Random vertices in 3D space

% Define random faces by connecting the vertices
% Faces should reference indices in the vertices array
faces = [
    1 2 3;
    1 3 4;
    2 3 5;
    4 5 6;
    6 7 8;
    1 5 8];  % Example of how faces might reference vertices

% Create the random patch object
h = patch(ax, 'Vertices', vertices, 'Faces', faces, ...
    'FaceColor', 'cyan', 'EdgeColor', 'black');



x0 = 0;
y0 = 0;
z0 = 0;
gizmoPointA = plot3(ax,x0,y0,z0,'k','Marker','o','MarkerFaceColor','k','MarkerSize',5,'Tag','gizmoPointA','LineWidth',1);
gizmoPointB = plot3(ax,x0+1,y0+1,z0,'m','Marker','o','MarkerFaceColor','m','MarkerSize',5,'Tag','gizmoPointB','LineWidth',1);


gizmo_app(ax,fig,[],gizmoPointA,gizmoPointB);


% Set axes limits
xlim(ax, [-10 10]);  % X-axis limit from 0 to 1
ylim(ax, [-10 10]);  % Y-axis limit from 0 to 1
zlim(ax, [-10 10]);  % Z-axis limit from 0 to 1

% Set X and Y axis locations
ax.XAxisLocation = 'bottom';  % X-axis on the bottom
ax.YAxisLocation = 'left';    % Y-axis on the left
view(3);  % 3D view