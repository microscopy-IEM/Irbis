#output - couple of ply files with meshes of indiviudal spines
#return could be the number of spines

import bpy

import os
print(os.getcwd())

def separate_spines(input_file = 'temp_meshIntersection_remeshed.ply'):
    bpy.ops.import_mesh.ply(filepath=input_file)
    input_name = input_file.split('.')[0]     #file needs to be without any path 
    '''
    #deleting every mesh that is not our input
    for mesh in bpy.data.meshes:
        if mesh.name != input_name:
            bpy.data.meshes.remove(mesh)
        else:
            sel = bpy.data.objects[mesh.name]
            sel.select_set(True)
            bpy.context.view_layer.objects.active = sel

    len_a = len(list(bpy.data.meshes))
    print(len_a)
    
    print(bpy.context.view_layer.objects.active)
    '''
    bpy.ops.mesh.separate(type='LOOSE')

    

    len_b = len(list(bpy.data.meshes))
    print(len_b)
    n_generated = 0

    for object in list(bpy.data.meshes):
        name = object.name
        if name != input_name:
            obj = bpy.data.objects[name]
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            print(bpy.context.view_layer.objects.active)
            bpy.ops.export_mesh.ply(filepath=f'{name}.ply',use_selection=True)
            obj.select_set(False)
            n_generated += 1

    return(n_generated)
    

n = separate_spines('temp_meshIntersection_remeshed.ply')
print(n)



