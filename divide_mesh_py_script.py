import pymeshlab
import numpy as np

def divide_mesh(mesh_data, pointA, pointB, depth=8):
    # Helper function to ensure data is a NumPy array and convert memoryview if needed
    def to_numpy_array(data, dtype):
        if isinstance(data, memoryview):
            return np.array(data, dtype=dtype)
        return np.asarray(data, dtype=dtype)

    ms = pymeshlab.MeshSet()

    # Iterate over each mesh entry in mesh_data
    for i, mesh in enumerate(mesh_data):
        # Prepare required arguments
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }

        # Conditionally add normals if they are available and non-empty
        if 'vertexNormals' in mesh and mesh['vertexNormals']:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh and mesh['faceNormals']:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

        # Create the PyMeshLab mesh, passing only the necessary arguments
        new_mesh = pymeshlab.Mesh(**mesh_args)

        # Add the new mesh to the MeshSet with a unique name
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Split connected components of the first cut mesh
    ms.set_current_mesh(new_curr_id=1)
    n_complete = ms.number_meshes()
    ms.generate_splitting_by_connected_components()
    n_total = ms.number_meshes()
    n_objects = n_total - n_complete  # Count of new mesh components created by splitting

    # Find the component closest to pointA
    pointA = np.array(pointA)
    min_distances = []
    for i in range(n_complete, n_total):
        ms.set_current_mesh(new_curr_id=i)
        mesh_vertices = ms.current_mesh().vertex_matrix()
        distances = np.linalg.norm(mesh_vertices - pointA, axis=1)
        min_distances.append(np.min(distances))

    closest_mesh_id = np.argmin(min_distances) + n_complete
    ms.set_current_mesh(new_curr_id=closest_mesh_id)

    # Extract vertices and normals for the closest and parent meshes
    closest_mesh = ms.current_mesh()
    closest_vertices = closest_mesh.vertex_matrix()
    closest_normals = closest_mesh.vertex_normal_matrix()

    original_mesh = ms.mesh(id=0)
    original_vertices = original_mesh.vertex_matrix()
    original_normals = original_mesh.vertex_normal_matrix()

    # Define cap point and normal from `pointA` to `pointB`
    cap_points = np.array([pointA])  # Single cap point as `pointA`
    cap_normals = np.array([pointB - pointA])  # Normal in the direction from `pointA` to `pointB`

    # Mask and remove vertices in the closest mesh from the original mesh
    mask_vertices = np.isin(original_vertices, closest_vertices).all(axis=1)
    cut_original_vertices = original_vertices[~mask_vertices]
    cut_original_normals = original_normals[~mask_vertices]

    # Append cap points to both separated components
    closest_vertices = np.vstack((closest_vertices, cap_points))
    closest_normals = np.vstack((closest_normals, cap_normals))
    cut_original_vertices = np.vstack((cut_original_vertices, cap_points))
    cut_original_normals = np.vstack((cut_original_normals, -cap_normals))

    # Create meshes for the divided components
    m_closest = pymeshlab.Mesh(vertex_matrix=closest_vertices, v_normals_matrix=closest_normals)
    m_cut = pymeshlab.Mesh(vertex_matrix=cut_original_vertices, v_normals_matrix=cut_original_normals)

    # Initialize new MeshSet for processing reconstructed meshes
    ms2 = pymeshlab.MeshSet()
    ms2.add_mesh(m_closest, 'closest_mesh')
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth), preclean=True)
    ms2.meshing_repair_non_manifold_vertices()
    ms2.meshing_close_holes(newfaceselected=False)
    mesh_closest_reconstructed = ms2.current_mesh()

    ms2.add_mesh(m_cut, 'cut_mesh')
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth), preclean=True)
    ms2.meshing_repair_non_manifold_vertices()
    ms2.meshing_close_holes(newfaceselected=False)
    mesh_cut_reconstructed = ms2.current_mesh()

    # Return vertices and faces of reconstructed meshes
    return {
        "closest_mesh": {
            "vertices": mesh_closest_reconstructed.vertex_matrix(),
            "faces": mesh_closest_reconstructed.face_matrix()
        },
        "cut_mesh": {
            "vertices": mesh_cut_reconstructed.vertex_matrix(),
            "faces": mesh_cut_reconstructed.face_matrix()
        }
    }


output = divide_mesh(mesh_data, pointA, pointB, d)


