import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def find_closest_and_close_holes(mesh_data, max_hole_size=1000, match_threshold=0.1, early_stop_threshold=0.85, min_sample_size=50, tolerance=1e-3):
    """
    Finds and processes the closest mesh component to the original, closes holes, and optionally performs surface reconstruction.

    This function takes a list of meshes, splits each into connected components, and compares them to identify the component closest to a reference mesh.
    It then attempts to close holes in this selected component. If hole closing fails, a surface reconstruction is attempted as a fallback.

    Parameters:
    - mesh_data (list): A list of dictionaries, each representing a mesh with:
        - 'vertices' (ndarray): Nx3 array of vertex coordinates.
        - 'faces' (ndarray): Mx3 array of face indices.
        - 'vertexNormals' (optional ndarray): Nx3 array of vertex normal vectors - cannot be empty.
        - 'faceNormals' (optional ndarray): Mx3 array of face normal vectors - cannot be empty.
    - max_hole_size (int): Maximum allowable size of a hole for closing operations. Larger holes are ignored.
    - match_threshold (float): Minimum proportion of matching vertices to consider a component similar to the reference.
    - early_stop_threshold (float): Proportion threshold for early stopping if a strong match is found.
    - min_sample_size (int): Minimum number of vertices to sample from a component for meaningful comparisons.
    - tolerance (float): Distance threshold to determine if vertices are close enough to match.

    Returns:
    - dict: Contains the vertices, faces, vertexNormals, and faceNormals of the modified mesh.
    - list: List of dictionaries with component indices and their respective match proportions.

    """
    ms = pymeshlab.MeshSet()  # Initialize a MeshSet, which will hold and manage multiple meshes for processing

    # Load each mesh in mesh_data with optional normals for each component
    for i, mesh in enumerate(mesh_data):
        # Prepare mesh arguments, adding normals only if they are provided in mesh data
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Add mesh to the MeshSet, using unique names for each mesh
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Split each mesh into connected components; this is essential to separate distinct regions
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()  # Total number of meshes after splitting
    vertices_original = ms.mesh(0).vertex_matrix()  # Get the original mesh's vertices for comparison
    all_matches = []  # This will store matching data for each component

    # Loop over each split component to compare it against the original
    for i in range(2, n_total):
        vertices_cut = ms.mesh(i).vertex_matrix().copy()  # Ensure vertices array is contiguous for processing
        vertices_original = vertices_original.copy()

        # Efficiency: Use the smaller set for sampling, reducing the computational load of distance checks
        if len(vertices_cut) < len(vertices_original):
            step_size = max(1, len(vertices_cut) // min_sample_size)  # Define step size to ensure we don't undersample
            sampled_vertices = vertices_cut[::step_size]  # Sample every Nth vertex
        else:
            step_size = max(1, len(vertices_original) // min_sample_size)
            sampled_vertices = vertices_original[::step_size]

        # Calculate distances between sampled vertices and original vertices, identifying close matches within tolerance
        distances = np.linalg.norm(sampled_vertices[:, None, :] - vertices_original[None, :, :], axis=2)
        matches = np.any(distances <= float(tolerance), axis=1)  # Boolean array of matches within tolerance
        match_prop = np.sum(matches) / len(sampled_vertices)  # Proportion of sampled vertices that match
        
        all_matches.append({"index": i, "proportion": match_prop})  # Store match proportion and index
        
        # If a component is a strong match, we can skip further comparisons for efficiency
        if match_prop > early_stop_threshold:
            break

    # Identify the best match among all components based on the highest match proportion
    best_match = max(all_matches, key=lambda x: x["proportion"])
    best_match_index = int(best_match["index"])
    
    try:
        # Set the best-matching component as the active mesh for hole closing
        ms.set_current_mesh(new_curr_id=best_match_index)
        ms.meshing_close_holes(maxholesize=int(max_hole_size), newfaceselected=False)

        modified_mesh = ms.current_mesh()
        return {
            "vertices": modified_mesh.vertex_matrix(),
            "faces": modified_mesh.face_matrix(),
            "vertexNormals": modified_mesh.vertex_normal_matrix(),
            "faceNormals": modified_mesh.face_normal_matrix()
        }, all_matches

    except Exception as e:
        print(f"Failed to close holes with meshing_close_holes due to: {e}")
        print("Attempting to fill gaps with surface reconstruction...")

        # As a fallback, perform Poisson surface reconstruction if hole closing fails
        try:
            ms.generate_surface_reconstruction_screened_poisson(depth=8, preclean=True)
            modified_mesh = ms.current_mesh()
            return {
                "vertices": modified_mesh.vertex_matrix(),
                "faces": modified_mesh.face_matrix(),
                "vertexNormals": modified_mesh.vertex_normal_matrix(),
                "faceNormals": modified_mesh.face_normal_matrix()
            }, all_matches

        except RuntimeError as recon_error:
            print(f"Reconstruction also failed: {recon_error}")
            raise RuntimeError("Both hole closing and reconstruction failed. Cannot process mesh.")

# Call the function so that the script can run when called from Matlab
output, matches = find_closest_and_close_holes(
    mesh_data, max_hole_size, match_threshold, 
    early_stop_threshold, min_sample_size, tolerance
)
