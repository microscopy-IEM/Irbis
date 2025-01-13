try:
    import trimesh
    import numpy as np
    import sys
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh`')
    sys.exit(1)


def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def fix_mesh(trimesh_mesh, vertices, faces):
    if not trimesh_mesh.is_watertight:
        if 'pymeshfix' not in sys.modules:
            import pymeshfix 

        new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
        trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

    # use this intstead of fix_normals() - which does almost the same if I understand it correctly
    if not trimesh_mesh.is_winding_consistent:
        # non-consistent winding means that two adjacent faces have normals in opposite directions
        trimesh.repair.fix_winding(trimesh_mesh)
    if not trimesh_mesh.is_volume:
        # not volume means (at least in some situation) that the volume is negative - normals point inward
        trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)
    return trimesh_mesh


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
    meshes = []

    # Convert each dictionary to a Trimesh object
    for mesh in mesh_data:
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)

        trimesh_kwargs = {
            "vertices": vertices,
            "faces": faces
        }

        # Add vertex normals and face normals if available
        if 'vertexNormals' in mesh and len(mesh['vertexNormals']) > 0:
            trimesh_kwargs["vertex_normals"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and len(mesh['faceNormals']) > 0:
            trimesh_kwargs["face_normals"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

        # Create trimesh object and add to list
        trimesh_mesh = trimesh.Trimesh(**trimesh_kwargs, process=False)
        trimesh_mesh = fix_mesh(trimesh_mesh, vertices, faces)
        meshes.append(trimesh_mesh)

    # Merge all meshes into one
    merged_mesh = trimesh.util.concatenate(meshes)

    # Prepare output data
    output_data = {
        "vertices": merged_mesh.vertices,
        "faces": merged_mesh.faces,
        "vertexNormals": merged_mesh.vertex_normals if len(merged_mesh.vertex_normals) > 0 else np.zeros_like(merged_mesh.vertices),
        "faceNormals": merged_mesh.face_normals if len(merged_mesh.face_normals) > 0 else np.zeros_like(merged_mesh.faces)
    }

    return output_data


# Call the function to run in a MATLAB workflow
try:
    output = attach_objects(mesh_data)
except Exception as e:
    print(e)
    sys.exit(1)
