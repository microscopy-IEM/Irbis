% compare the selected irbis structure againts the base structure

function compareIrbisFileAgaintsBaseStructure()
    [fileName,path] = uigetfile('*.irbis','Select .irbis file','MultiSelect','off');

    irbisFileStruct = importdata([path '\' fileName]);

    modalities = fieldnames(irbisFileStruct);

    for modalityNum = 1:numel(modalities)
        modality = modalities{modalityNum};

        baseRoot = getBaseStruct(modality);
        validateStructAndPrintDifferences(irbisFileStruct.(modality),baseRoot.(modality))
    end
end