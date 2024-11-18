function processedStruct = processDataForResultsViewer(inputStruct)

    % find the table - different name based on modality
    if isfield(inputStruct, 'List')
        listArray = inputStruct.List;
    elseif isfield(inputStruct, 'tracksList')
        listArray = inputStruct.tracksList;
    elseif isfield(inputStruct, 'pointsList')
        listArray = input.pointsList;
    else
        processedStruct = [];
        return
    end

    combinedList = combineTableAcrossTimepoints(listArray);
    if ~isempty(combinedList)
        processedStruct.combinedList = combinedList;
        if isfield(inputStruct, 'storedCategorizations')
            processedStruct.storedCategorizations = inputStruct.storedCategorizations;
        else
            processedStruct.storedCategorizations = CategorizationStorage();
        end
        if isfield(inputStruct, 'storedFilters')
            processedStruct.storedFilters = inputStruct.storedFilters;
        else
            processedStruct.storedFilters = FilteringStorage();
        end
        if isfield(inputStruct, 'storedGroupIdFilters')
            processedStruct.storedGroupIdFilters = inputStruct.storedGroupIdFilters;
        else
            processedStruct.storedGroupIdFilters = GroupIdFilteringStorage();
        end   
    else
        processedStruct = [];
    end
end