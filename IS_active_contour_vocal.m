function result = IS_active_contour_vocal(pointA,pointB,pointsInROI,varargin)

% parameters:
par = inputParser;
addParameter(par,'Iterations',300,@isnumeric);
addParameter(par,'ContractionBias',-0.5,@isnumeric);
addParameter(par,'SmoothFactor',1,@isnumeric);

addParameter(par,'radiusScaling',1.1,@isnumeric);
addParameter(par,'sizeIm',100,@isnumeric);
addParameter(par,'realCenterDim',1,@isnumeric);

parse(par,varargin{:});

sizeIm = par.Results.sizeIm;
realCenterDim = par.Results.realCenterDim;
radiusScaling = par.Results.radiusScaling;

% parameters for active contour algorithm:
Iterations = par.Results.Iterations;
ContractionBias = par.Results.ContractionBias;
SmoothFactor = par.Results.SmoothFactor;

% predefined lists:
pointsRotated = [];
pointsRescaled = [];
contourRescaled = [];

NormalVector = (pointB-pointA)/norm(pointB-pointA);
% BA is the normal vector obtained from the central line direction

ProjVector = [0,1,0];
% currently, the points are projected into the xz plane
% subsequently, they are transformed into the binary image

% parameters describing the rotation into the plane:
cosTheta = dot(ProjVector,NormalVector)/(norm(ProjVector)*norm(NormalVector));
sinTheta = norm(cross(ProjVector,NormalVector))/(norm(ProjVector)*norm(NormalVector));

C = cross(ProjVector,NormalVector);
u1 = C(1)/norm(C);
u2 = C(2)/norm(C);
u3 = C(3)/norm(C);

R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
    u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
    u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];

% rotating the original point cloud to be parallel with a plane:
for i=1:size(pointsInROI,1)
    v = [pointsInROI(i,1)-pointA(1),pointsInROI(i,2)-pointA(2),pointsInROI(i,3)-pointA(3)];
    vRot = v*R;
    pointsRotated(i,1) = vRot(1);
    pointsRotated(i,2) = vRot(2);
    pointsRotated(i,3) = vRot(3);  

end

pointB_rotated = (pointB-pointA)*R

% projecting the point cloud onto a plane and rescaling the dimensions:
pointsRescaled(:,1) = (pointsRotated(:,1))*sizeIm/realCenterDim + sizeIm/2;
pointsRescaled(:,2) = 0;
pointsRescaled(:,3) = (pointsRotated(:,3))*sizeIm/realCenterDim + sizeIm/2;

% transforming the projected and rescaled points into a binary image:
binaryImage = zeros(sizeIm,sizeIm);

for i=1:size(pointsRescaled,1)

    xR = pointsRescaled(i,1);
    yR = pointsRescaled(i,3);
    if xR >= 1 && xR <= sizeIm && yR >= 1 && yR <= sizeIm
        binaryImage(round(yR),round(xR)) = 255;
    end
end

binaryImage = imgaussfilt(binaryImage,2);
binaryImage(binaryImage>2) = 255;

% active contour algorithm:

squaredDist = pointsRescaled(:,1).^2 + pointsRescaled(:,2).^2;
[minDistanceSqrt,index] = min(squaredDist);

disp('minimum radius')
disp(index)
disp(sqrt(minDistanceSqrt))
minDistance = sqrt(minDistanceSqrt);

figure
imshow(binaryImage,[])
r = drawcircle("Center",[sizeIm/2,sizeIm/2],'Radius',10,'Visible','on');
mask = createMask(r);

tic
bw = activecontour(binaryImage,mask,Iterations,'edge','ContractionBias',ContractionBias,'SmoothFactor',SmoothFactor);
toc

hold on
visboundaries(bw,'Color','r')

% calculating contour from the activecontour mask:
cont = contour(bw).';
ending = cont(1,2);

% simplifying contour:
simpCont = cont(2:ending,:);
simpCont = reducepoly(simpCont,0.01);

plot(simpCont(:,1),simpCont(:,2))
drawnow
hold off

% rescaling contour back into the um within the plane:
contourRescaled(:,1) = ((simpCont(:,1)-sizeIm/2)*(realCenterDim)/sizeIm)*radiusScaling;
contourRescaled(:,2) = zeros(size(simpCont,1),1);
contourRescaled(:,3) = ((simpCont(:,2)-sizeIm/2)*(realCenterDim)/sizeIm)*radiusScaling;

contourFinal = [];
R_inv = R';

% rotating contour into the original position of the point cloud:
for i=1:size(contourRescaled,1)
    v_inv = [contourRescaled(i,1),contourRescaled(i,2),contourRescaled(i,3)];
    vRotInv = v_inv*R_inv;
    contourFinal(i,1) = vRotInv(1)+pointA(1);
    contourFinal(i,2) = vRotInv(2)+pointA(2);
    contourFinal(i,3) = vRotInv(3)+pointA(3);
end

pointB_rotatedBack = pointB_rotated*R_inv + pointA;

diff = NormalVector - (pointB_rotatedBack-pointA)
diffangle = acos(dot(pointB_rotatedBack-pointA,NormalVector)/(norm(pointB_rotatedBack-pointA)*norm(NormalVector)))

diffangle2 = acos(dot(contourFinal(1,:)-pointA,NormalVector-pointA)/(norm(NormalVector-pointA)*norm(contourFinal(1,:)-pointA)))
% diffangle2 = acos(dot(backRotated(10,:),pointB)/(norm(pointB)*norm(backRotated(10,:))))
diffangle2 = acos(dot(contourFinal(1,:)-pointA,pointB_rotatedBack-pointA)/(norm(pointB_rotatedBack-pointA)*norm(contourFinal(1,:)-pointA)))

figure
scatter3(pointsInROI(:,1),pointsInROI(:,2),pointsInROI(:,3));
hold on
scatter3(contourFinal(:,1),contourFinal(:,2),contourFinal(:,3));
drawnow
hold off

result = contourFinal(:,:);

end