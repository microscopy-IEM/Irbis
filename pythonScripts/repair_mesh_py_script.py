from unittest import result


try:
    import sys
    import numpy as np
    import trimesh
    import traceback
except ImportError as e:
    print(e)
    print('Please install the required packages using `pip install numpy trimesh`')
    sys.exit(1)



def to_numpy_array(data, dtype):
    """
    Ensure data is a NumPy array, converting memoryview if needed.

    Args:
        data: Input data (array-like or memoryview).
        dtype: Desired NumPy dtype.

    Returns:
        np.ndarray: Data as a NumPy array of the specified dtype.
    """
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)



def load_mesh(mesh_input):
    """
    Load a mesh from a dictionary containing 'vertices' and 'faces'.

    Args:
        mesh_input (dict): Dictionary with 'vertices' and 'faces' arrays.

    Returns:
        trimesh.Trimesh: Loaded mesh object.
    """
    vertices = to_numpy_array(mesh_input['vertices'], dtype=np.float64)
    faces = to_numpy_array(mesh_input['faces'], dtype=np.int32)
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
    return mesh



def repair_winding_by_face_removal(mesh):
    """
    Repair winding inconsistencies by removing one face per inconsistent edge.
    
    Parameters
    ----------
    mesh : trimesh.Trimesh
        The mesh to repair.
    
    Returns
    -------
    repaired_mesh : trimesh.Trimesh
        The repaired mesh with winding-inconsistent faces removed.
    
    """
    
    adjacency = mesh.face_adjacency
    adjacencyEdges = mesh.face_adjacency_edges
    
    # Pre-allocate for inconsistent edges
    facesToRemove = set()
    inconsistentCount = 0
    
    # Vectorized direction checking
    for facePair, edge in zip(adjacency, adjacencyEdges):
        f1 = mesh.faces[facePair[0]]
        f2 = mesh.faces[facePair[1]]
        
        # Check if edge appears in same orientation in both faces
        # This is more efficient than creating tuples
        edge_v0, edge_v1 = edge[0], edge[1]
        
        # Find edge orientation in f1
        found1 = False
        for i in range(3):
            if (f1[i] == edge_v0 and f1[(i + 1) % 3] == edge_v1):
                found1 = True
                break
        
        # Find edge orientation in f2
        found2 = False
        for i in range(3):
            if (f2[i] == edge_v0 and f2[(i + 1) % 3] == edge_v1):
                found2 = True
                break
        
        # If both found the edge in same direction OR both found it reversed,
        # then winding is inconsistent
        if found1 == found2:  # Both same orientation = inconsistent
            facesToRemove.add(facePair[0])
            facesToRemove.add(facePair[1])
            inconsistentCount += 1
    
    # Create repaired mesh
    facesToKeep = np.array([i not in facesToRemove for i in range(len(mesh.faces))], dtype=bool)
    repairedMesh = trimesh.Trimesh(
        vertices=mesh.vertices,
        faces=mesh.faces[facesToKeep]
    )
    repairedMesh.remove_unreferenced_vertices()
    
    print(f"Original mesh: {len(mesh.faces)} faces, is_winding_consistent = {mesh.is_winding_consistent}")
    print(f"Removed {len(facesToRemove)} faces from {inconsistentCount} inconsistent edges")
    print(f"Repaired mesh: {len(repairedMesh.faces)} faces, is_winding_consistent = {repairedMesh.is_winding_consistent}")
    
    return repairedMesh


