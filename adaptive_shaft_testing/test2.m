newCoord = [];
newCoordRot = [];
newCoordRotIn = [];

a = pointB(1)-pointA(1);
b = pointB(2)-pointA(2);
c = pointB(3)-pointA(3);
d = a*pointA(1)+b*pointA(2)+c*pointA(3);

A=[1 0 0 -a; 0 1 0 -b; 0 0 1 -c; a b c 0];

for i=1:size(pointsInROI)

x = pointsInROI(i,1);
y = pointsInROI(i,2);
z = pointsInROI(i,3);

B=[x; y; z; d];
X=A\B;
px=X(1);
py=X(2);
pz=X(3);

newCoord(i,:) = [px,py,pz];


end

for i=1:1000:size(newCoord,1)
    eo = newCoord(i,:) - pointA;
    oi = pointA - pointB;
    cosTheta = dot(eo,oi)/(norm(eo)*norm(oi));     
    Theta = acos(cosTheta);
    disp(i)
    disp(Theta)
end    

figure
scatter3(pointsInROI(:,1),pointsInROI(:,2),pointsInROI(:,3))
hold on

% disp(pointsInROI(1:20,:))
% disp(newCoord(1:20,:))

% figure
scatter3(newCoord(:,1),newCoord(:,2),newCoord(:,3))
% hold on

% cosTheta = c/sqrt(a^2 + b^2 + c^2);
sinTheta = sqrt((a^2 + b^2)/(a^2 + b^2 + c^2));
cosTheta = cos(asin(sinTheta));
u1 = b/sqrt(a^2 + b^2);
u2 = -a/sqrt(a^2 + b^2);
u3 = 0;

% R_ad = [cosTheta + u1^2 * (1 - cosTheta),      u1 * u2 * (1 - cosTheta),    u2 * sinTheta;
%     u2 * u1 * (1 - cosTheta),    cosTheta + u2^2 * (1 - cosTheta),    u1 * sinTheta;
%     - u2 * sinTheta,    u1 * sinTheta,    cosTheta];
% disp('size(R_ad)')
% disp(size(R_ad))

R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
    u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
    u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];



sizeIm = 400;
for i=1:size(newCoord)
    v = [newCoord(i,1)-pointA(1),newCoord(i,2)-pointA(2),newCoord(i,3)-pointA(3)];
    vRot = v*R;
    newCoordRotIn(i,1) = (vRot(1));
    newCoordRotIn(i,2) = (vRot(2));
    newCoordRotIn(i,3) = vRot(3);    

    % newCoordRot(i,1) = (vRot(1)+3)*sizeIm/4;
    % newCoordRot(i,2) = (vRot(2)+5)*sizeIm/4;
    % newCoordRot(i,3) = 0;
end



rotA = (pointA-pointA)*R;
rotB = (pointB-pointA)*R;

disp('rotated vector')
disp(rotA)
disp(rotB)

for i=1:1000:size(newCoord,1)
    eo = newCoordRotIn(i,:) - rotA;
    oi = rotA - rotB;
    cosTheta = dot(eo,oi)/(norm(eo)*norm(oi));     
    Theta = acos(cosTheta);
    disp(i)
    disp(Theta)
end  

disp('mins')
disp(min(newCoordRotIn(:,1)))
disp(max(newCoordRotIn(:,1)))
disp(min(newCoordRotIn(:,2)))
disp(max(newCoordRotIn(:,2)))
disp(min(newCoordRotIn(:,3)))
disp(max(newCoordRotIn(:,3)))

shiftX = -min(newCoordRotIn(:,1))+0.05;
shiftY = -min(newCoordRotIn(:,2))+0.05;
rescaleX = (max(newCoordRotIn(:,1))-min(newCoordRotIn(:,1)))*1.1;
rescaleY = (max(newCoordRotIn(:,2))-min(newCoordRotIn(:,2)))*1.1;
Zshift = min(newCoordRotIn(:,3));

newCoordRot(:,1) = (newCoordRotIn(:,1)+shiftX)*sizeIm/rescaleX;
newCoordRot(:,2) = (newCoordRotIn(:,2)+shiftY)*sizeIm/rescaleX;
newCoordRot(:,3) = 0;

figure
scatter3(newCoordRotIn(:,1),newCoordRotIn(:,2),newCoordRotIn(:,3))
% disp('newCoordRotIn')
% disp(newCoordRotIn(1:20,:))
hold off

% figure
% scatter3(newCoordRot(:,1),newCoordRot(:,2),newCoordRot(:,3))

binaryImage_high = zeros(sizeIm,sizeIm);

for i=1:size(newCoordRot,1)
    xR = newCoordRot(i,1);
    yR = newCoordRot(i,2);
    binaryImage_high(round(yR),round(xR)) = 255;
end

imshow(binaryImage_high)
%imwrite(binaryImage_high,'point_cloud_image_high.png')
