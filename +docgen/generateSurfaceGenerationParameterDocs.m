function generateSurfaceGenerationParameterDocs(sourceFile, outputFile)
% generateSurfaceGenerationParameterDocs Generate surface parameter docs.
%
% The page is generated from IsosurfaceGenerator properties. Default values
% are evaluated through getDefaultParameters so the documentation follows the
% class behavior, while descriptions stay close to the property comments.

    if nargin < 1 || isempty(sourceFile)
        sourceFile = which("IsosurfaceGenerator");
    end

    if nargin < 2 || isempty(outputFile)
        outputFile = fullfile(pwd, "docs", "reference", "spine-generation-parameters", "surface-generation-parameters.md");
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found.");
    end

    defaults = IsosurfaceGenerator.getDefaultParameters();
    docgen.generateClassPropertyReferenceDocs( ...
        sourceFile, ...
        outputFile, ...
        "IsosurfaceGenerator", ...
        "Surface generation parameters", ...
        "This page describes 3D surface reconstruction parameters used by `IsosurfaceGenerator`.", ...
        defaults, ...
        "Core reconstruction", ...
        "These parameters are returned by `IsosurfaceGenerator.getDefaultParameters()` but were not found in the parsed properties block.");
end
