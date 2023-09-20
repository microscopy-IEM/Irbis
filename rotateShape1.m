clc;
close all;
clear all;

load ImarisObjects2.mat

l = vFilaments_1_6_Position_1;
l = l(30:70,:);

% l = [1:10;5.*ones(1,10);5.*ones(1,10)]';
% angles = [0 20 0];
% translation = [0 0 0];
% tform = rigidtform3d(angles,translation);
% 
% l = transformPointsForward(tform,l);

scatter3(l(:,1),l(:,2),l(:,3))
hold on

% r = rectangle('Position',[2,2,4,4])
i = 5;

xc = l(i,1);
yc = l(i,2);
zc = l(i,3);

xp = l(i+1,1);
yp = l(i+1,2);
zp = l(i+1,3);

P1 = [xc yc,zc];
P2 = [xp,yp,zp];

gamma = atand((P2(1) - P1(1)) / (P2(2) - P1(2)))

alpha = atand((P2(1) - P1(1)) / (P2(3) - P1(3)))

% angleradian = acos((P2(2)-P1(2)) / norm(P2-P1))

a = 0.3;
c = [0,0];

n = [1,0.5,0.5];

x = [c(1) - a,c(1) - a,c(1)+a,c(1) + a,c(1) - a];
z = [c(2) - a,c(2) + a,c(2)+a,c(2) - a,c(2) - a];
y = [0 0 0 0 0];

hold on
plot3(x+xc,y+yc,z+zc)

angles = [90-alpha 0 -gamma];
translation = [0 0 0];
tform = rigidtform3d(angles,translation);

[x,y,z] = transformPointsForward(tform,x,y,z);

hold on
plot3(x+xc,y+yc,z+zc)

view(2)
axis equal
ax = gca;

% ax.View = [0 0];
% xlim([0 10])
% ylim([0 10])
% zlim([0 10])

