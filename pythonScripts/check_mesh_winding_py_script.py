try:
    import numpy as np
    import trimesh
except ImportError as e:
    raise RuntimeError(
        "Missing required packages for mesh winding check. "
        "Please install them using `pip install numpy trimesh`."
    ) from e


def to_numpy_array(data, dtype):
    """
    Ensure data is a NumPy array, converting memoryview if needed.

    Args:
        data: Input data (array-like or memoryview).
        dtype: Desired NumPy dtype.

    Returns:
        np.ndarray: Data as a NumPy array of the specified dtype.
    """
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)



def load_mesh(mesh_input):
    """
    Load a mesh from a dictionary containing 'vertices' and 'faces'.

    Args:
        mesh_input (dict): Dictionary with 'vertices' and 'faces' arrays.

    Returns:
        trimesh.Trimesh: Loaded mesh object.
    """
    vertices = to_numpy_array(mesh_input['vertices'], dtype=np.float64)
    faces = to_numpy_array(mesh_input['faces'], dtype=np.int32)
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
    return mesh



try:
    # Expects mesh_data as a dictionary with 'vertices' and 'faces' keys, where values are array-like (e.g. lists, numpy arrays, or memoryviews)
    mesh = load_mesh(mesh_data)
    is_winding_consistent = mesh.is_winding_consistent
except Exception as e:
    raise RuntimeError(f"Error checking mesh winding: {e}") from e
