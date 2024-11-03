function mesh = attach_objects_python(mesh_data)

    output = pyrunfile('attach_objects_py_script.py',"output",mesh_data=mesh_data);

    % Access the vertices and faces from the Python dictionary
    joined_vertices = double(output{'vertices'});
    joined_faces = double(output{'faces'}) + 1;    % needs to be converted to Matlab's numbering from 1 instead of Python's from 0

    mesh = surfaceMesh(joined_vertices, joined_faces);

end