classdef ObjectFeatureExtractor
    %OBJECTFEATUREEXTRACTOR Computes mesh-derived features for each object in a table.
    %
    % ---------------------------------------------------------------------
    % Required input columns:
    %   Mesh
    % Optional input columns:
    %   basePoint (required for distance-based features)
    %
    % Assumptions:
    %   1) Mesh geometry is represented in consistent physical units
    %      (for example micrometers) across all rows.
    %   2) Faces reference 3-vertex triangles.
    %
    % Output feature definitions:
    %   volume
    %       Formula: V = |sum(dot(cross(v1, v2), v3))| / 6 over all faces
    %                where [v1 v2 v3] are the triangle vertex coordinates
    %       Meaning: signed-tetrahedra mesh volume magnitude (enclosed volume)
    %       Units: unit^3 (for example um^3)
    %
    %   surface
    %       Formula: A = 0.5 * sum(norm(cross(v2 - v1, v3 - v1))) over all faces
    %                where [v1 v2 v3] are the triangle vertex coordinates
    %       Meaning: total area of all mesh triangles
    %       Units: unit^2 (for example um^2)
    %
    %   averageDistance
    %       Formula: mean(||v_i - p||)
    %       Meaning: average distance from basePoint p to vertices v_i
    %       Units: unit (for example um)
    %
    %   euclideanLength
    %       Formula: mean(top 5% of ||v_i - p||)
    %       Meaning: robust estimate of maximal spine extent from base point
    %       Units: unit (for example um)
    %
    %   distanceCoefficientOfVariation
    %       Formula: std(d_i)/mean(d_i), where d_i = ||v_i - p||
    %       Meaning: relative spread of vertex distances from base point
    %       Units: dimensionless
    %
    %   sphericity
    %       Formula: (pi^(1/3) * (6V)^(2/3)) / S
    %       Meaning: compactness relative to a sphere (1 = perfect sphere)
    %       Units: dimensionless
    %
    %   convexHullVolume
    %       Formula: second output of convhull(x, y, z)
    %       Meaning: volume of the convex hull enclosing all vertices
    %       Units: unit^3 (for example um^3)
    %
    %   solidity
    %       Formula: V / V_hull
    %       Meaning: fraction of convex hull occupied by object volume
    %       Units: dimensionless
    %
    %   openAngle
    %       Formula:
    %           s = mean(v_i - p)
    %           theta_i = atan2d(||cross(s, v_i - p)||, dot(s, v_i - p))
    %           openAngle = mean(theta_i)
    %       Meaning: average angular spread of vertex directions from base point
    %       Units: degrees
    %
    %   baseToTipAngle
    %       Formula: angle between the normal vector at the base point and the vector from base point to the mean of the 5% furthest vertices (tip point)
    %       Meaning: orientation of the base patch relative to the main axis of the object
    %       Units: degrees
    %
    %   basePatchArea
    %       Formula: sum of areas of faces in base patch
    %       Meaning: surface area of the patch where the spine is cut from the shaft
    %       Units: unit^2 (for example um^2)
    % ---------------------------------------------------------------------

    properties (Constant)
        % Canonical list of feature columns produced by this extractor.
        featureNames = ["volume", "surface", ...
            "averageDistance", "euclideanLength", "distanceCoefficientOfVariation", "sphericity", "openAngle", ...
            "convexHullVolume", "solidity", "baseToTipAngle", "basePatchArea"];
    end



    methods (Static)
        function featureNames = getFeatureNames()
            %GETFEATURENAMES Return the list of feature names produced by this extractor.
            featureNames = ObjectFeatureExtractor.featureNames;
        end


        
        function outputTable = calculateAllFeatures(inputTable)
            %CALCULATEALLFEATURES Compute all configured features for each table row.
            %
            % Workflow:
            %   1) Validate required input structure.
            %   2) Ensure output feature columns exist.
            %   3) For each row, extract mesh geometry.
            %   4) Compute geometric and distance-based features when possible.
            ObjectFeatureExtractor.validateInputTable(inputTable);

            outputTable = ObjectFeatureExtractor.ensureFeatureColumns(inputTable);
            nRows = height(outputTable);

            for rowIndex = 1:nRows
                % Step 1: pull vertices/faces for the current row and skip invalid meshes.
                [vertices, faces] = ObjectFeatureExtractor.extractMeshArrays(outputTable, rowIndex);
                if ~ObjectFeatureExtractor.isValidMesh(vertices, faces)
                    continue
                end

                % Step 2: compute core geometric features only when missing/invalid.
                if ~(isfinite(outputTable.volume(rowIndex)) && outputTable.volume(rowIndex) > 0)
                    % volume: enclosed 3-D volume of the object mesh.
                    warning('Computing volume for row %d because it was zero or invalid', rowIndex);
                    outputTable.volume(rowIndex) = ObjectFeatureExtractor.calculateVolume(vertices, faces);
                end

                if ~(isfinite(outputTable.surface(rowIndex)) && outputTable.surface(rowIndex) > 0)
                    % surface: total surface area of the object mesh.
                    warning('Computing surface area for row %d because it was zero or invalid', rowIndex);
                    outputTable.surface(rowIndex) = ObjectFeatureExtractor.calculateSurface(vertices, faces);
                end

                volumeValue = outputTable.volume(rowIndex);
                surfaceValue = outputTable.surface(rowIndex);

                % Step 3: compute derived compactness metric from volume and surface.
                if isfinite(volumeValue) && volumeValue > 0 && isfinite(surfaceValue) && surfaceValue > 0
                    % sphericity: how sphere-like the object is (1 for perfect sphere).
                    outputTable.sphericity(rowIndex) = (pi^(1/3) * (6 * volumeValue)^(2/3)) / surfaceValue;
                end

                % Step 4: compute convex hull volume and solidity.
                % convexHullVolume: volume of the object's convex hull.
                convexHullVolumeValue = ObjectFeatureExtractor.calculateConvexHullVolume(vertices);
                outputTable.convexHullVolume(rowIndex) = convexHullVolumeValue;

                if isfinite(volumeValue) && volumeValue > 0 && isfinite(convexHullVolumeValue) && convexHullVolumeValue > 0
                    % solidity: fraction of convex hull occupied by the object (volume/hull volume).
                    outputTable.solidity(rowIndex) = volumeValue / convexHullVolumeValue;
                end


                % Step 5: compute distance-based features from basePoint.
                point = ObjectFeatureExtractor.extractBasePoint(outputTable, rowIndex);
                [averageDistance, euclideanLength, distanceCoefficientOfVariation, openAngle, tipPoint] = ...
                    ObjectFeatureExtractor.calculateDistanceFeatures(vertices, point);

                outputTable.averageDistance(rowIndex) = averageDistance;
                outputTable.euclideanLength(rowIndex) = euclideanLength;
                outputTable.distanceCoefficientOfVariation(rowIndex) = distanceCoefficientOfVariation;
                outputTable.openAngle(rowIndex) = openAngle;

                % Step 5b: calculate angle between basePoint-to-tipPoint and basePointNormal if available
                angleWithNormal = nan;
                if ismember('basePointNormal', outputTable.Properties.VariableNames)
                    basePointNormal = outputTable.basePointNormal(rowIndex, :);
                    if all(isfinite(basePointNormal)) && norm(basePointNormal) > 0 && all(isfinite(point)) && all(isfinite(tipPoint))
                        v = tipPoint - point;
                        if norm(v) > 0
                            v = v / norm(v);
                            n = basePointNormal / norm(basePointNormal);
                            dotProd = dot(v, n);
                            dotProd = min(max(dotProd, -1), 1); % Clamp for safety
                            angleWithNormal = acosd(dotProd);
                        end
                    end
                end
                if ~ismember('baseToTipAngle', outputTable.Properties.VariableNames)
                    outputTable.baseToTipAngle = nan(height(outputTable), 1);
                end
                outputTable.baseToTipAngle(rowIndex) = angleWithNormal;

                % Step 6: compute base patch area if 'basePatch' column exists and is valid.
                if ismember('basePatch', outputTable.Properties.VariableNames)
                    surfaceArea = 0;
                    patches = outputTable.basePatch{rowIndex};
                    for i = 1:numel(patches)
                        patchSurfaceArea = ObjectFeatureExtractor.calculateSurface(patches(i).vertices, patches(i).faces);
                        surfaceArea = surfaceArea + patchSurfaceArea;
                    end
                    outputTable.basePatchArea(rowIndex) = surfaceArea;
                end
            end
        end



        function [averageDistance, euclideanLength, distanceCoefficientOfVariation, openAngle, tipPoint] = calculateDistanceFeatures(vertices, point)
            %CALCULATEDISTANCEFEATURES Compute distance distribution metrics.
            %
            % Returns NaN outputs when point is missing/invalid.

            % averageDistance: mean distance from basePoint to all mesh vertices.
            averageDistance = nan;
            % euclideanLength: mean of the top 5% largest vertex distances from basePoint.
            euclideanLength = nan;
            % distanceCoefficientOfVariation: std/mean of those vertex distances.
            distanceCoefficientOfVariation = nan;
            % openAngle: mean angular spread between the mean direction vector and vertex vectors.
            openAngle = nan;
            % tipPoint: furthest vertex from basePoint (used for angle calculation)
            tipPoint = [nan nan nan];

            if any(isnan(point))
                return
            end

            % Convert each vertex to a vector relative to the reference point.
            relativeVectors = vertices - point;

            distances = sqrt(sum(relativeVectors.^2, 2));
            if isempty(distances)
                return
            end

            % Central tendency and tail-extent of radial distances.
            averageDistance = mean(distances, 'omitnan');

            [sortedDistances, sortedIdx] = sort(distances, 'descend');
            nFurthest = max(1, ceil(numel(distances) * 0.05));
            euclideanLength = mean(sortedDistances(1:nFurthest), 'omitnan');
            % tipPoint: mean of the 5% furthest vertices from basePoint
            tipIdxs = sortedIdx(1:nFurthest);
            tipPoint = mean(vertices(tipIdxs, :), 1);

            if isfinite(averageDistance) && averageDistance > 0
                distanceCoefficientOfVariation = std(distances, 'omitnan') / averageDistance;
            end

            % Angular spread around the mean direction from the reference point.
            sumVector = mean(relativeVectors, 1, 'omitnan');
            if all(isfinite(sumVector)) && norm(sumVector) > 0
                nVertices = size(vertices, 1);
                atan2Angles = nan(nVertices, 1);
                for i = 1:nVertices
                    currentVector = relativeVectors(i, :);
                    dotProduct = dot(sumVector, currentVector);
                    crossProduct = cross(sumVector, currentVector);
                    atan2Angles(i) = atan2d(norm(crossProduct), dotProduct);
                end
                openAngle = mean(atan2Angles, 'omitnan');
            end
        end



        function convexHullVolumeValue = calculateConvexHullVolume(vertices)
            %CALCULATECONVEXHULLVOLUME Compute convex hull volume robustly.
            % Returns NaN when convex hull fails or is non-positive.
            convexHullVolumeValue = nan;

            try
                [~, convexVolume] = convhull(vertices(:, 1), vertices(:, 2), vertices(:, 3));
            catch
                return
            end

            if isfinite(convexVolume) && convexVolume > 0
                convexHullVolumeValue = convexVolume;
            end
        end



        function volume = calculateVolume(vertices, faces)
            %CALCULATEVOLUME Compute enclosed volume via signed tetrahedra sum.
            v1 = vertices(faces(:,1), :);
            v2 = vertices(faces(:,2), :);
            v3 = vertices(faces(:,3), :);

            volume = abs(sum(dot(cross(v1, v2, 2), v3, 2))) / 6;
        end



        function surface = calculateSurface(vertices, faces)
            %CALCULATESURFACE Compute total triangle area of mesh surface.
            v1 = vertices(faces(:,1), :);
            v2 = vertices(faces(:,2), :);
            v3 = vertices(faces(:,3), :);

            crossProd = cross(v2 - v1, v3 - v1, 2);
            surface = 0.5 * sum(sqrt(sum(crossProd.^2, 2)));
        end



        function [selectedFeatures, wasConfirmed] = promptFeatureSelection(preselectedFeatures)
            %PROMPTFEATURESELECTION Show a modal feature picker for output columns.
            %
            % Inputs:
            %   preselectedFeatures (optional): string/cell/char list of
            %   features that should be pre-checked in the UI.
            %
            % Outputs:
            %   selectedFeatures: selected feature names as string array.
            %   wasConfirmed: true when user presses OK, false on cancel/close.
            %
            % Behavior:
            %   - Unknown preselected names are ignored.
            %   - If no preselection is provided, all features are preselected.

            allFeatures = ObjectFeatureExtractor.featureNames;

            if nargin < 1 || isempty(preselectedFeatures)
                preselectedFeatures = allFeatures;
            end

            if ischar(preselectedFeatures)
                preselectedFeatures = string({preselectedFeatures});
            else
                preselectedFeatures = string(preselectedFeatures);
            end
            preselectedFeatures = preselectedFeatures(ismember(preselectedFeatures, allFeatures));

            selectedFeatures = strings(0, 1);
            wasConfirmed = false;

            nFeatures = numel(allFeatures);
            figureHeight = 170 + 30 * nFeatures;
            figureHeight = min(max(figureHeight, 300), 700);

            fig = uifigure( ...
                'Name', 'Select Features', ...
                'Position', [100 100 420 figureHeight], ...
                'Resize', 'off', ...
                'WindowStyle', 'modal');

            fig.CloseRequestFcn = @onCancel;

            gridLayout = uigridlayout(fig, [nFeatures + 4, 2]);
            gridLayout.RowHeight = [{28}, repmat({24}, 1, nFeatures), {10}, {30}, {30}];
            gridLayout.ColumnWidth = {'1x', '1x'};
            gridLayout.Padding = [12 12 12 12];
            gridLayout.RowSpacing = 6;

            titleLabel = uilabel(gridLayout, ...
                'Text', 'Choose features to calculate:', ...
                'FontWeight', 'bold');
            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = [1 2];

            featureCheckboxes = gobjects(nFeatures, 1);
            for i = 1:nFeatures
                featureCheckboxes(i) = uicheckbox(gridLayout, ...
                    'Text', char(allFeatures(i)), ...
                    'Value', ismember(allFeatures(i), preselectedFeatures));
                featureCheckboxes(i).Layout.Row = i + 1;
                featureCheckboxes(i).Layout.Column = [1 2];
            end

            selectAllButton = uibutton(gridLayout, ...
                'Text', 'Select all', ...
                'ButtonPushedFcn', @(~, ~) setAllCheckboxes(true));
            selectAllButton.Layout.Row = nFeatures + 3;
            selectAllButton.Layout.Column = 1;

            clearButton = uibutton(gridLayout, ...
                'Text', 'Clear', ...
                'ButtonPushedFcn', @(~, ~) setAllCheckboxes(false));
            clearButton.Layout.Row = nFeatures + 3;
            clearButton.Layout.Column = 2;

            okButton = uibutton(gridLayout, ...
                'Text', 'OK', ...
                'ButtonPushedFcn', @onOk);
            okButton.Layout.Row = nFeatures + 4;
            okButton.Layout.Column = 1;

            cancelButton = uibutton(gridLayout, ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @onCancel);
            cancelButton.Layout.Row = nFeatures + 4;
            cancelButton.Layout.Column = 2;

            uiwait(fig);

            function setAllCheckboxes(newValue)
                % Toggle all feature checkboxes at once.
                for idx = 1:nFeatures
                    featureCheckboxes(idx).Value = newValue;
                end
            end



            function onOk(~, ~)
                % Return selected features and close dialog.
                mask = false(nFeatures, 1);
                for idx = 1:nFeatures
                    mask(idx) = featureCheckboxes(idx).Value;
                end
                selectedFeatures = allFeatures(mask);
                wasConfirmed = true;
                delete(fig);
            end



            function onCancel(~, ~)
                % Return empty selection and close dialog.
                selectedFeatures = strings(0, 1);
                wasConfirmed = false;
                delete(fig);
            end
        end
    end



    methods (Access = private, Static)
        function validateInputTable(inputTable)
            %VALIDATEINPUTTABLE Validate minimal table schema required by extractor.
            if ~istable(inputTable)
                error('ObjectFeatureExtractor:InvalidInputType', ...
                    'Input must be a table.');
            end

            variableNames = inputTable.Properties.VariableNames;
            if ~ismember('Mesh', variableNames)
                error('ObjectFeatureExtractor:MissingMeshColumn', ...
                    'Input table must contain a ''Mesh'' column.');
            end
        end



        function outputTable = ensureFeatureColumns(inputTable)
            %ENSUREFEATURECOLUMNS Create/reset feature columns in output table.
            %
            % Existing volume/surface are preserved to avoid overriding valid
            % precomputed values. Other feature columns are reset to NaN.
            outputTable = inputTable;

            featureNames = ObjectFeatureExtractor.featureNames;

            for i = 1:numel(featureNames)
                currentName = featureNames(i);
                currentNameChar = char(currentName);
                if ~ismember(currentNameChar, outputTable.Properties.VariableNames)
                    outputTable.(currentNameChar) = nan(height(outputTable), 1);
                else
                    if ~ismember(currentNameChar, {'volume', 'surface'})
                        outputTable.(currentNameChar)(:) = nan;
                    end
                end
            end

            % Descriptions for each feature
            featureDescriptions = struct(...
                'volume', 'Enclosed 3D volume of the object mesh', ...
                'surface', 'Total surface area of the object mesh', ...
                'averageDistance', 'Mean distance from basePoint to all mesh vertices', ...
                'euclideanLength', 'Mean of the top 5% largest vertex distances from basePoint', ...
                'distanceCoefficientOfVariation', 'Std/mean of vertex distances from basePoint', ...
                'sphericity', 'Surface compactness relative to a sphere of the same volume (1 = perfect sphere)', ...
                'openAngle', 'Average angular spread of vertex directions from basePoint', ...
                'convexHullVolume', 'Volume of the convex hull enclosing all vertices', ...
                'solidity', 'Fraction of convex hull occupied by object volume', ...
                'basePatchArea', 'Surface area of the patch where the spine is cut from the shaft', ...
                'baseToTipAngle', 'Angle between base point normal and base-to-tip direction (degrees)');
            % Units for each feature
            featureUnits = struct(...
                'volume', 'um^3', ...
                'surface', 'um^2', ...
                'averageDistance', 'um', ...
                'euclideanLength', 'um', ...
                'distanceCoefficientOfVariation', '', ...
                'sphericity', '', ...
                'openAngle', 'degrees', ...
                'convexHullVolume', 'um^3', ...
                'solidity', '', ...
                'basePatchArea', 'um^2', ...
                'baseToTipAngle', 'degrees' ...
            );

            % Assign VariableDescriptions and VariableUnits as cell arrays in the correct order
            varNames = outputTable.Properties.VariableNames;
            nVars = numel(varNames);
            % Use existing VariableDescriptions/Units if present, else create new
            if isfield(outputTable.Properties, 'VariableDescriptions') && numel(outputTable.Properties.VariableDescriptions) == nVars
                varDescriptions = outputTable.Properties.VariableDescriptions;
            else
                varDescriptions = repmat({''}, 1, nVars);
            end
            if isfield(outputTable.Properties, 'VariableUnits') && numel(outputTable.Properties.VariableUnits) == nVars
                varUnits = outputTable.Properties.VariableUnits;
            else
                varUnits = repmat({''}, 1, nVars);
            end
            for i = 1:nVars
                name = varNames{i};
                if isfield(featureDescriptions, name)
                    varDescriptions{i} = featureDescriptions.(name);
                end
                if isfield(featureUnits, name)
                    varUnits{i} = featureUnits.(name);
                end
            end
            outputTable.Properties.VariableDescriptions = varDescriptions;
            outputTable.Properties.VariableUnits = varUnits;
        end



        function [vertices, faces] = extractMeshArrays(inputTable, rowIndex)
            %EXTRACTMESHARRAYS Normalize one row's mesh representation to arrays.
            vertices = [];
            faces = [];

            meshColumn = inputTable.Mesh;
            if iscell(meshColumn)
                meshValue = meshColumn{rowIndex};
            else
                meshValue = meshColumn(rowIndex);
            end

            if isempty(meshValue)
                return
            end

            [vertices, faces] = ObjectFeatureExtractor.extractVerticesFaces(meshValue);
        end



        function [vertices, faces] = extractVerticesFaces(meshValue)
            %EXTRACTVERTICESFACES Support multiple mesh object conventions.
            %
            % Handles:
            %   - surfaceMesh
            %   - struct fields: Vertices/Faces or vertices/faces
            %   - object properties: Vertices/Faces or vertices/faces
            vertices = [];
            faces = [];

            if isa(meshValue, 'surfaceMesh')
                vertices = double(meshValue.Vertices);
                faces = double(meshValue.Faces);
                return
            end

            if isstruct(meshValue)
                if isfield(meshValue, 'Vertices')
                    vertices = double(meshValue.Vertices);
                elseif isfield(meshValue, 'vertices')
                    vertices = double(meshValue.vertices);
                end

                if isfield(meshValue, 'Faces')
                    faces = double(meshValue.Faces);
                elseif isfield(meshValue, 'faces')
                    faces = double(meshValue.faces);
                end

                return
            end

            if isobject(meshValue)
                if isprop(meshValue, 'Vertices')
                    vertices = double(meshValue.Vertices);
                elseif isprop(meshValue, 'vertices')
                    vertices = double(meshValue.vertices);
                end

                if isprop(meshValue, 'Faces')
                    faces = double(meshValue.Faces);
                elseif isprop(meshValue, 'faces')
                    faces = double(meshValue.faces);
                end
            end
        end



        function tf = isValidMesh(vertices, faces)
            %ISVALIDMESH Perform lightweight topology/shape checks for triangles.
            tf = ~isempty(vertices) && ~isempty(faces) && ...
                size(vertices, 2) == 3 && size(faces, 2) == 3 && ...
                size(vertices, 1) >= 3 && size(faces, 1) >= 1;
        end



        function point = extractBasePoint(inputTable, rowIndex)
            %EXTRACTBASEPOINT Get [x y z] reference point for row.
            % Returns NaNs when not available or invalid.
            point = [nan nan nan];

            if ~ismember('basePoint', inputTable.Properties.VariableNames)
                return
            end

            pointColumn = inputTable.basePoint;
            if iscell(pointColumn)
                candidate = pointColumn{rowIndex};
            else
                candidate = pointColumn(rowIndex, :);
            end

            if isempty(candidate)
                return
            end

            candidate = double(candidate);
            if isvector(candidate) && numel(candidate) >= 3
                point = reshape(candidate(1:3), 1, 3);
            end
        end
    end
end
