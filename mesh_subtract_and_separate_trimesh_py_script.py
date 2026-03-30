try:
    import trimesh
    import numpy as np
    import sys
    # import time     # only for testing purposes
    import pymeshfix 
    import traceback
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh pymeshfix`')
    sys.exit(1)

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)


def mesh_subtract_and_separate(mesh_data):
    """
    Subtracts the second mesh from the first and splits the result into connected components

    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces'.

    Returns:
        dict: Contains n_objects and component_data for each component.
    """
    # Convert mesh data to trimesh objects
    meshes = []
    for id, mesh in enumerate(mesh_data[:2]):
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)
        trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)

        if trimesh_mesh.volume < 0:
            trimesh_mesh.invert()  # Invert the mesh to correct negative volume

        if not trimesh_mesh.is_watertight:
            print('mesh is not watertight')
            print(id)
            # not watertight means it has holes or non-manifold edges
            # first try to use fill_holes()
            trimesh.repair.fill_holes(trimesh_mesh)
            try:
                new_faces = trimesh.repair.stitch(trimesh_mesh)
                if new_faces is not None and len(new_faces) > 0:
                    print(f'Stitched {len(new_faces)} faces')
                    all_faces = np.vstack((trimesh_mesh.faces, new_faces))
                    trimesh_mesh.faces = all_faces
                    trimesh_mesh.remove_unreferenced_vertices()
            except Exception as e:
                print(f"Error during stitching: {e}")
                traceback.print_exc()

        # # use this intstead of fix_normals() - which does almost the same if I understand it correctly
        # if not trimesh_mesh.is_winding_consistent:
        #     # non-consistent winding means that two adjacent faces have normals in opposite directions
        #     # print('winding is not consistent')
        #     # print(id)
        #     trimesh.repair.fix_winding(trimesh_mesh)
        # if not trimesh_mesh.is_volume:
        #     # not volume means (at least in some situation) that the volume is negative - normals point inward
        #     # print('mesh is not volume')
        #     # print(id)
        #     trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)

        # if not trimesh_mesh.is_watertight:
        #     print('mesh is still not watertight after repairs')
        #     print(id)

        #     broken = trimesh.repair.broken_faces(trimesh_mesh)
        #     print(f'broken faces: {broken}')
        #     print(f'number of broken faces: {len(broken)}')

        #     trimesh_mesh = remove_broken_faces(trimesh_mesh)

        # # if not trimesh_mesh.is_watertight:
        # #     print('attempting to fix mesh with pymeshfix')

        # #     new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
        # #     trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

        if not trimesh_mesh.is_winding_consistent:
            # non-consistent winding means that two adjacent faces have normals in opposite directions
            # print('winding is not consistent')
            # print(id)
            trimesh.repair.fix_winding(trimesh_mesh)
        # if not trimesh_mesh.is_volume:
        #     # not volume means (at least in some situation) that the volume is negative - normals point inward
        #     # print('mesh is not volume')
        #     # print(id)
        #     trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)
        # # we are hoping that everything is fixed by now

        # if not trimesh_mesh.is_volume: 
        #     print('mesh is still not volume after repairs')
        #     print(id)

        print(trimesh_mesh.volume)
        print(trimesh_mesh.is_watertight)
        print(trimesh_mesh.is_winding_consistent)

        meshes.append(trimesh_mesh)

    # Perform boolean subtraction (first - second)
    difference_mesh = trimesh.boolean.difference([meshes[0], meshes[1]], check_volume=False)
    print(f'nFaces: {len(difference_mesh.faces)}')
    print(f'Difference mesh volume: {difference_mesh.volume}')

    # Separate connected components
    components = difference_mesh.split(only_watertight=False)
    print(f'Number of components: {len(components)}')

    component_data = {}

    # Process each component to extract vertices and base points
    for idx, component in enumerate(components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros_like(faces)

        component_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertexNormals': vertex_normals,
            'faceNormals': face_normals
        }

            # print('no base point found')

    n_objects = len(components)

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }


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


# Call from Matlab
try:
    output = mesh_subtract_and_separate(mesh_data)
except Exception as e:
    print(f"Error performing mesh subtraction: {e}")
    traceback.print_exc()
    output = None
    sys.exit(1)