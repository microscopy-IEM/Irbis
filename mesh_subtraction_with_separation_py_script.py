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
                traceback.print_exc()

    if not mesh.is_winding_consistent:
        print("Mesh is not winding consistent. Attempting to fix...")
        # This should be after fixing watertightness, as fixing watertightness may change the winding consistency
        trimesh.repair.fix_winding(mesh)  # This also does check of is_winding_consistent, but the value should already be cached

    if mesh.volume < 0:
        print("Mesh has negative volume. Attempting to fix...")
        mesh.invert()

    print(f"Final mesh properties: Watertight={mesh.is_watertight}, Winding Consistent={mesh.is_winding_consistent}, Volume={mesh.volume}")

    return mesh



def subtract_and_separate(main_mesh, helper_mesh):
    """
    Computes the boolean difference of two meshes and splits the result into components.

    Args:
        main_mesh (trimesh.Trimesh): The main mesh.
        helper_mesh (trimesh.Trimesh): The helper mesh to subtract.

    Returns:
        dict: Dictionary of separated mesh components (indexed from 1).
    """
    subtraction_mesh = trimesh.boolean.difference([main_mesh, helper_mesh], check_volume=False)
    components = subtraction_mesh.split(only_watertight=False)
    print(f"Subtraction mesh properties: Watertight={subtraction_mesh.is_watertight}, Winding Consistent={subtraction_mesh.is_winding_consistent}, Volume={subtraction_mesh.volume}, Empty={subtraction_mesh.is_empty}")
    print(f"Number of components in subtraction: {len(components)}")
    subtraction_data = {}

    for idx, component in enumerate(components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros_like(faces)

        # Subtraction data is a dictionary where the key is the component index (starting from 1 for Matlab) 
        subtraction_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertex_normals': vertex_normals,
            'face_normals': face_normals
        }

    return subtraction_data



def run_subtraction(mesh_data):
    """
    Main entry point. Loads meshes, performs subtraction and separation, retries with mesh fixing if needed.

    Args:
        mesh_data (list): List of dicts for main and helper meshes.

    Returns:
        dict: Dictionary with subtraction objects and their count.
    """
    main_mesh = load_mesh(mesh_data[0])     # I assume that the main mesh has already been fixed
    helper_mesh = load_mesh(mesh_data[1])   # We do not fix this mesh because it has already been 'fixed' during reconstruction

    subtraction_objects = subtract_and_separate(main_mesh, helper_mesh)

    if len(subtraction_objects) == 0:
        # Try applying the fix to the main mesh and helper mesh, and then try subtraction again
        main_mesh = fix_mesh(main_mesh)
        helper_mesh = fix_mesh(helper_mesh)
        subtraction_objects = subtract_and_separate(main_mesh, helper_mesh)

    print(f"Number of subtraction objects: {len(subtraction_objects)}")

    return {
        "subtraction_objects": subtraction_objects, 
        "n_subtractions": len(subtraction_objects)
    }



try:
    output = run_subtraction(mesh_data)
except Exception as e:
    print(f"Error performing mesh subtraction: {e}")
    traceback.print_exc()
    sys.exit(1)


