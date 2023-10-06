import pymeshlab
import pyvista as pv
import trimesh


'''
def pt_shaft_to_mesh(depth=6):
    shaftset = pymeshlab.MeshSet()

    shaftset.load_new_mesh('temp_ptShaft.ply')
    shaftset.generate_surface_reconstruction_screened_poisson(depth=int(depth))
    shaftset.save_current_mesh('temp_meshShaft.ply')

    return()
'''

def intersection_of_meshes(neuron_name='temp_meshNeuron.ply',shaft_name='temp_meshShaft.ply'):
    neuron = trimesh.load_mesh(neuron_name)
    shaft = trimesh.load_mesh(shaft_name)
    neuron_pv = pv.wrap(neuron)
    shaft_pv = pv.wrap(shaft)

    intersection = neuron_pv.boolean_intersection(shaft_pv)
    intersection.save('temp_meshIntersection.ply')

    return()

intersection_of_meshes()



