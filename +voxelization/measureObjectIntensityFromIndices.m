function [intensityStats, objectIntensityValues] = measureObjectIntensityFromIndices( ...
        objectIndices, intensityChannel, varargin)
% measureObjectIntensityFromIndices Measure signal values under object masks.
%
%   intensityStats = measureObjectIntensityFromIndices(objectIndices, intensityChannel)
%   measures mean and standard deviation of intensity values for each object.
%
%   objectIndices is a cell array where objectIndices{i} contains global
%   linear indices for object i. These are the indices produced by
%   meshObjectsToVoxelIndices.
%
%   intensityChannel is the 3-D image/channel to sample. It must use the same
%   array indexing as the voxel space used to create objectIndices. In this
%   project that means [Y X Z], matching gridSize = [ny nx nz].
%
%   intensityStats is a table with one row per object. By default it includes:
%     ObjectIndex
%     Label
%     RawVoxelCount          Number of input indices for this object.
%     VoxelCount             Number of indices sampled from intensityChannel.
%     MeasurementVoxelCount  Number of voxels used for mean/std.
%     NaNVoxelCount          Number of NaN-valued voxels in the object.
%     MeanIntensity
%     StdIntensity
%
%   [intensityStats, objectIntensityValues] = measureObjectIntensityFromIndices(...)
%   also returns the sampled intensity values for each object as a cell array.
%   These values are after optional duplicate removal, but before NaN omission.
%
%   Name-value options:
%     Labels            Label value for each object. Default: 1:nObjects.
%     NanPolicy         'omitnan' or 'includenan'. Default: 'omitnan'.
%                       With 'omitnan', NaN values are excluded from mean/std.
%     UseUniqueVoxels   Remove duplicate indices within each object before
%                       measuring. Default: false.
%     StdNormalization  Normalization passed to std. Use 0 for MATLAB default
%                       sample normalization, or 1 for population
%                       normalization. Default: 0.
%
%   Example:
%     intensityStats = measureObjectIntensityFromIndices( ...
%         objectIndices, inputChannel);
%
%     disp(intensityStats(:, ["ObjectIndex", "MeanIntensity", "StdIntensity"]))

    if ~iscell(objectIndices)
        error('objectIndices must be a cell array.');
    end

    validateIntensityChannel(intensityChannel);

    objectCount = numel(objectIndices);
    options = parseIntensityMeasurementOptions(objectCount, varargin{:});
    channelVoxelCount = numel(intensityChannel);

    if nargout > 1
        objectIntensityValues = cell(objectCount, 1);
    end

    objectIndexColumn = (1:objectCount).';
    labelColumn = options.Labels(:);
    rawVoxelCountColumn = zeros(objectCount, 1);
    voxelCountColumn = zeros(objectCount, 1);
    measurementVoxelCountColumn = zeros(objectCount, 1);
    nanVoxelCountColumn = zeros(objectCount, 1);
    meanIntensityColumn = NaN(objectCount, 1);
    stdIntensityColumn = NaN(objectCount, 1);

    for objectIndex = 1:objectCount
        currentObjectIndices = validateObjectIndices( ...
            objectIndices{objectIndex}, objectIndex, channelVoxelCount);

        rawVoxelCountColumn(objectIndex) = numel(currentObjectIndices);

        % By default, preserve the index list exactly as provided. This means
        % duplicate voxels contribute repeatedly to the measured mean/std.
        % Set UseUniqueVoxels to true only when duplicate entries should be
        % collapsed before sampling intensity values.
        if options.UseUniqueVoxels
            currentObjectIndices = unique(currentObjectIndices);
        end

        voxelCountColumn(objectIndex) = numel(currentObjectIndices);

        if isempty(currentObjectIndices)
            if nargout > 1
                objectIntensityValues{objectIndex} = zeros(0, 1);
            end
            continue
        end

        currentIntensityValues = double(intensityChannel(currentObjectIndices));
        currentIntensityValues = currentIntensityValues(:);

        if nargout > 1
            objectIntensityValues{objectIndex} = currentIntensityValues;
        end

        nanVoxelCountColumn(objectIndex) = nnz(isnan(currentIntensityValues));

        switch options.NanPolicy
            case 'omitnan'
                valuesForMeasurement = currentIntensityValues(~isnan(currentIntensityValues));

            case 'includenan'
                valuesForMeasurement = currentIntensityValues;
        end

        measurementVoxelCountColumn(objectIndex) = numel(valuesForMeasurement);

        if isempty(valuesForMeasurement)
            continue
        end

        meanIntensityColumn(objectIndex) = mean(valuesForMeasurement);
        stdIntensityColumn(objectIndex) = std( ...
            valuesForMeasurement, options.StdNormalization);
    end

    intensityStats = table( ...
        objectIndexColumn, ...
        labelColumn, ...
        rawVoxelCountColumn, ...
        voxelCountColumn, ...
        measurementVoxelCountColumn, ...
        nanVoxelCountColumn, ...
        meanIntensityColumn, ...
        stdIntensityColumn, ...
        'VariableNames', { ...
            'ObjectIndex', ...
            'Label', ...
            'RawVoxelCount', ...
            'VoxelCount', ...
            'MeasurementVoxelCount', ...
            'NaNVoxelCount', ...
            'MeanIntensity', ...
            'StdIntensity'});
