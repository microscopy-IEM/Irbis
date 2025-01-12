function mesh = attach_objects_python(mesh_data, varargin)

    if nargin > 1
        library_selection = varargin{1};    % 1 for pymeshlab, 2 for trimesh
    else
        library_selection = 1;
    end

    if library_selection == 1
        % Use pymeshlab for mesh processing
        % Call the Python script with mesh data and parameters
        output = pyrunfile('attach_objects_py_script.py', "output", ...
            mesh_data=mesh_data);
    elseif library_selection == 2
        % Use trimesh for mesh processing
        % Call the Python script with mesh data and parameters
        output = pyrunfile('attach_objects_trimesh_py_script.py', "output", ...
            mesh_data=mesh_data);
    else
        error("Invalid library selection. Please choose 1 for pymeshlab or 2 for trimesh.");
    end

    % Access the vertices and faces from the Python dictionary
    joined_vertices = double(output{'vertices'});
    joined_faces = double(output{'faces'}) + 1;    % needs to be converted to Matlab's numbering from 1 instead of Python's from 0

    mesh = surfaceMesh(joined_vertices, joined_faces);

end