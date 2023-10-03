import pymeshlab

def remesh(input_file = 'temp_meshIntersection.ply',output_file='temp_meshIntersection_remeshed.ply'):
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(input_file)
    ms.remeshing_isotropic_explicit_remeshing(iterations=1)
    ms.save_current_mesh(output_file)

    return()

remesh()