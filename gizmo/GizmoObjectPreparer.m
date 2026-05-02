classdef GizmoObjectPreparer
    % Prepares 3D object data for GizmoTool scaling and positioning.
    %
    % Usage examples:
    %   prepared = GizmoObjectPreparer.prepare( ...
    %       'Object', objectStruct, ...
    %       'ScaleAxes', {'x','xyz','z'});
    %
    %   prepared = GizmoObjectPreparer.preparePredefined('thinCuboid');
    %   prepared = GizmoObjectPreparer.preparePredefined('sphere');
    %
    % Returned struct fields:
    %   prepared.objectForGizmo    -> original object input (single handle/struct or cell array), never merged
    %   prepared.gizmoCenter       -> [1x3] centre position in original coordinates
    %   prepared.scalePointVectors -> list of axis vectors for scaling handles
    %   prepared.scalePointPositions -> list of scaling handle positions (relative to gizmo center)

    properties (Access = private)
        InputObject = []
        PredefinedObjectName (1,1) string = ""

        ScaleAxes cell = {'xyz'}
        ScalePointPositions cell = {}
        GizmoCenter double = []
    end


    methods (Access = public)
        function obj = GizmoObjectPreparer(varargin)
            % Parse and store user inputs; used by direct construction and by prepare().
            parser = inputParser;
            parser.FunctionName = 'GizmoObjectPreparer';

            addParameter(parser, 'Object', []);
            addParameter(parser, 'PredefinedObject', "");
            addParameter(parser, 'ScaleAxes', {'xyz'});
            addParameter(parser, 'ScalePointPositions', {});
            addParameter(parser, 'GizmoCenter', []);
            addParameter(parser, 'AxesHandle', []);  % for potential future use in predefined object creation

            parse(parser, varargin{:});

            obj.InputObject = parser.Results.Object;
            obj.PredefinedObjectName = string(parser.Results.PredefinedObject);
            obj.ScaleAxes = GizmoObjectPreparer.normalizeScaleAxes(parser.Results.ScaleAxes);
            obj.ScalePointPositions = GizmoObjectPreparer.normalizeScalePointPositions(parser.Results.ScalePointPositions);
            obj.GizmoCenter = parser.Results.GizmoCenter;
        end



        function prepared = build(obj)
            % Build final gizmo-preparation output; main workflow used after constructor/prepare().
            [objectForGizmo, meshList, scaleAxes] = obj.resolveObjectInput();   % this returns scaleAxes because the predefined objects have their own
            allVertices = GizmoObjectPreparer.collectAllVertices(meshList);

            if isempty(allVertices)
                error('GizmoObjectPreparer:EmptyVertices', 'Object vertices are empty.');
            end

            if isempty(obj.GizmoCenter)
                center = GizmoObjectPreparer.calculateCenterOfGravityFromMeshes(meshList);
            else
                validateattributes(obj.GizmoCenter, {'numeric'}, {'size',[1 3], 'real', 'finite'}, mfilename, 'GizmoCenter');
                center = double(obj.GizmoCenter);
            end

            localVertices = allVertices - center;
            scaleVectors = GizmoObjectPreparer.axisNamesToVectors(scaleAxes);

            if isempty(obj.ScalePointPositions)
                scalePositions = GizmoObjectPreparer.calculateOutermostScalePoints(localVertices, scaleVectors);
            else
                if numel(obj.ScalePointPositions) ~= numel(scaleVectors)
                    error('GizmoObjectPreparer:ScalePointCountMismatch', ...
                        'Number of ScalePointPositions (%d) must match number of ScaleAxes (%d).', ...
                        numel(obj.ScalePointPositions), numel(scaleVectors));
                end
                scalePositions = obj.ScalePointPositions;
            end

            prepared = struct();
            prepared.objectForGizmo = objectForGizmo;
            prepared.gizmoCenter = center;
            prepared.scalePointVectors = scaleVectors;
            prepared.scalePointPositions = scalePositions;
        end
    end


    methods (Static)
        function prepared = prepare(object, varargin)
            % Convenience entry point that instantiates class and runs build().
            
            preparer = GizmoObjectPreparer('Object', object, varargin{:});
            prepared = preparer.build();
        end



        function prepared = preparePredefined(type)
            % Convenience entry point for creating and preparing a predefined object by type name.
            arguments
                type (1,1) string {mustBeMember(type, ["cylinder", "thinCuboid", "sphere"])}
            end

            preparer = GizmoObjectPreparer('PredefinedObject', type);
            prepared = preparer.build();
        end
    end



    methods (Access = private)
        function [objectForGizmo, meshList, scaleAxes] = resolveObjectInput(obj)
            % Resolve input source (provided object(s) or predefined object); used by build().
            hasObject = ~isempty(obj.InputObject);
            hasPredefined = strlength(strtrim(obj.PredefinedObjectName)) > 0;

            if hasObject && hasPredefined
                error('GizmoObjectPreparer:AmbiguousSource', ...
                    'Provide either ''Object'' or ''PredefinedObject'', not both.');
            end

            if ~hasObject && ~hasPredefined
                error('GizmoObjectPreparer:MissingSource', ...
                    'Provide either ''Object'' or ''PredefinedObject''.');
            end

            if hasPredefined
                [predefinedObject, scaleAxes] = GizmoObjectPreparer.createPredefinedObject(obj.PredefinedObjectName);
                meshList = {GizmoObjectPreparer.ensureFacesAreOneBased(predefinedObject)};
                objectForGizmo = predefinedObject;  % keep as struct for predefined objects, since we won't have an original handle to preserve
            else
                scaleAxes = obj.ScaleAxes;
                [objectForGizmo, meshList] = GizmoObjectPreparer.unpackObjectReferences(obj.InputObject);
            end
        end
    end



    methods (Static, Access = private)
        function scaleAxes = normalizeScaleAxes(scaleAxesInput)
            % Normalize axis-name input format; used in constructor before vector conversion.
            if isstring(scaleAxesInput)
                scaleAxesInput = cellstr(scaleAxesInput);
            end

            if ischar(scaleAxesInput)
                scaleAxesInput = {scaleAxesInput};
            end

            if ~iscell(scaleAxesInput)
                error('GizmoObjectPreparer:InvalidScaleAxes', ...
                    'ScaleAxes must be a string/cell array such as {''x'',''xyz'',''z''}.');
            end

            scaleAxes = cell(1, numel(scaleAxesInput));
            for k = 1:numel(scaleAxesInput)
                axisName = lower(string(scaleAxesInput{k}));
                axisName = erase(axisName, " ");
                if strlength(axisName) == 0
                    error('GizmoObjectPreparer:InvalidAxisName', 'Scale axis name cannot be empty.');
                end
                scaleAxes{k} = char(axisName);
            end
        end



        function vectors = axisNamesToVectors(scaleAxes)
            % Convert axis names like 'xyz' to [1 1 1] vectors; used by build().
            vectors = cell(1, numel(scaleAxes));

            for k = 1:numel(scaleAxes)
                axisName = scaleAxes{k};

                hasX = contains(axisName, 'x');
                hasY = contains(axisName, 'y');
                hasZ = contains(axisName, 'z');

                allowed = regexp(axisName, '^[xyz]+$', 'once');
                if isempty(allowed)
                    error('GizmoObjectPreparer:InvalidAxisName', ...
                        'Invalid axis combination "%s". Allowed examples: ''x'', ''yz'', ''xyz''.', axisName);
                end

                vec = [double(hasX), double(hasY), double(hasZ)];
                if all(vec == 0)
                    error('GizmoObjectPreparer:InvalidAxisName', ...
                        'Axis "%s" does not map to any vector.', axisName);
                end

                vectors{k} = vec;
            end
        end



        function center = calculateCenterOfGravityFromMeshes(meshList)
            % Compute weighted mesh center of gravity from multiple meshes; used by build() when center is not provided.
            weightedCenterSum = [0 0 0];
            totalWeight = 0;

            for i = 1:numel(meshList)
                mesh = meshList{i};
                vertices = mesh.vertices;
                faces = mesh.faces;

                if isempty(vertices)
                    continue;
                end

                if isempty(faces)
                    localCenter = mean(vertices, 1);
                    localWeight = size(vertices, 1);
                else
                    v1 = vertices(faces(:,1), :);
                    v2 = vertices(faces(:,2), :);
                    v3 = vertices(faces(:,3), :);

                    centroids = (v1 + v2 + v3) / 3;
                    crossProd = cross(v2 - v1, v3 - v1, 2);
                    areas = 0.5 * vecnorm(crossProd, 2, 2);
                    localWeight = sum(areas);

                    if localWeight < 1e-12
                        localCenter = mean(vertices, 1);
                        localWeight = size(vertices, 1);
                    else
                        localCenter = sum(centroids .* areas, 1) / localWeight;
                    end
                end

                weightedCenterSum = weightedCenterSum + localCenter * localWeight;
                totalWeight = totalWeight + localWeight;
            end

            if totalWeight < 1e-12
                allVertices = GizmoObjectPreparer.collectAllVertices(meshList);
                center = mean(allVertices, 1);
            else
                center = weightedCenterSum / totalWeight;
            end
        end



        function scalePointPositions = calculateOutermostScalePoints(localVertices, scaleVectors)
            % Find furthest vertex per scale direction to place default scale handles; used by build().
            scalePointPositions = cell(1, numel(scaleVectors));

            % Small outward margin so the handle is placed slightly outside the object.
            outsideRelativeMargin = 0.05;   % 2% of projection magnitude
            sceneScale = max(vecnorm(localVertices, 2, 2));
            if isempty(sceneScale) || sceneScale < 1e-12
                sceneScale = 1;
            end
            outsideAbsoluteMin = 1e-3 * sceneScale;

            for k = 1:numel(scaleVectors)
                vec = scaleVectors{k};
                direction = vec / norm(vec);

                % Keep only active dimensions for directional matching.
                activeMask = vec ~= 0;
                activeVertices = localVertices;
                activeVertices(:, ~activeMask) = 0;

                norms = vecnorm(activeVertices, 2, 2);
                projections = activeVertices * direction(:);

                valid = norms > 1e-12;
                if ~any(valid)
                    scalePointPositions{k} = zeros(1, 3);
                    continue;
                end

                % Vertex closest to the direction vector (largest cosine similarity).
                cosine = -inf(size(norms));
                cosine(valid) = projections(valid) ./ norms(valid);
                bestCosine = max(cosine(valid));

                cosTol = 1e-9;
                candidates = find(cosine >= (bestCosine - cosTol));
                if numel(candidates) > 1
                    % Tie-breaker: keep the candidate further along that direction.
                    [~, localIdx] = max(projections(candidates));
                    chosenIdx = candidates(localIdx);
                else
                    chosenIdx = candidates(1);
                end

                % Enforce equal non-zero values on all active axes.
                chosenProjection = projections(chosenIdx);

                % Move slightly further in the same direction (outside the object).
                outwardDelta = max(abs(chosenProjection) * outsideRelativeMargin, outsideAbsoluteMin);
                chosenProjection = chosenProjection + outwardDelta;

                nActive = nnz(activeMask);
                equalValue = chosenProjection / sqrt(nActive);

                pos = zeros(1, 3);
                pos(activeMask) = equalValue;
                scalePointPositions{k} = pos;
            end
        end



        function normalized = normalizeScalePointPositions(inputPositions)
            % Normalize custom scale-point positions to cell-of-1x3 format; used in constructor.
            if isempty(inputPositions)
                normalized = {};
                return;
            end

            if isnumeric(inputPositions) && size(inputPositions,2) == 3
                normalized = cell(1, size(inputPositions,1));
                for i = 1:size(inputPositions,1)
                    normalized{i} = inputPositions(i,:);
                end
                return;
            end

            if ~iscell(inputPositions)
                error('GizmoObjectPreparer:InvalidScalePointPositions', ...
                    'ScalePointPositions must be empty, N-by-3 numeric, or a cell array of 1-by-3 vectors.');
            end

            normalized = cell(1, numel(inputPositions));
            for i = 1:numel(inputPositions)
                pos = inputPositions{i};
                validateattributes(pos, {'numeric'}, {'size',[1 3], 'real', 'finite'}, mfilename, 'ScalePointPositions');
                normalized{i} = double(pos);
            end
        end



        function allVertices = collectAllVertices(meshList)
            % Concatenate vertices from all meshes for global geometric operations; used by build().
            allVertices = zeros(0,3);

            for i = 1:numel(meshList)
                mesh = meshList{i};
                if ~isempty(mesh.vertices)
                    allVertices = [allVertices; mesh.vertices]; %#ok<AGROW>
                end
            end
        end



        function [objectForGizmo, meshList] = unpackObjectReferences(inputObject)
            % Keep original object reference(s) while extracting mesh geometry; used by resolveObjectInput().
            if iscell(inputObject)
                objectList = inputObject;
            else
                objectList = {inputObject};
            end

            meshList = cell(1, numel(objectList));
            validMask = false(1, numel(objectList));

            for i = 1:numel(objectList)
                current = GizmoObjectPreparer.extractObjectStruct(objectList{i});
                meshList{i} = GizmoObjectPreparer.ensureFacesAreOneBased(current);
                validMask(i) = ~isempty(meshList{i}.vertices);
            end

            if ~any(validMask)
                error('GizmoObjectPreparer:NoValidObjects', ...
                    'No valid objects were provided. Each object must contain vertices and faces.');
            end

            objectList = objectList(validMask);
            meshList = meshList(validMask);

            if numel(objectList) == 1
                objectForGizmo = objectList{1};
            else
                objectForGizmo = objectList;
            end
        end



        function objectStruct = extractObjectStruct(inputObject)
            % Extract vertices/faces from patch handle or struct input; used by unpackObjectReferences().
            if isgraphics(inputObject, 'patch')
                objectStruct = struct('vertices', inputObject.Vertices, 'faces', inputObject.Faces);
                return;
            end

            if isgraphics(inputObject)
                handleType = lower(string(inputObject.Type));
                if ismember(handleType, ["scatter", "line"])
                    x = inputObject.XData(:);
                    y = inputObject.YData(:);
                    z = inputObject.ZData(:);

                    if isempty(z)
                        z = zeros(size(x));
                    end

                    if ~(numel(x) == numel(y) && numel(y) == numel(z))
                        error('GizmoObjectPreparer:InvalidPointObject', ...
                            'Point-based graphics objects must have XData, YData and ZData of equal length.');
                    end

                    objectStruct = struct('vertices', [double(x), double(y), double(z)], 'faces', zeros(0,3));
                    return;
                end
            end

            if ~isstruct(inputObject)
                error('GizmoObjectPreparer:InvalidObject', ...
                    ['Object must be a struct with vertices/faces, a supported graphics handle ' ...
                     '(patch/scatter/line), or a cell array of them.']);
            end

            if isfield(inputObject, 'vertices')
                vertices = inputObject.vertices;
            elseif isfield(inputObject, 'Vertices')
                vertices = inputObject.Vertices;
            else
                error('GizmoObjectPreparer:MissingVertices', 'Object does not contain vertices/Vertices.');
            end

            if isfield(inputObject, 'faces')
                faces = inputObject.faces;
            elseif isfield(inputObject, 'Faces')
                faces = inputObject.Faces;
            else
                error('GizmoObjectPreparer:MissingFaces', 'Object does not contain faces/Faces.');
            end

            validateattributes(vertices, {'numeric'}, {'ncols',3, 'real', 'finite'}, mfilename, 'vertices');
            validateattributes(faces, {'numeric'}, {'ncols',3, 'integer', 'nonnegative'}, mfilename, 'faces');

            objectStruct = struct('vertices', double(vertices), 'faces', double(faces));
        end



        function objectStruct = ensureFacesAreOneBased(objectStruct)
            % Convert zero-based face indexing to one-based MATLAB indexing; used after object extraction/creation.
            if isempty(objectStruct.faces)
                return;
            end

            minFaceIndex = min(objectStruct.faces, [], 'all');
            if minFaceIndex == 0
                objectStruct.faces = objectStruct.faces + 1;
            end
        end



        function [objectStruct, scaleAxes] = createPredefinedObject(name)
            % Get predefined object from requested type and predefined params; used by resolveObjectInput().
            objectType = lower(strtrim(name));

            switch objectType
                case "cylinder"
                    nSides = 30;
                    nLayers = 10;   % updated from 3
                    radius = 0.5;
                    height = 2;
                    numberingType = 1;
                    nBaseLayers = 1;  % new parameter for additional rings in the bases

                    [vertices, faces] = createCylinderObject(nSides, nLayers, radius, height, numberingType, nBaseLayers);
                    objectStruct = struct('vertices', vertices, 'faces', faces);
                    scaleAxes = {'xz', 'y'};

                case "thincuboid"
                    scalingFactor = 1;
                    scalingVector = [1 scalingFactor scalingFactor];
                    flattenedAxis = 1;
                    flatteningFactor = 0.001;
                    % flatteningFactor = 1;
                    numberingType = 1;

                    [vertices, faces] = createThinCuboidObject(scalingVector, flattenedAxis, flatteningFactor, numberingType);
                    objectStruct = struct('vertices', vertices, 'faces', faces);
                    scaleAxes = {'yz'};

                case "sphere"
                    radius = 0.5;
                    nDivisions = 20;
                    numberingType = 1;

                    [vertices, faces] = createSphere(radius, nDivisions, numberingType);
                    objectStruct = struct('vertices', vertices, 'faces', faces);
                    scaleAxes = {'xyz'};
                otherwise
                    error('GizmoObjectPreparer:UnsupportedPredefinedObject', ...
                        'Unsupported predefined object "%s". Supported: cylinder, thinCuboid, sphere.', objectType);
            end
        end
    end
end
