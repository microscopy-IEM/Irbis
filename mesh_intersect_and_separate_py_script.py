import pymeshlab
import numpy as np
from utils_py_script import to_numpy_array  # Assumes `to_numpy_array` is defined in utils_py_script.py

def mesh_intersect_and_separate(mesh_data):
    """
    Intersects two meshes and separates the resulting mesh into connected components.
    
    Parameters:
        mesh_data (list): A list of dictionaries with each containing 'vertices', 'faces', 
                          and optionally 'vertexNormals' and 'faceNormals'.
                          
    Returns:
        dict: Contains the number of objects (n_objects), component data with vertices, faces, 
              vertexNormals, and faceNormals for each component.
    """
    ms = pymeshlab.MeshSet()

    # Load the two meshes from mesh_data with the necessary attributes
    for i, mesh in enumerate(mesh_data[:2]):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }
        if 'vertexNormals' in mesh and mesh['vertexNormals']:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and mesh['faceNormals']:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)
        
        # Create and add the new mesh to the MeshSet
        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Perform boolean intersection between the two meshes
    ms.generate_boolean_intersection(first_mesh=0, second_mesh=1)

    # Record the initial mesh count before splitting
    n_complete = ms.mesh_number()

    # Split the result into connected components
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()

    # Prepare dictionaries to store vertices, faces, and normals for each connected component
    component_data = {}

    for i in range(n_complete, n_total):
        ms.set_current_mesh(new_curr_id=i)
        current_mesh = ms.current_mesh()
        component_index = i - n_complete + 1

        # Store the separated component's mesh data
        component_data[component_index] = {
            "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
        }

    n_objects = n_total - n_complete

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }

output = mesh_intersect_and_separate(mesh_data)


# import pymeshlab
# import numpy as np
# from utils_py_script import to_numpy_array  # `to_numpy_array` is defined in utils_py_script.py
# 
# def mesh_intersect_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small):
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
#     ms.generate_boolean_intersection(first_mesh = 0, second_mesh = 1)
# 
#     # ms.save_current_mesh(str(output),save_vertex_normal=True)
# 
#     n_complete = ms.number_meshes()
# 
#     ms.generate_splitting_by_connected_components()
# 
#     n_total = ms.number_meshes()
# 
#     vertices_dict = dict()
#     faces_dict = dict()
#     vertex_normals_dict = dict()
#     face_normals_dict = dict()
# 
#     for i in range(n_complete,n_total):
#         ms.set_current_mesh(new_curr_id = i)
#         cm = ms.current_mesh()
#         j = i + 1 - n_complete
#         # ms.save_current_mesh(f'temp_intersect_{j}.ply')
# 
#         vertices_dict[j] = cm.vertex_matrix()
#         faces_dict[j] = cm.face_matrix()
#         vertex_normals_dict[j] = cm.vertex_normal_matrix()
#         face_normals_dict[j] = cm.face_normal_matrix()
# 
#     n_objects = n_total - n_complete
# 
#     return(n_objects,vertices_dict,faces_dict,vertex_normals_dict,face_normals_dict)
# 
# n_objects,vertices,faces,vertex_normals,face_normals = mesh_intersect_and_separate(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)