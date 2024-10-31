import pymeshlab

def attach_objects(mesh_data):
    ms = pymeshlab.MeshSet()
    
    # Iterate through each mesh in mesh_data
    for mesh in mesh_data:
        vertices = mesh['vertices']
        faces = mesh['faces']
        new_mesh = pymeshlab.Mesh(vertex_matrix=vertices, face_matrix=faces)
        ms.add_mesh(new_mesh)
    
    # print(f'Loaded mesh count: {ms.number_meshes()}')

    # Merge visible meshes and delete originals
    ms.generate_by_merging_visible_meshes(mergevisible=False, deletelayer=True)
    
    # print(f'Adjusted mesh count: {ms.number_meshes()}')

    # Ensure final_mesh contains vertices and faces to return
    final_mesh = ms.current_mesh()
    print(final_mesh)
    print(final_mesh.vertex_normal_matrix())
    print(final_mesh.face_normal_matrix())
    vertices = final_mesh.vertex_matrix()
    faces = final_mesh.face_matrix()
    
    # Return the vertices and faces in a dictionary format
    return {'vertices': vertices, 'faces': faces}

joined_dict = attach_objects(mesh_data)

# import pymeshlab
# import os
# 
# def attach_objects(object_number=2,temp_path ='C:\\Users\\Public\\MMP\\temp'):
#     os.chdir(temp_path)
# 
#     ms = pymeshlab.MeshSet()
# 
#     for i in range(int(object_number)):
#         ms.load_new_mesh(f'attach_{i}.ply')
#     print(f'loaded mesh n: {ms.number_meshes()}')
# 
#     ms.generate_by_merging_visible_meshes(mergevisible=False,deletelayer=True)
# 
#     print(f'adjusted mesh n: {ms.number_meshes()}')
# 
#     ms.save_current_mesh(f'attached.ply')
# 
# attach_objects(objectNumber,temp_path=path)
# 
# #attach_objects(2,temp_path='C:\\Users\\Public\\IrbisApp\\temp')