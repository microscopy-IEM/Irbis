import trimesh

def check_watertightness(vertices, faces):
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
    print(f'watertight: {mesh.is_watertight}')
    print(f'winding consistent: {mesh.is_winding_consistent}')
    print(f'volume: {mesh.is_volume}')


check_watertightness(vertices, faces)
