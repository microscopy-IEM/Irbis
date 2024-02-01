import pymeshlab
import os

def attach_objects(object_number=2,temp_path ='C:\\Users\\Public\\MMP\\temp'):
    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()

    for i in range(int(object_number)):
        ms.load_new_mesh(f'attach_{i}.ply')
    print(f'loaded mesh n: {ms.number_meshes()}')

    ms.generate_by_merging_visible_meshes(mergevisible=False,deletelayer=True)

    print(f'adjusted mesh n: {ms.number_meshes()}')

    ms.save_current_mesh(f'attached.ply')

attach_objects(objectNumber,temp_path=path)

#attach_objects(2,temp_path='C:\\Users\\Public\\IrbisApp\\temp')