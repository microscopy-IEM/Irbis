import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

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
    ms = pymeshlab.MeshSet()

    # Load vertices and vertex normals
    for i, mesh in enumerate(mesh_data[:1]):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64)
        }
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)

        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Perform Poisson surface reconstruction
    ms.generate_surface_reconstruction_screened_poisson(depth=int(depth), preclean=True)

    # Repair non-manifold vertices
    ms.meshing_repair_non_manifold_vertices()

    # Close holes in the mesh
    ms.meshing_close_holes(newfaceselected=False)

    # Decimate the mesh if fraction to keep is specified and not equal to 1
    if fraction_to_keep != 1:
        face_num = int(ms.current_mesh().face_number() * fraction_to_keep)
        ms.meshing_decimation_quadric_edge_collapse(
            targetfacenum=face_num,
            preserveboundary=True,
            preservenormal=True,
            preservetopology=True,
            autoclean=True
        )

    component_data = {}

    # If separate flag is true, split the mesh into connected components
    if separate:
        n_complete = ms.mesh_number()

        # Separate connected components
        ms.generate_splitting_by_connected_components()
        n_total = ms.mesh_number()

        # Collect data for each component that meets the minimum vertex count
        object_num = 1
        for i in range(n_complete, n_total):
            ms.set_current_mesh(new_curr_id=i)
            if ms.current_mesh().vertex_number() >= min_vertex_num:
                current_mesh = ms.current_mesh()

                # Store component data
                component_data[object_num] = {
                    "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
                    "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
                    "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
                    "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
                }
                object_num += 1

        n_objects = object_num - 1

    else:
        # If no separation is required, store data for the single reconstructed mesh
        current_mesh = ms.current_mesh()
        component_data[1] = {
            "vertices": to_numpy_array(current_mesh.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(current_mesh.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(current_mesh.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(current_mesh.face_normal_matrix(), dtype=np.float64)
        }

        n_objects = 1

    return {
        "n_objects": n_objects,
        "component_data": component_data
    }

# Call the function so that the script can run when called from Matlab
output = reconstruct_mesh(
    mesh_data=mesh_data,
    depth=8,
    fraction_to_keep=0.8,
    min_vertex_num=20,
    separate=True
)