function [n_objects,vertices,faces,vertex_normals,face_normals] = mesh_subtract_and_separate_and_save_plane_python(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)

    [n_objects,vertices,faces,vertex_normals,face_normals] = pyrunfile('mesh_subtract_and_separate_and_save_plane_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals"], ...
        vertices_big=vertices_big,faces_big=faces_big,vertex_normals_big=vertex_normals_big,face_normals_big=face_normals_big, ...
        vertices_small=vertices_small,faces_small=faces_small,vertex_normals_small=vertex_normals_small,face_normals_small=face_normals_small);

end