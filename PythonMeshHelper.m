classdef PythonMeshHelper 

    properties (Constant)
        % Define any constant properties if needed
        distance_tolerance = 1e-4;      % maximum distance difference to consider two vertices as matching
        min_match = 0.1;
        min_valid_faces = 25;           % minimum number of faces for a component to be considered for adjusting dendrite
    end


    methods (Static)
        function [nObjects, meshCell] = reconstruct(depth, mesh_data, fractionToKeep, minVertexNum, separate)

            arguments
                depth (1,1) {mustBeNumeric}
                mesh_data
                fractionToKeep (1,1) {mustBeNumeric} = 1
                minVertexNum (1,1) {mustBeNumeric} = 20
                separate {mustBeNumericOrLogical} = false
            end

            output = pyrunfile('poisson_reconstruction_py_script.py',"output", ...
                mesh_data=mesh_data, ...
                d=depth, ...
                f=fractionToKeep, ...
                nVer=minVertexNum, ...
                separate=separate);
            % the open3d version seems to be faster compared to pymeshlab (0.5 vs 1.4 s on constant shaft)
                % same for adaptive shaft (0.6 vs 4.2 s)

            % Retrieve the number of objects
            nObjects = int8(output{'n_objects'});

            % Retrieve component data and initialize the cell array for surface meshes
            componentData = output{'component_data'};
            meshCell = cell(1, nObjects);

            % Loop through each object and create surfaceMesh from Python output
            for i = 1:nObjects
                meshCell{i} = PythonMeshHelper.pyDictToMesh(componentData{i});
            end
        end



        function [parentMesh, intersectionMeshes, subtractionMeshes] = runBooleanSegmentation(mesh_data)
            % runBooleanSegmentation - Performs boolean segmentation (intersection and subtraction) on two meshes using a Python script.
            %
            % Inputs:
            %   mesh_data - Cell array or struct containing mesh data (vertices, faces) for the main and helper meshes.
            %
            % Outputs:
            %   parentMesh         - The original mesh as a MATLAB surfaceMesh object.
            %   intersectionMeshes - Cell array of intersection meshes (as surfaceMesh objects).
            %   subtractionMeshes  - Cell array of subtraction meshes (as surfaceMesh objects).
            %
            % This function calls 'mesh_boolean_segmentation_py_script.py' to perform the operations using trimesh in Python.
            try
                output = pyrunfile('mesh_boolean_segmentation_py_script.py', "output", ...
                    mesh_data=mesh_data);
            catch ME
                disp(ME.message);
                error("Error in running the python script.");
            end

            parentMesh = PythonMeshHelper.pyDictToMesh(output{'parent_mesh'});

            nIntersections = int8(output{'n_intersections'});   % this should be 1
            intersectionMeshes = cell(1, nIntersections);
                for i = 1:nIntersections
                    try
                        intersectionMeshes{i} = PythonMeshHelper.pyDictToMesh(output{'intersection_objects'}{i});
                    catch ME
                        if isequal(ME.identifier, 'PythonMeshHelper:InvalidMeshData')
                            disp(['Intersection mesh ' num2str(i) ' is invalid and will be skipped.']);
                        else
                            rethrow(ME);
                        end
                    end
                end
            intersectionMeshes(cellfun('isempty', intersectionMeshes)) = [];


            nSubtractions = int8(output{'n_subtractions'});
            subtractionMeshes = cell(1, nSubtractions);

                for i = 1:nSubtractions
                    try
                        subtractionMeshes{i} = PythonMeshHelper.pyDictToMesh(output{'subtraction_objects'}{i});
                    catch ME
                        if isequal(ME.identifier, 'PythonMeshHelper:InvalidMeshData')
                            disp(['Subtraction mesh ' num2str(i) ' is invalid and will be skipped.']);
                        else
                            rethrow(ME);
                        end
                    end
                end
            subtractionMeshes(cellfun('isempty', subtractionMeshes)) = [];

            % this did not work because the input is py.dict:
            % differenceMeshCell = cellfun(@(x) PythonMeshHelper.pyDictToMesh(x), output{'subtraction_objects'});
        end



        function testMeshValidity(Mesh)
            % testMeshValidity - Tests the validity of a mesh using a Python script.
            %
            % Inputs:
            %   mesh_data - Cell array or struct containing mesh data (vertices, faces) for the main and helper meshes.
            %
            % This function calls 'test_mesh_validity_py_script.py' to perform the operations using trimesh in Python.
            mesh_data = PythonMeshHelper.meshToPyStruct(Mesh);
            
            try
                pyrunfile('test_mesh_validity_py_script.py', ...
                    mesh_data=mesh_data);
            catch ME
                disp(ME.message);
                error("Error in running the python script.");
            end
        end



        function repairedMesh = repairMesh(Mesh)
            % repairMesh - Repairs a mesh using a Python script.
            %
            % Inputs:
            %   Mesh - MATLAB surfaceMesh object containing vertices, faces, and optionally vertex and face normals.
            %
            % This function calls 'repair_mesh_py_script.py' to perform the operations using trimesh in Python.

            mesh_data = PythonMeshHelper.meshToPyStruct(Mesh);
            
            try
                outputDict = pyrunfile('repair_mesh_py_script.py', "output", ...
                    mesh_data=mesh_data);
            catch ME
                disp(ME.message);
                error("Error in running the python script.");
            end

            repairedMesh = PythonMeshHelper.pyDictToMesh(outputDict);
        end



        function [dendriteMesh, subtractionMeshes] = redefineWithCylinder(mesh_data)
            % redefineWithCylinder - Subtracts a cylinder from a mesh and adjusts a dendrite mesh using a Python script.
            %
            % Inputs:
            %   mesh_data - Cell array or struct containing mesh data for the full mesh, cylinder, original spine, and dendrite.
            %
            % Outputs:
            %   dendriteMesh      - Adjusted dendrite mesh as a surfaceMesh object.
            %   subtractionMeshes - Cell array of valid subtraction meshes (as surfaceMesh objects).
            %
            % This function calls 'mesh_redefinition_with_cylinder_py_script.py' to perform the operations using trimesh in Python.
            
            try
                output = pyrunfile('mesh_redefinition_with_cylinder_py_script.py',"output", ...
                    mesh_data=mesh_data, ...
                    distance_tolerance=PythonMeshHelper.distance_tolerance, ...
                    min_match=PythonMeshHelper.min_match, ...
                    min_valid_faces=PythonMeshHelper.min_valid_faces);

            catch ME
                disp(ME.message);
                error("Error in running the python script.");
            end

            dendriteMesh = PythonMeshHelper.pyDictToMesh(output{'new_dendrite_data'});
            nSubtractions = int8(output{'n_valid_subtractions'});
            subtractionMeshes = cell(1, nSubtractions);
            for i = 1:nSubtractions
                subtractionMeshes{i} = PythonMeshHelper.pyDictToMesh(output{'valid_subtraction_data'}{i});
            end
        end


        function subtractionMeshes = subtractAndSeparate(mesh_data)
            % subtractAndSeparate - Performs boolean subtraction and separates resulting mesh components using a Python script.
            %
            % Inputs:
            %   mesh_data - Cell array or struct containing mesh data for the main and helper meshes.
            %
            % Outputs:
            %   subtractionMeshes - Cell array of subtraction meshes (as surfaceMesh objects).
            %
            % This function calls 'mesh_subtraction_with_separation_py_script.py' to perform the operations using trimesh in Python.

            try
                % Use trimesh for mesh processing
                % Call the Python script with mesh data and parameters
                output = pyrunfile('mesh_subtraction_with_separation_py_script.py', "output", ...
                    mesh_data=mesh_data);
            
            catch ME    % this is not perfect - we do not handle not having the outputs of python script, so it will crash anyway
                disp(ME.message);
                error("Error in running the python script.");
            end

            nSubtractions = int8(output{'n_subtractions'});
            subtractionMeshes = cell(1, nSubtractions);
            for i = 1:nSubtractions
                subtractionMeshes{i} = PythonMeshHelper.pyDictToMesh(output{'subtraction_objects'}{i});
            end
        end



        function meshStruct = meshToPyStruct(Mesh)
            % meshToPyStruct - Converts a MATLAB surfaceMesh object to a Python struct (dictionary) format.
            %
            % Inputs:
            %   Mesh - MATLAB surfaceMesh object containing vertices, faces, and optionally vertex and face normals.
            %
            % Outputs:
            %   meshStruct - Python struct (dictionary) with fields: 'vertices', 'faces', 'vertex_normals', 'face_normals'.
            %
            % This function prepares the mesh data for use in Python scripts by converting it to a compatible format.

            meshStruct = struct();
            meshStruct.vertices = Mesh.Vertices;
            meshStruct.faces = Mesh.Faces - 1; % Adjust for Python 0-based indexing
            if ~isempty(Mesh.VertexNormals)
                meshStruct.vertex_normals = Mesh.VertexNormals;
            end
            if ~isempty(Mesh.FaceNormals)
                meshStruct.face_normals = Mesh.FaceNormals;
            end
        end



        function Mesh = pyDictToMesh(pythonDict)
            % pyDictToMesh - Converts a Python dictionary with mesh data to a MATLAB surfaceMesh object.
            %
            % Inputs:
            %   pythonDict - Python dictionary with fields: 'vertices', 'faces', 'vertex_normals', 'face_normals'.
            %
            % Outputs:
            %   Mesh - MATLAB surfaceMesh object constructed from the input data.

            vertices = double(pythonDict{'vertices'});
            faces = int32(pythonDict{'faces'}) + 1; % Adjust for MATLAB 1-based indexing
            vertexNormals = double(pythonDict{'vertex_normals'});
            faceNormals = double(pythonDict{'face_normals'});

            if isempty(vertices)
                ME = MException('PythonMeshHelper:InvalidMeshData', 'The vertices data is empty. Cannot create a mesh.');
                throw(ME);
            end

            % Create the surfaceMesh for each component
            Mesh = surfaceMesh(vertices, faces, "VertexNormals", vertexNormals, "FaceNormals", faceNormals);
        end

    end
end


