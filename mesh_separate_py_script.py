import pymeshlab
import os

def mesh_separate(input = 'temp_meshSynapses.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(input)

    n_complete = ms.number_meshes()
    print(n_complete)

    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()
    print(n_total)

    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)
        j = i + 1 - n_complete
        ms.save_current_mesh(f'temp_{j}.ply')

    n_spines = n_total - n_complete

    return(n_spines)

n_spines = mesh_separate(input_name)