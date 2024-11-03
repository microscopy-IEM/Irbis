import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # `to_numpy_array` is defined in utils_py_script.py

def mesh_subtract_and_separate_with_color(mesh_data, green_threshold=0.3, tolerance=1e-4, distance_threshold=0.1):
    """
    Subtracts the second mesh from the first, splits the result into connected components, 
    and identifies vertices for base point calculation based on green color intensity.
    For example, used for spines generation.
    
    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces', and optionally 'vertexNormals' and 'faceNormals'.
        green_threshold (int): Threshold for the green component to identify vertices connected to the small mesh.
        tolerance (float): Distance tolerance for proximity checks.
        distance_threshold (float): Threshold for which vertices are considered for calculating base point
            - used if no vertices with green component are found
        
    Returns:
        dict: Contains n_objects, component_data, and base_points for each component.
    """
    ms = pymeshlab.MeshSet()

    # Load meshes and apply distinct colors to each for tracking after boolean operation
    for i, mesh in enumerate(mesh_data[:2]):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

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

    # Perform boolean difference with vertex color transfer
    ms.generate_boolean_difference(first_mesh=0, second_mesh=1, transfer_vert_color=True)

    # Split the result into connected components to isolate regions from the operation
    n_complete = ms.mesh_number()
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()

    component_data = {}
    base_points = []
    component_colors_array = {}

    # Process each component to collect vertices and their attributes, and identify base points
    for i in range(n_complete, n_total):
        ms.set_current_mesh(new_curr_id=i)
        current_mesh = ms.current_mesh()

        # Prepare a dictionary for storing vertices, faces, and normals for each component
        component_index = i - n_complete + 1
        component_data[component_index] = {
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
        component_colors_array[component_index] = component_colors

        # Calculate base point as the mean position and normal of all selected vertices with high green intensity
        if len(matched_vertices) > 0:
            mean_vertex = np.mean(matched_vertices, axis=0)
            mean_normal = np.mean(matched_normals, axis=0)
            base_points.append(np.concatenate((mean_vertex, mean_normal)))
        else:
            small_mesh_vertices = to_numpy_array(mesh_data[1]['vertices'], dtype=np.float64)
            # If no matched vertices are found with the green threshold, select up to 20 unique closest vertices below the distance threshold
            # Calculate distances between each vertex in the current component mesh and vertices in the small mesh.
            # The result is a matrix of shape (current_mesh_vertices, small_mesh_vertices) where each element [i, j]
            # represents the Euclidean distance between vertex i in the current mesh and vertex j in the small mesh.
            distances = np.linalg.norm(current_mesh.vertex_matrix()[:, None, :] - small_mesh_vertices[None, :, :], axis=2)
        
            # Identify indices where distances are below the specified threshold
            # This creates a tuple of arrays, where below_threshold_indices[0] contains the indices of `current_mesh.vertex_matrix()`
            # and below_threshold_indices[1] contains the indices of `small_mesh_vertices` for all pairs below the threshold.
            below_threshold_indices = np.where(distances < distance_threshold)
        
            # Check if any distances met the threshold criteria
            if below_threshold_indices[0].size > 0:
                # Flatten the indices of current mesh vertices that are within the threshold
                # `flat_indices` will contain all vertex indices in `current_mesh.vertex_matrix()` that
                # have at least one corresponding distance below the threshold.
                flat_indices = below_threshold_indices[0]
        
                # Select up to 20 unique closest vertices within the threshold by using argpartition.
                # `np.argpartition` finds the indices of the 20 smallest elements in `distances[below_threshold_indices]`.
                # Applying `np.unique` removes duplicate indices, ensuring only unique vertices are chosen.
                unique_nearest_indices = np.unique(np.argpartition(distances[below_threshold_indices], 20)[:20])
        
                # Use these unique indices to retrieve coordinates and normals from the current mesh.
                matched_vertices = current_mesh.vertex_matrix()[unique_nearest_indices]
                matched_normals = current_mesh.vertex_normal_matrix()[unique_nearest_indices]

                mean_vertex = np.mean(matched_vertices, axis=0)
                mean_normal = np.mean(matched_normals, axis=0)
                base_points.append(np.concatenate((mean_vertex, mean_normal)))
            else:
                # Append NaNs if no matched vertices
                base_points.append(np.full(6, np.nan))

    n_objects = n_total - n_complete
    base_points = np.array(base_points)

    return {
        "n_objects": n_objects,
        "component_data": component_data,
        "base_points": base_points,
        "component_colors": component_colors_array
    }

# Call the function so that the script can run when called from Matlab
output = mesh_subtract_and_separate_with_color(mesh_data, green_threshold, distance_threshold)