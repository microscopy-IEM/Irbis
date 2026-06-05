function generateDocumentation()
    docgen.generateIrbisTableDocs("./docs/reference/parameters")
    docgen.generateStructureOverviewDocs("getBaseStruct.m", "./docs/reference/irbis-file-structure.md")
    docgen.generateFeatureDescriptionDocs("ObjectFeatureExtractor.m", "./docs/reference/parameters/object-features.md")
end