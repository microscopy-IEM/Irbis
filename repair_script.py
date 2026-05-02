import trimesh
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

vertices = to_numpy_array(mesh['vertices'], dtype=np.float64)
faces = to_numpy_array(mesh['faces'], dtype=np.int32)
trimesh_mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)

# process : bool (default: True)
#   if True, Nan and Inf values will be removed
#   immediately and vertices will be merged
# validate : bool (default: False)
#   If True, degenerate and duplicate faces will be
#   removed immediately, and some functions will alter
#   the mesh to ensure consistent results.

try:
    if not trimesh_mesh.is_watertight:
        print("Mesh is not watertight. Attempting to fix...")
        is_watertight = trimesh.repair.fill_holes(trimesh_mesh, use_fan=True) # This also does check of is_watertight, but the value should already be cached
        if not is_watertight:
            print("Filling holes did not help. Using stitch")
            new_faces, new_vertices = trimesh.repair.stitch(trimesh_mesh, insert_vertices=True)
            print(f'Added {len(new_faces)} faces and {len(new_vertices)} vertices to stitch the mesh.')
            all_faces = np.vstack((trimesh_mesh.faces, new_faces))
            trimesh_mesh.faces = all_faces
            all_vertices = np.vstack((trimesh_mesh.vertices, new_vertices))
            trimesh_mesh.vertices = all_vertices
            trimesh_mesh.remove_unreferenced_vertices()
except Exception as e:
    print(f"Error while fixing watertightness: {e}")

if not trimesh_mesh.is_winding_consistent:
    print("Mesh is not winding consistent. Attempting to fix...")
    # This should be after fixing watertightness, as fixing watertightness may change the winding consistency
    trimesh.repair.fix_winding(trimesh_mesh)  # This also does check of is_winding_consistent, but the value should already be cached

if trimesh_mesh.volume < 0:
    print("Mesh has negative volume. Attempting to fix...")
    trimesh_mesh.invert()