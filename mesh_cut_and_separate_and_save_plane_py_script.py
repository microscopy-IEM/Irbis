import pymeshlab
import numpy as np

def mesh_cut_and_separate(bigger = 'temp_meshNeuron.ply', smaller = 'temp_meshShaft.ply', output = 'temp_meshSpines.ply'):
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(bigger)
    ms.load_new_mesh(smaller)

    shaft = ms.mesh(1).vertex_matrix()

    ms.generate_boolean_difference(first_mesh=0,second_mesh=1)

    ms.save_current_mesh(str(output),save_vertex_normal=True)

    n_complete = ms.number_meshes()
    print(n_complete)

    ms.generate_splitting_by_connected_components()

    n_total = ms.number_meshes()
    print(n_total)

    file = open('temp_cuttingPlaneList.csv','w')

    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)
        j = i + 1 - n_complete
        ms.save_current_mesh(f'temp_{j}.ply')

        spine = ms.mesh(i).vertex_matrix()
        spine_normal = ms.mesh(i).vertex_normal_matrix()

        vertices = []
        normals = []

        for vertex_n in range(0,len(spine)):
            if np.any(np.all(spine[vertex_n] == shaft[:],axis = 1)):
                vertices.append(list(spine[vertex_n]))
                normals.append(list(spine_normal[vertex_n]))

        av = [item[0] for item in vertices]
        bv = [item[1] for item in vertices]
        cv = [item[2] for item in vertices]
        an = [item[0] for item in normals]
        bn = [item[1] for item in normals]
        cn = [item[2] for item in normals]

        mean_list = [np.mean(av),np.mean(bv),np.mean(cv),np.mean(an),np.mean(bn),np.mean(cn)]
        for mean in mean_list:
            file.write(str(mean) + ';')    
        file.write('\n')
    file.close()

    n_spines = n_total - n_complete

    return(n_spines)

n_spines = mesh_cut_and_separate()