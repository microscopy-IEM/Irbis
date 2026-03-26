try:
    import trimesh
    import numpy as np
    import sys
    # import time     # only for testing purposes
    import pymeshfix 
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh pymeshfix`')
    sys.exit(1)

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def repair_mesh(vertices, faces):
    trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)

    if not trimesh_mesh.is_watertight:
        print('mesh is not watertight')
        # not watertight means it has holes or non-manifold edges
        new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
        trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

    # use this intstead of fix_normals() - which does almost the same if I understand it correctly
    if not trimesh_mesh.is_winding_consistent:
        # non-consistent winding means that two adjacent faces have normals in opposite directions
        print('winding is not consistent')
        trimesh.repair.fix_winding(trimesh_mesh)
    if not trimesh_mesh.is_volume:
        # not volume means (at least in some situation) that the volume is negative - normals point inward
        print('mesh is not volume')
        trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)
    if not trimesh_mesh.is_volume: 
        print('mesh is still not volume')

    return trimesh_mesh.vertices, trimesh_mesh.faces

new_vertices, new_faces = repair_mesh(vertices, faces)
        