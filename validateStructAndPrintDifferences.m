function validateStructAndPrintDifferences(loadedStruct, baseStruct)
    if ~isstruct(loadedStruct)
        return  
    end
    baseFields = fieldnames(baseStruct);
    for i = 1:length(baseFields)
        field = baseFields{i};
        if ~isfield(loadedStruct, field)
            disp([field '    missing in:'])
            disp(loadedStruct)
        elseif isstruct(baseStruct.(field)) && isstruct(loadedStruct.(field))
            loadedStruct.(field) = validateAndUpdateStruct(loadedStruct.(field), baseStruct.(field));
        end
    end

    loadedFields = fieldnames(loadedStruct);
    for i = 1:length(loadedFields)
        field = loadedFields{i};
        if ~isfield(baseStruct, field)
            disp([field '    surplus in:'])
            disp(loadedStruct)
        end
    end
end
