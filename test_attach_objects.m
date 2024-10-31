function test_attach_objects
    % Number of random meshes to generate for testing
    objectNumber = 3;

    % Generate random meshes
    mesh_data = cell(1, objectNumber);
    for i = 1:objectNumber
        % Random vertices (N x 3 matrix for N points in 3D space)
        numVertices = randi([10, 20]); % Random number of vertices between 10 and 20
        vertices = rand(numVertices, 3);

        % Random faces (M x 3 matrix for triangular faces)
        numFaces = randi([5, 15]); % Random number of faces between 5 and 15
        faces = randi([1, numVertices], numFaces, 3) - 1; % Zero-index for Python

        % Random volume and surface area values
        volume = rand();
        surface = rand();

        % Add generated data to mesh_data structure
        mesh_data{i} = struct('vertices', vertices, ...
                              'faces', faces, ...
                              'volume', volume, ...
                              'surface', surface);
    end

    assignin("base","mesh_data",mesh_data)

    % Call the Python function with the generated data
    output = pyrunfile('test_variables.py', "output", object_number=objectNumber, mesh_data=mesh_data)


    % Access the vertices and faces from the Python dictionary
    vertices = double(output{'vertices'});
    faces = double(output{'faces'});

    % Display to check the output
    disp('Vertices:');
    disp(vertices);
    disp('Faces:');
    disp(faces);
end
