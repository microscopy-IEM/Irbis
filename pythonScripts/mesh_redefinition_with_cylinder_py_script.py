try:
    import numpy as np
    import trimesh
    from scipy.spatial.distance import cdist
except ImportError as e:
    raise RuntimeError(
        "Missing required packages for cylinder mesh redefinition. "
        "Please install them using `pip install numpy trimesh scipy`."
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
    vertex_normals = to_numpy_array(mesh_input.get('vertex_normals', []), dtype=np.float64)
    face_normals = to_numpy_array(mesh_input.get('face_normals', []), dtype=np.float64)
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, vertex_normals=vertex_normals, face_normals=face_normals, process=True)
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
        # print("Mesh has negative v;olume. Attempting to fix...")
        mesh.invert()

    # print(f"Final mesh properties: Watertight={mesh.is_watertight}, Winding Consistent={mesh.is_winding_consistent}, Volume={mesh.volume}")

    return mesh



def subtract_and_keep_valid(full_mesh, cylinder_mesh, original_spine_mesh, distance_tolerance=1e-4, min_match=0.1):
    """
    Subtracts a cylinder mesh from a full mesh and keeps only components that match the original spine mesh.

    Args:
        full_mesh (trimesh.Trimesh): The full mesh to subtract from.
        cylinder_mesh (trimesh.Trimesh): The cylinder mesh to subtract.
        original_spine_mesh (trimesh.Trimesh): The reference spine mesh for validation.
        distance_tolerance (float): Maximum distance allowed to consider two vertices as matching when validating added components against the original spine mesh.
        min_match (float): Minimum proportion of matching vertices for accepting a component as valid.

    Returns:
        dict: Dictionary of valid subtraction mesh components (indexed from 1).
    """
    subtraction_mesh = trimesh.boolean.difference([full_mesh, cylinder_mesh], check_volume=False)
    components = subtraction_mesh.split(only_watertight=False)
    # print(f"Number of components after subtraction: {len(components)}")
    all_matches = []

    # For each component, calculate the proportion of vertices that are within the tolerance distance to the original spine mesh vertices
    for component in components:
        vertices_cut = component.vertices
        vertices_original = original_spine_mesh.vertices

        # Determine which set of vertices is smaller for efficient distance calculation
        if len(vertices_cut) < len(vertices_original):
            sampled_vertices = vertices_cut
            comparison_vertices = vertices_original
        else:
            sampled_vertices = vertices_original
            comparison_vertices = vertices_cut

        # Downsample sampled_vertices if it exceeds the minimum sample size
        # step_size = int(max(1, len(sampled_vertices) // min_sample_size))
        # sampled_vertices = sampled_vertices[::step_size]

        # Calculate Euclidean distances
        distances = cdist(sampled_vertices, comparison_vertices)    # Array of pairwise distances with size (len(sampled_vertices), len(comparison_vertices))
        matches = np.any(distances <= distance_tolerance, axis=1)

        match_prop = float(np.sum(matches) / len(sampled_vertices))
        all_matches.append(match_prop)

    # Filter components that meet the match threshold
    ids_above_threshold = [i for i, match in enumerate(all_matches) if match > min_match]
    if not ids_above_threshold:
        ids_above_threshold = list(range(len(components)))
    valid_components = [components[i] for i in ids_above_threshold]

    # print(f"Number of valid components after subtraction: {len(valid_components)}")

    valid_subtraction_data = {}
    for idx, component in enumerate(valid_components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros_like(faces)

        valid_subtraction_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertex_normals': vertex_normals,
            'face_normals': face_normals
        }

    return valid_subtraction_data


