import pymeshlab
import os

def find_intersection_volume(spine = 'temp_1.ply',synapses = 'temp_meshSynapses.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)

    # requires optimization!!!
    # it is calculating the number of synapses every time, but it is always the same number

    msSynapses = pymeshlab.MeshSet()
    msSynapses.load_new_mesh(synapses)
    num_sep_pre = msSynapses.number_meshes()
    msSynapses.generate_splitting_by_connected_components()
    num_separated = msSynapses.number_meshes() - num_sep_pre

    msAll = pymeshlab.MeshSet()
    msAll.load_new_mesh(spine)
    msAll.load_new_mesh(synapses)
    msAll.generate_boolean_union(first_mesh=0,second_mesh=1)
    num_union_pre = msAll.number_meshes()
    msAll.generate_splitting_by_connected_components()
    num_union = msAll.number_meshes() - num_union_pre
    #print('numbers')
    #print(num_separated)
    #print(num_union)

    contains_synapse = False
    volume = 0
    if num_separated >= num_union:
        msAll.generate_boolean_intersection(first_mesh=1,second_mesh=0)
        contains_synapse = True
        volume = msAll.get_geometric_measures()['mesh_volume']
    return([contains_synapse,volume])

results = find_intersection_volume(spine_name,synapses_name,temp_path=path)

