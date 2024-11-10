import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

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
            - component_colors: Dictionary with arrays of colors of individual vertices for each component.
    """
    ms = pymeshlab.MeshSet()
    
    # Convert vertices_original to a NumPy array with correct data type
    vertices_original = to_numpy_array(vertices_original, dtype=np.float64)
    
    # Load each mesh in mesh_data
    for i, mesh in enumerate(mesh_data):
        # Prepare the mesh arguments dynamically
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Create the PyMeshLab mesh and add to MeshSet with a unique name
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

        try:
            # Apply distinct color to each mesh (e.g., red for first mesh, green for second)
            if i == 0:
                color = pymeshlab.Color(255, 0, 0)
                ms.set_color_per_vertex(color1=color)  # Red for the base mesh
            else:
                color = pymeshlab.Color(0, 255, 0)
                ms.set_color_per_vertex(color1=color)  # Green for the small mesh
        except Exception as e:
            print(f"Error setting color for mesh {i}: {e}")

    # Perform boolean difference between the first two meshes
    ms.generate_boolean_difference(first_mesh=0, second_mesh=1, transfer_vert_color=True)
    
    # Split result into connected components
    n_complete = ms.mesh_number()
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()
    
    all_matches = []

    # Calculate match proportions for each component by comparing against original vertices
    for i in range(n_complete, n_total):
        # Convert the vertices of the current mesh component to a NumPy array
        vertices_cut = to_numpy_array(ms.mesh(i).vertex_matrix(), dtype=np.float64)
        
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

        # Calculate Euclidean distances between each sampled vertex and all vertices in comparison_vertices
        # Broadcasting ensures that `distances` is an array of shape (sampled_vertices.size, comparison_vertices.size)
        # where each element represents the distance from one sampled vertex to one comparison vertex
        distances = np.linalg.norm(sampled_vertices[:, None, :] - comparison_vertices[None, :, :], axis=2)
        
        # Check if each sampled vertex has a match within the defined tolerance by finding distances <= tolerance.
        # `matches` is a boolean array where True indicates a match for that sampled vertex.
        matches = np.any(distances <= float(tolerance), axis=1)
        
        # Calculate the proportion of sampled vertices that have at least one match in the original vertices.
        match_prop = float(np.sum(matches) / len(sampled_vertices))  # Ensure float for Python compatibility
        all_matches.append(match_prop)
    
    # Filter components that meet the match threshold
    ids_above_threshold = [i + n_complete for i, match in enumerate(all_matches) if match > float(threshold)]
    if not ids_above_threshold:
        ids_above_threshold = list(range(n_complete, n_total))  # Include all if none match the threshold

    # Extract component data and calculate base points
    component_data = {}
    base_points = []
    component_colors_array = {}

    for j, component_id in enumerate(ids_above_threshold, start=1):
        ms.set_current_mesh(new_curr_id=component_id)
        current_mesh = ms.current_mesh()

        component_data[j] = {
            "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
        }


        # Extract vertices with green component above a certain threshold to identify those originating from or near the small mesh
        component_colors = current_mesh.vertex_color_matrix()
        green_vertices_mask = component_colors[:, 1] > float(green_threshold)  # Only vertices with green > threshold
        matched_vertices = current_mesh.vertex_matrix()[green_vertices_mask]
        matched_normals = current_mesh.vertex_normal_matrix()[green_vertices_mask]
        component_colors_array[j] = component_colors

        # Calculate base point as the mean position and normal of all selected vertices with high green intensity
        if len(matched_vertices) > 0:
            mean_vertex = np.mean(matched_vertices, axis=0)
            mean_normal = np.mean(matched_normals, axis=0)
            base_points.append(np.concatenate((mean_vertex, mean_normal)))
        else:
            # small_mesh_vertices = to_numpy_array(mesh_data[1]['vertices'], dtype=np.float64)
            # # If no matched vertices are found with the green threshold, select up to 20 unique closest vertices below the distance threshold
            # # Calculate distances between each vertex in the current component mesh and vertices in the small mesh.
            # # The result is a matrix of shape (current_mesh_vertices, small_mesh_vertices) where each element [i, j]
            # # represents the Euclidean distance between vertex i in the current mesh and vertex j in the small mesh.
            # distances = np.linalg.norm(current_mesh.vertex_matrix()[:, None, :] - small_mesh_vertices[None, :, :], axis=2)
            # 
            # # Identify indices where distances are below the specified threshold
            # # This creates a tuple of arrays, where below_threshold_indices[0] contains the indices of `current_mesh.vertex_matrix()`
            # # and below_threshold_indices[1] contains the indices of `small_mesh_vertices` for all pairs below the threshold.
            # below_threshold_indices = np.where(distances < float(distance_threshold))
            # 
            # # Check if any distances met the threshold criteria
            # if below_threshold_indices[0].size > 0:
            #     # Flatten the indices of current mesh vertices that are within the threshold
            #     # `flat_indices` will contain all vertex indices in `current_mesh.vertex_matrix()` that
            #     # have at least one corresponding distance below the threshold.
            #     flat_indices = below_threshold_indices[0]
            # 
            #     # Select up to 20 unique closest vertices within the threshold by using argpartition.
            #     # `np.argpartition` finds the indices of the 20 smallest elements in `distances[below_threshold_indices]`.
            #     # Applying `np.unique` removes duplicate indices, ensuring only unique vertices are chosen.
            #     unique_nearest_indices = np.unique(np.argpartition(distances[below_threshold_indices], 20)[:20])
            # 
            #     # Use these unique indices to retrieve coordinates and normals from the current mesh.
            #     matched_vertices = current_mesh.vertex_matrix()[unique_nearest_indices]
            #     matched_normals = current_mesh.vertex_normal_matrix()[unique_nearest_indices]
            # 
            #     mean_vertex = np.mean(matched_vertices, axis=0)
            #     mean_normal = np.mean(matched_normals, axis=0)
            #     base_points.append(np.concatenate((mean_vertex, mean_normal)))
            # else:
            #     # Append NaNs if no matched vertices
            base_points.append(np.full(6, np.nan))
            

    n_objects = n_total - n_complete
    base_points = np.array(base_points)

    return {
        "n_objects": len(ids_above_threshold),
        "component_data": component_data,
        "base_points": np.array(base_points),
        "component_colors": component_colors_array
    }

output = mesh_subtract_cylinder_and_find_closest_object(mesh_data, vertices_original, tolerance, threshold, min_sample_size, green_threshold, distance_threshold)