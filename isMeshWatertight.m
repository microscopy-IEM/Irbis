function isWatertight = isMeshWatertight(vertices, faces)
    % isWatertightMesh checks if a mesh is watertight using trimesh in Python
    %
    % Inputs:
    %   vertices - Nx3 array of vertex coordinates
    %   faces    - Mx3 array of face indices (MATLAB 1-based indexing)
    %
    % Output:
    %   isWatertight - true if the mesh is watertight, false otherwise
    
    % % Ensure Python environment is set
    % if count(pyenv, 'Status') == 0 || pyenv().Status == "NotLoaded"
    %     pyenv('Version', 'C:\path_to_python\python.exe');
    % end

    % Adjust MATLAB 1-based indexing to Python 0-based indexing

    % disp('testing watertightness with trimesh')
    faces_py = faces - 1;
    
    % Create the trimesh object in Python
    mesh = py.trimesh.Trimesh(py.numpy.array(vertices, 'float64'), ...
                              py.numpy.array(faces_py, 'int32'));

    disp(py.trimesh.repair.broken_faces(mesh))
    
    % Check if the mesh is watertight
    isWatertight = logical(mesh.is_watertight);
end
