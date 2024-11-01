function [nObjects, meshCell] = reconstruct_mesh_python(depth,mesh_data,varargin)

    % disp('in matlab function')
    if nargin == 3
        fractionToKeep = 0.8;
        minVertexNum = 20;
        % disp('3 args')
        separate = 1;
    elseif nargin == 4
        fractionToKeep = 0.8;
        minVertexNum = 20;
        separate = varargin{1};
        % disp('5 args')
    else
        separate = 1;
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
        % disp('else args')
    end

    output = pyrunfile('reconstruct_mesh_py_script.py',"output", ...
        mesh_data=mesh_data, ...
        d=depth, ...
        f=fractionToKeep, ...
        nVer=minVertexNum, ...
        separate=separate);

    % Retrieve the number of objects
    nObjects = int8(output{'n_objects'})

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


