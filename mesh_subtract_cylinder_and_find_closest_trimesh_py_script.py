try:
    import trimesh
    import numpy as np
    from scipy.spatial.distance import cdist
    import sys
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh scipy`')
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

def mesh_subtract_cylinder_and_find_closest_object(mesh_data, vertices_original, tolerance=1e-4, threshold=0.1, min_sample_size=50, green_threshold=0.3, distance_threshold=0.1):
    """
    Subtracts a cylinder from a base mesh, splits the result into connected components, 
    and identifies components that are closest to an original set of vertices.

    Parameters:
        mesh_data (list of dict): List of mesh data dictionaries, each with vertices, faces, 
                                  and optionally vertexNormals and faceNormals.
                                  - mesh_data[0]: Base mesh to subtract from.
                                  - mesh_data[1]: Cylinder mesh to subtract.
        vertices_original (array-like): Array of original vertices to compare against.
        tolerance (float): Tolerance for vertex distance matching.
        threshold (float): Proportion threshold for match acceptance.
        min_sample_size (int): Minimum sample size for efficient matching.
        green_threshold (int): Threshold for the green component to identify vertices connected to the cylinder mesh.
        distance_threshold (float): Threshold for which vertices are considered for calculating base point
            - used if no vertices with green component are found

    Returns:
        dict: Dictionary containing:
            - n_objects: Number of components meeting the match criteria.
            - component_data: Dictionary with vertices, faces, vertexNormals, and faceNormals for each component.
            - base_points: Array of average base points for each component close to the original mesh.
    """
    # Convert vertices_original to a NumPy array with correct data type
    vertices_original = to_numpy_array(vertices_original, dtype=np.float64)
    
    # Create Trimesh objects for the meshes
    base_mesh = trimesh.Trimesh(
        vertices=to_numpy_array(mesh_data[0]['vertices'], dtype=np.float64),
        faces=to_numpy_array(mesh_data[0]['faces'], dtype=np.int32)
    )

    base_mesh = fix_mesh(base_mesh, mesh_data[0]['vertices'], mesh_data[0]['faces'])
    # print(base_mesh.is_volume)
    # print(base_mesh.is_watertight)
    # base_mesh.fix_normals()

    cylinder_mesh = trimesh.Trimesh(
        vertices=to_numpy_array(mesh_data[1]['vertices'], dtype=np.float64),
        faces=to_numpy_array(mesh_data[1]['faces'], dtype=np.int32)
    )

    cylinder_mesh = fix_mesh(cylinder_mesh, mesh_data[1]['vertices'], mesh_data[1]['faces'])

    # Perform boolean difference
    subtracted_mesh = base_mesh.difference(cylinder_mesh)

    if subtracted_mesh is None or subtracted_mesh.is_empty:
        raise ValueError("Boolean subtraction resulted in an empty mesh.")

    # Split result into connected components
    connected_components = subtracted_mesh.split(only_watertight=False)

    all_matches = []

    # Calculate match proportions for each component
    for component in connected_components:
        vertices_cut = component.vertices
        
        # Determine which set of vertices is smaller for efficient distance calculation
        if len(vertices_cut) < len(vertices_original):
            sampled_vertices = vertices_cut
            comparison_vertices = vertices_original
        else:
            sampled_vertices = vertices_original
            comparison_vertices = vertices_cut

        # Downsample sampled_vertices if it exceeds the minimum sample size
        step_size = int(max(1, len(sampled_vertices) // min_sample_size))
        sampled_vertices = sampled_vertices[::step_size]

        # Calculate Euclidean distances
        distances = cdist(sampled_vertices, comparison_vertices)
        matches = np.any(distances <= tolerance, axis=1)

        match_prop = float(np.sum(matches) / len(sampled_vertices))
        all_matches.append(match_prop)

    # Filter components that meet the match threshold
    ids_above_threshold = [i for i, match in enumerate(all_matches) if match > threshold]
    if not ids_above_threshold:
        ids_above_threshold = list(range(len(connected_components)))

    # Extract component data and calculate base points
    component_data = {}
    base_points = []

    for j, component_id in enumerate(ids_above_threshold, start=1):
        component = connected_components[component_id]
        component_data[j] = {
            "vertices": component.vertices,
            "faces": component.faces
        }

        # Calculate base point (mean position and normal)
        mean_vertex = np.mean(component.vertices, axis=0)
        # print(component.vertex_normals)
        if component.vertex_normals is not None:
            mean_normal = np.mean(component.vertex_normals, axis=0)
        else:
            mean_normal = np.array([np.nan, np.nan, np.nan])
        base_points.append(np.concatenate((mean_vertex, mean_normal)))

    n_objects = len(ids_above_threshold)
    base_points = np.array(base_points)

    return {
        "n_objects": n_objects,
        "component_data": component_data,
        "base_points": base_points
    }

# Call from Matlab
try:
    output = mesh_subtract_cylinder_and_find_closest_object(mesh_data, vertices_original, tolerance, threshold, min_sample_size, green_threshold, distance_threshold)
except Exception as e:
    
    print(f"Error: {str(e)}")
    output = None

    sys.exit(1)
    