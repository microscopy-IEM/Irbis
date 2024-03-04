import pymeshlab
import os

def reconstruct_mesh(depth=8,input='temp_pt.ply',output='temp_mesh.ply',temp_path ='C:\\Users\\Public\\MMP\\temp',fraction_to_keep=0.8,min_vertex_num=20,separate=1):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(str(input))  

    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)

    ms.meshing_repair_non_manifold_vertices()

    ms.meshing_close_holes(newfaceselected = False)

    fraction_to_keep = float(fraction_to_keep)
    if fraction_to_keep != 1:
        face_num = int(ms.current_mesh().face_number() * fraction_to_keep)
        ms.meshing_decimation_quadric_edge_collapse(targetfacenum = face_num,preserveboundary = True, preservenormal = True, preservetopology = True, autoclean = True)

    ms.save_current_mesh(str(output))         
    if int(separate) == 1:
        n_complete = ms.mesh_number()

        ms.generate_splitting_by_connected_components()

        n_total = ms.mesh_number()

        object_num = 1
        for i in range(n_complete,n_total):
            ms.set_current_mesh(new_curr_id = i)
            if ms.current_mesh().vertex_number() >= int(min_vertex_num):
                ms.save_current_mesh(f'temp_{object_num}.ply')
                object_num += 1

        n_objects = n_total - n_complete
        return(object_num-1)
    else:
        return(1)

n_objects = reconstruct_mesh(depth=d,input=input_name,output=output_name,temp_path=path,fraction_to_keep=f,min_vertex_num=nVer,separate=separate)
