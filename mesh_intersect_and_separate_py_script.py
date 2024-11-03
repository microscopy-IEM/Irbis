import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # Assumes `to_numpy_array` is defined in utils_py_script.py

def mesh_intersect_and_separate(mesh_data):
    """
    Intersects two meshes and separates the resulting mesh into connected components.
    For example, used for generation of dendritic centre. 
    
    Parameters:
        mesh_data (list): A list of dictionaries with each containing 'vertices', 'faces', 
                          and optionally 'vertexNormals' and 'faceNormals'.
                          
    Returns:
        dict: Contains the number of objects (n_objects), component data with vertices, faces, 
              vertexNormals, and faceNormals for each component.
    """
    ms = pymeshlab.MeshSet()

    # Load the two meshes from mesh_data with the necessary attributes
    for i, mesh in enumerate(mesh_data[:2]):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Create and add the new mesh to the MeshSet
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Perform boolean intersection between the two meshes
    ms.generate_boolean_intersection(first_mesh=0, second_mesh=1)

    # Record the initial mesh count before splitting
    n_complete = ms.mesh_number()

    # Split the result into connected components
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()

    # Prepare dictionaries to store vertices, faces, and normals for each connected component
    component_data = {}

    for i in range(n_complete, n_total):
        ms.set_current_mesh(new_curr_id=i)
        current_mesh = ms.current_mesh()
        component_index = i - n_complete + 1

        # Store the separated component's mesh data
        component_data[component_index] = {
            "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
        }

    n_objects = n_total - n_complete

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }

# Call the function so that the script can run when called from Matlab
output = mesh_intersect_and_separate(mesh_data)