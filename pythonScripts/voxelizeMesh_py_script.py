# Python code that can do voxelization of mask

# Utilized approach for existing scripts
    # Convert mesh to an array in Matlab
    # Pass that as a struct
    # In Python, the struct is read and converted to numpy array
    # The resulting mesh is again extracted to a numpy array and passed back
    
import open3d as o3d
import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)

def voxelize_mesh(mesh_data, voxel_size=0.05):
    # print("Voxelizing mesh with Open3D...")
    # Ensure the data is in the correct format
    vertices = np.asarray(mesh_data['vertices'])
    faces = np.asarray(mesh_data['faces'])

    voxel_size = float(voxel_size)

    # Create an Open3D mesh from vertices and faces
    mesh = o3d.geometry.TriangleMesh()
    mesh.vertices = o3d.utility.Vector3dVector(vertices)
    mesh.triangles = o3d.utility.Vector3iVector(faces)
    
    # Ensure the mesh is valid for voxelization
    if not mesh.has_vertices() or not mesh.has_triangles():
        raise ValueError("Invalid mesh: missing vertices or triangles")
        
    # Create voxel grid from the mesh
    voxel_grid = o3d.geometry.VoxelGrid.create_from_triangle_mesh(
        mesh, voxel_size=voxel_size)
    
    # Extract voxel coordinates
    voxels = voxel_grid.get_voxels()
    voxel_coordinates = []
    origin_pix = np.round(voxel_grid.origin / voxel_size)

    # Just getting the grid index is not enough, because the origin is not (0,0,0)
    # We need to add the origin to each voxel's grid index, and take into account um-pixel conversion
    for voxel in voxels:
        coordinate_pix = voxel.grid_index + origin_pix
        coordinate_pix = np.maximum(coordinate_pix, 0)  # Avoid having negative coordinates
        # voxel_coordinates.append(voxel_grid.origin + voxel.grid_index * voxel_size)
        voxel_coordinates.append(coordinate_pix)

    # Convert to numpy array for easier handling
    voxel_coordinates = np.array(voxel_coordinates)

    # print(voxel_coordinates.shape)
        
    return voxel_coordinates

# print(data)
# print(voxel_size)
voxel_coordinates = voxelize_mesh(mesh_data=data, voxel_size=voxel_size)

