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
        
        start_time = time.time()
        ms.load_new_mesh(str(input))  
        end_time = time.time()
        print(f'Execution time for loading: {end_time - start_time} s')

    ms.set_current_mesh(new_curr_id=1)
    n_complete = ms.number_meshes()
    print(n_complete)

    start_time = time.time()
    ms.generate_splitting_by_connected_components()
    end_time = time.time()
    print(f'Execution time for splitting: {end_time - start_time} s')

    n_total = ms.number_meshes()
    print(n_total)    

    n_objects = n_total - n_complete
    print(n_objects)

    min_distances = []

    start_time = time.time()
    # find the mesh closest to pointA
    pointA = np.array(pointA)
    print(f'pointA: {pointA}')
    pointB = np.array(pointB)
    print(f'pointB: {pointB}')
    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)
        mesh_vertices = ms.current_mesh().vertex_matrix()
        distances = np.linalg.norm(mesh_vertices - pointA, axis=1)
        min_dist = np.min(distances)
        min_distances.append(min_dist)

    # closest_dist = np.min(min_distances)
    # closest = closest_dist.index(closest_dist)
    closest = np.argmin(min_distances)
    #closest = 1
    closest = closest + n_complete
    print(f'closest: {closest}')

    closest_mesh = ms.mesh(id = closest)
    print(f'closest mesh: {closest_mesh.vertex_number()}')
    closest_mesh_vertices = closest_mesh.vertex_matrix()
    print(len(closest_mesh_vertices))
    closest_mesh_normals = closest_mesh.vertex_normal_matrix()
    original_mesh = ms.mesh(id = 0)
    original_mesh_vertices = original_mesh.vertex_matrix()
    original_mesh_normals = original_mesh.vertex_normal_matrix()
    print(len(original_mesh_vertices))
    print(f'original mesh: {original_mesh.vertex_number()}')

    #ms.show_polyscope()

    ms.set_current_mesh(new_curr_id = closest)
    print(ms.current_mesh().vertex_number())
    ms.compute_selection_from_mesh_border()
    selection_array = ms.current_mesh().vertex_selection_array()
    print(f' vertex selection: {np.sum(ms.current_mesh().vertex_selection_array())}')
    # print(f'{ms.current_mesh().vertex_matrix()[selection_array]}')
    polyline_vertices = ms.current_mesh().vertex_matrix()[selection_array]
    polyline_normals = ms.current_mesh().vertex_normal_matrix()[selection_array]
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

    pointC = np.mean(polyline_vertices,axis=0)
    #pointC = pointA
    cap_points = pointC
    print(f'pointC: {pointC}')
    pointC_normal = np.array(pointB-pointA)
    cap_points_normals = pointC_normal
    for i in range(0,len(polyline_vertices),2):
        pointC1 = (pointC*1 + polyline_vertices[i]*3)/4
        pointC2 = (pointC + polyline_vertices[i])/2
        pointC3 = (pointC*3 + polyline_vertices[i]*1)/4
        cap_points = np.vstack((cap_points,pointC1))
        cap_points = np.vstack((cap_points,pointC2))
        cap_points = np.vstack((cap_points,pointC3))
        pointC1_normal = ((pointC_normal*1 + polyline_normals[i]*3)/4)/(10*np.linalg.norm((pointC_normal*1 + polyline_normals[i]*3)/4))
        pointC2_normal = ((pointC_normal + polyline_normals[i])/2)/(10*np.linalg.norm((pointC_normal + polyline_normals[i])/2))
        pointC3_normal = ((pointC_normal*3 + polyline_normals[i]*1)/4)/(10*np.linalg.norm((pointC_normal*3 + polyline_normals[i])/4))
        cap_points_normals = np.vstack((cap_points_normals,pointC1_normal))
        cap_points_normals = np.vstack((cap_points_normals,pointC2_normal))
        cap_points_normals = np.vstack((cap_points_normals,pointC3_normal))
    
    #ms.show_polyscope()
    
    # delete points from the original array
    mask_vertices = np.isin(original_mesh_vertices,closest_mesh_vertices)
    mask_vertices = np.all(mask_vertices,axis=1)
    print(mask_vertices)
    cut_original_vertices = original_mesh_vertices[~mask_vertices]
    print(len(cut_original_vertices))
    print(f'original normal: {(original_mesh_normals)}')
    mask_normals = np.isin(original_mesh_normals,closest_mesh_normals)
    print(mask_normals)
    mask_normals = np.all(mask_normals,axis=1)
    print(mask_normals)
    cut_original_normals = original_mesh_normals[~mask_vertices]
    print(len(cut_original_normals))

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

    end_time = time.time()
    print(f'Execution time for most of the script: {end_time - start_time} s')

    ms2 = pymeshlab.MeshSet()
    ms2.add_mesh(m_closest,'closest_mesh')

    start_time = time.time()
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    end_time = time.time()
    print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')

    start_time = time.time()
    ms2.meshing_repair_non_manifold_vertices()
    end_time = time.time()
    print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    start_time = time.time()
    ms2.meshing_close_holes(newfaceselected = False)
    end_time = time.time()
    print(f'Execution time for hole filling: {end_time - start_time} s')    

    ms2.save_current_mesh(f'temp_cut_out_1.ply')

    ms2.add_mesh(m_cut,'cut_mesh')
    start_time = time.time()
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth),preclean=True)
    end_time = time.time()
    print(f'Execution time for poissoon reconstruction: {end_time - start_time} s')

    start_time = time.time()
    ms2.meshing_repair_non_manifold_vertices()
    end_time = time.time()
    print(f'Execution time for removing non-manifold vertices: {end_time - start_time} s')

    start_time = time.time()
    ms2.meshing_close_holes(newfaceselected = False)
    end_time = time.time()
    print(f'Execution time for hole filling: {end_time - start_time} s')

    ms2.save_current_mesh(f'temp_cut_out_2.ply')

    return()

pointA = np.array([16.9545,10.7210,4.4708])
pointB = np.array([18.0151,11.4710,4.4708])
d = 8
path = 'C:\\Users\\Public\\IrbisApp\\temp'
divide_mesh(pointA = pointA,pointB = pointB, depth = d, temp_path = path)

