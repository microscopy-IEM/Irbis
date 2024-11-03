# poisson_py_script.py

import pymeshlab
import os

def poisson_plus_decimation(depth=8,fraction_to_keep=0.1,input='poinCloud_tp_1_.ply',output='Mesh_temporary.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh(str(input))
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)

    current_mesh = ms.current_mesh()
    print(current_mesh.face_number())

    face_num = int(current_mesh.face_number() * fraction_to_keep)
    ms.meshing_decimation_quadric_edge_collapse(targetfacenum = face_num,preserveboundary = True, preservenormal = True, preservetopology = True, autoclean = True)

    ms.save_current_mesh(str(output),save_vertex_normal=True)
    print(ms.current_mesh().face_number())

    return(current_mesh)


output = poisson_plus_decimation(d,fraction_to_keep,input_name,output_name,temp_path=path)