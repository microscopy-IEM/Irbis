function [croppedMasks, cropInfo] = objectVoxelIndicesToCroppedMasks(objectIndices, gridSize, varargin)
% objectVoxelIndicesToCroppedMasks Create one cropped mask per object.
%
%   croppedMasks = objectVoxelIndicesToCroppedMasks(objectIndices, gridSize)
%   returns a cell array where croppedMasks{i} is the smallest [Y X Z] mask
%   containing object i.
%
%   [croppedMasks, cropInfo] = objectVoxelIndicesToCroppedMasks(...)
%   also returns per-object crop bounds. The bounds are global voxel limits,
%   so a voxel in croppedMasks{i} can be mapped back to the full image.
%
%   This function is useful when you do not need one full global label image.
%   It uses the same object index lists as objectVoxelIndicesToLabelMask, but
%   each object is written into its own local array.
%
%   Name-value options:
%     ObjectValues  Value written for each object. Default: 1:nObjects.
%     Labels        Alias for ObjectValues, kept for consistency.
%     Binary        true writes all objects as 1 in logical crops. Default:
%                   false.
%     OutputClass   Output class. Default: uint16/uint32, or logical in
%                   Binary mode.
%     CropPadding   Extra voxels around each crop, in [y x z] order.
%                   Scalar or three-element vector. Default: 0.
%
%   Example:
%     [croppedMasks, cropInfo] = objectVoxelIndicesToCroppedMasks( ...
%         objectIndices, [248 776 41], 'Binary', true, 'CropPadding', 2);

    if ~iscell(objectIndices)
        error('objectIndices must be a cell array.');
    end

    gridSize = validateGridSize(gridSize);
    options = parseCroppedMaskOptions(numel(objectIndices), varargin{:});
    fullVolumeVoxelCount = prod(gridSize);

    objectCount = numel(objectIndices);
    croppedMasks = cell(objectCount, 1);
    cropInfo = repmat(createEmptyCropInfo(), objectCount, 1);

    for objectIndex = 1:objectCount
        currentObjectIndices = validateObjectIndices( ...
            objectIndices{objectIndex}, objectIndex, fullVolumeVoxelCount);

        rawVoxelCount = numel(currentObjectIndices);
        currentObjectIndices = unique(currentObjectIndices);

        cropInfo(objectIndex).ObjectIndex = objectIndex;
        cropInfo(objectIndex).ObjectValue = options.ObjectValues(objectIndex);
        cropInfo(objectIndex).RawVoxelCount = rawVoxelCount;
        cropInfo(objectIndex).VoxelCount = numel(currentObjectIndices);
        cropInfo(objectIndex).DuplicateVoxelCount = rawVoxelCount - numel(currentObjectIndices);

        if isempty(currentObjectIndices)
            croppedMasks{objectIndex} = zeros([0 0 0], options.OutputClass);
            continue
        end

        [globalY, globalX, globalZ] = ind2sub(gridSize, currentObjectIndices);
        [yLimits, xLimits, zLimits] = computeCropLimits( ...
            globalY, globalX, globalZ, gridSize, options.CropPadding);

        localGridSize = [diff(yLimits) + 1, diff(xLimits) + 1, diff(zLimits) + 1];
        localMask = zeros(localGridSize, options.OutputClass);

        localY = globalY - yLimits(1) + 1;
        localX = globalX - xLimits(1) + 1;
        localZ = globalZ - zLimits(1) + 1;
        localIndices = sub2ind(localGridSize, localY, localX, localZ);

        localMask(localIndices) = cast(options.ObjectValues(objectIndex), options.OutputClass);
        croppedMasks{objectIndex} = localMask;

        cropInfo(objectIndex).IsEmpty = false;
        cropInfo(objectIndex).YLimits = yLimits;
        cropInfo(objectIndex).XLimits = xLimits;
        cropInfo(objectIndex).ZLimits = zLimits;
        cropInfo(objectIndex).LocalGridSize = localGridSize;
    end
end

