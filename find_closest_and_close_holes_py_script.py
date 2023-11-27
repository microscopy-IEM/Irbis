import pymeshlab
import numpy as np
import os

def find_closest_and_close_holes(original = 'temp_originalSpine.ply',input = 'temp_cut_in.ply',output = 'temp_cut_out.ply',temp_path ='C:\\Users\\Public\\MMP\\temp'):

    os.chdir(temp_path)
    
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(original)
    ms.load_new_mesh(input)  

    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()

    vertices_original = ms.mesh(0).vertex_matrix()

    matches = []

    for i in range(2,n_total):
        vertices_cut = ms.mesh(i).vertex_matrix()
        if len(vertices_cut) < len(vertices_original):
            matchList = [np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))]
            matchProp = np.sum(matchList)/len(matchList)
            #criterion = np.all([np.any(np.all(vertices_cut[vertex] == vertices_original[:],axis = 1)) for vertex in range(0,len(vertices_cut))])
        elif len(vertices_cut) >= len(vertices_original):
            matchList = [np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))]
            #criterion = np.all([np.any(np.all(vertices_original[vertex] == vertices_cut[:],axis = 1)) for vertex in range(0,int(len(vertices_original)/5))])
            matchProp = np.sum(matchList)/len(matchList)
            if matchProp > 0.1:
                matchProp = 1.1
        print(i)
        print(matchProp)
        matches.append(matchProp)
    
    max_match_n = matches.index(max(matches))
    max_match_i = max_match_n + 2

    print(f'match found in {max_match_i} with match {max(matches)}')
    ms.set_current_mesh(new_curr_id = max_match_i)
    ms.meshing_close_holes(maxholesize = 1000,newfaceselected = False)
    ms.save_current_mesh(str(output),save_vertex_normal = True)
    return()  

output = find_closest_and_close_holes(original_name,input_name,output_name,temp_path=path)  