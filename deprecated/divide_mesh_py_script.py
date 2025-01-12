import pymeshlab
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def divide_mesh(mesh_data, pointA, pointB, depth=8):
    """
    Accepts the original mesh and the cut part on the side of the cutting plane in the direction
    of the plane normal. Finds the separated component of the cut mesh closest to the cut point. 
    Subtracts this component from the original mesh, applies Poisson reconstruction, 
    and closes holes on both divided components.

    Parameters:
        mesh_data (list of dict): List of dictionaries for each mesh 
            (first: original, second: cut part in the direction of normal), each containing:
            - 'vertices': Vertex coordinates for the mesh (NumPy array or memoryview).
            - 'faces': Face indices for the mesh (NumPy array or memoryview).
            - 'vertexNormals' (optional): Vertex normals (NumPy array or memoryview) - cannot be empty.
            - 'faceNormals' (optional): Face normals (NumPy array or memoryview) - cannot be empty.
        pointA (array-like): 3D coordinates of the reference point for division.
        pointB (array-like): 3D coordinates of the endpoint to define division direction.
        depth (int): Depth for Poisson surface reconstruction.
        
    Returns:
        dict: Contains two reconstructed meshes as 'closest_mesh' and 'cut_mesh', each with:
            - 'vertices': Reconstructed vertex coordinates as a NumPy array.
            - 'faces': Reconstructed face indices as a NumPy array.
            - 'vertexNormals': Vertex normals as a NumPy array.
            - 'faceNormals': Face normals as a NumPy array.
            'closest_mesh' is the original mesh without the cut component (can contain parts on both
            sides of the cutting plane), 'cut_mesh' is the cut component closest to the cutting point.
    """
    ms = pymeshlab.MeshSet()

    # Load each mesh and include normals if provided in mesh_data
    for i, mesh in enumerate(mesh_data):
        mesh_args = {
            "vertex_matrix": to_numpy_array(mesh['vertices'], dtype=np.float64),
            "face_matrix": to_numpy_array(mesh['faces'], dtype=np.int32)
        }

        # Add optional vertex and face normals if they exist in the input data
        if 'vertexNormals' in mesh:
            mesh_args["v_normals_matrix"] = to_numpy_array(mesh['vertexNormals'], dtype=np.float64)
        if 'faceNormals' in mesh:
            mesh_args["f_normals_matrix"] = to_numpy_array(mesh['faceNormals'], dtype=np.float64)

        new_mesh = pymeshlab.Mesh(**mesh_args)
        ms.add_mesh(new_mesh, f"mesh_{i}")

    # Split connected components of the mesh to isolate the detached parts
    ms.set_current_mesh(new_curr_id=1)
    n_complete = ms.mesh_number()
    ms.generate_splitting_by_connected_components()
    n_total = ms.mesh_number()
    n_objects = n_total - n_complete  # Number of new components after splitting

    # Identify the component closest to pointA
    pointA = np.array(pointA)
    min_distances = []
    for i in range(n_complete, n_total):
        ms.set_current_mesh(new_curr_id=i)
        mesh_vertices = ms.current_mesh().vertex_matrix()
        distances = np.linalg.norm(mesh_vertices - pointA, axis=1)
        min_distances.append(np.min(distances))

    closest_mesh_id = np.argmin(min_distances) + n_complete
    ms.set_current_mesh(new_curr_id=closest_mesh_id)

    # Extract vertices and normals for the closest and remaining parts
    closest_mesh = ms.current_mesh()
    closest_vertices = closest_mesh.vertex_matrix()
    closest_normals = closest_mesh.vertex_normal_matrix()

    original_mesh = ms.mesh(id=0)
    original_vertices = original_mesh.vertex_matrix()
    original_normals = original_mesh.vertex_normal_matrix()

    # Define a cap point and direction normal between pointA and pointB for reconstruction
    cap_points = np.array([pointA])  # Set cap as pointA
    cap_normals = np.array([pointB - pointA])  # Directional normal from pointA to pointB

    # Remove vertices in the closest mesh from the original mesh, retaining others
    mask_vertices = np.isin(original_vertices, closest_vertices).all(axis=1)
    cut_original_vertices = original_vertices[~mask_vertices]
    cut_original_normals = original_normals[~mask_vertices]

    # Add cap points to each divided component for continuity
    closest_vertices = np.vstack((closest_vertices, cap_points))
    closest_normals = np.vstack((closest_normals, cap_normals))
    cut_original_vertices = np.vstack((cut_original_vertices, cap_points))
    cut_original_normals = np.vstack((cut_original_normals, -cap_normals))

    # Create meshes for each component after division and cap insertion
    m_closest = pymeshlab.Mesh(vertex_matrix=closest_vertices, v_normals_matrix=closest_normals)
    m_cut = pymeshlab.Mesh(vertex_matrix=cut_original_vertices, v_normals_matrix=cut_original_normals)

    # Initialize a new MeshSet to apply reconstruction and hole closure to each divided part
    ms2 = pymeshlab.MeshSet()
    ms2.add_mesh(m_closest, 'closest_mesh')
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth), preclean=True)
    ms2.meshing_repair_non_manifold_vertices()
    ms2.meshing_close_holes(newfaceselected=False)
    mesh_closest_reconstructed = ms2.current_mesh()

    ms2.add_mesh(m_cut, 'cut_mesh')
    ms2.generate_surface_reconstruction_screened_poisson(depth=int(depth), preclean=True)
    ms2.meshing_repair_non_manifold_vertices()
    ms2.meshing_close_holes(newfaceselected=False)
    mesh_cut_reconstructed = ms2.current_mesh()

    # Return final mesh data with vertices, faces, and normals of each divided component
    return {
        "closest_mesh": {
            "vertices": to_numpy_array(mesh_closest_reconstructed.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(mesh_closest_reconstructed.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(mesh_closest_reconstructed.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(mesh_closest_reconstructed.face_normal_matrix(), dtype=np.float64)
        },
        "cut_mesh": {
            "vertices": to_numpy_array(mesh_cut_reconstructed.vertex_matrix(), dtype=np.float64),
            "faces": to_numpy_array(mesh_cut_reconstructed.face_matrix(), dtype=np.int32),
            "vertexNormals": to_numpy_array(mesh_cut_reconstructed.vertex_normal_matrix(), dtype=np.float64),
            "faceNormals": to_numpy_array(mesh_cut_reconstructed.face_normal_matrix(), dtype=np.float64)
        }
    }

# Call the function so that the script can run when called from Matlab
output = divide_mesh(mesh_data, pointA, pointB, d)