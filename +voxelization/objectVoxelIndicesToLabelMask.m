function [labelMask, overlapInfo] = objectVoxelIndicesToLabelMask(objectIndices, gridSize, varargin)
% objectVoxelIndicesToLabelMask Build a labeled volume from object indices.
%
%   labelMask = objectVoxelIndicesToLabelMask(objectIndices, gridSize)
%   [labelMask, overlapInfo] = objectVoxelIndicesToLabelMask(objectIndices, gridSize)
%
%   objectIndices is a cell array where objectIndices{i} contains global
%   linear indices for object i. The indices must refer to an array with size
%   gridSize = [ny nx nz].
%
%   The output is a numeric label volume with the same size as gridSize.
%   Background voxels are 0. By default, object i receives label i.
%   To use custom per-object values, pass ObjectValues or Labels:
%
%     labelMask = objectVoxelIndicesToLabelMask(objectIndices, gridSize, ...
%         'ObjectValues', [10 20 30]);
%
%   To create a binary mask, set Binary to true. All object voxels become 1,
%   and background remains 0:
%
%     binaryMask = objectVoxelIndicesToLabelMask(objectIndices, gridSize, ...
%         'Binary', true);
%
%   Separating this step from voxelization is intentional: the voxelizer can
%   store compact per-object index lists, and this function can later build a
%   label mask using the overlap policy and output class needed for a
%   specific analysis.
%
%   overlapInfo is a struct array with one element per object. It reports how
%   many voxels from each object also appear in at least one other object:
%     VoxelCount                Unique voxel count for this object.
%     OverlappingVoxelCount     Number of this object's voxels shared with
%                               one or more other objects.
%     OverlappingVoxelPercent   100 * OverlappingVoxelCount / VoxelCount.
%     OverlappingObjectIndices  Other object indices sharing voxels with
%                               this object.
%     OverlappingLabels         Labels corresponding to those objects.
%
%   Name-value options:
%     ObjectValues     Value written for each object. Default: 1:nObjects.
%                      Must contain one positive integer per object.
%     Labels           Alias for ObjectValues, kept for older scripts.
%     Binary           true creates a logical object-vs-background mask with
%                      all object voxels set to 1. Default: false.
%     OutputClass      Numeric output class. Default: uint16, or uint32 when
%                      object values do not fit in uint16. In Binary mode,
%                      the default is logical.
%     CollisionPolicy  How to handle overlapping object indices:
%                        'overwrite' later objects overwrite earlier labels
%                        'first' keep the first label already written
%                        'error' throw an error on any overlap
%
%                      If you are actively troubleshooting overlaps, use
%                      'overwrite' or 'first' while requesting overlapInfo.
%                      With 'error', MATLAB stops at the first detected
%                      overlap and does not return outputs.
%
%   Example:
%     [labelMask, overlapInfo] = objectVoxelIndicesToLabelMask(objectIndices, ...
%         [248 776 41], 'CollisionPolicy', 'overwrite');

    if ~iscell(objectIndices)
        error('objectIndices must be a cell array.');
    end

    gridSize = validateGridSize(gridSize);
    options = parseLabelMaskOptions(numel(objectIndices), varargin{:});

    labelMask = zeros(gridSize, options.OutputClass);
    voxelCount = prod(gridSize);

    [validatedObjectIndices, rawVoxelCounts, uniqueVoxelCounts] = ...
        validateAllObjectIndices(objectIndices, voxelCount);

    if nargout > 1
        overlapInfo = computeOverlapInfo( ...
            validatedObjectIndices, rawVoxelCounts, uniqueVoxelCounts, options.ObjectValues);
    end

    for objectIndex = 1:numel(objectIndices)
        currentObjectIndices = validatedObjectIndices{objectIndex};
        if isempty(currentObjectIndices)
            continue
        end

        objectValue = cast(options.ObjectValues(objectIndex), options.OutputClass);

        switch options.CollisionPolicy
            case 'overwrite'
                % Fastest policy: later objects are allowed to replace labels
                % written by earlier objects.
                labelMask(currentObjectIndices) = objectValue;

            case 'first'
                % Preserve earlier labels. This is useful when object order is
                % meaningful and overlaps should not change previous objects.
                isUnlabeled = labelMask(currentObjectIndices) == 0;
                currentObjectIndices = currentObjectIndices(isUnlabeled);
                labelMask(currentObjectIndices) = objectValue;

            case 'error'
                % Strict mode for workflows where any voxel overlap indicates
                % a segmentation or mesh-preparation problem.
                if any(labelMask(currentObjectIndices) ~= 0)
                    error(['Object %d overlaps with an already-labeled object. ', ...
                        'Use CollisionPolicy ''overwrite'' or ''first'' while inspecting ', ...
                        'the second output, overlapInfo, to troubleshoot overlaps.'], objectIndex);
                end
                labelMask(currentObjectIndices) = objectValue;
        end
    end
