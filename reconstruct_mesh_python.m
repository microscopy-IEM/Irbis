function [nObjects, meshCell, components] = reconstruct_mesh_python(depth,mesh_data,varargin)

    % 241201 - corrected version
    % argument 1 - depth (number)
    % argument 2 - mesh_data (struct containing both vertices, faces, and possibly also normals)
    
    % define default values: 
    fractionToKeep = 0.8;
    minVertexNum = 20;
    separate = 1;
    
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

    % 241201 - THIS WAS INCORRECT WITH THE NEW INPUT!!
    % if nargin == 3
    %     fractionToKeep = 0.8;
    %     minVertexNum = 20;
    %     % disp('3 args')
    %     separate = 1;
    % elseif nargin == 4
    %     fractionToKeep = 0.8;
    %     minVertexNum = 20;
    %     separate = varargin{1};
    %     % disp('5 args')
    % else
    %     separate = 1;
    %     fractionToKeep = varargin{1};
    %     minVertexNum = varargin{2};
    %     % disp('else args')
    % end

    output = pyrunfile('reconstruct_mesh_py_script.py',"output", ...
        mesh_data=mesh_data, ...
        d=depth, ...
        f=fractionToKeep, ...
        nVer=minVertexNum, ...
        separate=separate);

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


