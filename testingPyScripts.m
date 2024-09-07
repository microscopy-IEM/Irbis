d = load('mesh_data.mat');

verticesBig = py.numpy.array(d.verticesBigMat);
facesBig = py.numpy.array(d.facesBigMat);
vertexNormalsBig = py.numpy.array(d.vertexNormalsBigMat);
faceNormalsBig = py.numpy.array(d.faceNormalsBigMat);

verticesSmall = py.numpy.array(d.verticesSmallMat);
facesSmall = py.numpy.array(d.facesSmallMat);
vertexNormalsSmall = py.numpy.array(d.vertexNormalsSmallMat);
faceNormalsSmall = py.numpy.array(d.faceNormalsSmallMat);

[n_objects,vertices,faces,vertex_normals,face_normals,base_points] = mesh_subtract_and_separate_and_save_plane_python( ...
    verticesBig,facesBig,vertexNormalsBig,faceNormalsBig,verticesSmall,facesSmall,vertexNormalsSmall,faceNormalsSmall)

disp('end of script')