# import pymeshlab
# import os
# import time
# import numpy as np
# 
# def divide_mesh(pointA,pointB,depth=8,temp_path ='C:\\Users\\Public\\MMP\\temp'):
#     os.chdir(temp_path)
#     ms = pymeshlab.MeshSet()
#     ms.load_new_mesh('temp_parent.ply')  
#     for i in [1,2]:
#         input = f'temp_cut_in_{i}.ply'
#         ms.load_new_mesh(str(input))  
# 
# 
#     ms.set_current_mesh(new_curr_id=1)
#     n_complete = ms.number_meshes()
# 
#     ms.generate_splitting_by_connected_components()
# 
#     n_total = ms.number_meshes()
# 
#     n_objects = n_total - n_complete
# 
#     min_distances = []
# 
#     # find the mesh closest to pointA
#     pointA = np.array(pointA)
#     pointB = np.array(pointB)
#     for i in range(n_complete,n_total):
#         ms.set_current_mesh(new_curr_id = i)
#         mesh_vertices = ms.current_mesh().vertex_matrix()
#         distances = np.linalg.norm(mesh_vertices - pointA, axis=1)
#         min_dist = np.min(distances)
#         min_distances.append(min_dist)
# 
#     closest = np.argmin(min_distances)
#     closest = closest + n_complete
# 
#     closest_mesh = ms.mesh(id = closest)
#     closest_mesh_vertices = closest_mesh.vertex_matrix()
#     closest_mesh_normals = closest_mesh.vertex_normal_matrix()
#     original_mesh = ms.mesh(id = 0)
#     original_mesh_vertices = original_mesh.vertex_matrix()
#     original_mesh_normals = original_mesh.vertex_normal_matrix()
# 
# 
#     ms.set_current_mesh(new_curr_id = closest)
#     '''
#     ms.compute_selection_from_mesh_border()
#     ms.generate_from_selected_vertices()
#     print(ms.current_mesh().vertex_number())
#     ms.generate_polyline_from_selected_edges()
#     '''
#     #axis = np.array(pointB-pointA)/np.linalg.norm(np.array(pointB-pointA))
#     #ms.generate_polyline_from_planar_section()
#     #ms.generate_polyline_from_planar_section(planeaxis=3,customaxis=axis,planeoffset=pointA)
# 
# 
#     '''polyline = ms.current_mesh()
#     polyline_vertices = polyline.vertex_matrix()
#     polyline_normals = polyline.vertex_normal_matrix()
#     print(polyline_vertices)'''
# 
#     #pointC = np.mean(polyline_vertices,axis=1)
#     pointC = pointA
#     cap_points = pointC
#     # print(f'pointC: {pointC}')
#     pointC_normal = np.array(pointB-pointA)
#     cap_points_normals = pointC_normal
#     '''for i in range(0,len(polyline_vertices),2):
#         pointCs = (pointC + polyline_vertices[i])/2
#         cap_points = np.vstack((cap_points,pointCs))
#         pointCs_normal = (pointC_normal + polyline_normals[i])/2
#         cap_points_normals = np.vstack((cap_points_normals,pointCs_normal))'''
# 
#     #ms.show_polyscope()
# 
#     # delete points from the original array
#     mask_vertices = np.isin(original_mesh_vertices,closest_mesh_vertices)
#     mask_vertices = np.all(mask_vertices,axis=1)
#     # print(mask_vertices)
#     cut_original_vertices = original_mesh_vertices[~mask_vertices]
#     # print(len(cut_original_vertices))
#     # print(f'original normal: {(original_mesh_normals)}')
#     mask_normals = np.isin(original_mesh_normals,closest_mesh_normals)
#     # print(mask_normals)
#     mask_normals = np.all(mask_normals,axis=1)
#     # print(mask_normals)
#     cut_original_normals = original_mesh_normals[~mask_vertices]
#     # print(len(cut_original_normals))
# 
#     # add the cap points to the divided matrixes
#     closest_mesh_vertices = np.vstack((closest_mesh_vertices,cap_points))
# 
#     closest_mesh_normals = np.vstack((closest_mesh_normals,cap_points_normals))
#     cut_original_vertices = np.vstack((cut_original_vertices,cap_points))
#     cut_original_normals = np.vstack((cut_original_normals,(-1)*cap_points_normals))
# 
#     #faces = np.empty()
#     m_closest = pymeshlab.Mesh(vertex_matrix=closest_mesh_vertices,v_normals_matrix=closest_mesh_normals)
#     #m_closest.vertex_normal_matrix = closest_mesh_normals
# 
#     m_cut = pymeshlab.Mesh(vertex_matrix=cut_original_vertices,v_normals_matrix=cut_original_normals)
#     #m_cut.vertex_normal_matrix = cut_original_normals
# 
#     # end_time = time.time()
#     # print(f'Execution time for most of the script: {end_time - start_time} s')
# 
#     ms2 = pymeshlab.MeshSet()
#     ms2.add_mesh(m_closest,'closest_mesh')
# 
#     # start_time = time.time()
#     ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
#     # end_time = time.time()
#     # print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')
# 
#     # start_time = time.time()
#     ms2.meshing_repair_non_manifold_vertices()
#     # end_time = time.time()
#     # print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')
# 
#     # start_time = time.time()
#     ms2.meshing_close_holes(newfaceselected = False)
#     # end_time = time.time()
#     # print(f'Execution time for hole filling: {end_time - start_time} s')    
# 
#     ms2.save_current_mesh(f'temp_cut_out_1.ply')
# 
#     ms2.add_mesh(m_cut,'cut_mesh')
#     # start_time = time.time()
#     ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
#     # end_time = time.time()
#     # print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')
# 
#     # start_time = time.time()
#     ms2.meshing_repair_non_manifold_vertices()
#     # end_time = time.time()
#     # print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')
# 
#     # start_time = time.time()
#     ms2.meshing_close_holes(newfaceselected = False)
#     # end_time = time.time()
#     # print(f'Execution time for hole filling: {end_time - start_time} s')
# 
#     ms2.save_current_mesh(f'temp_cut_out_2.ply')
# 
#     return()
# 
# divide_mesh(pointA = pointA,pointB = pointB, depth = d, temp_path = path)
# 
