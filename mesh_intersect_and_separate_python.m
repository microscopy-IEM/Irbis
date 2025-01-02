function [nObjects, meshCell] = mesh_intersect_and_separate_python(mesh_data, varargin)

    if nargin > 1
        library_selection = varargin{1};    % 1 for pymeshlab, 2 for trimesh
    else
        library_selection = 1;
    end

    if library_selection == 1
        % Use pymeshlab for mesh processing
        % Call the Python script with mesh data and parameters
        output = pyrunfile('mesh_intersect_and_separate_py_script.py', "output", ...
            mesh_data=mesh_data);
    elseif library_selection == 2
        % Use trimesh for mesh processing
        % Call the Python script with mesh data and parameters
        output = pyrunfile('mesh_intersect_and_separate_trimesh_py_script.py', "output", ...
            mesh_data=mesh_data);
    else
        error("Invalid library selection. Please choose 1 for pymeshlab or 2 for trimesh.");
    end

    % % Call the Python script with mesh data and parameters
    % output = pyrunfile('mesh_intersect_and_separate_py_script.py', "output", ...
    %     mesh_data=mesh_data);

    % Retrieve the number of objects
    nObjects = int8(output{'n_objects'});

    % Retrieve component data and initialize the cell array for surface meshes
    componentData = output{'component_data'};
    meshCell = cell(1, nObjects);

    % Loop through each object and create surfaceMesh from Python output
    for i = 1:nObjects
        % Extract vertices, faces, vertexNormals, and faceNormals
        vertices = double(componentData{i}{'vertices'});
        faces = int32(componentData{i}{'faces'}) + 1; % Adjust for MATLAB 1-based indexing
        vertexNormals = double(componentData{i}{'vertexNormals'});
        faceNormals = double(componentData{i}{'faceNormals'});

        % Create the surfaceMesh for each component
        meshCell{i} = surfaceMesh(vertices, faces, "VertexNormals", vertexNormals, "FaceNormals", faceNormals);
    end
end