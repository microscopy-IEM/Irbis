# poisson_py_script.py

import pymeshlab

def poisson(depth):

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh('poinCloud_tp_1_.ply')
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth))
    ms.save_current_mesh('Mesh_temporary.ply',save_vertex_normal=True)

    current_mesh = ms.current_mesh()

    return(current_mesh)

output = poisson(d)