import trimesh
import numpy as np
import sys


def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)


def mesh_subtract_and_separate_with_color(mesh_data, green_threshold=0.3, distance_threshold=0.1):
    """
    Subtracts the second mesh from the first, splits the result into connected components, 
    and identifies vertices for base point calculation based on green color intensity.

    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces'.
        green_threshold (float): Threshold for the green component to identify vertices connected to the small mesh.
        distance_threshold (float): Threshold for vertices to calculate base point if no green vertices are found.

    Returns:
        dict: Contains n_objects, component_data, and base_points for each component.
    """
    # Convert mesh data to trimesh objects
    meshes = []
    for mesh in mesh_data[:2]:
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)
        trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
        print('is_volume before')
        print(trimesh_mesh.is_volume)

        trimesh_mesh.fix_normals()  # Should prevent issues with is_volume being False
        # trimesh_mesh.fix_normals()  # Should prevent issues with is_volume being False

        
        print('is_volume after')
        print(trimesh_mesh.is_volume)

        print('volume')
        print(trimesh_mesh.volume)

        print(trimesh_mesh.is_watertight)

        print(trimesh_mesh.is_winding_consistent)

        if not trimesh_mesh.is_watertight:
            print('mesh is not watertight')
            if 'pymeshfix' not in sys.modules:
                import pymeshfix 

            new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
            trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)
            trimesh_mesh.fix_normals()

            print('is_volume after')
            print(trimesh_mesh.is_volume)

            print('volume')
            print(trimesh_mesh.volume)

            print(trimesh_mesh.is_watertight)

            print(trimesh_mesh.is_winding_consistent)



        meshes.append(trimesh_mesh)

    # Apply distinct colors (Red and Green)
    meshes[0].visual.vertex_colors = [255, 0, 0, 255]  # Red
    meshes[1].visual.vertex_colors = [0, 255, 0, 255]  # Green

    # Perform boolean subtraction (first - second)
    difference_mesh = trimesh.boolean.difference([meshes[0], meshes[1]])

    # Separate connected components
    components = difference_mesh.split(only_watertight=False)

    component_data = {}
    base_points = []
    component_colors_array = {}

    # Process each component to extract vertices and base points
    for idx, component in enumerate(components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros_like(faces)
        vertex_colors = component.visual.vertex_colors / 255.0

        component_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertexNormals': vertex_normals,
            'faceNormals': face_normals
        }

        green_mask = vertex_colors[:, 1] > green_threshold
        green_vertices = vertices[green_mask]
        green_normals = component.vertex_normals[green_mask]

        if len(green_vertices) > 0:
            mean_vertex = np.mean(green_vertices, axis=0)
            mean_normal = np.mean(green_normals, axis=0)
            base_points.append(np.concatenate((mean_vertex, mean_normal)))
        else:
            # Fallback to distance-based method if no green vertices
            distances = np.linalg.norm(vertices[:, None, :] - meshes[1].vertices[None, :, :], axis=2)
            close_indices = np.where(np.min(distances, axis=1) < distance_threshold)[0]
            
            if len(close_indices) > 0:
                mean_vertex = np.mean(vertices[close_indices], axis=0)
                mean_normal = np.mean(component.vertex_normals[close_indices], axis=0)
                base_points.append(np.concatenate((mean_vertex, mean_normal)))
            else:
                base_points.append(np.full(6, np.nan))

        component_colors_array[idx + 1] = vertex_colors     # Start indexing from 1 - adjusted for Matlab

    n_objects = len(components)
    base_points = np.array(base_points)

    print(n_objects)

    return {
        "n_objects": n_objects,
        "component_data": component_data,
        "base_points": base_points,
        "component_colors": component_colors_array
    }

# Example call
print('using trimesh subtract script')
output = mesh_subtract_and_separate_with_color(mesh_data, green_threshold=0.3, distance_threshold=0.1)
