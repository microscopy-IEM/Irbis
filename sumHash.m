function hash = sumHash(input)
    % Convert input to a string representation
    serializedInput = serialize(input);
    
    % Compute a simple hash by summing ASCII values
    hash = mod(sum(double(serializedInput)), 2^32); % 32-bit hash
end

function str = serialize(input)
    % Convert various data types to a string
    if isstruct(input)
        % Handle structures by sorting fields for consistency
        fields = sort(fieldnames(input)); % Sort fields alphabetically
        str = '';
        for i = 1:numel(fields)
            str = [str, fields{i}, serialize(input.(fields{i}))]; %#ok<AGROW>
        end
    elseif iscell(input)
        % Handle cell arrays by recursively serializing elements
        str = '[';
        for i = 1:numel(input)
            str = [str, serialize(input{i})]; %#ok<AGROW>
        end
        str = [str, ']'];
    elseif isa(input, 'dictionary')
        % Handle dictionaries by sorting keys and serializing key-value pairs
        keysList = sort(keys(input)); % Sort dictionary keys
        str = '{';
        for i = 1:numel(keysList)
            key = keysList{i};
            value = input(key);
            str = [str, key, ':', serialize(value)]; %#ok<AGROW>
        end
        str = [str, '}'];
    elseif isnumeric(input) || islogical(input)
        % Handle numeric or logical arrays
        str = mat2str(input);
    elseif ischar(input) || isstring(input)
        % Handle strings or character arrays
        str = char(input); % Convert to a character array
    else
        % Error for unsupported data types
        error('Unsupported data type: %s', class(input));
    end
end

