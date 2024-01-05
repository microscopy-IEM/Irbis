
X = traj(:,1);
Y = traj(:,2);
Z = traj(:,3);

% Vq = interp3(X,Y,Z,V,Xq,Yq,Zq)

fnplt(cscvn(traj(:,[1:end 1])),'r',2)