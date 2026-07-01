function maskedImage = applyMaskToImage(rawImage, mask, varargin)
% applyMaskToImage Set foreground and/or background values in a raw image.
%
%   maskedImage = applyMaskToImage(rawImage, mask)
%   returns rawImage with background voxels set to 0. Foreground voxels keep
%   their original raw intensity values. Foreground is defined as mask ~= 0.
%
%   maskedImage = applyMaskToImage(rawImage, mask, ...)
%   lets you choose whether background, foreground, or both are overwritten.
%   Pass [] for either value to keep that region unchanged.
%
%   Name-value options:
%     BackgroundValue       Value assigned where mask is background.
%                           Default: 0. Use [] to keep background unchanged.
%     ForegroundValue       Value assigned where mask is foreground.
%                           Default: [] keeps original foreground intensities.
%     ForegroundMaskValues  Label values treated as foreground. Default: []
%                           means all nonzero mask voxels are foreground.
%     InvertMask            Swap foreground/background after selecting the
%                           foreground mask. Default: false.
%     OutputClass           Class of maskedImage. Default: class(rawImage).
%
%   Examples:
%     % Keep object intensities, set outside to 0.
%     maskedImage = applyMaskToImage(rawImage, labelMask);
%
%     % Create a constant-valued binary-looking image in raw image space.
%     maskedImage = applyMaskToImage(rawImage, labelMask, ...
%         'BackgroundValue', 0, 'ForegroundValue', 1, 'OutputClass', 'double');
%
%     % Keep only labels 3 and 7 as foreground.
%     maskedImage = applyMaskToImage(rawImage, labelMask, ...
%         'ForegroundMaskValues', [3 7]);

    validateRawImageAndMask(rawImage, mask);
    options = parseMaskingOptions(rawImage, varargin{:});

    foregroundMask = createForegroundMask(mask, options.ForegroundMaskValues);
    if options.InvertMask
        foregroundMask = ~foregroundMask;
    end

    maskedImage = cast(rawImage, options.OutputClass);

    if ~isempty(options.BackgroundValue)
        maskedImage(~foregroundMask) = cast(options.BackgroundValue, options.OutputClass);
    end

    if ~isempty(options.ForegroundValue)
        maskedImage(foregroundMask) = cast(options.ForegroundValue, options.OutputClass);
    end
end

function validateRawImageAndMask(rawImage, mask)
% validateRawImageAndMask Ensure image and mask can be indexed together.

    if ~(isnumeric(rawImage) || islogical(rawImage))
        error('rawImage must be a numeric or logical array.');
    end

    if ~(isnumeric(mask) || islogical(mask))
        error('mask must be a numeric or logical array.');
    end

    if ~isequal(size(rawImage), size(mask))
        error('rawImage and mask must have the same size.');
    end
end

function options = parseMaskingOptions(rawImage, varargin)
% parseMaskingOptions Validate user choices for region replacement.

    scalarOrEmpty = @(value) isempty(value) || ...
        ((isnumeric(value) || islogical(value)) && isscalar(value));

    parser = inputParser;
    addParameter(parser, 'BackgroundValue', 0, scalarOrEmpty);
    addParameter(parser, 'ForegroundValue', [], scalarOrEmpty);
    addParameter(parser, 'ForegroundMaskValues', [], ...
        @(value) isnumeric(value) || islogical(value));
    addParameter(parser, 'InvertMask', false, ...
        @(value) (islogical(value) || isnumeric(value)) && isscalar(value) && ...
        (islogical(value) || value == 0 || value == 1));
    addParameter(parser, 'OutputClass', class(rawImage), ...
        @(value) ischar(value) || isstring(value));
    parse(parser, varargin{:});

    outputClass = char(parser.Results.OutputClass);
    validateImageOutputClass(outputClass);

    options.BackgroundValue = parser.Results.BackgroundValue;
    options.ForegroundValue = parser.Results.ForegroundValue;
    options.ForegroundMaskValues = parser.Results.ForegroundMaskValues;
    options.InvertMask = logical(parser.Results.InvertMask);
    options.OutputClass = outputClass;
end

function foregroundMask = createForegroundMask(mask, foregroundMaskValues)
% createForegroundMask Convert a label/binary mask into a logical selector.

    if isempty(foregroundMaskValues)
        foregroundMask = mask ~= 0;
    else
        foregroundMask = ismember(mask, foregroundMaskValues);
    end
end

function validateImageOutputClass(outputClass)
% validateImageOutputClass Restrict output to common image-compatible classes.

    allowedClasses = {'logical', 'uint8', 'uint16', 'uint32', 'uint64', ...
        'int8', 'int16', 'int32', 'int64', 'single', 'double'};
    if ~any(strcmp(outputClass, allowedClasses))
        error(['OutputClass must be logical, an integer class, single, ', ...
            'or double.']);
    end
end
