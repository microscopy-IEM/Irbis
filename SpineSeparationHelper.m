classdef (Sealed) SpineSeparationHelper

    methods (Static)
        function [T, newIds] = addMeshesToTable(T, meshes, singularParentRowName, ancestryDict, basePoints, basePointNormals, trajectory, patches, minPoints)

            arguments
                T table
                meshes cell
                singularParentRowName (1,1) {mustBeText}
                ancestryDict
                basePoints double = [];
                basePointNormals double = [];
                trajectory double = [];
                patches cell = {};
                minPoints double = 20; % Default value, adjust as needed
            end

            % Extract points
            pointsCell = cellfun(@(m) m.Vertices, meshes, 'UniformOutput', false);

            % Filter out regions with insufficient points
            validIndices = cellfun(@(pts) size(pts, 1) > minPoints, pointsCell);

            % Apply the validIndices filter to all relevant variables
            validMeshes = meshes(validIndices)';
            % Prepare the table entries
            numValidRegions = sum(validIndices);

            startIdx = height(T) + 1;
            rowIndexes = startIdx : (startIdx + numValidRegions - 1);

            existingRowNames = T.Properties.RowNames;

            warning('off', 'MATLAB:table:RowsAddedExistingVars'); % Supress warning for adding only some rows and extending the rest automatically

            T{rowIndexes, 'Mesh'} = validMeshes;
            T{rowIndexes, 'parentId'} = repmat(str2double(singularParentRowName), numValidRegions, 1);
            T{rowIndexes, 'parent'} = repmat({ancestryDict}, numValidRegions, 1);
            T{rowIndexes, 'positionShift'} = repmat({[0 0 0]}, numValidRegions, 1);
            T{rowIndexes, 'color'} = mat2cell(rand(numValidRegions,3), ones(numValidRegions, 1), 3);

            % Only relevant for spines, not for dendritic centre
            if ~isempty(basePoints) && ~isempty(trajectory)
                % TO OPTIMIZE - decide whether the calculation of normal from trajectory should be reomved altogether, or should be kept in another column

                % validBasePoints = basePoints(validIndices, :);
                % vecB = validBasePoints(:,1:3);
                % [pointIdx, ~] = knnsearch(trajectory, vecB);
                % vecA = trajectory(pointIdx, :);
                % vecNorms = sqrt(sum((vecA - vecB).^2, 2));
                % vec = (vecA - vecB) ./ vecNorms;

                % assignin("base", "basePoints", basePoints)
                try
                    T{rowIndexes, 'basePoint'} = basePoints(validIndices,1:3);
                    % T{rowIndexes, 'basePointNormal'} = vec;
                    T{rowIndexes, 'basePointNormal'} = basePointNormals(validIndices,1:3);
                catch
                    % TO OPTIMIZE - this is an ugly code!!!
                    % this can accidentally cause problems or delete previous datasets

                    disp(['size of columns basePoint and basePointNormal was converted so that it contains three columns!!!'])
                    T.basePoint =  nan(height(T), 3);
                    T.basePointNormal = nan(height(T), 3);

                    T{rowIndexes, 'basePoint'} = basePoints(validIndices,1:3);
                    % T{rowIndexes, 'basePointNormal'} = vec;
                    T{rowIndexes, 'basePointNormal'} = basePointNormals(validIndices,1:3);
                end
            end

            if ~isempty(patches)
                % patches is a cell array of structure lists
                % each structure list contains base patches for one mesh (places where the spine is cut from the dendritic shaft)
                validPatches = patches(validIndices);
                T{rowIndexes, 'basePatch'} = validPatches;
            end

            warning('on', 'MATLAB:table:RowsAddedExistingVars'); % turn it back on

            if startIdx > 1
                maxRowId = max(str2double(existingRowNames));
                rowId = maxRowId + 1;
                newIds = rowId : rowId + numValidRegions - 1;
            else
                newIds = 1 : numValidRegions;
            end

            % Generate row names for the specified range
            newRowNames = arrayfun(@num2str, newIds, 'UniformOutput', false)';  % this has to be a column cell array -> transpose with '
            % size(existingRowNames{:})
            % assignin("base", "existingRowNames", existingRowNames)
            % size(newRowNames{:})
            % assignin("base", "newRowNames", newRowNames)
            if isempty(existingRowNames)
                T.Properties.RowNames = newRowNames;
            else
                % T.Properties.RowNames returned in the previous line is a column cell array
                T.Properties.RowNames = [existingRowNames; newRowNames];
            end
        end



        function meshData = prepareMeshDataForPython(biggerObjectTable, biggerObjectRowName, smallerObjectTable, smallerObjectRowName)
            % Initialize mesh_data cell array
            meshData = cell(1, 2);

            currentFullMeshCell = biggerObjectTable{biggerObjectRowName,'Mesh'};
            currentFullMesh = currentFullMeshCell{1};
            meshData{1} = struct('vertices', currentFullMesh.Vertices, ...
                                    'faces', currentFullMesh.Faces - 1); % Zero-index for Python
            
            % Conditionally add vertexNormals if not empty
            if ~isempty(currentFullMesh.VertexNormals)
                meshData{1}.vertexNormals = currentFullMesh.VertexNormals;
            end
            
            % Conditionally add faceNormals if not empty
            if ~isempty(currentFullMesh.FaceNormals)
                meshData{1}.faceNormals = currentFullMesh.FaceNormals;
            end

            currentDendriticShaftMeshCell = smallerObjectTable{smallerObjectRowName,'Mesh'};
            currentDendriticShaftMesh = currentDendriticShaftMeshCell{1};

            meshData{2} = struct('vertices', currentDendriticShaftMesh.Vertices, ...
                                    'faces', currentDendriticShaftMesh.Faces - 1); % Zero-index for Python
            
            % Conditionally add vertexNormals if not empty
            if ~isempty(currentDendriticShaftMesh.VertexNormals)
                meshData{2}.vertexNormals = currentDendriticShaftMesh.VertexNormals;
            end
            
            % Conditionally add faceNormals if not empty
            if ~isempty(currentDendriticShaftMesh.FaceNormals)
                meshData{2}.faceNormals = currentDendriticShaftMesh.FaceNormals;
            end
        end
    end
end