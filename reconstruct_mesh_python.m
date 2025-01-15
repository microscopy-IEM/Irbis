function [nObjects, meshCell, components] = reconstruct_mesh_python(depth,mesh_data,varargin)

    % 241201 - corrected version
    % argument 1 - depth (number)
    % argument 2 - mesh_data (struct containing both vertices, faces, and possibly also normals)
    
    % define default values: 
    fractionToKeep = 1;
    minVertexNum = 20;
    separate = 1;

    library_selection = 2; % 1 for pymeshlab, 2 for open3d
    
    % overwrite the default values when custom are specified: 
    if nargin == 3
        % there is 1 varargin
        separate = varargin{1};
    elseif nargin == 4
        % there are 2 varargin
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
    elseif nargin == 5
        % there are 3 varargin 
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
        separate = varargin{3};
    else
        warning("There are more arguments than expected to reconstruct_mesh_python")
    end

    if library_selection == 1
        output = pyrunfile('reconstruct_mesh_py_script.py',"output", ...
            mesh_data=mesh_data, ...
            d=depth, ...
            f=fractionToKeep, ...
            nVer=minVertexNum, ...
            separate=separate);
        
    elseif library_selection == 2

        output = pyrunfile('reconstruct_mesh_open3d_py_script.py',"output", ...
            mesh_data=mesh_data, ...
            d=depth, ...
            f=fractionToKeep, ...
            nVer=minVertexNum, ...
            separate=separate);
    end

    % the open3d version seems to be faster (0.5 vs 1.4 s on constant shaft)
        % same for adaptive shaft (0.6 vs 4.2 s)

    % Retrieve the number of objects
    nObjects = int8(output{'n_objects'});

    % Retrieve component data and initialize the cell array for surface meshes
    componentData = output{'component_data'};
    meshCell = cell(1, nObjects);
    components = cell(1, nObjects);

    % Loop through each object and create surfaceMesh from Python output
    for i = 1:nObjects
        % Extract vertices, faces, vertexNormals, and faceNormals
        vertices = double(componentData{i}{'vertices'});
        faces = int32(componentData{i}{'faces'}) + 1; % Adjust for MATLAB 1-based indexing
        vertexNormals = double(componentData{i}{'vertexNormals'});
        faceNormals = double(componentData{i}{'faceNormals'});

        % Create the surfaceMesh for each component
        meshCell{i} = surfaceMesh(vertices, faces, "VertexNormals", vertexNormals, "FaceNormals", faceNormals);

        components{i} = struct('vertices', vertices, ...
                                    'faces',faces, ...
                                    'vertexNormals', vertexNormals, ...
                                    'faceNormals', faceNormals);
    end
end


