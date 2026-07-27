function generateObjectConnectionReferenceDocs(sourceFile, outputFile)
% generateObjectConnectionReferenceDocs Generate object connection docs.

    if nargin < 1 || isempty(sourceFile)
        sourceFile = which("assignGroupIdsGreedily");
    end

    if nargin < 2 || isempty(outputFile)
        outputFile = fullfile(pwd, "docs", "reference", "object-connection", "greedy-object-connection.md");
    end

    docgen.generateDocPageReferenceDocs( ...
        sourceFile, ...
        outputFile, ...
        "Greedy object connection in time", ...
        "This page describes the greedy matching procedure used to assign group IDs to model objects across consecutive time points.");
end
