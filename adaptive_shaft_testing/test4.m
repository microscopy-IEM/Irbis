xyProj = [];

xyProj(:,1) = simpCont(:,1)*rescaleX/sizeIm - shiftX;
xyProj(:,2) = simpCont(:,2)*rescaleX/sizeIm - shiftY;
xyProj(:,3) = zeros(size(simpCont,1),1);

disp(xyProj(1:20,:))

% scatter3(newCoordRotIn(:,1),newCoordRotIn(:,2),newCoordRotIn(:,3))
% hold on
% scatter3(xyProj(:,1),xyProj(:,2),xyProj(:,3))
% hold off

backRotated = [];
% R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
%     u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
%     u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];

R_inv = R';

disp(R*R_inv)

for i=1:size(xyProj,1)
    v_inv = [xyProj(i,1),xyProj(i,2),Zshift];
    vRotInv = v_inv*R_inv;
    backRotated(i,1) = vRotInv(1)+pointA(1);
    backRotated(i,2) = vRotInv(2)+pointA(2);
    backRotated(i,3) = vRotInv(3)+pointA(3);
end

scatter3(newCoord(:,1),newCoord(:,2),newCoord(:,3))
hold on
scatter3(backRotated(:,1),backRotated(:,2),backRotated(:,3))
hold off

