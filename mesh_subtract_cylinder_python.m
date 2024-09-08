function [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = mesh_subtract_cylinder_python(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small)

    [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = pyrunfile('mesh_subtract_cylinder_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals","base_points"], ...
        vertices_big=vertices_big,faces_big=faces_big,vertex_normals_big=vertex_normals_big,face_normals_big=face_normals_big, ...
        vertices_small=vertices_small);

end