import pymeshlab
import os
import time

def reconstruct_mesh(depth=8,input='temp_pt.ply',output='temp_mesh.ply',temp_path ='C:\\Users\\Public\\MMP\\temp',fraction_to_keep=0.8,min_vertex_num=20,separate=1):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()

    start_time = time.time()
    ms.load_new_mesh(str(input))  
    end_time = time.time()
    print(f'Execution time for loading: {end_time - start_time} s')

    start_time = time.time()
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    end_time = time.time()
    print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')

    start_time = time.time()
    ms.meshing_repair_non_manifold_vertices()
    end_time = time.time()
    print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    start_time = time.time()
    ms.meshing_close_holes(newfaceselected = False)
    end_time = time.time()
    print(f'Execution time for hole filling: {end_time - start_time} s')

    fraction_to_keep = float(fraction_to_keep)
    if fraction_to_keep != 1:
        start_time = time.time()
        face_num = int(ms.current_mesh().face_number() * fraction_to_keep)
        ms.meshing_decimation_quadric_edge_collapse(targetfacenum = face_num,preserveboundary = True, preservenormal = True, preservetopology = True, autoclean = True)
        end_time = time.time()
        print(f'Execution time for decimation: {end_time - start_time} s')

    ms.save_current_mesh(str(output)) 
    if int(separate) == 1:
        n_complete = ms.number_meshes()
        print(n_complete)

        start_time = time.time()
        ms.generate_splitting_by_connected_components()
        end_time = time.time()
        print(f'Execution time for splitting: {end_time - start_time} s') 

        n_total = ms.number_meshes()
        print(n_total)     

        object_num = 1
        for i in range(n_complete,n_total):
            ms.set_current_mesh(new_curr_id = i)
            print(f'Vertex num {object_num}: {ms.current_mesh().vertex_number()}')
            if ms.current_mesh().vertex_number() >= int(min_vertex_num):
                ms.save_current_mesh(f'temp_{object_num}.ply') 
                object_num += 1

        n_objects = n_total - n_complete
        return(object_num-1)
    else:
        return(1)

n_objects = reconstruct_mesh(depth=d,input=input_name,output=output_name,temp_path=path,fraction_to_keep=f,min_vertex_num=nVer,separate=separate)
