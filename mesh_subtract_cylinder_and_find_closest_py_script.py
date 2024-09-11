import pymeshlab
import numpy as np

def mesh_subtract_cylinder_and_find_closest_object(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_cylinder,faces_cylinder,vertices_original):

    ms = pymeshlab.MeshSet()

    if len(vertex_normals_big)==0 or len(face_normals_big)==0:
        m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big)
    else:
        m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big,v_normals_matrix=vertex_normals_big,f_normals_matrix=face_normals_big)

    m_cylinder = pymeshlab.Mesh(vertex_matrix = vertices_cylinder, face_matrix = faces_cylinder)

    ms.add_mesh(m_big)
    ms.add_mesh(m_cylinder)

    ms.generate_boolean_difference(first_mesh=0,second_mesh=1)

    n_complete = ms.number_meshes()
    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()

    # print(n_complete)
    # print(n_total)

    matches = []
    distances = []

    # centreOriginal = np.mean(vertices_original, axis=0)
    # print(centreOriginal)
    # 
    # for i in range(n_complete,n_total):
    #     vertices_cut = ms.mesh(i).vertex_matrix()
    #     distances_i = np.linalg.norm(vertices_cut - centreOriginal, axis=1)
    #     avg_distance = np.mean(distances_i)
    # 
    #     print(avg_distance)
    #     distances.append(avg_distance)
    # 
    # min_distance_n = distances.index(min(distances))
    # min_distance_i = min_distance_n + n_complete

    tolerance = 1e-4
    threshold = 0.1
    # for i in range(n_complete,n_total):
    #     vertices_cut = ms.mesh(i).vertex_matrix()
    #     if len(vertices_cut) < len(vertices_original):
    #         matchList = [np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))]
    #         matchProp = np.sum(matchList)/len(matchList)
    #         #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
    #     elif len(vertices_cut) >= len(vertices_original):
    #         matchList = [np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))]
    #         #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
    #         matchProp = np.sum(matchList)/len(matchList)
    #         if matchProp > 0.1:
    #             matchProp = 1.1
    for i in range(n_complete,n_total):
        # print(i)
        vertices_cut = ms.mesh(i).vertex_matrix()
        if len(vertices_cut) > 0.5*len(vertices_big):
            # print(f'{i} too big')
            matchProp = 0
        elif len(vertices_cut) < len(vertices_original):
            # print(f'{i} smaller than original')
            matchList = [np.any(np.all(np.isclose(vertices_cut[vertex], vertices_original, atol=tolerance),axis = 1)) for vertex in range(0,len(vertices_cut))]
            matchProp = np.sum(matchList)/len(matchList)
            #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
        elif len(vertices_cut) >= len(vertices_original):
            # print(f'{i} bigger than original')
            matchList = [np.any(np.all(np.isclose(vertices_original[vertex], vertices_cut, atol=tolerance),axis = 1)) for vertex in range(0,int(len(vertices_original)))]
            #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
            matchProp = np.sum(matchList)/len(matchList)
            # if matchProp > 0.1:
            #     matchProp = 1.1

        # print(i)
        # print(matchProp)
        # print(len(vertices_cut))
        # print(matchProp)
        # ms.save_current_mesh(f'testMesh_{i}.ply')
        matches.append(matchProp)

    matches_above_threshold = [i for i, value in enumerate(matches) if value > threshold]
    print(matches_above_threshold)
    if len(matches_above_threshold) == 0:
        print('NO MATCH - ALL ADDED')
        ids_above_threshold = [i for i in range(n_complete,n_total)]
    else:
        ids_above_threshold = [m + n_complete for m in matches_above_threshold]
    # print(ids_above_threshold)

    # max_match_n = matches.index(max(matches))
    # max_match_i = max_match_n + n_complete

    vertices_dict = dict()
    faces_dict = dict()
    vertex_normals_dict = dict()
    face_normals_dict = dict()

    base_points = [];

    j = 1
    for i in ids_above_threshold:
        ms.set_current_mesh(new_curr_id = i)
        cm = ms.current_mesh()

        # print(ids_above_threshold[i])
        # j = int(ids_above_threshold[i])
        # print(j)
        
        vertices_dict[j] = cm.vertex_matrix()
        faces_dict[j] = cm.face_matrix()
        vertex_normals_dict[j] = cm.vertex_normal_matrix()
        face_normals_dict[j] = cm.face_normal_matrix()

        base_vertices = []
        
        for vertex_n in range(0,len(cm.vertex_matrix())):
            if np.any(np.all(cm.vertex_matrix()[vertex_n] == vertices_cylinder, axis = 1)):
                base_vertices.append(list(cm.vertex_matrix()[vertex_n]))
        
        av = [item[0] for item in base_vertices]
        bv = [item[1] for item in base_vertices]
        cv = [item[2] for item in base_vertices]

        mean_list = [np.mean(av), np.mean(bv), np.mean(cv)]
        base_points.append(mean_list)

        j += 1

    base_points = np.array(base_points)
        

    # ms.set_current_mesh(new_curr_id = max_match_i)
    # # ms.set_current_mesh(new_curr_id = min_distance_i)
    # cm = ms.current_mesh()

    # vertices_new = cm.vertex_matrix()
    # faces_new = cm.face_matrix()
    # vertex_normals_new = cm.vertex_normal_matrix()
    # face_normals_new = cm.face_normal_matrix()

    # base_vertices = []
    # 
    # for vertex_n in range(0,len(vertices_new)):
    #     if np.any(np.all(vertices_new[vertex_n] == vertices_cylinder, axis = 1)):
    #         base_vertices.append(list(vertices_new[vertex_n]))
    # 
    # av = [item[0] for item in base_vertices]
    # bv = [item[1] for item in base_vertices]
    # cv = [item[2] for item in base_vertices]
    # 
    # base_point = np.array([np.mean(av), np.mean(bv), np.mean(cv)])

    # n_objects = n_total - n_complete
    n_objects = len(ids_above_threshold)

    # return(n_objects,vertices_new,faces_new,vertex_normals_new,face_normals_new,base_points)
    return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict,base_points)

n_objects,vertices,faces,vertex_normals,face_normals,base_points = mesh_subtract_cylinder_and_find_closest_object(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_cylinder,faces_cylinder,vertices_original)






