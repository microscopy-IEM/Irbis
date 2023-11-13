clc;
close all;
clear all;

fullMesh = readSurfaceMesh('temp_meshFull.ply');
dendriteMesh = readSurfaceMesh('temp_meshShaft.ply');


f = figure;
f.Position = [100 300 1000 1000];
ax = gca;
axis equal
grid on
rotate3d 'off'
disableDefaultInteractivity(ax)

MyDragzoom(ax,'on');


ax.XLim = [-5 40];
ax.YLim = [-5 40];
ax.ZLim = [-5 40];

xlabel('x')
ylabel('y')
zlabel('z')

patch(ax,'Faces',dendriteMesh.Faces,'Vertices',dendriteMesh.Vertices,'Tag','ShaftPlot','FaceColor','b','FaceAlpha',0.2,'EdgeColor','b');
hold on
patch(ax,'Faces',fullMesh.Faces,'Vertices',fullMesh.Vertices,'Tag','FullPlot','FaceColor','g','FaceAlpha',0.2,'EdgeColor','g');
hold on

% for s=1:34
%     Mspine = readmatrix(['indfile' num2str(s) '.csv']);
%     disp(Mspine)
%     disp(size(Mspine))
%     plot3(Mspine(:,1),Mspine(:,2),Mspine(:,3),'o','MarkerFaceColor','k')
%     hold on
% end
M = readmatrix('DEV_myfile.csv');

for i=1:size(M,1)
    A = M(i,1:3);
    n = M(i,4:6)/norm(M(i,4:6));
    B = A-n;
    plot3(ax,A(1),A(2),A(3),'r','Marker','o','MarkerFaceColor','r','MarkerSize',12,'Tag','xBallPoint','UserData',[1 0 0]);
    hold on
    plot3(ax,B(1),B(2),B(3),'r','Marker','o','MarkerFaceColor','g','MarkerSize',12,'Tag','xBallPoint','UserData',[1 0 0]);
    hold on
    line(ax,[A(1),B(1)],[A(2),B(2)],[A(3),B(3)],'Tag','xlineLink','Color',[0.3010 0.7450 0.9330],'LineWidth',1);
    hold on
end
hold off