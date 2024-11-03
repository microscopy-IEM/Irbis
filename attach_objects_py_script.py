import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # to_numpy_array is in utils_py_script.py

def attach_objects(mesh_data):
    """
    Merges multiple meshes into a single mesh and returns the combined vertices, faces, 
    and vertex and face normals. Used mostly for formally connecting multiple disconnected
    meshes together. For example, when the spines get disconnected from the shaft. 

    Parameters:
        mesh_data (list of dict): List of dictionaries, each containing:
            - 'vertices': Vertex coordinates for the mesh (NumPy array or memoryview).
            - 'faces': Face indices for the mesh (NumPy array or memoryview).
            - 'vertexNormals' (optional): Vertex normals (NumPy array or memoryview) - cannot be empty.
            - 'faceNormals' (optional): Face normals (NumPy array or memoryview) - cannot be empty.

    Returns:
        dict: Dictionary with merged mesh data:
            - 'vertices': Merged vertex coordinates as a NumPy array.
            - 'faces': Merged face indices as a NumPy array.
            - 'vertexNormals': Merged vertex normals as a NumPy array
            - 'faceNormals': Merged face normals as a NumPy array
    """
    ms = pymeshlab.MeshSet()

    # Load each mesh from mesh_data, adding optional normals if they exist
    for i, mesh in enumerate(mesh_data):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }

        # Include vertex normals and face normals if available in the input data
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Merge all visible meshes into one and delete original layers
    ms.generate_by_merging_visible_meshes(mergevisible=False, deletelayer=True)

    # Extract vertices, faces, and normals from the merged mesh
    final_mesh = ms.current_mesh()
    output_data = {
        "vertices": to_numpy_array(final_mesh.vertex_matrix(), dtype=np.float64),
        "faces": to_numpy_array(final_mesh.face_matrix(), dtype=np.int32),
        "vertexNormals": to_numpy_array(final_mesh.vertex_normal_matrix(), dtype=np.float64),
        "faceNormals": to_numpy_array(final_mesh.face_normal_matrix(), dtype=np.float64)
    }

    return output_data

# Call the function so that the script can run when called from Matlab
output = attach_objects(mesh_data)