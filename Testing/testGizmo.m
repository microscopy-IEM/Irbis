clc;
close all;
clear all;

my3Dline = [];

f = figure;
f.Position = [100 300 1000 1000];
% plot3(my3Dline(:,1),my3Dline(:,2),my3Dline(:,3),'LineWidth',2)
hold on
ax = gca;
axis equal
grid on
rotate3d 'off'
disableDefaultInteractivity(ax)

ax.YDir = "reverse";

% ax.ZLim = [0, 10];

% % ax.XLim = [-5 5];
% % ax.YLim = [-5 5];
% % ax.ZLim = [-5 5];
ax.XLim = [0 20];
ax.YLim = [0 20];
ax.ZLim = [10 16];
ax.XLimMode = "manual";
ax.YLimMode = "manual";
ax.ZLimMode = "manual";

% get(ax)

ax.CameraUpVectorMode = "manual";
ax.CameraUpVector = [0 0 1];

ax.View = [0 89];

xlabel('x')
ylabel('y')
zlabel('z')

x0 = 10;
y0 = 10;
z0 = 13;

gizmoPointA = plot3(ax,x0,y0,z0,'k','Marker','o','MarkerFaceColor','k','MarkerSize',5,'Tag','gizmoPointA','LineWidth',1);
gizmoPointB = plot3(ax,x0+1,y0+1,z0,'m','Marker','o','MarkerFaceColor','m','MarkerSize',5,'Tag','gizmoPointB','LineWidth',1);


% x0 = my3Dline(50,1);
% y0 = my3Dline(50,2);
% z0 = my3Dline(50,3);

ax.FontUnits = 'pixels';
ax.Units = "pixels";

selection = 'cylinder';

switch selection
    case 'cuboid'
        scalingFactor = 1;
        thickness = 0.1;
        [vertices,faces] = getThinCuboid([1 scalingFactor scalingFactor],1,thickness,1);
        objectStruct = struct('vertices',vertices,'faces',faces);
        % plane-like (cuboid)
        objectStruct.scalePointVectors = {[0 1 1]};
        % objectStruct.symmetryElementVectors = {[0 1 0]};
        objectStruct.symmetryElementVector = [1 1 1];
    case 'cylinder'


        scalingFactor = 1;
        % [vertices,faces] = getThinCuboid([1 scalingFactor scalingFactor],1,0.001,1);
        [vertices,faces] = getCylinder(30,3,0.5,2,1);

        objectStruct = struct('vertices',vertices,'faces',faces);
        % plane-like (cuboid)
        objectStruct.scalePointVectors = {[0 1 1]};

        % cylinder 
        objectStruct.scalePointVectors = {[1 0 1], [0 1 0]};
        % objectStruct.symmetryElementVectors = {[0 1 0]};
        objectStruct.symmetryElementVector = [0 1 0];

        
end

MyDragzoom();
gizmo_cuboid_testing(ax,f,my3Dline,gizmoPointA,gizmoPointB,objectStruct)
% gizmo_app_testing(ax,f,my3Dline,gizmoPointA,gizmoPointB)

% gizmo(ax,[])


% gizmo_cuboid(ax,f,my3Dline,gizmoPointA,gizmoPointB,2)

