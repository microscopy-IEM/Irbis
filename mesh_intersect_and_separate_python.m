function [nObjects, meshCell] = mesh_intersect_and_separate_python(mesh_data)

    % Call the Python script with mesh data and parameters
    output = pyrunfile('mesh_intersect_and_separate_py_script.py', "output", ...
        mesh_data=mesh_data);

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


% function [n_objects,vertices,faces,vertex_normals,face_normals] = mesh_intersect_and_separate_python(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)
% 
%     [n_objects,vertices,faces,vertex_normals,face_normals] = pyrunfile('mesh_intersect_and_separate_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals"], ...
%         vertices_big=vertices_big,faces_big=faces_big,vertex_normals_big=vertex_normals_big,face_normals_big=face_normals_big, ...
%         vertices_small=vertices_small,faces_small=faces_small,vertex_normals_small=vertex_normals_small,face_normals_small=face_normals_small);
% 
% 
% 
% end