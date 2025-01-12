import trimesh
import numpy as np
import sys

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)


def fix_mesh(mesh_data):
    """
    Fixes the mesh data by ensuring that the mesh is watertight, has consistent winding, and is a volume.
    
    Parameters:
        mesh_data (list): A list of dictionaries with each containing 'vertices', 'faces'.
                          
    Returns:
        dict: Contains the number of objects (n_objects), fixed mesh data with vertices, faces,
              for each mesh.
    """
    # Convert mesh data to trimesh objects
    fixed_mesh_data = {}
    for idx, mesh in enumerate(mesh_data):
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)
        trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
        if not trimesh_mesh.is_watertight:
            print('mesh is not watertight')
            # not watertight means it has holes or non-manifold edges
            if 'pymeshfix' not in sys.modules:
                import pymeshfix 

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

        vertices = trimesh_mesh.vertices
        faces = trimesh_mesh.faces

        fixed_mesh_data[idx+1] = {       # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
        }

    return fixed_mesh_data

# Example call
try:
    fixed_mesh_data = fix_mesh(mesh_data)
except Exception as e:
    print(f"Error fixing mesh: {e}")
    fixed_mesh_data = None
    
    import sys
    sys.exit(1)
