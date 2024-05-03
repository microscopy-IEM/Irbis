function result = isNumericOrString(x)

    % helping function for IrbisResultsViewer to select only specific columns

    result = isnumeric(x) || ischar(x) || isstring(x);
end