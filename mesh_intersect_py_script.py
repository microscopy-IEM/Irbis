import pymeshlab
import os

def mesh_intersection(bigger = 'temp_meshNeuron.ply', smaller = 'temp_meshShaft.ply', output = 'temp_meshCutCenter.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(bigger)
    ms.load_new_mesh(smaller)
    ms.generate_boolean_intersection(first_mesh = 0, second_mesh = 1)

    ms.save_current_mesh(str(output),save_vertex_normal=True)
    return()

mesh_intersection(temp_path=path)