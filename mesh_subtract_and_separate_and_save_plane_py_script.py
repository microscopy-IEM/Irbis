import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # `to_numpy_array` is defined in utils_py_script.py

def mesh_subtract_and_separate_with_color(mesh_data, green_threshold=0.3, tolerance=1e-4):
    """
    Subtracts the second mesh from the first, splits the result into connected components, 
    and identifies vertices for base point calculation based on green color intensity.
    
    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces', and optionally 'vertexNormals' and 'faceNormals'.
        green_threshold (int): Threshold for the green component to identify vertices connected to the small mesh.
        tolerance (float): Distance tolerance for proximity checks.
        
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
        if 'vertexNormals' in mesh and mesh['vertexNormals']:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and mesh['faceNormals']:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

        print(f'mesh {i} added')

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
            # Optionally, you can set a default color or take other corrective actions here

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

output = mesh_subtract_and_separate_with_color(mesh_data, green_threshold)



# import pymeshlab
# import numpy as np
# 
# def mesh_subtract_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small):
# 
#     ms = pymeshlab.MeshSet()
# 
#     if len(vertex_normals_big)==0 or len(face_normals_big)==0:
#         m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big)
#     else:
#         m_big = pymeshlab.Mesh(vertex_matrix = vertices_big,face_matrix=faces_big,v_normals_matrix=vertex_normals_big,f_normals_matrix=face_normals_big)
# 
#     if len(vertex_normals_small)==0 or len(face_normals_small)==0:
#         m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small)
#     else:
#         m_small = pymeshlab.Mesh(vertex_matrix = vertices_small,face_matrix=faces_small,v_normals_matrix=vertex_normals_small,f_normals_matrix=face_normals_small)
# 
#     ms.add_mesh(m_big)
#     ms.add_mesh(m_small)
# 
#     shaft = ms.mesh(1).vertex_matrix()
# 
#     ms.generate_boolean_difference(first_mesh=0,second_mesh=1)
# 
#     # ms.save_current_mesh(str(output),save_vertex_normal=True)
# 
#     n_complete = ms.number_meshes()
#     print(n_complete)
# 
#     ms.generate_splitting_by_connected_components()
# 
#     n_total = ms.number_meshes()
#     print(n_total)
# 
#     # file = open('temp_cuttingPlaneList.csv','w')
# 
#     vertices_dict = dict()
#     faces_dict = dict()
#     vertex_normals_dict = dict()
#     face_normals_dict = dict()
# 
#     base_points = [];
# 
#     for i in range(n_complete,n_total):
#         ms.set_current_mesh(new_curr_id = i)
#         cm = ms.current_mesh()
#         j = i + 1 - n_complete
#         # ms.save_current_mesh(f'temp_subtract_{j}.ply')
# 
#         vertices_dict[j] = cm.vertex_matrix()
#         faces_dict[j] = cm.face_matrix()
#         vertex_normals_dict[j] = cm.vertex_normal_matrix()
#         face_normals_dict[j] = cm.face_normal_matrix()
# 
#         spine = ms.mesh(i).vertex_matrix()
#         spine_normal = ms.mesh(i).vertex_normal_matrix()
# 
#         vertices = []
#         normals = []
# 
#         for vertex_n in range(0,len(spine)):
#             if np.any(np.all(spine[vertex_n] == shaft[:],axis = 1)):
#                 vertices.append(list(spine[vertex_n]))
#                 normals.append(list(spine_normal[vertex_n]))
# 
#         av = [item[0] for item in vertices]
#         bv = [item[1] for item in vertices]
#         cv = [item[2] for item in vertices]
#         an = [item[0] for item in normals]
#         bn = [item[1] for item in normals]
#         cn = [item[2] for item in normals]
# 
#         mean_list = [np.mean(av),np.mean(bv),np.mean(cv),np.mean(an),np.mean(bn),np.mean(cn)]
# 
#         base_points.append(mean_list)
# 
#     #     for mean in mean_list:
#     #         file.write(str(mean) + ';')    
#     #     file.write('\n')
#     # file.close()
# 
#     n_objects = n_total - n_complete
# 
#     base_points = np.array(base_points)
# 
#     # print('base_points lenght')
#     # print(len(base_points))
#     return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict,base_points)
# 
# n_objects,vertices,faces,vertex_normals,face_normals,base_points = mesh_subtract_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)