function generateDocumentation()
    docgen.generateIrbisTableDocs("./docs/reference/parameters")
    docgen.generateStructureOverviewDocs("getBaseStruct.m", "./docs/reference/irbis-file-structure.md")
    docgen.generateFeatureDescriptionDocs("ObjectFeatureExtractor.m", "./docs/reference/parameters/object-features.md")
    docgen.generateSurfaceGenerationParameterDocs("IsosurfaceGenerator.m", "./docs/reference/spine-generation-parameters/surface-generation-parameters.md")
    docgen.generateAdaptiveShaftGenerationParameterDocs("AdaptiveShaftGenerator.m", "./docs/reference/spine-generation-parameters/adaptive-shaft-generation-parameters.md")
    docgen.generateObjectConnectionReferenceDocs("assignGroupIdsGreedily.m", "./docs/reference/spine-generation-parameters/greedy-object-connection.md")
    docgen.generateTutorialSnippets()
end
