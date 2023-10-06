# poisson_py_script.py

import pymeshlab

def poisson(depth=8,input='poinCloud_tp_1_.ply',output='Mesh_temporary.ply'):

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh(str(input))
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    ms.save_current_mesh(str(output),save_vertex_normal=True)

    current_mesh = ms.current_mesh()

    return(current_mesh)


output = poisson(d,input_name,output_name)
print('Python ran shaft_mesh generation')