function fileName = makeExportFileName(tableType, labels, values, format)
%MAKEEXPORTFILENAME Build a filesystem-safe default ResultsViewer export name.

    parts = [{'IrbisResults', tableType}, labeledParts(labels, values)];
    parts = parts(~cellfun(@isempty, parts));
    fileName = [strjoin(parts, '_') '.' format];
end


function parts = labeledParts(labels, values)
    parts = cell(1, numel(labels));

    for i = 1:numel(labels)
        valuePart = safeFilePart(values{i});
        if ~isempty(valuePart)
            parts{i} = [labels{i} '-' valuePart];
        else
            parts{i} = '';
        end
    end
end


function textOut = safeFilePart(value)
    if iscell(value) || isstring(value)
        value = cellstr(string(value));
        value = value(1:min(3, numel(value)));
        textOut = strjoin(value, '_');
    elseif isnumeric(value)
        textOut = num2str(value);
    else
        textOut = char(string(value));
    end

    textOut = regexprep(strtrim(textOut), '\s+', '-');
    textOut = regexprep(textOut, '[^A-Za-z0-9_.-]+', '-');
    textOut = regexprep(textOut, '^[-_.]+|[-_.]+$', '');
end
