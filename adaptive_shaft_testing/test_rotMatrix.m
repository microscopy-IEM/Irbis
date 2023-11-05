a = pointB(1)-pointA(1);
b = pointB(2)-pointA(2);
c = pointB(3)-pointA(3);
d = a*pointA(1)+b*pointA(2)+c*pointA(3);

v = [a,b,c];
k = [0,0,1];

cosTheta = c/sqrt(a^2 + b^2 + c^2);
disp(cosTheta)
sinTheta = sqrt(a^2 + b^2)/sqrt(a^2 + b^2 + c^2);
u1 = b/sqrt(a^2 + b^2);
u2 = -a/sqrt(a^2 + b^2);
u3 = 0;

u = [u1,u2,u3];

Theta1 = acos(cosTheta);
Theta2 = asin(sinTheta);

disp(Theta1)
disp(Theta2)


cosTheta2 = dot([a,b,c],[0,0,1])/(norm([a,b,c])*norm([0,0,1]))
theta = acos(cosTheta2)

costhetaU1 = dot(v,u)/(norm(v)*norm(u))
thetaU1 = acos(costhetaU1)

