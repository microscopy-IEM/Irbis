import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # `to_numpy_array` is defined in utils_py_script.py

def mesh_subtract_cylinder_and_find_closest_object(mesh_data, vertices_original, tolerance=1e-4, threshold=0.1, min_sample_size=50):
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

    Returns:
        dict: Dictionary containing:
            - n_objects: Number of components meeting the match criteria.
            - component_data: Dictionary with vertices, faces, vertexNormals, and faceNormals for each component.
            - base_points: Array of average base points for each component close to the original mesh.
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
        if 'vertexNormals' in mesh and mesh['vertexNormals']:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and mesh['faceNormals']:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Create the PyMeshLab mesh and add to MeshSet with a unique name
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")
    
    # Perform boolean difference between the first two meshes
    ms.generate_boolean_difference(first_mesh=0, second_mesh=1)
    
    # Split result into connected components
    n_complete = ms.number_meshes()
    ms.generate_splitting_by_connected_components()
    n_total = ms.number_meshes()
    
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
        matches = np.any(distances <= tolerance, axis=1)
        
        # Calculate the proportion of sampled vertices that have at least one match in the original vertices.
        match_prop = float(np.sum(matches) / len(sampled_vertices))  # Ensure float for Python compatibility
        all_matches.append(match_prop)
    
    # Filter components that meet the match threshold
    ids_above_threshold = [i + n_complete for i, match in enumerate(all_matches) if match > threshold]
    if not ids_above_threshold:
        ids_above_threshold = list(range(n_complete, n_total))  # Include all if none match the threshold

    # Extract component data and calculate base points
    component_data = {}
    base_points = []

    for j, component_id in enumerate(ids_above_threshold, start=1):
        ms.set_current_mesh(new_curr_id=component_id)
        current_mesh = ms.current_mesh()

        component_data[j] = {
            "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
        }

        # Find base points in the component that match vertices in the cylinder
        base_vertices = [vertex for vertex in current_mesh.vertex_matrix()
                         if np.any(np.all(np.isclose(vertex, to_numpy_array(mesh_data[1]['vertices'], dtype=np.float64), atol=tolerance), axis=1))]
        if base_vertices:
            base_points.append(np.mean(base_vertices, axis=0))

    return {
        "n_objects": len(ids_above_threshold),
        "component_data": component_data,
        "base_points": np.array(base_points)
    }

result = mesh_subtract_cylinder_and_find_closest_object(mesh_data, vertices_original)


