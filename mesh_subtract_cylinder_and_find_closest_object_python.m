function [nObjects, meshCell, basePoints] = mesh_subtract_cylinder_and_find_closest_object_python(mesh_data,vertices_original)

    tolerance = 1e-4;
    threshold = 0.1;
    min_sample_size = 50;
    green_threshold = 0.1;
    distance_threshold = 0.1;

    output = pyrunfile('mesh_subtract_cylinder_and_find_closest_py_script.py',"output", ...
        mesh_data=mesh_data, ...
        vertices_original=vertices_original, ...
        tolerance=tolerance, ...
        threshold=threshold, ...
        min_sample_size=min_sample_size, ...
        green_threshold=green_threshold, ...
        distance_threshold=distance_threshold);

    nObjects = int8(output{'n_objects'});

    componentData = output{'component_data'};

    meshCell = cell(1, nObjects);

    for i = 1:nObjects
        vertices = double(componentData{i}{'vertices'});
        faces = int32(componentData{i}{'faces'}) + 1;
        vertexNormals = double(componentData{i}{'vertexNormals'});
        faceNormals = double(componentData{i}{'faceNormals'});
        meshCell{i} = surfaceMesh(vertices, faces, "VertexNormals", vertexNormals, "FaceNormals", faceNormals);
    end

    basePoints = double(output{'base_points'});
end