path = 'C:\Users\Public\IrbisApp\temp';
pathAdapted = strrep(path,'\','/');
depth = 8;
input_name = 'temp_ptPrimary.ply';
% input_name = 'temp_ptShaft.ply';
output_name = 'test.ply';

% % n_spines = pyrunfile('mesh_reconstruct_and_separate_py_script.py','n_spines',d=depth,input_name=input_name,path=pathAdapted);
% 
% poisson_pt = pyrunfile('poisson_mesh_py_script.py','output',d=depth,input_name=input_name,output_name=output_name,path=pathAdapted);
% 
% tic
% dendriticMesh = readSurfaceMesh([path '\' 'temp_meshShaft.ply']);
% toc 
% 
% tic
% isWatertight(dendriticMesh)
% toc

n = reconstruct_mesh_python(depth,'temp_ptPrimary.ply',path,fractionToKeep,minVertexNum,'temp_meshPrimary.ply');

% n = reconstruct_mesh_python(depth,input_name,path,0,output_name)