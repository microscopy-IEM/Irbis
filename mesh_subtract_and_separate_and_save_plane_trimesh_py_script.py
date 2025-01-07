import trimesh
import numpy as np
import sys
import time     # only for testing purposes

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)


def mesh_subtract_and_separate(mesh_data, green_threshold=0.3, distance_threshold=0.1):
    """
    Subtracts the second mesh from the first, splits the result into connected components, 
    and identifies vertices for base point calculation based on distance from the second mesh.

    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces'.
        DEPRECATED: green_threshold (float): Threshold for the green component to identify vertices connected to the small mesh.
        distance_threshold (float): Threshold for vertices to calculate base point if no green vertices are found.

    Returns:
        dict: Contains n_objects, component_data, and base_points for each component.

    Notes: 
        distance_threshold - will need to be fine-tuned and tested, to prevent including non-base points from the spine
    """
    # Convert mesh data to trimesh objects
    meshes = []
    for mesh in mesh_data[:2]:
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

        # we are hoping that everything is fixed by now

        meshes.append(trimesh_mesh)

    # Perform boolean subtraction (first - second)
    difference_mesh = trimesh.boolean.difference([meshes[0], meshes[1]])

    # Separate connected components
    components = difference_mesh.split(only_watertight=False)

    component_data = {}
    base_points = []
    component_colors_array = {}     # deprecated 

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

        distances = np.linalg.norm(vertices[:, None, :] - meshes[1].vertices[None, :, :], axis=2)
        close_indices = np.where(np.min(distances, axis=1) < distance_threshold)[0]
        
        if len(close_indices) > 0:
            mean_vertex = np.mean(vertices[close_indices], axis=0)
            mean_normal = np.mean(component.vertex_normals[close_indices], axis=0)

            # move the mean vertex to the surface of the mesh
            # timing and printing only for testing purposes
            start_time = time.time()
            closest, distance, _ = trimesh.proximity.closest_point(component, mean_vertex.reshape(1, 3))
            end_time = time.time()
            print('time for closest point calculation: ', end_time - start_time)
            print(distance)
            print(closest)
            base_points.append(np.concatenate((closest.reshape(3,), mean_normal)))
        else:
            base_points.append(np.full(6, np.nan))
            print(idx)
            print('no base point found')

    n_objects = len(components)
    base_points = np.array(base_points)

    # print(n_objects)

    return {
        "n_objects": n_objects,
        "component_data": component_data,
        "base_points": base_points,
        "component_colors": component_colors_array
    }

# Example call
print('using trimesh subtract script')
output = mesh_subtract_and_separate(mesh_data, green_threshold=0.3, distance_threshold=0.1)
