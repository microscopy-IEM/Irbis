% test oversample_mesh
clear all
clc;
close all
addpath(genpath('../src'));
addpath('../data');


filenames = {'tetrahedron';...
             'cube';...
             'octahedron';...
             'icosahedron';...
             'dodecahedron';...
             'dodecahedron2';...
             'disk';...
             'sinusoidal_dodecahedron_MR';...
             'torus_light';...                     
             'meshed_mtlb_logo';...
             'kitten';...
             'Gargoyle_3k';...                        
             };

         
id = 8;         
filename = strcat(cell2mat(filenames(id,1)),'.mat');         
load(filename);
plot_mesh(V,T);

% oversample mesh to 2x to measure the speed differences for large mesh

[V,T] = oversample_mesh_new(V,T); % 'default' / midedge or 'centre'
% [V,T] = oversample_mesh_new(V,T); % 'default' / midedge or 'centre'

% % Oversample the whole mesh with original script
tic
[Vnew,Tnew] = oversample_mesh(V,T); % 'default' / midedge or 'centre'
t1 = toc;
disp(['Oversampled with original script in: ' num2str(t1) ' s'])
plot_mesh(Vnew,Tnew);


tic
[Vnew2,Tnew2] = oversample_mesh_new(V,T); % 'default' / midedge or 'centre'
t2 = toc;
disp(['Oversampled with new script in: ' num2str(t2) ' s'])
plot_mesh(Vnew2,Tnew2);

r = t1/t2;
disp(['Speed improved: ' num2str(r) ' x'])

mesh = surfaceMesh(V,T);
subdivide(mesh,"loop",1);
% subdivide(mesh,"midpoint-split",1);


plot_mesh(mesh.Vertices,double(mesh.Faces));
removeDefects(mesh,"duplicate-vertices")
removeDefects(mesh,"duplicate-faces")
% surfaceMeshShow(mesh)

% % Oversample one triangle subset only; method = 'centre'

% tic
% [Vnew_centre,Tnew_centre] = oversample_mesh_new(V,T,'centre'); % restricted to the first half of the triangle set
% disp(['Oversampled with nwe script in centre mode in: ' num2str(toc) ' s'])
% plot_mesh(Vnew_centre,Tnew_centre);


simplify(mesh,SimplificationMethod="vertex-clustering", ...
VoxelSize=0.05,MergeMethod="Quadric")
plot_mesh(mesh.Vertices,double(mesh.Faces));
