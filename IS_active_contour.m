function result = IS_active_contour(pointA,pointB,pointsInROI,radiusFactor)

clear binaryImage_high;

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

newCoord(i,:) = [X(1),X(2),X(3)];

end

sinTheta = sqrt((a^2 + b^2)/(a^2 + b^2 + c^2));
cosTheta = cos(asin(sinTheta));
u1 = b/sqrt(a^2 + b^2);
u2 = -a/sqrt(a^2 + b^2);
u3 = 0;

R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
    u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
    u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];


for i=1:size(newCoord)
    v = [newCoord(i,1)-pointA(1),newCoord(i,2)-pointA(2),newCoord(i,3)-pointA(3)];
    vRot = v*R;
    newCoordRotIn(i,1) = (vRot(1));
    newCoordRotIn(i,2) = (vRot(2));
    newCoordRotIn(i,3) = vRot(3);  

end

sizeIm = 400;
shiftX = -min(newCoordRotIn(:,1))+0.05;
shiftY = -min(newCoordRotIn(:,2))+0.05;
rescaleX = (max(newCoordRotIn(:,1))-min(newCoordRotIn(:,1)))*1.1;
rescaleY = (max(newCoordRotIn(:,2))-min(newCoordRotIn(:,2)))*1.1;
Zshift = min(newCoordRotIn(:,3));

newCoordRot(:,1) = (newCoordRotIn(:,1)+shiftX)*sizeIm/rescaleX;
newCoordRot(:,2) = (newCoordRotIn(:,2)+shiftY)*sizeIm/rescaleX;
newCoordRot(:,3) = 0;

binaryImage_high = zeros(sizeIm,sizeIm);

for i=1:size(newCoordRot,1)
    xR = newCoordRot(i,1);
    yR = newCoordRot(i,2);
    binaryImage_high(round(yR),round(xR)) = 255;
end

imshow(binaryImage_high)
r = drawcircle("Center",[(shiftX)*sizeIm/rescaleX,(shiftY)*sizeIm/rescaleX],'Radius',50,'Visible','off');
mask = createMask(r);

bw = activecontour(binaryImage_high,mask,600,'edge','ContractionBias',-0.5);

hold on
visboundaries(bw,'Color','r')
hold off

cont = contour(bw).';
ending = cont(1,2);

simpCont = cont(2:ending,:);

xyProj = [];


xyProj(:,1) = (simpCont(:,1)*(rescaleX)/sizeIm - shiftX)*radiusFactor;
xyProj(:,2) = (simpCont(:,2)*(rescaleX)/sizeIm - shiftY)*radiusFactor;
xyProj(:,3) = zeros(size(simpCont,1),1);

backRotated = [];
R_inv = R';

for i=1:size(xyProj,1)
    v_inv = [xyProj(i,1),xyProj(i,2),Zshift];
    vRotInv = v_inv*R_inv;
    backRotated(i,1) = vRotInv(1)+pointA(1);
    backRotated(i,2) = vRotInv(2)+pointA(2);
    backRotated(i,3) = vRotInv(3)+pointA(3);
end

result = backRotated(:,:);

end