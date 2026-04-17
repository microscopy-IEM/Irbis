classdef SpineSynapseMatcher
    %SPINESYNAPSEMATCHER Static utilities for spine/synapse matching workflows.

    properties (Constant)
        DefaultMaxCentroidDistance = 2; % microns
        DefaultSignedDistanceTolerance = 0.001; % microns - maximum signed distance for a synapse centroid to be considered 'inside a spine'
        DistanceIncrement = 0.5; % microns;
    end

    methods (Static)
        function [spinesTable, synapsesTable] = match(spinesTable, synapsesTable)
            % The main entry point that will take in the tables, read the meshes, find overlapping objects and write the relevant columns to the tables

            arguments
                spinesTable table
                synapsesTable table
            end

            % First, find closest spine for each synapse centroid
            synapses = synapsesTable.Mesh;
            synapseIds = str2double(synapsesTable.Properties.RowNames);

            spines = spinesTable.Mesh;
            spineIds = str2double(spinesTable.Properties.RowNames);

            overlapResults = SpineSynapseMatcher.matchSynapseCentroidsToSpines(spines, synapses, SpineSynapseMatcher.DefaultMaxCentroidDistance, SpineSynapseMatcher.DefaultSignedDistanceTolerance);

            % Update synapses table with spine matches
            synapsesTable.centroid = overlapResults.synapseCentroid;
            synapsesTable.isInSpine = overlapResults.isOverlapping;
            synapsesTable.distToSpine = overlapResults.signedDistance;
            validMatches = overlapResults.spineIndex > 0;
            synapsesTable.closestSpineId = NaN(height(synapsesTable), 1);
            synapsesTable.closestSpineId(validMatches) = spineIds(overlapResults.spineIndex(validMatches));

            spineResults = SpineSynapseMatcher.getSynapsesPerSpine(overlapResults, synapseIds, numel(spines));

            % Update spines table with synapse matches
            spinesTable.hasSynapse = spineResults.hasSynapse;
            spinesTable.synapseCount = spineResults.synapseCount;
            spinesTable.synapseIds = spineResults.synapseIds;

            % If there is basePoint information in the spines table, we can also compute the distance from each synapse to the base point of its matched spine
            if ismember('basePoint', spinesTable.Properties.VariableNames)
                spineBasePoints = spinesTable.basePoint;
                synapseCentroids = overlapResults.synapseCentroid;

                % Preallocate array for distances
                synapsesTable.distToSpineBasePoint = NaN(height(synapsesTable), 1);

                for synapseIndex = 1:height(synapsesTable)
                    if synapsesTable.isInSpine(synapseIndex) && ~isnan(synapsesTable.closestSpineId(synapseIndex))
                        spineId = synapsesTable.closestSpineId(synapseIndex);
                        spineBasePoint = spineBasePoints(spinesTable.Properties.RowNames == string(spineId), :);
                        synapseCentroid = synapseCentroids(synapseIndex, :);
                        distanceToBasePoint = sqrt(sum((synapseCentroid - spineBasePoint) .^ 2));
                        synapsesTable.distToSpineBasePoint(synapseIndex) = distanceToBasePoint;
                    end
                end
            end
        end



        function overlapResults = matchSynapseCentroidsToSpines(spines, synapses, maxCentroidDistance, signedDistanceTolerance)
            % Match each synapse centroid to the closest spine surface.
            %
            % Rationale:
            % - Use centroid distance only as a fast candidate filter.
            % - Use point2trimesh signed distance for final geometric matching.

            arguments
                spines (1,:) cell
                synapses (1,:) cell
                maxCentroidDistance (1,1) double {mustBeReal, mustBeNonnegative} = inf
                signedDistanceTolerance (1,1) double {mustBeReal} = 0
            end

            numSpines = numel(spines);
            numSynapses = numel(synapses);

            overlapResults = table( ... 
                (1:numSynapses).', ...
                zeros(numSynapses, 1), ...
                zeros(numSynapses, 1), ...
                NaN(numSynapses, 1), ...
                false(numSynapses, 1), ...
                NaN(numSynapses, 3), ...
                'VariableNames', {'synapseIndex', 'spineIndex', 'overlappingSpineIndex', ...
                'signedDistance', 'isOverlapping', 'synapseCentroid'});

            if numSpines == 0 || numSynapses == 0
                return;
            end

            spineCentroids = SpineSynapseMatcher.computeMeshCentroids(spines);
            synapseCentroids = SpineSynapseMatcher.computeMeshCentroids(synapses);
            centroidDistanceSquared = SpineSynapseMatcher.computePairwiseSquaredDistances(synapseCentroids, spineCentroids);

            maxCentroidDistanceSquared = maxCentroidDistance ^ 2;

            for synapseIndex = 1:numSynapses
                overlapResults.synapseCentroid(synapseIndex, :) = synapseCentroids(synapseIndex, :);

                rowDistancesSquared = centroidDistanceSquared(synapseIndex, :);
                candidateIndices = SpineSynapseMatcher.findCandidateObjectsInRange(rowDistancesSquared, maxCentroidDistanceSquared, SpineSynapseMatcher.DistanceIncrement ^ 2);

                bestSpineIndex = 0;
                bestSignedDistance = inf;
                bestCentroidDistanceSquared = inf;

                for candidateIndex = 1:numel(candidateIndices)
                    spineIndex = candidateIndices(candidateIndex);
                    signedDistanceValue = SpineSynapseMatcher.computeSignedDistancePoint2TriMesh( ...
                        spines{spineIndex}, synapseCentroids(synapseIndex, :));

                    if signedDistanceValue < bestSignedDistance || ...
                            (signedDistanceValue == bestSignedDistance && rowDistancesSquared(spineIndex) < bestCentroidDistanceSquared)
                        bestSignedDistance = signedDistanceValue;
                        bestSpineIndex = spineIndex;
                        bestCentroidDistanceSquared = rowDistancesSquared(spineIndex);
                    end
                end

                if bestSpineIndex == 0
                    % disp(numel(candidateIndices));
                    % disp(bestSignedDistance)
                    continue;
                end

                overlapResults.spineIndex(synapseIndex) = bestSpineIndex;
                if bestSignedDistance <= signedDistanceTolerance
                    % overlappingSpineIndex is only populated when the synapse centroid is inside the spine mesh (signed distance <= 0) 
                    overlapResults.overlappingSpineIndex(synapseIndex) = bestSpineIndex;
                end
                overlapResults.signedDistance(synapseIndex) = bestSignedDistance;
                overlapResults.isOverlapping(synapseIndex) = bestSignedDistance <= signedDistanceTolerance;
            end
        end



        function spineSummary = getSynapsesPerSpine(overlapResults, synapseIds, numSpines)
            %SUMMARIZESPINESYNAPSEASSIGNMENTS Aggregate synapse matches per spine index.

            arguments
                overlapResults table
                synapseIds double {mustBeVector}
                numSpines (1,1) double {mustBeInteger} = -1
            end

            if numSpines < -1
                error('getSynapsesPerSpine:InvalidNumSpines', ...
                    'numSpines must be -1 (auto) or a nonnegative integer.');
            end

            requiredVariables = {'overlappingSpineIndex'};
            for variableIndex = 1:numel(requiredVariables)
                if ~ismember(requiredVariables{variableIndex}, overlapResults.Properties.VariableNames)
                    error('getSynapsesPerSpine:MissingVariable', ...
                        'overlapResults must contain variable "%s".', requiredVariables{variableIndex});
                end
            end

            % Only rows that actually landed in a spine should contribute to the grouping.
            matchedMask = overlapResults.overlappingSpineIndex > 0;
            matchedSpineIndices = overlapResults.overlappingSpineIndex(matchedMask);
            synapseIds = synapseIds(:);
            matchedSynapseIds = synapseIds(matchedMask);

            % If the caller does not provide the total spine count, infer it from the
            % largest matched spine index. That keeps the summary aligned to the
            % observed index space in overlapResults.
            if numSpines < 0
                if isempty(matchedSpineIndices)
                    numSpines = 0;
                else
                    numSpines = max(matchedSpineIndices);
                end
            end

            if numSpines == 0
                spineSummary = table([], [], [], {}, ...
                    'VariableNames', {'spineIndex', 'hasSynapse', 'synapseCount', 'synapseIds'});
                return;
            end

            % Group synapse indices by spine index using a compact accumulator.
            synapseIndicesBySpine = accumarray( ...
                matchedSpineIndices, matchedSynapseIds, [numSpines, 1], ...
                @(indexValues) {reshape(indexValues, 1, [])}, {[]});

            synapseCount = cellfun(@numel, synapseIndicesBySpine);
            hasSynapse = synapseCount > 0;

            spineSummary = table( ...
                (1:numSpines).', ...
                hasSynapse, ...
                synapseCount, ...
                synapseIndicesBySpine, ...
                'VariableNames', {'spineIndex', 'hasSynapse', 'synapseCount', 'synapseIds'});
        end
    end




    methods (Static, Access = private)
        function centroids = computeMeshCentroids(meshes)
            numMeshes = numel(meshes);
            centroids = NaN(numMeshes, 3);

            for meshIndex = 1:numMeshes
                vertices = SpineSynapseMatcher.getMeshVertices(meshes{meshIndex});
                if isempty(vertices)
                    continue;
                end

                if size(vertices, 2) == 3
                    centroids(meshIndex, :) = mean(double(vertices), 1);
                elseif size(vertices, 1) == 3
                    centroids(meshIndex, :) = mean(double(vertices).', 1);
                else
                    error('matchSynapseCentroidsToSpines:InvalidVertices', 'Vertices must be an N-by-3 or 3-by-N array.');
                end
            end
        end



        function distanceSquared = computePairwiseSquaredDistances(pointsA, pointsB)
            aSquared = sum(pointsA .^ 2, 2);
            bSquared = sum(pointsB .^ 2, 2).';
            distanceSquared = aSquared + bSquared - 2 * (pointsA * pointsB.');
            distanceSquared = max(distanceSquared, 0);
        end



        function candidateIndices = findCandidateObjectsInRange(rowDistancesSquared, maxCentroidDistanceSquared, increment)
            withinRange = rowDistancesSquared <= maxCentroidDistanceSquared;

            candidateIndices = find(withinRange);
            if ~isempty(candidateIndices)
                [~, order] = sort(rowDistancesSquared(candidateIndices), 'ascend');
                candidateIndices = candidateIndices(order);
            else
                % disp('No candidates found within maxCentroidDistance. Incrementing search radius.');
                newMaxCentroidDistanceSquared = maxCentroidDistanceSquared + increment;
                candidateIndices = SpineSynapseMatcher.findCandidateObjectsInRange(rowDistancesSquared, newMaxCentroidDistanceSquared, increment);
            end
        end



        function vertices = getMeshVertices(mesh)
            vertices = [];

            if isstruct(mesh)
                if isfield(mesh, 'Vertices')
                    vertices = mesh.Vertices;
                elseif isfield(mesh, 'vertices')
                    vertices = mesh.vertices;
                end
                return;
            end

            if isobject(mesh)
                if isprop(mesh, 'Vertices')
                    vertices = mesh.Vertices;
                elseif isprop(mesh, 'vertices')
                    vertices = mesh.vertices;
                end
            end
        end



        function faces = getMeshFaces(mesh)
            faces = [];

            if isstruct(mesh)
                if isfield(mesh, 'Faces')
                    faces = mesh.Faces;
                elseif isfield(mesh, 'faces')
                    faces = mesh.faces;
                end
                return;
            end

            if isobject(mesh)
                if isprop(mesh, 'Faces')
                    faces = mesh.Faces;
                elseif isprop(mesh, 'faces')
                    faces = mesh.faces;
                end
            end
        end



        function signedDistanceValue = computeSignedDistancePoint2TriMesh(mesh, point)
            vertices = SpineSynapseMatcher.getMeshVertices(mesh);
            faces = SpineSynapseMatcher.getMeshFaces(mesh);

            if isempty(vertices) || isempty(faces)
                error('matchSynapseCentroidsToSpines:UnsupportedMeshType', 'point2trimesh requires mesh vertices and faces.');
            end

            signedDistance = point2trimesh( ...
                'Faces', double(faces), ...
                'Vertices', double(vertices), ...
                'QueryPoints', double(point(:).'), ...
                'Algorithm', 'linear');

            signedDistanceValue = double(signedDistance(1));
        end
    end
end
