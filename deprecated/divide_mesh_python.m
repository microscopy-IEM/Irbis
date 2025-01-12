function meshCell = divide_mesh_python(mesh_data,pointA,pointB,depth)

    output = pyrunfile('divide_mesh_py_script.py',"output",mesh_data=mesh_data,pointA=pointA,pointB=pointB,d=depth);

    meshCell = cell(1,2);

    % Extract closest_mesh vertices and faces
    closest_vertices = double(output{'closest_mesh'}{'vertices'});
    closest_faces = double(output{'closest_mesh'}{'faces'}) + 1;
    meshCell{1} = surfaceMesh(closest_vertices, closest_faces);
    
    % Extract cut_mesh vertices and faces
    cut_vertices = double(output{'cut_mesh'}{'vertices'});
    cut_faces = double(output{'cut_mesh'}{'faces'}) + 1;
    meshCell{2} = surfaceMesh(cut_vertices, cut_faces);

end