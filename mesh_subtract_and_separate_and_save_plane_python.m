function [nObjects, meshCell, basePoints] = mesh_subtract_and_separate_and_save_plane_python(mesh_data, varargin)
    % Define parameters for use in the Python script
    green_threshold = 0.3;
    tolerance = 1e-4;
    distance_threshold = 0.1;

    if nargin > 1
        library_selection = varargin{1};    % 1 for pymeshlab, 2 for trimesh
    else
        library_selection = 1;
    end

    try
        if library_selection == 1
            % Use pymeshlab for mesh processing
            % Call the Python script with mesh data and parameters
            output = pyrunfile('mesh_subtract_and_separate_and_save_plane_py_script.py', "output", ...
                mesh_data=mesh_data, ...
                green_threshold=green_threshold, ...
                tolerance=tolerance, ...
                distance_threshold=distance_threshold);
        elseif library_selection == 2
            % Use trimesh for mesh processing
            % Call the Python script with mesh data and parameters
            output = pyrunfile('mesh_subtract_and_separate_and_save_plane_trimesh_py_script.py', "output", ...
                mesh_data=mesh_data, ...
                green_threshold=green_threshold, ...
                tolerance=tolerance, ...
                distance_threshold=distance_threshold);
        else
            error("Invalid library selection. Please choose 1 for pymeshlab or 2 for trimesh.");
        end
    
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

    % Retrieve base points
    basePoints = double(output{'base_points'});

    % assignin("base","basePoints",basePoints)

    % componentColors = dictionary(output{'component_colors'});

    % assignin("base","componentColors",componentColors)

    % % Plot the meshes as patches
    % figure;
    % hold on;
    % for i = 1:nObjects
    %     % Extract vertices and faces from the surfaceMesh object
    %     vertices = meshCell{i}.Vertices;
    %     faces = meshCell{i}.Faces;

    %     % Plot patch for each component
    %     patch('Vertices', vertices, 'Faces', faces, ...
    %         'FaceColor', 'cyan', 'EdgeColor', 'black', 'FaceAlpha', 0.5);
    % end

    % % Plot base points as scatter
    % scatter3(basePoints(:,1), basePoints(:,2), basePoints(:,3), 50, 'red', 'filled');

    % % Configure plot appearance
    % axis equal;
    % xlabel('X'); ylabel('Y'); zlabel('Z');
    % grid on;
    % title('Mesh Components and Base Points');
    % hold off;

end


% function [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = mesh_subtract_and_separate_and_save_plane_python(vertices_big,faces_big,vertex_normals_big,face_normals_big,vertices_small,faces_small,vertex_normals_small,face_normals_small)
% 
%     [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = pyrunfile('mesh_subtract_and_separate_and_save_plane_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals","base_points"], ...
%         vertices_big=vertices_big,faces_big=faces_big,vertex_normals_big=vertex_normals_big,face_normals_big=face_normals_big, ...
%         vertices_small=vertices_small,faces_small=faces_small,vertex_normals_small=vertex_normals_small,face_normals_small=face_normals_small);
% 
% end