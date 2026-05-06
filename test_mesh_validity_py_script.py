try:
    import sys
    import numpy as np
    import trimesh
    import traceback
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh pymeshfix`')
    sys.exit(1)



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



def fix_mesh(mesh):
    """
    Attempt to repair a mesh to ensure watertightness, winding consistency, and positive volume.

    Args:
        mesh (trimesh.Trimesh): Input mesh to repair.

    Returns:
        trimesh.Trimesh: Repaired mesh.
    """
    if not mesh.is_watertight:
        print("Mesh is not watertight. Attempting to fix...")

        is_watertight = trimesh.repair.fill_holes(mesh, use_fan=True) # This also does check of is_watertight, but the value should already be cached
        if not is_watertight:
            try:
                # try-except statemenent added here, because the stitch function fails if no faces are produced
                print("Filling holes did not help. Using stitch")
                new_faces, new_vertices = trimesh.repair.stitch(mesh, insert_vertices=True)
                print(f'Added {len(new_faces)} faces and {len(new_vertices)} vertices to stitch the mesh.')
                all_faces = np.vstack((mesh.faces, new_faces))
                mesh.faces = all_faces
                all_vertices = np.vstack((mesh.vertices, new_vertices))
                mesh.vertices = all_vertices
                # mesh.remove_unreferenced_vertices()
                # print("Filling holes did not help. Using stitch")
                # new_faces = trimesh.repair.stitch(mesh, insert_vertices=False)
                # print(f'Added {len(new_faces)} faces stitch the mesh.')
                # all_faces = np.vstack((mesh.faces, new_faces))
                # mesh.faces = all_faces
                # mesh.remove_unreferenced_vertices()
            except Exception as e:
                print(f"Error during stitching: {e}")
                # traceback.print_exc()

    if not mesh.is_winding_consistent:
        print("Mesh is not winding consistent. Attempting to fix...")
        # This should be after fixing watertightness, as fixing watertightness may change the winding consistency
        trimesh.repair.fix_winding(mesh)  # This also does check of is_winding_consistent, but the value should already be cached

    if mesh.volume < 0:
        print("Mesh has negative volume. Attempting to fix...")
        mesh.invert()

    print(f"Final mesh properties: Watertight={mesh.is_watertight}, Winding Consistent={mesh.is_winding_consistent}, Volume={mesh.volume}")

    return mesh


fix_mesh(load_mesh(mesh_data))