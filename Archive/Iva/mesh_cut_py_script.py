import pymeshlab

def mesh_cut(bigger = 'temp_meshNeuron.ply', smaller = 'temp_meshShaft.ply', output = 'temp_meshSpines.ply'):
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(bigger)
    ms.load_new_mesh(smaller)
    ms.generate_boolean_difference(first_mesh=0,second_mesh=1)

    ms.save_current_mesh(str(output),save_vertex_normal=True)
    return()

mesh_cut()