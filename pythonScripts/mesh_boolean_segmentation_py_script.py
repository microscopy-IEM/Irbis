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
        # print("Mesh is not watertight. Attempting to fix...")

        is_watertight = trimesh.repair.fill_holes(mesh, use_fan=True) # This also does check of is_watertight, but the value should already be cached
        if not is_watertight:
            try:
                # try-except statemenent added here, because the stitch function fails if no faces are produced
                # print("Filling holes did not help. Using stitch")
                new_faces, new_vertices = trimesh.repair.stitch(mesh, insert_vertices=True)
                # print(f'Added {len(new_faces)} faces and {len(new_vertices)} vertices to stitch the mesh.')
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
                # print(f"Error during stitching: {e}")
                # traceback.print_exc()
                pass


    if not mesh.is_winding_consistent:
        # print("Mesh is not winding consistent. Attempting to fix...")
        # This should be after fixing watertightness, as fixing watertightness may change the winding consistency
        trimesh.repair.fix_winding(mesh)  # This also does check of is_winding_consistent, but the value should already be cached

    if mesh.volume < 0:
        # print("Mesh has negative volume. Attempting to fix...")
        mesh.invert()

    # print(f"Final mesh properties: Watertight={mesh.is_watertight}, Winding Consistent={mesh.is_winding_consistent}, Volume={mesh.volume}")

    return mesh



def intersect(main_mesh, helper_mesh):
    """
    Computes the boolean intersection of two meshes.

    Args:
        main_mesh (trimesh.Trimesh): The main mesh.
        helper_mesh (trimesh.Trimesh): The helper mesh.

    Returns:
        dict: Dictionary with intersection mesh data (indexed from 1).
    """
    intersection_mesh = trimesh.boolean.intersection([main_mesh, helper_mesh], check_volume=False)
    # We do not do split here, because by default, the intersection (dendrite) should be one component anyway
    print(f"Intersection mesh properties: Watertight={intersection_mesh.is_watertight}, Winding Consistent={intersection_mesh.is_winding_consistent}, Volume={intersection_mesh.volume}, Empty={intersection_mesh.is_empty}")
    intersection_objects = {}
    intersection_objects[1] = {       # Start indexing from 1 - adjusted for Matlab
        'vertices': intersection_mesh.vertices,
        'faces': intersection_mesh.faces,
        'vertex_normals': intersection_mesh.vertex_normals if len(intersection_mesh.vertex_normals) > 0 else np.zeros_like(intersection_mesh.vertices),
        'face_normals': intersection_mesh.face_normals if len(intersection_mesh.face_normals) > 0 else np.zeros_like(intersection_mesh.faces)
    }

    return intersection_objects



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

        subtraction_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertex_normals': vertex_normals,
            'face_normals': face_normals
        }

    return subtraction_data



def segment_mesh(mesh_data):
    """
    Main entry point. Fixes the main mesh, loads the helper mesh, computes intersection and subtraction, and returns all results.

    Args:
        mesh_data (list): List of dicts for main and helper meshes.

    Returns:
        dict: Dictionary with parent mesh, intersection objects, subtraction objects, and their counts.
    """
    # main_mesh = fix_mesh(load_mesh(mesh_data[0]))
    main_mesh = load_mesh(mesh_data[0])  # We do not fix this mesh because the repair step was added to the 3D reconstruction
    helper_mesh = load_mesh(mesh_data[1])   # We do not fix this mesh because it has already been 'fixed' during reconstruction

    intersection_objects = intersect(main_mesh, helper_mesh)
    subtraction_objects = subtract_and_separate(main_mesh, helper_mesh)

    parent_object = {
        'vertices': main_mesh.vertices,
        'faces': main_mesh.faces,
        'vertex_normals': main_mesh.vertex_normals if len(main_mesh.vertex_normals) > 0 else np.zeros_like(main_mesh.vertices),
        'face_normals': main_mesh.face_normals if len(main_mesh.face_normals) > 0 else np.zeros_like(main_mesh.faces)
    }

    print(f"Number of intersection objects: {len(intersection_objects)}")
    print(f"Number of subtraction objects: {len(subtraction_objects)}")

    return {
        "parent_mesh": parent_object, 
        "intersection_objects": intersection_objects,
        "n_intersections": len(intersection_objects),
        "subtraction_objects": subtraction_objects, 
        "n_subtractions": len(subtraction_objects)
    }



try:
    output = segment_mesh(mesh_data)
except Exception as e:
    print(f"Error performing mesh intersection: {e}")
    traceback.print_exc()
    sys.exit(1)


