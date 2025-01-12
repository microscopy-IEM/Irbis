function meshCell = fix_mesh_python(mesh_data)

    try
        % Call the Python script with mesh data
        fixed_mesh_data = pyrunfile('fix_mesh_py_script.py', "fixed_mesh_data", ...
            mesh_data=mesh_data);
    catch ME
        disp(ME.message);
        error("Error in running the python script.");
    end

    % Loop through each object and create surfaceMesh from Python output
    meshCell = cell(1, numel(mesh_data));
    for i = 1:numel(mesh_data)
        % Extract vertices, faces, vertexNormals, and faceNormals
        vertices = double(fixed_mesh_data{i}{'vertices'});
        faces = int32(fixed_mesh_data{i}{'faces'}) + 1; % Adjust for MATLAB 1-based indexing

        % Create the surfaceMesh for each component
        meshCell{i} = surfaceMesh(vertices, faces);
    end
end
