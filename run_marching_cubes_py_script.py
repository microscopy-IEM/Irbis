import skimage
import trimesh
import pymeshfix 
import numpy as np

def run_marching_cubes(zstack, level):
    level = int(level)
    vertices, faces, normals, values = skimage.measure.marching_cubes(zstack, level=level, allow_degenerate=False)

    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
    print(mesh.is_watertight)  # check if the mesh is watertight
    broken_faces = trimesh.repair.broken_faces(mesh)
    print(f'broken faces: {broken_faces}')
    print(len(faces))
    print(len(broken_faces))



    # use this intstead of fix_normals() - which does almost the same if I understand it correctly
    if not mesh.is_winding_consistent:
        # non-consistent winding means that two adjacent faces have normals in opposite directions
        print('winding is not consistent')
        # print(id)
        trimesh.repair.fix_winding(mesh)
    if not mesh.is_volume:
        # not volume means (at least in some situation) that the volume is negative - normals point inward
        print('mesh is not volume')
        # print(id)
        trimesh.repair.fix_inversion(mesh, multibody=False)

    if not mesh.is_watertight:
        print('mesh is not watertight')
        # not watertight means it has holes or non-manifold edges
        # first try to use fill_holes()
        trimesh.repair.fill_holes(mesh)

    if not mesh.is_watertight:
        print('mesh is still not watertight after repairs')

        broken = trimesh.repair.broken_faces(mesh)
        print(f'broken faces: {broken}')
        print(f'number of broken faces: {len(broken)}')

        mesh = remove_broken_faces(mesh)



    # if not trimesh_mesh.is_watertight:
    #     print('attempting to fix mesh with pymeshfix')

    #     new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
    #     trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

    if not mesh.is_winding_consistent:
        # non-consistent winding means that two adjacent faces have normals in opposite directions
        # print('winding is not consistent')
        # print(id)
        trimesh.repair.fix_winding(mesh)
    if not mesh.is_volume:
        # not volume means (at least in some situation) that the volume is negative - normals point inward
        # print('mesh is not volume')
        # print(id)
        trimesh.repair.fix_inversion(mesh, multibody=False)
    # we are hoping that everything is fixed by now

    if not mesh.is_volume: 
        print('mesh is still not volume after repairs')
        print(id)
    return vertices, faces, normals, values

def remove_broken_faces(mesh):
    # Identify broken faces
    broken_faces = trimesh.repair.broken_faces(mesh)
    if len(broken_faces) > 0:
        print(f"Removing {len(broken_faces)} broken faces")
        mesh.update_faces(np.setdiff1d(np.arange(len(mesh.faces)), broken_faces))
        mesh.remove_unreferenced_vertices()
        watertight = trimesh.repair.fill_holes(mesh)
        print(f"Filled holes: {watertight}")
    return mesh

run_marching_cubes(zstack, level)