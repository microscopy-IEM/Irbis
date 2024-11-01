import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def find_closest_and_close_holes(mesh_data, max_hole_size=1000, match_threshold=0.1, early_stop_threshold=0.85, min_sample_size=50):
    """
    Finds the closest mesh component to the original and closes holes on the selected component.

    Parameters:
        mesh_data (list): List of dictionaries with vertices, faces, and optionally normals for each mesh.
        max_hole_size (int): Maximum hole size for closing.
        match_threshold (float): Minimum match proportion to consider a mesh similar to the original.
        early_stop_threshold (float): Threshold for early stopping if a strong match is found.
        min_sample_size (int): Minimum size of downsampled array to ensure comparisons are meaningful.
    
    Returns:
        dict: The vertices and faces of the modified mesh with holes closed.
        list: A list of all matches with their indices and proportions.
    """
    ms = pymeshlab.MeshSet()

    # Load each mesh in mesh_data
    for i, mesh in enumerate(mesh_data):
        # Prepare the mesh arguments dynamically
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh and mesh['vertexNormals']:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and mesh['faceNormals']:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Create the PyMeshLab mesh and add to MeshSet with a unique name
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Generate connected components for further analysis
    ms.generate_splitting_by_connected_components()
    n_total = ms.number_meshes()
    vertices_original = ms.mesh(0).vertex_matrix()
    all_matches = []

    tolerance=1e-3
    for i in range(2, n_total):
        print(i)
        vertices_cut = ms.mesh(i).vertex_matrix()
        
        # Ensure contiguous array for compatibility with .view()
        vertices_cut = vertices_cut.copy()
        vertices_original = vertices_original.copy()

        # Branch to compare against the smaller vertex set for efficiency
        if len(vertices_cut) < len(vertices_original):
            if len(vertices_cut) >= min_sample_size:
                step_size = int(len(vertices_cut) // min_sample_size)
                sampled_vertices = vertices_cut[::step_size].copy()  # Copy to ensure contiguity

                # Use broadcasting to calculate pairwise distances and check for matches within tolerance
                distances = np.linalg.norm(sampled_vertices[:, None, :] - vertices_original[None, :, :], axis=2)
                matches = np.any(distances <= tolerance, axis=1)
                match_prop = np.sum(matches) / len(sampled_vertices)
            else:
                # For non-downsampled, calculate pairwise distances for all vertices
                distances = np.linalg.norm(vertices_cut[:, None, :] - vertices_original[None, :, :], axis=2)
                matches = np.any(distances <= tolerance, axis=1)
                match_prop = np.sum(matches) / len(vertices_cut)
        else:
            if len(vertices_original) >= min_sample_size:
                step_size = int(len(vertices_original) // min_sample_size)
                sampled_vertices = vertices_original[::step_size].copy()  # Copy to ensure contiguity

                distances = np.linalg.norm(sampled_vertices[:, None, :] - vertices_cut[None, :, :], axis=2)
                matches = np.any(distances <= tolerance, axis=1)
                match_prop = np.sum(matches) / len(sampled_vertices)
            else:
                distances = np.linalg.norm(vertices_original[:, None, :] - vertices_cut[None, :, :], axis=2)
                matches = np.any(distances <= tolerance, axis=1)
                match_prop = np.sum(matches) / len(vertices_original)
        print(match_prop)


    # # Find the closest matching component using vectorized comparison
    # for i in range(2, n_total):
    #     vertices_cut = ms.mesh(i).vertex_matrix()
    # 
    #     # Ensure contiguous array for compatibility with .view()
    #     vertices_cut = vertices_cut.copy()
    #     vertices_original = vertices_original.copy()

        # # Branch to compare against the smaller vertex set for efficiency
        # if len(vertices_cut) < len(vertices_original):
        #     # Sample every N-th vertex if large enough, else compare all
        #     if len(vertices_cut) >= min_sample_size:
        #         step_size = int(len(vertices_cut) // min_sample_size)
        #         print('cut smaller than original')
        #         print(step_size)
        #         sampled_vertices = vertices_cut
        #         # sampled_vertices = vertices_cut[::step_size]
        #         # Use .view to treat each row (vertex) as a single unit for comparison
        #         matches = np.isin(sampled_vertices.view([('', sampled_vertices.dtype)] * sampled_vertices.shape[1]),
        #                           vertices_original.view([('', vertices_original.dtype)] * vertices_original.shape[1]))
        #         match_prop = np.sum(matches) / len(sampled_vertices)
        #         print('a')
        #         print(match_prop)
        #     else:
        #         matches = np.isin(vertices_cut.view([('', vertices_cut.dtype)] * vertices_cut.shape[1]),
        #                           vertices_original.view([('', vertices_original.dtype)] * vertices_original.shape[1]))
        #         match_prop = np.sum(matches) / len(vertices_cut)
        #         print('b')
        #         print(match_prop)
        # else:
        #     # Flip comparison if original is smaller, for similar reasons
        #     if len(vertices_original) >= min_sample_size:
        #         step_size = int(len(vertices_original) // min_sample_size)
        #         print('cut bigger than original')
        #         print(step_size)
        #         sampled_vertices = vertices_original
        #         # sampled_vertices = vertices_original[::step_size]
        #         matches = np.isin(sampled_vertices.view([('', sampled_vertices.dtype)] * sampled_vertices.shape[1]),
        #                           vertices_cut.view([('', vertices_cut.dtype)] * vertices_cut.shape[1]))
        #         match_prop = np.sum(matches) / len(sampled_vertices)
        #         print('c')
        #         print(match_prop)
        #     else:
        #         matches = np.isin(vertices_original.view([('', vertices_original.dtype)] * vertices_original.shape[1]),
        #                           vertices_cut.view([('', vertices_cut.dtype)] * vertices_cut.shape[1]))
        #         match_prop = np.sum(matches) / len(vertices_original)
        #         print('d')
        #         print(match_prop)

        # Store all matches with their indices and proportions
        all_matches.append({"index": i, "proportion": match_prop})

        # Early stop if a strong match is found (adjust threshold if downsampling)
        adjusted_stop_threshold = early_stop_threshold if min(len(vertices_cut), len(vertices_original)) >= min_sample_size else 0.9
        if match_prop > adjusted_stop_threshold:
            print(f"Early stopping: strong match found at mesh {i} with match proportion {match_prop}")
            break

    print(all_matches)
    # Extract the best match
    best_match = max(all_matches, key=lambda x: x["proportion"])
    
    # Print debug information about best match
    print(f"Best match index: {best_match['index']}, proportion: {best_match['proportion']}")
    
    # Ensure `best_match["index"]` is an integer
    best_match_index = int(best_match["index"])
    
    # Select the best matching mesh and close holes
    try:
        # Set the current mesh based on best match index
        ms.set_current_mesh(new_curr_id=best_match_index)
        
        # Ensure vertices and faces of the selected mesh are of the correct type
        current_mesh = ms.current_mesh()
        vertices = current_mesh.vertex_matrix()
        faces = current_mesh.face_matrix()
        
        # Print debug information for types
        print("Vertices dtype:", vertices.dtype)
        print("Faces dtype:", faces.dtype)

        ms.save_current_mesh(str('C:/Users/iva.svecova/Downloads/output_before.ply'),save_vertex_normal = True)

        # # Repair non-manifold edges to ensure the mesh is 2-manifold
        # ms.meshing_repair_non_manifold_edges()
        
        # Close holes with the specified max hole size
        ms.meshing_close_holes(maxholesize=int(max_hole_size), newfaceselected=False)

        ms.save_current_mesh(str('C:/Users/iva.svecova/Downloads/output.ply'),save_vertex_normal = True)
    
    except Exception as e:
        print(f"Failed to close holes with meshing_close_holes due to: {e}")
        print("Attempting to fill gaps with surface reconstruction...")

        # Perform surface reconstruction as a fallback method
        try:
            ms.generate_surface_reconstruction_screened_poisson(depth=8, preclean=True)
            print("Surface reconstruction completed successfully.")

        except RuntimeError as recon_error:
            print(f"Reconstruction also failed: {recon_error}")
            raise RuntimeError("Both hole closing and reconstruction failed. Cannot process mesh.")

    
    # Return the modified mesh's vertices and faces, along with all matches
    modified_mesh = ms.current_mesh()
    return {
        "vertices": modified_mesh.vertex_matrix(),
        "faces": modified_mesh.face_matrix()
    }, all_matches

#     # Extract the best match using np.max
#     best_match = max(all_matches, key=lambda x: x["proportion"])
# 
#     # # Check if a valid match was found
#     # if best_match["proportion"] < match_threshold:
#     #     raise ValueError("No sufficiently similar mesh component found.")
# 
#     # Select the best matching mesh and close holes
#     ms.set_current_mesh(new_curr_id=best_match["index"])
#     ms.meshing_close_holes(maxholesize=max_hole_size, newfaceselected=False)
# 
#     # Return the modified mesh's vertices and faces, along with all matches
#     modified_mesh = ms.current_mesh()
#     return {
#         "vertices": modified_mesh.vertex_matrix(),
#         "faces": modified_mesh.face_matrix()
#     }, all_matches
# 
# Example usage with mesh data dictionaries
output, matches = find_closest_and_close_holes(mesh_data, max_hole_size, match_threshold, early_stop_threshold, min_sample_size)



# import pymeshlab
# import numpy as np
# import os
# 
# def find_closest_and_close_holes(original = 'temp_originalSpine.ply',input = 'temp_cut_in.ply',output = 'temp_cut_out.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):
# 
#     os.chdir(temp_path)
# 
#     ms = pymeshlab.MeshSet()
#     ms.load_new_mesh(original)
#     ms.load_new_mesh(input)  
# 
#     ms.generate_splitting_by_connected_components()
# 
#     n_total = ms.number_meshes()
# 
#     vertices_original = ms.mesh(0).vertex_matrix()
# 
#     matches = []
# 
#     for i in range(2,n_total):
#         vertices_cut = ms.mesh(i).vertex_matrix()
#         if len(vertices_cut) < len(vertices_original):
#             matchList = [np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))]
#             matchProp = np.sum(matchList)/len(matchList)
#             #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
#         elif len(vertices_cut) >= len(vertices_original):
#             matchList = [np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))]
#             #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
#             matchProp = np.sum(matchList)/len(matchList)
#             if matchProp > 0.1:
#                 matchProp = 1.1
#         # print(i)
#         # print(matchProp)
#         matches.append(matchProp)
# 
#     max_match_n = matches.index(max(matches))
#     max_match_i = max_match_n + 2
# 
#     # print(f'match found in {max_match_i} with match {max(matches)}')
#     ms.set_current_mesh(new_curr_id = max_match_i)
#     ms.meshing_close_holes(maxholesize = 1000,newfaceselected = False)
#     ms.save_current_mesh(str(output),save_vertex_normal = True)
#     return()  
# 
# output = find_closest_and_close_holes(original_name,input_name,output_name,temp_path=path)  