function parameters = mergeStructWithDefaults(storedParameters, defaultParameters)
    % helper function that enables merging a default struct with new fields
    % useful to update older version of a stored struct after new fields have been added
    parameters = defaultParameters;

    if isempty(storedParameters) || ~isstruct(storedParameters)
        return
    end

    storedFields = fieldnames(storedParameters);

    for i = 1:numel(storedFields)
        field = storedFields{i};

        if isfield(defaultParameters, field) && ...
                isstruct(storedParameters.(field)) && ...
                isstruct(defaultParameters.(field))

            parameters.(field) = mergeStructWithDefaults( ...
                storedParameters.(field), ...
                defaultParameters.(field));

        else
            parameters.(field) = storedParameters.(field);
        end
    end
end