def repair_winding_by_vertex_removal(mesh):
    """
    Repair winding inconsistencies by removing both vertices of inconsistent edges
    and all faces that reference those vertices.

    Parameters
    ----------
    mesh : trimesh.Trimesh
        The mesh to repair.

    Returns
    -------
    repaired_mesh : trimesh.Trimesh
        The repaired mesh with offending vertices and faces removed.
    """
    adjacency = mesh.face_adjacency
    adjacencyEdges = mesh.face_adjacency_edges

    verticesToRemove = set()
    facesToRemove = set()
    inconsistentCount = 0

    for facePair, edge in zip(adjacency, adjacencyEdges):
        f1 = mesh.faces[facePair[0]]
        f2 = mesh.faces[facePair[1]]

        edge_v0, edge_v1 = edge[0], edge[1]

        found1 = False
        for i in range(3):
            if (f1[i] == edge_v0 and f1[(i + 1) % 3] == edge_v1):
                found1 = True
                break

        found2 = False
        for i in range(3):
            if (f2[i] == edge_v0 and f2[(i + 1) % 3] == edge_v1):
                found2 = True
                break

        if found1 == found2:
            # Mark the two adjacent faces and the two vertices for removal
            facesToRemove.add(facePair[0])
            facesToRemove.add(facePair[1])
            verticesToRemove.add(int(edge_v0))
            verticesToRemove.add(int(edge_v1))
            inconsistentCount += 1

    # Also remove any face that references any of the verticesToRemove
    for fi, face in enumerate(mesh.faces):
        if fi in facesToRemove:
            continue
        if any(v in verticesToRemove for v in face):
            facesToRemove.add(fi)

    if len(facesToRemove) == 0 and len(verticesToRemove) == 0:
        print("No inconsistent edges found for vertex-removal strategy.")
        return mesh

    # Build faces mask and new faces array
    facesToKeepMask = np.array([i not in facesToRemove for i in range(len(mesh.faces))], dtype=bool)
    new_faces = mesh.faces[facesToKeepMask]

    # Build vertex keep mask and remapping
    vertexKeepMask = np.array([i not in verticesToRemove for i in range(len(mesh.vertices))], dtype=bool)
    kept_indices = np.nonzero(vertexKeepMask)[0]
    if len(kept_indices) == 0:
        # Removing all vertices — return an empty mesh
        print("All vertices would be removed; returning empty mesh.")
        return trimesh.Trimesh(vertices=np.zeros((0, 3)), faces=np.zeros((0, 3), dtype=np.int32))

    old_to_new = -np.ones(len(mesh.vertices), dtype=int)
    old_to_new[kept_indices] = np.arange(len(kept_indices))

    try:
        reindexed_faces = old_to_new[new_faces]
    except Exception as e:
        print(f"Error reindexing faces after vertex removal: {e}")
        return mesh

    repairedMesh = trimesh.Trimesh(vertices=mesh.vertices[vertexKeepMask], faces=reindexed_faces)
    repairedMesh.remove_unreferenced_vertices()

    print(f"Vertex-removal: removed {len(verticesToRemove)} vertices and {len(facesToRemove)} faces from {inconsistentCount} inconsistent edges")
    print(f"Repaired mesh: {len(repairedMesh.faces)} faces, is_winding_consistent = {repairedMesh.is_winding_consistent}")

    return repairedMesh



def fix_mesh(mesh):
    """
    Attempt to repair a mesh to ensure watertightness, winding consistency, and positive volume.

    Args:
        mesh (trimesh.Trimesh): Input mesh to repair.

    Returns:
        trimesh.Trimesh: Repaired mesh.
    """
    if not mesh.is_watertight:
        print("Mesh is not watertight. Attempting to fix...")

        is_watertight = trimesh.repair.fill_holes(mesh, use_fan=True) # This also does check of is_watertight, but the value should already be cached
        if not is_watertight:
            try:
                # try-except statemenent added here, because the stitch function fails if no faces are produced
                print("Filling holes did not help. Using stitch")
                new_faces, new_vertices = trimesh.repair.stitch(mesh, insert_vertices=True)
                print(f'Added {len(new_faces)} faces and {len(new_vertices)} vertices to stitch the mesh.')
                all_faces = np.vstack((mesh.faces, new_faces))
                mesh.faces = all_faces
                all_vertices = np.vstack((mesh.vertices, new_vertices))
                mesh.vertices = all_vertices
                # mesh.remove_unreferenced_vertices()
                # print("Filling holes did not help. Using stitch")
                # new_faces = trimesh.repair.stitch(mesh, insert_vertices=False)
                # print(f'Added {len(new_faces)} faces stitch the mesh.')
                # all_faces = np.vstack((mesh.faces, new_faces))
                # mesh.faces = all_faces
                # mesh.remove_unreferenced_vertices()
            except Exception as e:
                print(f"Error during stitching: {e}")
                # traceback.print_exc()

    if not mesh.is_winding_consistent:
        print("Mesh is not winding consistent. Attempting to fix...")
        # This should be after fixing watertightness, as fixing watertightness may change the winding consistency
        trimesh.repair.fix_winding(mesh)  # This also does check of is_winding_consistent, but the value should already be cached

    if not mesh.is_winding_consistent:
        print("Mesh is still not winding consistent after fix_winding. Attempting vertex removal...")
        mesh = repair_winding_by_vertex_removal(mesh)
        # mesh = repair_winding_by_face_removal(mesh)   # This does not seem to solve the problem in situation when removing the vertices and all attached faces does

        if not mesh.is_watertight:
            print("Mesh is not watertight. Attempting to fix...")

            is_watertight = trimesh.repair.fill_holes(mesh, use_fan=True) # This also does check of is_watertight, but the value should already be cached
            if not is_watertight:
                try:
                    # try-except statemenent added here, because the stitch function fails if no faces are produced
                    print("Filling holes did not help. Using stitch")
                    new_faces, new_vertices = trimesh.repair.stitch(mesh, insert_vertices=True)
                    print(f'Added {len(new_faces)} faces and {len(new_vertices)} vertices to stitch the mesh.')
                    all_faces = np.vstack((mesh.faces, new_faces))
                    mesh.faces = all_faces
                    all_vertices = np.vstack((mesh.vertices, new_vertices))
                    mesh.vertices = all_vertices
                    # mesh.remove_unreferenced_vertices()
                    # print("Filling holes did not help. Using stitch")
                    # new_faces = trimesh.repair.stitch(mesh, insert_vertices=False)
                    # print(f'Added {len(new_faces)} faces stitch the mesh.')
                    # all_faces = np.vstack((mesh.faces, new_faces))
                    # mesh.faces = all_faces
                    # mesh.remove_unreferenced_vertices()
                except Exception as e:
                    print(f"Error during stitching: {e}")

    if mesh.volume < 0:
        print("Mesh has negative volume. Attempting to fix...")
        mesh.invert()

    result = find_holes(mesh)
    print(f"Holes: {result['num_holes']}, Sizes: {result['hole_sizes']}, Boundary Edges: {result['num_boundary_edges']}, All accounted for: {result['all_boundary_edges_in_holes']}")

    print(f"Final mesh properties: Watertight={mesh.is_watertight}, Winding Consistent={mesh.is_winding_consistent}, Volume={mesh.volume}, is_volume={mesh.is_volume}")

    return { 
            'vertices': mesh.vertices,
            'faces': mesh.faces,
            'vertex_normals': mesh.vertex_normals,
            'face_normals': mesh.face_normals
        }, mesh.is_winding_consistent



