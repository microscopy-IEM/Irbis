function meshCell = mesh_subtract_and_separate_python(mesh_data)
    % Does not calculate base points, but only does boolean subraction

    try
        % Use trimesh for mesh processing
        % Call the Python script with mesh data and parameters
        output = pyrunfile('mesh_subtract_and_separate_trimesh_py_script.py', "output", ...
            mesh_data=mesh_data);
    
    catch ME    % this is not perfect - we do not handle not having the outputs of python script, so it will crash anyway
        disp(ME.message);
        error("Error in running the python script.");
    end

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
