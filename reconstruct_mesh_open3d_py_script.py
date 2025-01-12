import open3d as o3d
import numpy as np
import trimesh
import sys
import pymeshfix 

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def fix_mesh_with_trimesh(o3d_mesh):
    # Use trimesh and if needed, pymeshfix, to repair the mesh
    vertices = np.asarray(o3d_mesh.vertices)
    faces = np.asarray(o3d_mesh.triangles)
    trimesh_mesh = trimesh.Trimesh(vertices, faces)
    
    if not trimesh_mesh.is_watertight:
        print('mesh is not watertight')
        # not watertight means it has holes or non-m    anifold edges
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

    return trimesh_mesh

def reconstruct_mesh(mesh_data, depth=8, fraction_to_keep=0.8, min_vertex_num=20, separate=True):
    """
    Reconstructs a mesh with Poisson surface reconstruction, repairs non-manifold vertices, 
    and optionally separates the mesh into connected components.

    Parameters:
        mesh_data (dict): Dictionary containing 'vertices' and optionally 'vertexNormals'.
        depth (int): Depth for Poisson surface reconstruction.
        fraction_to_keep (float): Fraction of faces to keep during mesh decimation.
        min_vertex_num (int): Minimum vertex count for separated components.
        separate (bool): Flag to separate connected components in the mesh.
    
    Returns:
        dict: Contains the number of objects (n_objects) and component_data with vertices, faces, 
              vertexNormals, and faceNormals for each component.
    """
    # Create an Open3D PointCloud object
    pcd = o3d.geometry.PointCloud()
    vertices = to_numpy_array(mesh_data[0]['vertices'], dtype=np.float64)
    pcd.points = o3d.utility.Vector3dVector(vertices)

    if 'vertexNormals' in mesh_data[0]:
        vertex_normals = to_numpy_array(mesh_data[0]['vertexNormals'], dtype=np.float64)
        pcd.normals = o3d.utility.Vector3dVector(vertex_normals)

    # Perform Poisson surface reconstruction
    mesh, densities = o3d.geometry.TriangleMesh.create_from_point_cloud_poisson(
        pcd, depth=int(depth)
    )
    # print(mesh.vertices)

    # Estimate the density of the points to remove low-density vertices
    densities = np.asarray(densities)
    # print(densities)
    if fraction_to_keep != 1:
        density_threshold = np.quantile(densities, 1 - fraction_to_keep)
        vertices_to_keep = densities > density_threshold

        # Apply the density filter
        mesh.remove_vertices_by_mask(~vertices_to_keep)
        # print('some vertices removed')
        # print(mesh.vertices)

    # Repair non-manifold geometry (if any)
    mesh = mesh.remove_non_manifold_edges()

    # # Close holes in the mesh
    # mesh = mesh.fill_holes()

    component_data = {}

    if separate:
        # Compute connected components
        labels = np.array(mesh.cluster_connected_triangles()[0])
        num_components = labels.max() + 1

        object_num = 1
        for i in range(num_components):
            # Extract each component as a new mesh
            indices = np.where(labels == i)[0]
            component = mesh.select_by_index(indices, retain_geometry=True)

            if len(component.vertices) >= min_vertex_num:

                # Fix the mesh with trimesh
                trimesh_mesh = fix_mesh_with_trimesh(component)

                vertices = trimesh_mesh.vertices
                faces = trimesh_mesh.faces
                vertex_normals = trimesh_mesh.vertex_normals if len(trimesh_mesh.vertex_normals) > 0 else np.zeros_like(vertices)
                face_normals = trimesh_mesh.face_normals if len(trimesh_mesh.face_normals) > 0 else np.zeros_like(faces)

                component_data[object_num] = { 
                    'vertices': vertices,
                    'faces': faces,
                    'vertexNormals': vertex_normals,
                    'faceNormals': face_normals
                }

                object_num += 1

        n_objects = object_num - 1
    else:
        # Store data for the single reconstructed mesh
        # Fix the mesh with trimesh
        trimesh_mesh = fix_mesh_with_trimesh(mesh)
        print(trimesh_mesh.is_watertight)

        vertices = trimesh_mesh.vertices
        faces = trimesh_mesh.faces
        vertex_normals = trimesh_mesh.vertex_normals if len(trimesh_mesh.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = trimesh_mesh.face_normals if len(trimesh_mesh.face_normals) > 0 else np.zeros_like(faces)

        component_data[1] = { 
            'vertices': vertices,
            'faces': faces,
            'vertexNormals': vertex_normals,
            'faceNormals': face_normals
        }

        n_objects = 1

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }

# Example call (parameters would need to be defined in the MATLAB environment)
print('open3d option')
try:
    output = reconstruct_mesh(
        mesh_data=mesh_data,
        depth=d,
        fraction_to_keep=f,
        min_vertex_num=nVer,
        separate=separate
    )
except Exception as e:
    print(e)
    output = None

    sys.exit(1)  # Return status 1 if an error occurred
