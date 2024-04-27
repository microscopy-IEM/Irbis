import pymeshlab
import numpy as np

def reconstruct_mesh(depth=8,fraction_to_keep=0.8,min_vertex_num=20,separate=1,pt_vertices = [],pt_normals = []):

    print('in python')
    
    pt_vertices = np.array(pt_vertices)
    pt_normals = np.array(pt_normals)
    print(pt_vertices)
    print(type(pt_vertices))
    print(pt_vertices.dtype)
    print(pt_vertices.shape)
    print(type(pt_normals))
    print(pt_normals.dtype)
    print(pt_normals.shape)


    ms = pymeshlab.MeshSet()

    m = pymeshlab.Mesh(vertex_matrix = pt_vertices,v_normals_matrix = pt_normals)
    ms.add_mesh(m)

    cm = ms.current_mesh()
    print(len(cm.vertex_matrix()))
    print(len(cm.face_matrix()))
    print(len(cm.edge_matrix()))
    print(cm.vertex_normal_matrix())
    print(cm.face_normal_matrix())
    print(cm.vertex_color_matrix())

    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)

    ms.meshing_repair_non_manifold_vertices()

    ms.meshing_close_holes(newfaceselected = False)

    fraction_to_keep = float(fraction_to_keep)
    if fraction_to_keep != 1:
        face_num = int(ms.current_mesh().face_number() * fraction_to_keep)
        ms.meshing_decimation_quadric_edge_collapse(targetfacenum = face_num,preserveboundary = True, preservenormal = True, preservetopology = True, autoclean = True)

    vertices = dict()
    faces = dict()
    vertex_normals = dict()
    face_normals = dict()

    if int(separate) == 1:
        n_complete = ms.number_meshes()

        ms.generate_splitting_by_connected_components()

        n_total = ms.number_meshes()

        object_num = 1

        for i in range(n_complete,n_total):
            ms.set_current_mesh(new_curr_id = i)
            if ms.current_mesh().vertex_number() >= int(min_vertex_num):
                ms.save_current_mesh(f'temp_{object_num}.ply')
                cm = ms.current_mesh()

                # assign the relevant measures to corresponding dicitionaries
                vertices[object_num] = cm.vertex_matrix()
                faces[object_num] = cm.face_matrix()
                vertex_normals[object_num] = cm.vertex_normal_matrix()
                face_normals[object_num] = cm.face_normal_matrix()

                object_num += 1
            # print('mesh attributes')
            # cm = ms.current_mesh()
            # print(dir(cm))
            # 
            # print(len(cm.vertex_matrix()))
            # print(len(cm.face_matrix()))
            # print(len(cm.edge_matrix()))
            # print(cm.vertex_normal_matrix())
            # print(cm.face_normal_matrix())
            # print(cm.vertex_color_matrix())


        n_objects = n_total - n_complete
        
        return((object_num-1),vertices,faces,vertex_normals,face_normals)
    else:
        cm = ms.current_mesh()
        vertices[1] = cm.vertex_matrix()
        faces[1] = cm.face_matrix()
        vertex_normals[1] = cm.vertex_normal_matrix()
        face_normals[1] = cm.face_normal_matrix()

        return(1,vertices,faces,vertex_normals,face_normals)

n_objects,vertices,faces,vertex_normals,face_normals = reconstruct_mesh(depth=d,fraction_to_keep=f,min_vertex_num=nVer,separate=separate,pt_vertices=pt_vertices,pt_normals=pt_normals)
