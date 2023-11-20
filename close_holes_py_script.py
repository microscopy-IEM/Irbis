import pymeshlab

def close_holes(input='poinCloud_tp_1_.ply',output='Mesh_temporary.ply'):

    ms = pymeshlab.MeshSet()

    ms.load_new_mesh(str(input))
    ms.meshing_close_holes(maxholesize=300,newfaceselected = False)
    ms.save_current_mesh(str(output),save_vertex_normal=True)

    current_mesh = ms.current_mesh()

    return(current_mesh)    

output = close_holes(input_name,output_name)