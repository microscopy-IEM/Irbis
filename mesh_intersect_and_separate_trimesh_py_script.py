try:
    import trimesh
    import numpy as np
    import sys
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


def mesh_intersect_and_separate(mesh_data):
    """
    Intersects two meshes and separates the resulting mesh into connected components.
    For example, used for generation of dendritic centre. 
    
    Parameters:
        mesh_data (list): A list of dictionaries with each containing 'vertices', 'faces'.
                          
    Returns:
        dict: Contains the number of objects (n_objects), component data with vertices, faces,
              for each component.
    """
    # Convert mesh data to trimesh objects
    meshes = []
    for mesh in mesh_data[:2]:
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)
        trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
        if not trimesh_mesh.is_watertight:
            # print('mesh is not watertight')
            # not watertight means it has holes or non-manifold edges
            new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
            trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

        # use this intstead of fix_normals() - which does almost the same if I understand it correctly
        if not trimesh_mesh.is_winding_consistent:
            # non-consistent winding means that two adjacent faces have normals in opposite directions
            # print('winding is not consistent')
            trimesh.repair.fix_winding(trimesh_mesh)
        if not trimesh_mesh.is_volume:
            # not volume means (at least in some situation) that the volume is negative - normals point inward
            # print('mesh is not volume')
            trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)

        # we are hoping that everything is fixed by now
        meshes.append(trimesh_mesh)

    # Perform boolean intersection between the two meshes
    intersection_mesh = trimesh.boolean.intersection(meshes)

    # Separate connected components
    components = intersection_mesh.split(only_watertight=False)

    component_data = {}

    # Process each component to extract vertices and faces
    for idx, component in enumerate(components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros_like(faces)

        component_data[idx+1] = {       # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertexNormals': vertex_normals,
            'faceNormals': face_normals
        }

    n_objects = len(components)

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }

# Call from Matlab
try:
    output = mesh_intersect_and_separate(mesh_data)
except Exception as e:
    print(f"Error performing mesh subtraction: {e}")
    sys.exit(1)
