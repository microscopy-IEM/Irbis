import pymeshlab
import numpy as np

def mesh_intersect_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small):

    ms = pymeshlab.MeshSet()

    if not(vertex_normals_big) or not(face_normals_big):
        m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big)
    else:
        m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big,v_normals_matrix=vertex_normals_big,f_normals_matrix=face_normals_big)

    if not(vertex_normals_small) or not(face_normals_small):
        m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small)
    else:
        m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small,v_normals_matrix=vertex_normals_small,f_normals_matrix=face_normals_small)

    ms.add_mesh(m_big)
    ms.add_mesh(m_small)

    ms.generate_boolean_intersection(first_mesh = 0, second_mesh = 1)

    # ms.save_current_mesh(str(output),save_vertex_normal=True)

    n_complete = ms.number_meshes()

    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()

    vertices_dict = dict()
    faces_dict = dict()
    vertex_normals_dict = dict()
    face_normals_dict = dict()

    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)
        cm = ms.current_mesh()
        j = i + 1 - n_complete
        # ms.save_current_mesh(f'temp_intersect_{j}.ply')

        vertices_dict[j] = cm.vertex_matrix()
        faces_dict[j] = cm.face_matrix()
        vertex_normals_dict[j] = cm.vertex_normal_matrix()
        face_normals_dict[j] = cm.face_normal_matrix()

    n_objects = n_total - n_complete

    return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict)

n_objects,vertices,faces,vertex_normals,face_normals = mesh_intersect_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)