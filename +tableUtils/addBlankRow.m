function T = addBlankRow(T, rowName)
%ADDBLANKROW Append a blank row to a MATLAB table.
%
%   T = addBlankRow(T) appends one row containing an appropriate blank value for each table variable:
%
%       floating-point numeric   NaN
%       integer numeric          0
%       logical                  false
%       string                   missing string
%       character                spaces
%       categorical              <undefined>
%       datetime                 NaT
%       duration                 NaN duration
%       calendarDuration         NaN calendar duration
%       cell                     {[]}
%       struct                   struct with the same fields
%
%   T = addBlankRow(T, rowName) appends the row using rowName.
%
%   If T already has numeric row names and rowName is omitted, the new row uses max(existing row names) + 1.
%
%   The function also works with empty tables and table variables that contain multiple values per row, such as an N-by-3 numeric variable.
%
%   Unsupported cases: zero-variable tables, nonnumeric existing row names without an explicit rowName, and custom table variable classes not handled below.

    arguments
        T table
        rowName (1,1) string = missing
    end

    if width(T) == 0
        error("addBlankRow:ZeroVariableTable", ...
            "Cannot add a blank row to a table with no variables.");
    end

    variableNames = T.Properties.VariableNames;
    blankValues = cell(1, width(T));

    for variableIndex = 1:width(T)
        variableName = variableNames{variableIndex};
        data = T.(variableName);

        blankValues{variableIndex} = createBlankTableValue(data);
    end

    if isempty(T.Properties.RowNames) && ~ismissing(rowName) && height(T) > 0
        error("addBlankRow:UnexpectedRowName", ...
            "A row name cannot be appended to a table that does not use row names.");
    end

    rowName = resolveRowName(T, rowName);

    if ~ismissing(rowName)
        if any(string(T.Properties.RowNames) == rowName)
            error("addBlankRow:DuplicateRowName", ...
                "Row name '%s' already exists.", ...
                rowName);
        end

        T(cellstr(rowName), :) = blankValues;
    else
        T(end + 1, :) = blankValues;
    end
end


function rowName = resolveRowName(T, rowName)
%RESOLVEROWNAME Infer the next numeric row name when the table already uses numeric row names.

    if ~ismissing(rowName) || isempty(T.Properties.RowNames)
        return
    end

    existingIds = str2double(string(T.Properties.RowNames));

    if any(~isfinite(existingIds))
        error("addBlankRow:MissingRowName", ...
            "A row name is required when appending to a table with nonnumeric row names.");
    end

    rowName = string(max(existingIds) + 1);
end


function blankValue = createBlankTableValue(data)
%CREATEBLANKTABLEVALUE Create one table-row value matching the input type.

    % A table variable can have dimensions N-by-M-by-...; replace its row dimension N with 1.
    outputSize = size(data);
    outputSize(1) = 1;

    if isfloat(data)
        blankValue = NaN(outputSize, "like", data);

    elseif isinteger(data)
        % Integer arrays cannot contain NaN.
        blankValue = zeros(outputSize, "like", data);

    elseif islogical(data)
        blankValue = false(outputSize);

    elseif isstring(data)
        blankValue = strings(outputSize);
        blankValue(:) = missing;

    elseif ischar(data)
        blankValue = repmat(' ', outputSize);

    elseif iscategorical(data)
        blankValue = createBlankCategorical(data, outputSize);

    elseif isdatetime(data)
        blankValue = NaT(outputSize, "TimeZone", data.TimeZone);
        blankValue.Format = data.Format;

    elseif isduration(data)
        blankValue = duration( ...
            NaN(outputSize), ...
            zeros(outputSize), ...
            zeros(outputSize));
        blankValue.Format = data.Format;

    elseif iscalendarduration(data)
        blankValue = calendarDuration( ...
            NaN(outputSize), ...
            NaN(outputSize), ...
            NaN(outputSize));
        blankValue.Format = data.Format;

    elseif iscell(data)
        blankValue = repmat({[]}, outputSize);

    elseif isstruct(data)
        blankValue = createBlankStruct(data, outputSize);

    else
        error( ...
            "addBlankRow:UnsupportedVariableType", ...
            "Table variable type '%s' is not supported.", ...
            class(data));
    end
end


function blankValue = createBlankCategorical(data, outputSize)
%CREATEBLANKCATEGORICAL Preserve categories and ordinal status.

    categoryNames = categories(data);

    blankValue = categorical( ...
        repmat(missing, outputSize), ...
        categoryNames, ...
        "Ordinal", isordinal(data));
end


function blankValue = createBlankStruct(data, outputSize)
%CREATEBLANKSTRUCT Create blank structs while retaining field names.

    fieldNames = fieldnames(data);

    if isempty(fieldNames)
        scalarBlank = struct();
    else
        fieldValues = repmat({[]}, size(fieldNames));
        scalarBlank = cell2struct(fieldValues, fieldNames, 1);
    end

    blankValue = repmat(scalarBlank, outputSize);
end
