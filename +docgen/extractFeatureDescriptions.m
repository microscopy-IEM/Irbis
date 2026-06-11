function features = extractFeatureDescriptions(sourceFile)
% extractFeatureDescriptions Parse %DOC_FEATURE blocks from a MATLAB source file.
%
% Supported format:
%
% %DOC_FEATURE volume
% % Meaning: Enclosed volume of the reconstructed mesh.
% % Formula: V
% % Units: µm³

    if nargin < 1 || isempty(sourceFile)
        sourceFile = which("ObjectFeatureExtractor");
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found.");
    end

    lines = splitlines(string(fileread(sourceFile)));

    features = struct( ...
        "name", {}, ...
        "meaning", {}, ...
        "formula", {}, ...
        "units", {} ...
    );

    current = emptyFeature();

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        if startsWith(line, "%") && contains(line, "DOC_FEATURE")
            if current.name ~= ""
                features(end+1) = current; %ok<AGROW>
            end

            current = emptyFeature();
            current.name = strtrim(extractAfter(line, "DOC_FEATURE"));

        elseif current.name ~= "" && startsWith(line, "%")
            cleaned = strtrim(extractAfter(line, "%"));

            if startsWith(cleaned, "Meaning:")
                current.meaning = strtrim(extractAfter(cleaned, "Meaning:"));

            elseif startsWith(cleaned, "Formula:")
                current.formula = strtrim(extractAfter(cleaned, "Formula:"));

            elseif startsWith(cleaned, "Units:")
                current.units = strtrim(extractAfter(cleaned, "Units:"));

            elseif startsWith(line, "%DOC_")
                break
            end
        end
    end

    if current.name ~= ""
        features(end+1) = current;
    end
end

function feature = emptyFeature()

    feature = struct( ...
        "name", "", ...
        "meaning", "", ...
        "formula", "", ...
        "units", "" ...
    );
end