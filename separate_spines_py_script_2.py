#output - couple of ply files with meshes of indiviudal spines
#return could be the number of spines

import bpy

def separate_spines(input_file = 'temp_meshIntersection_remeshed.ply'):
    # cleaning the environment
    for object in bpy.data.meshes:
        bpy.data.meshes.remove(object)

    len_a = len(list(bpy.data.meshes))
    print(len_a)
    bpy.ops.import_mesh.ply(filepath=input_file)
    input_name = input_file.split('.')[0]     #file needs to be without any path 
    bpy.ops.mesh.separate(type='LOOSE')

    

    len_b = len(list(bpy.data.meshes))
    print(len_b)
    n_generated = 0

    bpy.context.view_layer.objects.active = None

    for object in bpy.data.objects:
        object.select_set(False)

    for object in list(bpy.data.meshes):
        name = object.name
        obj = bpy.data.objects[name]
        if name == input_name:
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            print(bpy.context.view_layer.objects.active)
            print([obj.name for obj in bpy.context.selected_objects])
            bpy.ops.export_mesh.ply(filepath=f'temp_{input_name}.ply',use_selection=True)

            obj.select_set(False)
            bpy.data.meshes.remove(object)
        else:
            n_generated += 1
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            print(bpy.context.view_layer.objects.active)
            print([obj.name for obj in bpy.context.selected_objects])
            bpy.ops.export_mesh.ply(filepath=f'temp_{n_generated}.ply',use_selection=True)
            obj.select_set(False)
            if name != "temp_meshIntersection_remeshed.003":
                bpy.data.meshes.remove(object)
            
    print(bpy.data.meshes)
    bpy.ops.export_mesh.ply(filepath=f'temp_individual.ply')
    


    return(n_generated)
    

n = separate_spines()
print(n)