def adjust_dendrite(cylinder_mesh, original_spine_mesh, original_dendrite_mesh, min_faces, distance_tolerance):
    """
    Adjusts the dendrite mesh by adding lost parts and removing added parts after cylinder subtraction.

    Args:
        cylinder_mesh (trimesh.Trimesh): The cylinder mesh used for subtraction.
        original_spine_mesh (trimesh.Trimesh): The original spine mesh.
        original_dendrite_mesh (trimesh.Trimesh): The original dendrite mesh.
        min_faces (int): Minimum number of faces for a component to be considered valid.
        distance_tolerance (float): Maximum distance allowed to consider two vertices as matching when validating added components against the original spine mesh.

    Returns:
        dict: Dictionary with the new dendrite mesh data (vertices, faces, normals).
    """
    # print(f"Original dendrite mesh properties: Watertight={original_dendrite_mesh.is_watertight}, Winding Consistent={original_dendrite_mesh.is_winding_consistent}, Volume={original_dendrite_mesh.volume}")
    # lost_from_spine = intersection of original spine and cylinder - this should be added to the dendrite
    lost = trimesh.boolean.intersection([original_spine_mesh, cylinder_mesh], check_volume=False)
    split_lost = lost.split(only_watertight=False)
    # print(f"Number of lost components: {len(split_lost)}")
    valid_lost = [fix_mesh(m) for m in split_lost if  len(m.faces) > min_faces]

    if len(valid_lost) > 0:
        new_dendrite_mesh = trimesh.boolean.union([original_dendrite_mesh, *valid_lost], check_volume=False)
    else:
        new_dendrite_mesh = original_dendrite_mesh

    # added_to_spine = dendrite - cylinder_mesh, find only the component that correspond to the new spine
    # print(original_dendrite_mesh.volume)
    # print(cylinder_mesh.volume)
    added = trimesh.boolean.difference([original_dendrite_mesh, cylinder_mesh], check_volume=False)
    split_added = added.split(only_watertight=False)
    # print(f"Number of added components: {len(split_added)}")
    # print(f"Added components volumes: {[m.volume for m in split_added]}")
    # print(f"Added components faces: {[len(m.faces) for m in split_added]}")
    valid_added = [fix_mesh(m) for m in split_added if len(m.faces) > min_faces]
    vertices_original = original_spine_mesh.vertices
    valid_added = [m for m in valid_added if (np.any(cdist(m.vertices, vertices_original) < distance_tolerance) and len(m.faces) > min_faces)]

    if len(valid_added) > 0:
        new_dendrite_mesh = trimesh.boolean.difference([new_dendrite_mesh, *valid_added], check_volume=False)
    # print(f"New dendrite mesh properties: Watertight={new_dendrite_mesh.is_watertight}, Winding Consistent={new_dendrite_mesh.is_winding_consistent}, Volume={new_dendrite_mesh.volume}")
    new_dendrite_data = {
        "vertices": new_dendrite_mesh.vertices,
        "faces": new_dendrite_mesh.faces, 
        "vertex_normals": new_dendrite_mesh.vertex_normals if len(new_dendrite_mesh.vertex_normals) > 0 else np.zeros_like(new_dendrite_mesh.vertices),
        "face_normals": new_dendrite_mesh.face_normals if len(new_dendrite_mesh.face_normals) > 0 else np.zeros_like(new_dendrite_mesh.faces)
    }

    return new_dendrite_data



def redefine_with_cylinder(mesh_data, min_valid_faces=50, distance_tolerance=1e-4, min_match=0.1):
    """
    Main entry point. Redefines a mesh by subtracting a cylinder and adjusting the dendrite mesh.

    Args:
        mesh_data (list): List of dicts for full mesh, cylinder, original spine, and dendrite.

    Returns:
        dict: Dictionary with valid subtraction data, count, and new dendrite data.
    """
    full_mesh = fix_mesh(load_mesh(mesh_data[0]))
    cylinder_mesh = load_mesh(mesh_data[1])
    original_spine_mesh = load_mesh(mesh_data[2])
    original_dendrite_mesh = load_mesh(mesh_data[3])

    valid_subtraction_data = subtract_and_keep_valid(full_mesh, cylinder_mesh, original_spine_mesh, distance_tolerance, min_match)
    new_dendrite_data = adjust_dendrite(cylinder_mesh, original_spine_mesh, original_dendrite_mesh, min_valid_faces, distance_tolerance)

    # print(f"Number of valid components before assignment: {len(valid_subtraction_data)}")

    return {
        "valid_subtraction_data": valid_subtraction_data,
        "n_valid_subtractions": len(valid_subtraction_data),
        "new_dendrite_data": new_dendrite_data
    }



try:
    output = redefine_with_cylinder(mesh_data, min_valid_faces, distance_tolerance, min_match)
except Exception as e:
    raise RuntimeError(
        f"Error performing cylinder subtraction and dendrite adjustment: {e}"
    ) from e
