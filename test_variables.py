import pymeshlab
import numpy as np

print('beginning of python')

def test_variables(object_number, mesh_data):
    ms = pymeshlab.MeshSet()
    
    # Load each random mesh from mesh_data and check properties
    for i, mesh in enumerate(mesh_data):
        vertices = mesh['vertices']
        faces = mesh['faces']
        
        # Print types of vertices and faces
        print(f"Mesh {i + 1} vertices type: {type(vertices)}")
        print(f"Mesh {i + 1} faces type: {type(faces)}")
        
        # If vertices and faces are NumPy arrays, print shape and data type
        if isinstance(vertices, np.ndarray):
            print(f"Mesh {i + 1} vertices shape: {vertices.shape}, dtype: {vertices.dtype}")
        if isinstance(faces, np.ndarray):
            print(f"Mesh {i + 1} faces shape: {faces.shape}, dtype: {faces.dtype}")
        
        # Create a PyMeshLab mesh from the provided vertices and faces
        new_mesh = pymeshlab.Mesh(vertex_matrix=vertices, face_matrix=faces)
        ms.add_mesh(new_mesh)
        
        # Sanity check: Verify that vertices and faces are loaded
        current_mesh = ms.current_mesh()
        if current_mesh.vertex_number() > 0 and current_mesh.face_number() > 0:
            print(f"Mesh {i + 1} loaded successfully with {current_mesh.vertex_number()} vertices and {current_mesh.face_number()} faces.")
        else:
            print(f"Error: Mesh {i + 1} failed to load.")
    
    # Final sanity check: verify total mesh count in MeshSet
    print(f'Total number of meshes in MeshSet: {ms.number_meshes()}')
    
    # Optionally perform a merge to further confirm mesh integrity
    if ms.number_meshes() > 1:
        ms.generate_by_merging_visible_meshes(mergevisible=False, deletelayer=True)
        merged_mesh = ms.current_mesh()
        print(f"Merged mesh has {merged_mesh.vertex_number()} vertices and {merged_mesh.face_number()} faces.")
    else:
        print("No merging performed, only one mesh was loaded.")

     # Return vertices and faces of the merged mesh
    return {'vertices': merged_mesh.vertex_matrix(), 'faces': merged_mesh.face_matrix()}

# Run the test
output = test_variables(object_number, mesh_data)
print(f'Sanity check result: {"Success" if output else "Failure"}')
