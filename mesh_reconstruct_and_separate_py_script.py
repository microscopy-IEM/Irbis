import pymeshlab
import os
import time

def mesh_reconstruct_and_separate(depth=8,input='temp_pt.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):
    
    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh(str(input))
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)

    start_time = time.time()
    ms.meshing_repair_non_manifold_vertices()
    end_time = time.time()

    print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    start_time = time.time()
    ms.meshing_close_holes(newfaceselected = False)
    end_time = time.time()

    print(f'Execution time for hole filling: {end_time - start_time} s')

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

n_spines = mesh_reconstruct_and_separate(d,input_name,temp_path=path)