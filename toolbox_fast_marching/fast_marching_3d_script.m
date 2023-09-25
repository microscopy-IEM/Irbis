for i = 1:27;
    imtemp = im2double(imread('data/smallDendrite_z_stack.tif',i));
    M(:,:,i) = imtemp;
end


start_point = [79;1;13];
end_point = [466;559;16];

clear options;
options.nb_iter_max = Inf;
options.end_points = end_point;

[D,S,Q] = perform_fast_marching(M,start_point,options);

gpath = compute_geodesic(D,end_point);
plot_fast_marching_3d(M,S,gpath,start_point,end_point)

%plot3(gpath(1,:),gpath(2,:),gpath(3,:))