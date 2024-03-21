import pymeshlab
import os
import time
import numpy as np

def divide_mesh(pointA,pointB,depth=8,temp_path ='C:\\Users\\Public\\MMP\\temp'):
    os.chdir(temp_path)
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh('temp_parent.ply')  
    for i in [1,2]:
        input = f'temp_cut_in_{i}.ply'
        ms.load_new_mesh(str(input))  


    ms.set_current_mesh(new_curr_id=1)
    n_complete = ms.number_meshes()

    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()

    n_objects = n_total - n_complete

    min_distances = []

    # find the mesh closest to pointA
    pointA = np.array(pointA)
    pointB = np.array(pointB)
    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)
        mesh_vertices = ms.current_mesh().vertex_matrix()
        distances = np.linalg.norm(mesh_vertices - pointA, axis=1)
        min_dist = np.min(distances)
        min_distances.append(min_dist)

    closest = np.argmin(min_distances)
    closest = closest + n_complete

    closest_mesh = ms.mesh(id = closest)
    closest_mesh_vertices = closest_mesh.vertex_matrix()
    closest_mesh_normals = closest_mesh.vertex_normal_matrix()
    original_mesh = ms.mesh(id = 0)
    original_mesh_vertices = original_mesh.vertex_matrix()
    original_mesh_normals = original_mesh.vertex_normal_matrix()


    ms.set_current_mesh(new_curr_id = closest)
    '''
    ms.compute_selection_from_mesh_border()
    ms.generate_from_selected_vertices()
    print(ms.current_mesh().vertex_number())
    ms.generate_polyline_from_selected_edges()
    '''
    #axis = np.array(pointB-pointA)/np.linalg.norm(np.array(pointB-pointA))
    #ms.generate_polyline_from_planar_section()
    #ms.generate_polyline_from_planar_section(planeaxis=3,customaxis=axis,planeoffset=pointA)


    '''polyline = ms.current_mesh()
    polyline_vertices = polyline.vertex_matrix()
    polyline_normals = polyline.vertex_normal_matrix()
    print(polyline_vertices)'''

    #pointC = np.mean(polyline_vertices,axis=1)
    pointC = pointA
    cap_points = pointC
    # print(f'pointC: {pointC}')
    pointC_normal = np.array(pointB-pointA)
    cap_points_normals = pointC_normal
    '''for i in range(0,len(polyline_vertices),2):
        pointCs = (pointC + polyline_vertices[i])/2
        cap_points = np.vstack((cap_points,pointCs))
        pointCs_normal = (pointC_normal + polyline_normals[i])/2
        cap_points_normals = np.vstack((cap_points_normals,pointCs_normal))'''
    
    #ms.show_polyscope()
    
    # delete points from the original array
    mask_vertices = np.isin(original_mesh_vertices,closest_mesh_vertices)
    mask_vertices = np.all(mask_vertices,axis=1)
    # print(mask_vertices)
    cut_original_vertices = original_mesh_vertices[~mask_vertices]
    # print(len(cut_original_vertices))
    # print(f'original normal: {(original_mesh_normals)}')
    mask_normals = np.isin(original_mesh_normals,closest_mesh_normals)
    # print(mask_normals)
    mask_normals = np.all(mask_normals,axis=1)
    # print(mask_normals)
    cut_original_normals = original_mesh_normals[~mask_vertices]
    # print(len(cut_original_normals))

    # add the cap points to the divided matrixes
    closest_mesh_vertices = np.vstack((closest_mesh_vertices,cap_points))

    closest_mesh_normals = np.vstack((closest_mesh_normals,cap_points_normals))
    cut_original_vertices = np.vstack((cut_original_vertices,cap_points))
    cut_original_normals = np.vstack((cut_original_normals,(-1)*cap_points_normals))

    #faces = np.empty()
    m_closest = pymeshlab.Mesh(vertex_matrix=closest_mesh_vertices,v_normals_matrix=closest_mesh_normals)
    #m_closest.vertex_normal_matrix = closest_mesh_normals

    m_cut = pymeshlab.Mesh(vertex_matrix=cut_original_vertices,v_normals_matrix=cut_original_normals)
    #m_cut.vertex_normal_matrix = cut_original_normals

    # end_time = time.time()
    # print(f'Execution time for most of the script: {end_time - start_time} s')

    ms2 = pymeshlab.MeshSet()
    ms2.add_mesh(m_closest,'closest_mesh')

    # start_time = time.time()
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    # end_time = time.time()
    # print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')

    # start_time = time.time()
    ms2.meshing_repair_non_manifold_vertices()
    # end_time = time.time()
    # print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    # start_time = time.time()
    ms2.meshing_close_holes(newfaceselected = False)
    # end_time = time.time()
    # print(f'Execution time for hole filling: {end_time - start_time} s')    

    ms2.save_current_mesh(f'temp_cut_out_1.ply')

    ms2.add_mesh(m_cut,'cut_mesh')
    # start_time = time.time()
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    # end_time = time.time()
    # print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')

    # start_time = time.time()
    ms2.meshing_repair_non_manifold_vertices()
    # end_time = time.time()
    # print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    # start_time = time.time()
    ms2.meshing_close_holes(newfaceselected = False)
    # end_time = time.time()
    # print(f'Execution time for hole filling: {end_time - start_time} s')

    ms2.save_current_mesh(f'temp_cut_out_2.ply')

    return()

divide_mesh(pointA = pointA,pointB = pointB, depth = d, temp_path = path)