def find_holes(mesh):
    """
    Find and analyze holes in a mesh by identifying connected boundary edges.
    
    A hole consists of connected boundary edges (edges with fewer than 2 adjacent faces).
    This function groups boundary edges into connected components and reports their sizes.
    
    Parameters
    ----------
    mesh : trimesh.Trimesh
        The mesh to analyze.
    
    Returns
    -------
    dict : Dictionary containing:
        - 'num_holes': int, number of holes found
        - 'hole_sizes': list of ints, number of edges in each hole
        - 'num_boundary_edges': int, total number of boundary edges
        - 'all_boundary_edges_in_holes': bool, whether all boundary edges are accounted for in holes
        - 'holes': list of lists, edge indices for each hole
    """
    # Build a mapping of edges to face indices
    edgesToFaces = {}
    
    for faceIdx, face in enumerate(mesh.faces):
        # Get the three edges of the triangle (stored as sorted tuples for consistency)
        edges = [
            tuple(sorted([face[0], face[1]])),
            tuple(sorted([face[1], face[2]])),
            tuple(sorted([face[2], face[0]]))
        ]
        for edge in edges:
            if edge not in edgesToFaces:
                edgesToFaces[edge] = []
            edgesToFaces[edge].append(faceIdx)
    
    # Find boundary edges (edges with fewer than 2 adjacent faces)
    boundaryEdges = [edge for edge, faces in edgesToFaces.items() if len(faces) < 2]
    print(boundaryEdges)
    boundaryEdgeSet = set(boundaryEdges)
    
    # Build adjacency graph for boundary edges
    # Two boundary edges are adjacent if they share a vertex
    edgeAdjacency = {}
    boundaryEdgesList = list(boundaryEdges)
    
    for i, edge1 in enumerate(boundaryEdgesList):
        edgeAdjacency[i] = []
        for j, edge2 in enumerate(boundaryEdgesList):
            if i != j:
                # Check if edges share a vertex
                if edge1[0] in edge2 or edge1[1] in edge2:
                    edgeAdjacency[i].append(j)
    
    # Find connected components (holes) using depth-first search
    visited = set()
    holes = []
    
    def dfs(edgeIdx, hole):
        """Depth-first search to find connected boundary edges."""
        visited.add(edgeIdx)
        hole.append(edgeIdx)
        for neighbor in edgeAdjacency[edgeIdx]:
            if neighbor not in visited:
                dfs(neighbor, hole)
    
    for edgeIdx in range(len(boundaryEdgesList)):
        if edgeIdx not in visited:
            hole = []
            dfs(edgeIdx, hole)
            holes.append(hole)
    
    # Compute hole sizes
    holeSizes = [len(hole) for hole in holes]
    
    # Check if all boundary edges are accounted for in holes
    totalEdgesInHoles = sum(holeSizes)
    allBoundaryEdgesInHoles = (totalEdgesInHoles == len(boundaryEdgesList))
    
    print(f"Found {len(holes)} hole(s) with sizes: {holeSizes}")
    print(f"Total boundary edges: {len(boundaryEdgesList)}, All accounted for in holes: {allBoundaryEdgesInHoles}")

    return {
        'num_holes': len(holes),
        'hole_sizes': holeSizes,
        'num_boundary_edges': len(boundaryEdgesList),
        'all_boundary_edges_in_holes': allBoundaryEdgesInHoles,
        'holes': holes
    }



try:
    # Expects mesh_data as a dictionary with 'vertices' and 'faces' keys, where values are array-like (e.g. lists, numpy arrays, or memoryviews)
    output, is_winding_consistent = fix_mesh(load_mesh(mesh_data))
except Exception as e:
    print(f"Error performing mesh repair: {e}")
    traceback.print_exc()
    sys.exit(1)

