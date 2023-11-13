import pymeshlab

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

    for i in range(n_complete,n_total):
        ms.set_current_mesh(new_curr_id = i)

        spine = ms.mesh(i).vertex_matrix()
        alls = []
        for vertex_n in range(0,len(spine)):
            if np.any(shaft[:] == spines[vertex_n]):
                alls.append(spines[vertex_n])
        print(alls)
        j = i + 1 - n_complete
        ms.save_current_mesh(f'temp_{j}.ply')

    n_spines = n_total - n_complete
    print(n_spines)

    return([n_spines,0])

outcome = mesh_cut_and_separate()