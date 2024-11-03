# poisson_py_script.py

import pymeshlab
import os
import time

def poisson(depth=8,input='poinCloud_tp_1_.ply',output='Mesh_temporary.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh(str(input))

    print(f'Vertex number: {ms.current_mesh().vertex_number()}')

    # start_time = time.time()
    # ms.generate_sampling_poisson_disk()
    # end_time = time.time()

    # print(f'Execution time for poisson disk sampling: {end_time - start_time} s')   
    start_time = time.time()
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    end_time = time.time()
    print(f'Execution time for poisson reconstruction: {end_time - start_time} s')   
    # print(f'Vertex number: {ms.current_mesh().vertex_number()}')

    start_time = time.time()
    ms.save_current_mesh(str(output),save_vertex_normal=True)
    end_time = time.time()
    print(f'Execution time for saving: {end_time - start_time} s')  

    current_mesh = ms.current_mesh()

    return(current_mesh)


output = poisson(d,input_name,output_name,temp_path=path)