end

function validateIntensityChannel(intensityChannel)
% validateIntensityChannel Check that the channel can be indexed and measured.

    if ~(isnumeric(intensityChannel) || islogical(intensityChannel))
        error('intensityChannel must be a numeric or logical array.');
    end

    if isempty(intensityChannel)
        error('intensityChannel must not be empty.');
    end
end

function options = parseIntensityMeasurementOptions(objectCount, varargin)
% parseIntensityMeasurementOptions Validate labels and measurement behavior.

    parser = inputParser;
    addParameter(parser, 'Labels', [], @(value) isnumeric(value) && isvector(value));
    addParameter(parser, 'NanPolicy', 'omitnan', @(value) ischar(value) || isstring(value));
    addParameter(parser, 'UseUniqueVoxels', false, ...
        @(value) islogical(value) && isscalar(value));
    addParameter(parser, 'StdNormalization', 0, ...
        @(value) isnumeric(value) && isscalar(value) && (value == 0 || value == 1));
    parse(parser, varargin{:});

    labels = parser.Results.Labels;
    if isempty(labels)
        labels = 1:objectCount;
    end

    labels = double(labels(:).');
    if numel(labels) ~= objectCount
        error('Labels must contain one value per object.');
    end

    if any(~isfinite(labels)) || any(mod(labels, 1) ~= 0)
        error('Labels must contain finite integer values.');
    end

    nanPolicy = lower(char(parser.Results.NanPolicy));
    allowedNanPolicies = {'omitnan', 'includenan'};
    if ~any(strcmp(nanPolicy, allowedNanPolicies))
        error('NanPolicy must be ''omitnan'' or ''includenan''.');
    end

    options.Labels = labels;
    options.NanPolicy = nanPolicy;
    options.UseUniqueVoxels = parser.Results.UseUniqueVoxels;
    options.StdNormalization = double(parser.Results.StdNormalization);
end

function currentObjectIndices = validateObjectIndices( ...
        currentObjectIndices, objectIndex, channelVoxelCount)
% validateObjectIndices Protect against sampling outside intensityChannel.

    if isempty(currentObjectIndices)
        currentObjectIndices = zeros(0, 1);
        return
    end

    currentObjectIndices = double(currentObjectIndices(:));
    if any(~isfinite(currentObjectIndices)) || ...
            any(mod(currentObjectIndices, 1) ~= 0) || ...
            any(currentObjectIndices < 1) || any(currentObjectIndices > channelVoxelCount)
        error('objectIndices{%d} contains invalid linear indices for intensityChannel.', ...
            objectIndex);
    end
end