# import pymeshlab
# import numpy as np
# 
# def mesh_subtract_cylinder_and_find_closest_object(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_cylinder,faces_cylinder,vertices_original):
# 
#     ms = pymeshlab.MeshSet()
# 
#     if len(vertex_normals_big)==0 or len(face_normals_big)==0:
#         m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big)
#     else:
#         m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big,v_normals_matrix=vertex_normals_big,f_normals_matrix=face_normals_big)
# 
#     m_cylinder = pymeshlab.Mesh(vertex_matrix = vertices_cylinder, face_matrix = faces_cylinder)
# 
#     ms.add_mesh(m_big)
#     ms.add_mesh(m_cylinder)
# 
#     ms.generate_boolean_difference(first_mesh=0,second_mesh=1)
# 
#     n_complete = ms.number_meshes()
#     ms.generate_splitting_by_connected_components()
# 
#     n_total = ms.number_meshes()
# 
#     # print(n_complete)
#     # print(n_total)
# 
#     all_matches = []
#     distances = []
# 
#     # centreOriginal = np.mean(vertices_original, axis=0)
#     # print(centreOriginal)
#     # 
#     # for i in range(n_complete,n_total):
#     #     vertices_cut = ms.mesh(i).vertex_matrix()
#     #     distances_i = np.linalg.norm(vertices_cut - centreOriginal, axis=1)
#     #     avg_distance = np.mean(distances_i)
#     # 
#     #     print(avg_distance)
#     #     distances.append(avg_distance)
#     # 
#     # min_distance_n = distances.index(min(distances))
#     # min_distance_i = min_distance_n + n_complete
# 
#     tolerance = 1e-4
#     threshold = 0.1
#     # for i in range(n_complete,n_total):
#     #     vertices_cut = ms.mesh(i).vertex_matrix()
#     #     if len(vertices_cut) < len(vertices_original):
#     #         matchList = [np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))]
#     #         matchProp = np.sum(matchList)/len(matchList)
#     #         #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
#     #     elif len(vertices_cut) >= len(vertices_original):
#     #         matchList = [np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))]
#     #         #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
#     #         matchProp = np.sum(matchList)/len(matchList)
#     #         if matchProp > 0.1:
#     #             matchProp = 1.1
# 
#     min_sample_size = 50;
#     for i in range(n_complete, n_total):
#         print(i)
#         vertices_cut = ms.mesh(i).vertex_matrix()
# 
#         # Ensure contiguous array for compatibility with .view()
#         vertices_cut = vertices_cut.copy()
#         vertices_original = vertices_original.copy()
# 
#         # Branch to compare against the smaller vertex set for efficiency
#         if len(vertices_cut) < len(vertices_original):
#             if len(vertices_cut) >= min_sample_size:
#                 step_size = int(len(vertices_cut) // min_sample_size)
#                 sampled_vertices = vertices_cut[::step_size].copy()  # Copy to ensure contiguity
# 
#                 # Use broadcasting to calculate pairwise distances and check for matches within tolerance
#                 distances = np.linalg.norm(sampled_vertices[:, None, :] - vertices_original[None, :, :], axis=2)
#                 matches = np.any(distances <= tolerance, axis=1)
#                 match_prop = np.sum(matches) / len(sampled_vertices)
#             else:
#                 # For non-downsampled, calculate pairwise distances for all vertices
#                 distances = np.linalg.norm(vertices_cut[:, None, :] - vertices_original[None, :, :], axis=2)
#                 matches = np.any(distances <= tolerance, axis=1)
#                 match_prop = np.sum(matches) / len(vertices_cut)
#         else:
#             if len(vertices_original) >= min_sample_size:
#                 step_size = int(len(vertices_original) // min_sample_size)
#                 sampled_vertices = vertices_original[::step_size].copy()  # Copy to ensure contiguity
# 
#                 distances = np.linalg.norm(sampled_vertices[:, None, :] - vertices_cut[None, :, :], axis=2)
#                 matches = np.any(distances <= tolerance, axis=1)
#                 match_prop = np.sum(matches) / len(sampled_vertices)
#             else:
#                 distances = np.linalg.norm(vertices_original[:, None, :] - vertices_cut[None, :, :], axis=2)
#                 matches = np.any(distances <= tolerance, axis=1)
#                 match_prop = np.sum(matches) / len(vertices_original)
#         print(match_prop)
#         all_matches.append(match_prop)
# 
#     # for i in range(n_complete,n_total):
#     #     # print(i)
#     #     vertices_cut = ms.mesh(i).vertex_matrix()
#     #     if len(vertices_cut) > 0.5*len(vertices_big):
#     #         # print(f'{i} too big')
#     #         matchProp = 0
#     #     elif len(vertices_cut) < len(vertices_original):
#     #         # print(f'{i} smaller than original')
#     #         matchList = [np.any(np.all(np.isclose(vertices_cut[vertex], vertices_original, atol=tolerance),axis = 1)) for vertex in range(0,len(vertices_cut))]
#     #         matchProp = np.sum(matchList)/len(matchList)
#     #         #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
#     #     elif len(vertices_cut) >= len(vertices_original):
#     #         # print(f'{i} bigger than original')
#     #         matchList = [np.any(np.all(np.isclose(vertices_original[vertex], vertices_cut, atol=tolerance),axis = 1)) for vertex in range(0,int(len(vertices_original)))]
#     #         #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
#     #         matchProp = np.sum(matchList)/len(matchList)
#     #         # if matchProp > 0.1:
#     #         #     matchProp = 1.1
#     # 
#     #     # print(i)
#     #     # print(matchProp)
#     #     # print(len(vertices_cut))
#     #     # print(matchProp)
#     #     # ms.save_current_mesh(f'testMesh_{i}.ply')
#     #     matches.append(matchProp)
# 
#     matches_above_threshold = [i for i, value in enumerate(all_matches) if value > threshold]
#     print(matches_above_threshold)
#     if len(matches_above_threshold) == 0:
#         print('NO MATCH - ALL ADDED')
#         ids_above_threshold = [i for i in range(n_complete,n_total)]
#     else:
#         ids_above_threshold = [m + n_complete for m in matches_above_threshold]
#     # print(ids_above_threshold)
# 
#     # max_match_n = matches.index(max(matches))
#     # max_match_i = max_match_n + n_complete
# 
#     vertices_dict = dict()
#     faces_dict = dict()
#     vertex_normals_dict = dict()
#     face_normals_dict = dict()
# 
#     base_points = [];
# 
#     j = 1
#     for i in ids_above_threshold:
#         ms.set_current_mesh(new_curr_id = i)
#         cm = ms.current_mesh()
# 
#         # print(ids_above_threshold[i])
#         # j = int(ids_above_threshold[i])
#         # print(j)
# 
#         vertices_dict[j] = cm.vertex_matrix()
#         faces_dict[j] = cm.face_matrix()
#         vertex_normals_dict[j] = cm.vertex_normal_matrix()
#         face_normals_dict[j] = cm.face_normal_matrix()
# 
#         base_vertices = []
# 
#         for vertex_n in range(0,len(cm.vertex_matrix())):
#             if np.any(np.all(cm.vertex_matrix()[vertex_n] == vertices_cylinder, axis = 1)):
#                 base_vertices.append(list(cm.vertex_matrix()[vertex_n]))
# 
#         av = [item[0] for item in base_vertices]
#         bv = [item[1] for item in base_vertices]
#         cv = [item[2] for item in base_vertices]
# 
#         mean_list = [np.mean(av), np.mean(bv), np.mean(cv)]
#         base_points.append(mean_list)
# 
#         j += 1
# 
#     base_points = np.array(base_points)
# 
# 
#     # ms.set_current_mesh(new_curr_id = max_match_i)
#     # # ms.set_current_mesh(new_curr_id = min_distance_i)
#     # cm = ms.current_mesh()
# 
#     # vertices_new = cm.vertex_matrix()
#     # faces_new = cm.face_matrix()
#     # vertex_normals_new = cm.vertex_normal_matrix()
#     # face_normals_new = cm.face_normal_matrix()
# 
#     # base_vertices = []
#     # 
#     # for vertex_n in range(0,len(vertices_new)):
#     #     if np.any(np.all(vertices_new[vertex_n] == vertices_cylinder, axis = 1)):
#     #         base_vertices.append(list(vertices_new[vertex_n]))
#     # 
#     # av = [item[0] for item in base_vertices]
#     # bv = [item[1] for item in base_vertices]
#     # cv = [item[2] for item in base_vertices]
#     # 
#     # base_point = np.array([np.mean(av), np.mean(bv), np.mean(cv)])
# 
#     # n_objects = n_total - n_complete
#     n_objects = len(ids_above_threshold)
# 
#     # return(n_objects,vertices_new,faces_new,vertex_normals_new,face_normals_new,base_points)
#     return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict,base_points)
# 
# n_objects,vertices,faces,vertex_normals,face_normals,base_points = mesh_subtract_cylinder_and_find_closest_object(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_cylinder,faces_cylinder,vertices_original)
# 
# 
# 
# 
# 
# 
