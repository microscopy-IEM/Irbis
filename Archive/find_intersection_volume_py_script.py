import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def find_intersection_volume(spine_data, synapse_data):
    """
    Calculates intersection volume and checks if a synapse is inside a spine mesh.
    
    Parameters:
        spine_data (dict): Spine mesh with 'vertices', 'faces', and optionally 'vertexNormals'.
        synapse_data (dict): Synapse mesh with 'vertices', 'faces', and optionally 'vertexNormals'.

    Returns:
        dict: Contains 'contains_synapse' (bool) and 'intersection_volume' (float).
    """
    ms = pymeshlab.MeshSet()

    # Load spine mesh
    spine_args = {
        "vertex_matrix": to_numpy_array(spine_data['vertices'], dtype=np.float64),
        "face_matrix": to_numpy_array(spine_data['faces'], dtype=np.int32)
    }
    if 'vertexNormals' in spine_data and spine_data['vertexNormals']:
        spine_args["v_normals_matrix"] = to_numpy_array(spine_data['vertexNormals'], dtype=np.float64)

    m_spine = pymeshlab.Mesh(**spine_args)
    
    # Load synapse mesh
    synapse_args = {
        "vertex_matrix": to_numpy_array(synapse_data['vertices'], dtype=np.float64),
        "face_matrix": to_numpy_array(synapse_data['faces'], dtype=np.int32)
    }
    if 'vertexNormals' in synapse_data and synapse_data['vertexNormals']:
        synapse_args["v_normals_matrix"] = to_numpy_array(synapse_data['vertexNormals'], dtype=np.float64)
        
    m_synapse = pymeshlab.Mesh(**synapse_args)

    ms.add_mesh(m_spine, 'spine_mesh')
    ms.add_mesh(m_synapse, 'synapse_mesh')

    # Split synapse mesh into connected components once for efficiency
    ms.set_current_mesh(new_curr_id=1)
    initial_num_components = ms.mesh_number()
    ms.generate_splitting_by_connected_components()
    num_synapse_components = ms.mesh_number() - initial_num_components

    # Perform union of spine and synapse
    ms.generate_boolean_union(first_mesh=0, second_mesh=1)
    ms.set_current_mesh(new_curr_id=0)
    initial_union_components = ms.mesh_number()
    ms.generate_splitting_by_connected_components()
    num_union_components = ms.mesh_number() - initial_union_components

    # Check if the synapse is contained within the spine
    contains_synapse = False
    intersection_volume = 0
    if num_synapse_components >= num_union_components:
        # Calculate the intersection volume
        ms.generate_boolean_intersection(first_mesh=1, second_mesh=0)
        contains_synapse = True
        intersection_volume = ms.get_geometric_measures()['mesh_volume']

    return {"contains_synapse": contains_synapse, "intersection_volume": intersection_volume}

output = find_intersection_volume(spine_data, synapse_data)

# import pymeshlab
# import os
# 
# def find_intersection_volume(spine = 'temp_1.ply',synapses = 'temp_meshSynapses.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):
# 
#     os.chdir(temp_path)
# 
#     # requires optimization!!!
#     # it is calculating the number of synapses every time, but it is always the same number
# 
#     msSynapses = pymeshlab.MeshSet()
#     msSynapses.load_new_mesh(synapses)
#     num_sep_pre = msSynapses.number_meshes()
#     msSynapses.generate_splitting_by_connected_components()
#     num_separated = msSynapses.number_meshes() - num_sep_pre
# 
#     msAll = pymeshlab.MeshSet()
#     msAll.load_new_mesh(spine)
#     msAll.load_new_mesh(synapses)
#     msAll.generate_boolean_union(first_mesh=0,second_mesh=1)
#     num_union_pre = msAll.number_meshes()
#     msAll.generate_splitting_by_connected_components()
#     num_union = msAll.number_meshes() - num_union_pre
#     #print('numbers')
#     #print(num_separated)
#     #print(num_union)
# 
#     contains_synapse = False
#     volume = 0
#     if num_separated >= num_union:
#         msAll.generate_boolean_intersection(first_mesh=1,second_mesh=0)
#         contains_synapse = True
#         volume = msAll.get_geometric_measures()['mesh_volume']
#     return([contains_synapse,volume])
# 
# results = find_intersection_volume(spine_name,synapses_name,temp_path=path)

