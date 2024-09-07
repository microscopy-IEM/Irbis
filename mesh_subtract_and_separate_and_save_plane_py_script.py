import pymeshlab
import numpy as np
import os

print('after import 1')

print(os.getenv('QT_QPA_PLATFORM_PLUGIN_PATH'))
os.environ['QT_DEBUG_PLUGINS'] = '1'
os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = r'C:/Users/stepan.kortus/AppData/Local/Programs/Python/Python310/lib/site-packages/pymeshlab/lib/plugins'
print('after import and os setup')

def mesh_subtract_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small):
    print('in function before start')

    print(vertices_big)
    print(faces_big)
    print(vertices_small)
    print(faces_small)
    print(vertex_normals_big)

    mesh = pymeshlab.Mesh()

    # ms = pymeshlab.MeshSet()
    # print('in function after meshset')
    # if len(vertex_normals_big)==0:
    #     print('empty')
    # print('after if')
    # if len(vertex_normals_big)==0 or len(face_normals_big)==0:
    #     m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big)
    # else:
    #     m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big,v_normals_matrix=vertex_normals_big,f_normals_matrix=face_normals_big)
    # 
    # print('after first if')
    # if len(vertex_normals_small)==0 or len(face_normals_small)==0:
    #     m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small)
    # else:
    #     m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small,v_normals_matrix=vertex_normals_small,f_normals_matrix=face_normals_small)
    # 
    # ms.add_mesh(m_big)
    # ms.add_mesh(m_small)
    # 
    # shaft = ms.mesh(1).vertex_matrix()
    # 
    # ms.generate_boolean_difference(first_mesh=0,second_mesh=1)
    # 
    # # ms.save_current_mesh(str(output),save_vertex_normal=True)
    # 
    # n_complete = ms.number_meshes()
    # print(n_complete)
    # 
    # ms.generate_splitting_by_connected_components()
    # 
    # n_total = ms.number_meshes()
    # print(n_total)
    # 
    # # file = open('temp_cuttingPlaneList.csv','w')
    # 
    # vertices_dict = dict()
    # faces_dict = dict()
    # vertex_normals_dict = dict()
    # face_normals_dict = dict()
    # 
    # base_points = [];
    # 
    # for i in range(n_complete,n_total):
    #     ms.set_current_mesh(new_curr_id = i)
    #     cm = ms.current_mesh()
    #     j = i + 1 - n_complete
    #     # ms.save_current_mesh(f'temp_subtract_{j}.ply')
    # 
    #     vertices_dict[j] = cm.vertex_matrix()
    #     faces_dict[j] = cm.face_matrix()
    #     vertex_normals_dict[j] = cm.vertex_normal_matrix()
    #     face_normals_dict[j] = cm.face_normal_matrix()
    # 
    #     spine = ms.mesh(i).vertex_matrix()
    #     spine_normal = ms.mesh(i).vertex_normal_matrix()
    # 
    #     vertices = []
    #     normals = []
    # 
    #     for vertex_n in range(0,len(spine)):
    #         if np.any(np.all(spine[vertex_n] == shaft[:],axis = 1)):
    #             vertices.append(list(spine[vertex_n]))
    #             normals.append(list(spine_normal[vertex_n]))
    # 
    #     av = [item[0] for item in vertices]
    #     bv = [item[1] for item in vertices]
    #     cv = [item[2] for item in vertices]
    #     an = [item[0] for item in normals]
    #     bn = [item[1] for item in normals]
    #     cn = [item[2] for item in normals]
    # 
    #     mean_list = [np.mean(av),np.mean(bv),np.mean(cv),np.mean(an),np.mean(bn),np.mean(cn)]
    # 
    #     base_points.append(mean_list)
    # 
    # #     for mean in mean_list:
    # #         file.write(str(mean) + ';')    
    # #     file.write('\n')
    # # file.close()
    # 
    # n_objects = n_total - n_complete
    # 
    # base_points = np.array(base_points)
    # 
    # # print('base_points lenght')
    # # print(len(base_points))
    n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict,base_points =[0,0,0,0,0,0]
    return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict,base_points)

n_objects,vertices,faces,vertex_normals,face_normals,base_points = mesh_subtract_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)