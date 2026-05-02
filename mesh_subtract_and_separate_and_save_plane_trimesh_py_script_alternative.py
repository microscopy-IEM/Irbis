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


def _connected_vertex_groups(vertex_indices, edges):
    """Return connected groups of vertex indices using mesh edges."""
    if len(vertex_indices) == 0:
        return []

    vertex_set = set(int(v) for v in vertex_indices)
    adjacency = {int(v): set() for v in vertex_indices}

    for a, b in edges:
        a = int(a)
        b = int(b)
        if a in vertex_set and b in vertex_set:
            adjacency[a].add(b)
            adjacency[b].add(a)

    groups = []
    visited = set()
    for v in vertex_indices:
        v = int(v)
        if v in visited:
            continue
        stack = [v]
        visited.add(v)
        group = []
        while stack:
            cur = stack.pop()
            group.append(cur)
            for nxt in adjacency[cur]:
                if nxt not in visited:
                    visited.add(nxt)
                    stack.append(nxt)
        groups.append(np.array(group, dtype=np.int32))

    return groups


def _project_base_point_to_cap_surface(vertices, faces, cap_indices, seed_point):
    """Project a point onto the detected cap surface (prefers cap-only faces)."""
    cap_set = set(int(v) for v in cap_indices)

    # Keep faces fully inside the cap patch when possible.
    cap_face_mask = np.array([
        (int(f[0]) in cap_set) and (int(f[1]) in cap_set) and (int(f[2]) in cap_set)
        for f in faces
    ], dtype=bool)
    cap_faces = faces[cap_face_mask]

    if len(cap_faces) > 0:
        cap_mesh = trimesh.Trimesh(vertices=vertices, faces=cap_faces, process=False)
        closest, _, tri_ids = trimesh.proximity.closest_point(cap_mesh, seed_point.reshape(1, 3))
        projected = closest.reshape(3,)

        normal = np.array([np.nan, np.nan, np.nan], dtype=np.float64)
        if len(cap_mesh.face_normals) > 0 and len(tri_ids) > 0:
            fid = int(tri_ids[0])
            if 0 <= fid < len(cap_mesh.face_normals):
                normal = cap_mesh.face_normals[fid]
        return projected, normal

    # Fallback: no cap-only faces available, keep seed point.
    return seed_point.reshape(3,), np.array([np.nan, np.nan, np.nan], dtype=np.float64)


def _surface_normal_at_point(mesh, point):
    """Return local face normal at the closest point on mesh surface."""
    closest, _, tri_ids = trimesh.proximity.closest_point(mesh, point.reshape(1, 3))
    surface_point = closest.reshape(3,)

    if len(mesh.face_normals) > 0 and len(tri_ids) > 0:
        fid = int(tri_ids[0])
        if 0 <= fid < len(mesh.face_normals):
            return surface_point, np.array(mesh.face_normals[fid], dtype=np.float64)

    return surface_point, np.array([np.nan, np.nan, np.nan], dtype=np.float64)


def mesh_subtract_and_separate(mesh_data, green_threshold=0.3, distance_threshold=0.1):
    """
    Subtracts the second mesh from the first, splits the result into connected components, 
    and identifies vertices for base point calculation based on distance from the second mesh.

    Parameters:
        mesh_data (list): List of dictionaries containing 'vertices', 'faces'.
        DEPRECATED: green_threshold (float): Threshold for the green component to identify vertices connected to the small mesh.
        distance_threshold (float): Surface-distance threshold used to classify cap vertices.

    Returns:
        dict: Contains n_objects, component_data, and base_points for each component.

    Notes: 
        distance_threshold - will need to be fine-tuned and tested, to prevent including non-base points from the spine
    """
    # Convert mesh data to trimesh objects
    meshes = []
    for id, mesh in enumerate(mesh_data[:2]):
        vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
        faces = to_numpy_array(mesh['faces'], dtype=np.int32)
        trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)

        if not trimesh_mesh.is_watertight:
            # print('mesh is not watertight')
            # print(id)
            # not watertight means it has holes or non-manifold edges
            new_vertices, new_faces = pymeshfix.clean_from_arrays(vertices, faces)
            trimesh_mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces, process=True)

        # use this intstead of fix_normals() - which does almost the same if I understand it correctly
        if not trimesh_mesh.is_winding_consistent:
            # non-consistent winding means that two adjacent faces have normals in opposite directions
            # print('winding is not consistent')
            # print(id)
            trimesh.repair.fix_winding(trimesh_mesh)
        if not trimesh_mesh.is_volume:
            # not volume means (at least in some situation) that the volume is negative - normals point inward
            # print('mesh is not volume')
            # print(id)
            trimesh.repair.fix_inversion(trimesh_mesh, multibody=False)

        # we are hoping that everything is fixed by now

        meshes.append(trimesh_mesh)

    # Perform boolean subtraction (first - second)
    difference_mesh = trimesh.boolean.difference([meshes[0], meshes[1]])

    if difference_mesh is None or difference_mesh.is_empty:
        return {
            "n_objects": 0,
            "component_data": {},
            "base_points": np.zeros((0, 6), dtype=np.float64),
            "component_colors": {}
        }

    # Separate connected components
    components = difference_mesh.split(only_watertight=False)

    component_data = {}
    base_points = []
    component_colors_array = {}     # deprecated 

    # Query object for nearest distance from component vertices to mesh2 surface.
    subtractor_query = trimesh.proximity.ProximityQuery(meshes[1])

    # Process each component to extract vertices and base points
    for idx, component in enumerate(components):
        vertices = component.vertices
        faces = component.faces
        vertex_normals = component.vertex_normals if len(component.vertex_normals) > 0 else np.zeros_like(vertices)
        face_normals = component.face_normals if len(component.face_normals) > 0 else np.zeros((len(faces), 3), dtype=np.float64)

        component_data[idx + 1] = {     # Start indexing from 1 - adjusted for Matlab
            'vertices': vertices,
            'faces': faces,
            'vertexNormals': vertex_normals,
            'faceNormals': face_normals
        }

        # print(idx)
        # print(component.is_watertight)
        # print(component.is_winding_consistent)
        # print(component.is_volume)

        # Detect candidate cap vertices by distance to original mesh2 surface.
        _, surface_distances, _ = subtractor_query.on_surface(vertices)
        close_indices = np.where(surface_distances < float(distance_threshold))[0]
        
        if len(close_indices) > 0:
            # Split cap candidates into disconnected cap components and keep the largest one.
            groups = _connected_vertex_groups(close_indices, component.edges_unique)
            cap_patch = max(groups, key=len) if groups else close_indices

            # Base point center is the centroid of the largest cap component, projected to cap surface.
            cap_centroid = np.mean(vertices[cap_patch], axis=0)
            base_point, _ = _project_base_point_to_cap_surface(vertices, faces, cap_patch, cap_centroid)

            # Always derive normal from the local object surface at final base-point position.
            base_point, normal = _surface_normal_at_point(component, base_point)

            base_points.append(np.concatenate((base_point, normal)))
        else:
            base_points.append(np.full(6, np.nan))
            # print(idx)
            # print('no base point found')

    n_objects = len(components)
    base_points = np.array(base_points)

    # print(n_objects)

    return {
        "n_objects": n_objects,
        "component_data": component_data,
        "base_points": base_points,
        "component_colors": component_colors_array
    }

# Call from Matlab
try:
    output = mesh_subtract_and_separate(mesh_data, green_threshold=0.3, distance_threshold=0.1)
except Exception as e:
    print(f"Error performing mesh subtraction: {e}")
    output = None
    sys.exit(1)