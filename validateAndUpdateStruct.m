function updatedStruct = validateAndUpdateStruct(loadedStruct, baseStruct)
    % Add missing fields from baseStruct to loadedStruct
    baseFields = fieldnames(baseStruct);
    for i = 1:length(baseFields)
        field = baseFields{i};
        if ~isfield(loadedStruct, field)
            loadedStruct.(field) = baseStruct.(field);
        elseif isstruct(baseStruct.(field)) && isstruct(loadedStruct.(field))
            % Recursively validate and update sub-structures
            loadedStruct.(field) = validateAndUpdateStruct(loadedStruct.(field), baseStruct.(field));
        end
    end

    % Remove extra fields from loadedStruct that are not in baseStruct
    loadedFields = fieldnames(loadedStruct);
    for i = 1:length(loadedFields)
        field = loadedFields{i};
        if ~isfield(baseStruct, field)
            loadedStruct = rmfield(loadedStruct, field);
        end
    end

    updatedStruct = loadedStruct;
end
