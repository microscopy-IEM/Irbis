import pymeshlab
import os

def mesh_cut_and_separate(bigger = 'temp_meshNeuron.ply', smaller = 'temp_meshShaft.ply', output = 'temp_meshSpines.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(bigger)
    ms.load_new_mesh(smaller)
    ms.generate_boolean_difference(first_mesh=0,second_mesh=1)

    ms.save_current_mesh(str(output),save_vertex_normal=True)

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

n_spines = mesh_cut_and_separate()