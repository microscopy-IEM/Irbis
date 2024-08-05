function outputText = processDoubleArraysWithPaths(structVar, structPath, outputType)
    % Initialize an empty string to capture the text if needed
    outputText = '';
    
    % Get the field names of the structure
    fields = fieldnames(structVar);
    
    for i = 1:numel(fields)
        field = fields{i};
        if isempty(structPath)
            currentPath = field;
        else
            currentPath = [structPath, '.', field];
        end
        
        value = structVar.(field);
        
        if isstruct(value)
            nestedOutput = processDoubleArraysWithPaths(value, currentPath, outputType);
            if strcmp(outputType, 'capture')
                outputText = [outputText, nestedOutput]; %#ok<AGROW>
            end
        elseif isnumeric(value)
            formattedText = sprintf('%s:\t[%s]\n', currentPath, num2str(value));
            if strcmp(outputType, 'display')
                fprintf(formattedText);
            elseif strcmp(outputType, 'capture')
                outputText = [outputText, formattedText]; %#ok<AGROW>
            end
        end
    end
end
