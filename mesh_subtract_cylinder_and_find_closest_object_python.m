function [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = mesh_subtract_cylinder_and_find_closest_object_python(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_cylinder,faces_cylinder,vertices_original)

    [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = pyrunfile('mesh_subtract_cylinder_and_find_closest_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals","base_points"], ...
        vertices_big=vertices_big,faces_big=faces_big,vertex_normals_big=vertex_normals_big,face_normals_big=face_normals_big, ...
        vertices_cylinder=vertices_cylinder,faces_cylinder=faces_cylinder,vertices_original=vertices_original);

end