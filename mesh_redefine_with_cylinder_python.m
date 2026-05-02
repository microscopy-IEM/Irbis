function [nObjects, dendriteMesh, meshCell, basePoints] = mesh_redefine_with_cylinder_python(mesh_data, vertices_original)

    tolerance = 1e-4;
    threshold = 0.1;
    min_sample_size = 50;
    green_threshold = 0.1;
    distance_threshold = 0.1;
    
    try
        output = pyrunfile('mesh_subtract_cylinder_new2_object_py_script.py',"output", ...
            mesh_data=mesh_data, ...
            vertices_original=vertices_original, ...
            tolerance=tolerance, ...
            threshold=threshold, ...
            min_sample_size=min_sample_size, ...
            green_threshold=green_threshold, ...
            distance_threshold=distance_threshold);

    catch ME
        disp(ME.message);
        error("Error in running the python script.");
    end

    nObjects = int8(output{'n_objects'});

    dendrite_data = output{'dendrite_data'};

    vertices = double(dendrite_data{'vertices'});
    faces = int32(dendrite_data{'faces'}) + 1; % convert to 1-based indexing for Matlab
    dendriteMesh = surfaceMesh(vertices, faces);

    componentData = output{'component_data'};

    meshCell = cell(1, nObjects);

    for i = 1:nObjects
        vertices = double(componentData{i}{'vertices'});
        faces = int32(componentData{i}{'faces'}) + 1;
        % vertexNormals = double(componentData{i}{'vertexNormals'});
        % faceNormals = double(componentData{i}{'faceNormals'});
        % meshCell{i} = surfaceMesh(vertices, faces, "VertexNormals", vertexNormals, "FaceNormals", faceNormals);
        meshCell{i} = surfaceMesh(vertices, faces);
    end

    basePoints = double(output{'base_points'});
end