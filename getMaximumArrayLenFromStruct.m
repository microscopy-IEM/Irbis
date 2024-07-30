function maxLen = getMaximumArrayLenFromStruct(s, maxLen)
    % Get the field names of the struct
    fields = fieldnames(s);
    
    % Loop through each field
    for i = 1:length(fields)
        field = fields{i};
        value = s.(field);
        
        % Check if the field is a numeric array
        if isnumeric(value) && isvector(value)
            % Update the maximum length if this array is longer
            maxLen = max(maxLen, numel(value));
        elseif isstruct(value)
            % Recurse into sub-structs
            maxLen = getMaximumArrayLenFromStruct(value, maxLen);
        end
    end
end