end

function gridSize = validateGridSize(gridSize)
% validateGridSize Ensure the label volume size is a valid [ny nx nz] vector.

    gridSize = double(gridSize(:).');
    if numel(gridSize) ~= 3 || any(~isfinite(gridSize)) || ...
            any(gridSize < 1) || any(mod(gridSize, 1) ~= 0)
        error('gridSize must contain three positive integer values.');
    end
end

function options = parseLabelMaskOptions(objectCount, varargin)
% parseLabelMaskOptions Validate labels, output type, and overlap behavior.

    parser = inputParser;
    addParameter(parser, 'ObjectValues', [], @(value) isnumeric(value) && isvector(value));
    addParameter(parser, 'Labels', [], @(value) isnumeric(value) && isvector(value));
    addParameter(parser, 'Binary', false, ...
        @(value) (islogical(value) || isnumeric(value)) && isscalar(value) && ...
        (islogical(value) || value == 0 || value == 1));
    addParameter(parser, 'OutputClass', '', @(value) ischar(value) || isstring(value));
    addParameter(parser, 'CollisionPolicy', 'overwrite', ...
        @(value) ischar(value) || isstring(value));
    parse(parser, varargin{:});

    binaryMode = logical(parser.Results.Binary);
    explicitObjectValues = parser.Results.ObjectValues;
    explicitLabels = parser.Results.Labels;

    if binaryMode && (~isempty(explicitObjectValues) || ~isempty(explicitLabels))
        error('Binary mode cannot be combined with ObjectValues or Labels.');
    end

    if ~isempty(explicitObjectValues) && ~isempty(explicitLabels)
        explicitObjectValues = double(explicitObjectValues(:).');
        explicitLabels = double(explicitLabels(:).');
        if ~isequal(explicitObjectValues, explicitLabels)
            error('ObjectValues and Labels are aliases and must match if both are provided.');
        end
    end

    if binaryMode
        objectValues = ones(1, objectCount);
    elseif ~isempty(explicitObjectValues)
        objectValues = explicitObjectValues;
    elseif ~isempty(explicitLabels)
        objectValues = explicitLabels;
    else
        objectValues = 1:objectCount;
    end

    objectValues = double(objectValues(:).');
    if numel(objectValues) ~= objectCount
        error('ObjectValues must contain one value per object.');
    end

    if any(~isfinite(objectValues)) || any(mod(objectValues, 1) ~= 0) || any(objectValues < 1)
        error('ObjectValues must be positive integer values. Value 0 is reserved for background.');
    end

    outputClass = char(parser.Results.OutputClass);
    if isempty(outputClass)
        outputClass = chooseDefaultOutputClass(objectValues, binaryMode);
    end

    validateOutputClass(outputClass, objectValues);

    collisionPolicy = lower(char(parser.Results.CollisionPolicy));
    allowedPolicies = {'overwrite', 'first', 'error'};
    if ~any(strcmp(collisionPolicy, allowedPolicies))
        error('CollisionPolicy must be ''overwrite'', ''first'', or ''error''.');
    end

    options.ObjectValues = objectValues;
    options.Labels = objectValues;
    options.Binary = binaryMode;
    options.OutputClass = outputClass;
    options.CollisionPolicy = collisionPolicy;
end

function outputClass = chooseDefaultOutputClass(objectValues, binaryMode)
% chooseDefaultOutputClass Use compact integer storage when possible.

    if binaryMode
        outputClass = 'logical';
    elseif isempty(objectValues) || max(objectValues) <= double(intmax('uint16'))
        outputClass = 'uint16';
    else
        outputClass = 'uint32';
    end
end

function validateOutputClass(outputClass, labels)
% validateOutputClass Check that requested label type can store all labels.

    allowedClasses = {'logical', 'uint8', 'uint16', 'uint32', 'uint64', 'single', 'double'};
    if ~any(strcmp(outputClass, allowedClasses))
        error('OutputClass must be logical, uint8, uint16, uint32, uint64, single, or double.');
    end

    switch outputClass
        case 'logical'
            maximumRepresentableLabel = 1;
        case 'uint8'
            maximumRepresentableLabel = double(intmax('uint8'));
        case 'uint16'
            maximumRepresentableLabel = double(intmax('uint16'));
        case 'uint32'
            maximumRepresentableLabel = double(intmax('uint32'));
        case 'uint64'
            maximumRepresentableLabel = double(intmax('uint64'));
        otherwise
            maximumRepresentableLabel = realmax(outputClass);
    end

    if ~isempty(labels) && max(labels) > maximumRepresentableLabel
        error('Labels do not fit in OutputClass %s.', outputClass);
    end
end

function currentObjectIndices = validateObjectIndices(currentObjectIndices, objectIndex, voxelCount)
% validateObjectIndices Protect against writing outside the label volume.

    currentObjectIndices = double(currentObjectIndices(:));
    if any(~isfinite(currentObjectIndices)) || ...
            any(mod(currentObjectIndices, 1) ~= 0) || ...
            any(currentObjectIndices < 1) || any(currentObjectIndices > voxelCount)
        error('objectIndices{%d} contains invalid linear indices.', objectIndex);
    end
end

function [validatedObjectIndices, rawVoxelCounts, uniqueVoxelCounts] = ...
        validateAllObjectIndices(objectIndices, voxelCount)
% validateAllObjectIndices Validate once and remove within-object duplicates.
%
% Duplicate indices within one object do not change the label mask, but they
% would falsely look like overlap if we counted all indices together. Each
% object is therefore reduced to its unique voxel list before overlap stats
% and label writing.

    objectCount = numel(objectIndices);
    validatedObjectIndices = cell(objectCount, 1);
    rawVoxelCounts = zeros(objectCount, 1);
    uniqueVoxelCounts = zeros(objectCount, 1);

    for objectIndex = 1:objectCount
        currentObjectIndices = objectIndices{objectIndex};

        if isempty(currentObjectIndices)
            currentObjectIndices = zeros(0, 1);
        else
            currentObjectIndices = validateObjectIndices( ...
                currentObjectIndices, objectIndex, voxelCount);
        end

        rawVoxelCounts(objectIndex) = numel(currentObjectIndices);
        currentObjectIndices = unique(currentObjectIndices);
        uniqueVoxelCounts(objectIndex) = numel(currentObjectIndices);
        validatedObjectIndices{objectIndex} = currentObjectIndices;
    end
end

function overlapInfo = computeOverlapInfo( ...
        validatedObjectIndices, rawVoxelCounts, uniqueVoxelCounts, labels)
% computeOverlapInfo Report order-independent overlap diagnostics.
%
% A voxel is considered overlapping for an object if the same global voxel
% index appears in that object and in at least one other object. This is
% intentionally independent of CollisionPolicy: the diagnostic should tell
% you about the input geometry, not about which label-writing rule was used.

    objectCount = numel(validatedObjectIndices);
    overlapInfo = repmat(createEmptyOverlapInfo(), objectCount, 1);

    if objectCount == 0
        return
    end

    allObjectVoxels = vertcat(validatedObjectIndices{:});
    if isempty(allObjectVoxels)
        for objectIndex = 1:objectCount
            overlapInfo(objectIndex) = fillBasicOverlapFields( ...
                objectIndex, labels, rawVoxelCounts, uniqueVoxelCounts);
        end
        return
    end

    [uniqueGlobalVoxels, ~, globalVoxelGroups] = unique(allObjectVoxels);
    objectMembershipCounts = accumarray(globalVoxelGroups, 1);
    overlappingGlobalVoxels = uniqueGlobalVoxels(objectMembershipCounts > 1);

    for objectIndex = 1:objectCount
        currentObjectIndices = validatedObjectIndices{objectIndex};
        overlapInfo(objectIndex) = fillBasicOverlapFields( ...
            objectIndex, labels, rawVoxelCounts, uniqueVoxelCounts);

        if isempty(currentObjectIndices)
            continue
        end

        objectOverlapMask = ismember(currentObjectIndices, overlappingGlobalVoxels);
        overlappingVoxelCount = nnz(objectOverlapMask);

        overlapInfo(objectIndex).OverlappingVoxelCount = overlappingVoxelCount;
        overlapInfo(objectIndex).OverlappingVoxelPercent = ...
            100 * overlappingVoxelCount / uniqueVoxelCounts(objectIndex);

        if overlappingVoxelCount > 0
            overlappingObjectIndices = findObjectsSharingVoxels( ...
                currentObjectIndices(objectOverlapMask), validatedObjectIndices, objectIndex);
            overlapInfo(objectIndex).OverlappingObjectIndices = overlappingObjectIndices;
            overlapInfo(objectIndex).OverlappingLabels = labels(overlappingObjectIndices);
        end
    end
end

function overlapInfo = fillBasicOverlapFields( ...
        objectIndex, labels, rawVoxelCounts, uniqueVoxelCounts)
% fillBasicOverlapFields Store counts that do not depend on other objects.

    overlapInfo = createEmptyOverlapInfo();
    overlapInfo.ObjectIndex = objectIndex;
    overlapInfo.Label = labels(objectIndex);
    overlapInfo.RawVoxelCount = rawVoxelCounts(objectIndex);
    overlapInfo.VoxelCount = uniqueVoxelCounts(objectIndex);
    overlapInfo.DuplicateVoxelCount = rawVoxelCounts(objectIndex) - uniqueVoxelCounts(objectIndex);
end

function overlappingObjectIndices = findObjectsSharingVoxels( ...
        overlappingVoxels, validatedObjectIndices, currentObjectIndex)
% findObjectsSharingVoxels List which other objects share any overlap voxel.

    objectCount = numel(validatedObjectIndices);
    sharesVoxel = false(objectCount, 1);

    for otherObjectIndex = 1:objectCount
        if otherObjectIndex == currentObjectIndex || isempty(validatedObjectIndices{otherObjectIndex})
            continue
        end

        sharesVoxel(otherObjectIndex) = any( ...
            ismember(overlappingVoxels, validatedObjectIndices{otherObjectIndex}));
    end

    overlappingObjectIndices = find(sharesVoxel).';
end

function overlapInfo = createEmptyOverlapInfo()
% createEmptyOverlapInfo Default diagnostics for one object.

    overlapInfo = struct( ...
        'ObjectIndex', 0, ...
        'Label', 0, ...
        'RawVoxelCount', 0, ...
        'VoxelCount', 0, ...
        'DuplicateVoxelCount', 0, ...
        'OverlappingVoxelCount', 0, ...
        'OverlappingVoxelPercent', 0, ...
        'OverlappingObjectIndices', [], ...
        'OverlappingLabels', []);
end