function gridSize = validateGridSize(gridSize)
% validateGridSize Ensure the source volume size is a valid [ny nx nz] vector.

    gridSize = double(gridSize(:).');
    if numel(gridSize) ~= 3 || any(~isfinite(gridSize)) || ...
            any(gridSize < 1) || any(mod(gridSize, 1) ~= 0)
        error('gridSize must contain three positive integer values.');
    end
end

function options = parseCroppedMaskOptions(objectCount, varargin)
% parseCroppedMaskOptions Validate crop-mask value and padding options.

    parser = inputParser;
    addParameter(parser, 'ObjectValues', [], @(value) isnumeric(value) && isvector(value));
    addParameter(parser, 'Labels', [], @(value) isnumeric(value) && isvector(value));
    addParameter(parser, 'Binary', false, ...
        @(value) (islogical(value) || isnumeric(value)) && isscalar(value) && ...
        (islogical(value) || value == 0 || value == 1));
    addParameter(parser, 'OutputClass', '', @(value) ischar(value) || isstring(value));
    addParameter(parser, 'CropPadding', 0, ...
        @(value) isnumeric(value) && (isscalar(value) || numel(value) == 3));
    parse(parser, varargin{:});

    options.Binary = logical(parser.Results.Binary);
    options.ObjectValues = parseObjectValues( ...
        objectCount, parser.Results.ObjectValues, parser.Results.Labels, options.Binary);

    outputClass = char(parser.Results.OutputClass);
    if isempty(outputClass)
        outputClass = chooseDefaultOutputClass(options.ObjectValues, options.Binary);
    end
    validateOutputClass(outputClass, options.ObjectValues);
    options.OutputClass = outputClass;

    cropPadding = double(parser.Results.CropPadding(:).');
    if isscalar(cropPadding)
        cropPadding = repmat(cropPadding, 1, 3);
    end

    if any(~isfinite(cropPadding)) || any(cropPadding < 0) || any(mod(cropPadding, 1) ~= 0)
        error('CropPadding must contain non-negative integer values.');
    end

    options.CropPadding = cropPadding;
end

function objectValues = parseObjectValues(objectCount, objectValues, labels, binaryMode)
% parseObjectValues Resolve ObjectValues/Labels aliases and Binary mode.

    if binaryMode && (~isempty(objectValues) || ~isempty(labels))
        error('Binary mode cannot be combined with ObjectValues or Labels.');
    end

    if ~isempty(objectValues) && ~isempty(labels)
        objectValues = double(objectValues(:).');
        labels = double(labels(:).');
        if ~isequal(objectValues, labels)
            error('ObjectValues and Labels are aliases and must match if both are provided.');
        end
    end

    if binaryMode
        objectValues = ones(1, objectCount);
    elseif ~isempty(objectValues)
        objectValues = double(objectValues(:).');
    elseif ~isempty(labels)
        objectValues = double(labels(:).');
    else
        objectValues = 1:objectCount;
    end

    if numel(objectValues) ~= objectCount
        error('ObjectValues must contain one value per object.');
    end

    if any(~isfinite(objectValues)) || any(mod(objectValues, 1) ~= 0) || any(objectValues < 1)
        error('ObjectValues must be positive integer values. Value 0 is reserved for background.');
    end
end

function outputClass = chooseDefaultOutputClass(objectValues, binaryMode)
% chooseDefaultOutputClass Use logical crops for binary masks by default.

    if binaryMode
        outputClass = 'logical';
    elseif isempty(objectValues) || max(objectValues) <= double(intmax('uint16'))
        outputClass = 'uint16';
    else
        outputClass = 'uint32';
    end
end

function validateOutputClass(outputClass, objectValues)
% validateOutputClass Check that requested output type can store values.

    allowedClasses = {'logical', 'uint8', 'uint16', 'uint32', 'uint64', 'single', 'double'};
    if ~any(strcmp(outputClass, allowedClasses))
        error('OutputClass must be logical, uint8, uint16, uint32, uint64, single, or double.');
    end

    switch outputClass
        case 'logical'
            maximumRepresentableValue = 1;
        case 'uint8'
            maximumRepresentableValue = double(intmax('uint8'));
        case 'uint16'
            maximumRepresentableValue = double(intmax('uint16'));
        case 'uint32'
            maximumRepresentableValue = double(intmax('uint32'));
        case 'uint64'
            maximumRepresentableValue = double(intmax('uint64'));
        otherwise
            maximumRepresentableValue = realmax(outputClass);
    end

    if ~isempty(objectValues) && max(objectValues) > maximumRepresentableValue
        error('ObjectValues do not fit in OutputClass %s.', outputClass);
    end
end

function currentObjectIndices = validateObjectIndices(currentObjectIndices, objectIndex, voxelCount)
% validateObjectIndices Protect against reading outside the source volume.

    if isempty(currentObjectIndices)
        currentObjectIndices = zeros(0, 1);
        return
    end

    currentObjectIndices = double(currentObjectIndices(:));
    if any(~isfinite(currentObjectIndices)) || ...
            any(mod(currentObjectIndices, 1) ~= 0) || ...
            any(currentObjectIndices < 1) || any(currentObjectIndices > voxelCount)
        error('objectIndices{%d} contains invalid linear indices.', objectIndex);
    end
end

function [yLimits, xLimits, zLimits] = computeCropLimits( ...
        globalY, globalX, globalZ, gridSize, cropPadding)
% computeCropLimits Return inclusive global bounds for one padded object crop.

    yLimits = [max(1, min(globalY) - cropPadding(1)), ...
        min(gridSize(1), max(globalY) + cropPadding(1))];
    xLimits = [max(1, min(globalX) - cropPadding(2)), ...
        min(gridSize(2), max(globalX) + cropPadding(2))];
    zLimits = [max(1, min(globalZ) - cropPadding(3)), ...
        min(gridSize(3), max(globalZ) + cropPadding(3))];
end

function cropInfo = createEmptyCropInfo()
% createEmptyCropInfo Default metadata for an empty cropped object.

    cropInfo = struct( ...
        'ObjectIndex', 0, ...
        'ObjectValue', 0, ...
        'IsEmpty', true, ...
        'RawVoxelCount', 0, ...
        'VoxelCount', 0, ...
        'DuplicateVoxelCount', 0, ...
        'YLimits', [NaN NaN], ...
        'XLimits', [NaN NaN], ...
        'ZLimits', [NaN NaN], ...
        'LocalGridSize', [0 0 0]);
end
