function properties = extractClassPropertyMetadata(sourceFile, defaultGroupName)
% extractClassPropertyMetadata Extract documented MATLAB class properties.
%
% The extractor is intentionally small and conservative. It reads property
% declarations, their default expressions, inline comments and nearby group
% comments from a MATLAB class file.

    if nargin < 1 || isempty(sourceFile)
        error("Source file is required.");
    end

    if nargin < 2 || isempty(defaultGroupName)
        defaultGroupName = "Core reconstruction";
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found: %s", sourceFile);
    end

    lines = splitlines(string(fileread(sourceFile)));

    properties = struct( ...
        "name", {}, ...
        "defaultExpression", {}, ...
        "description", {}, ...
        "group", {}, ...
        "sourceReference", {}, ...
        "isConstant", {} ...
    );

    inPropertiesBlock = false;
    isConstantBlock = false;
    currentGroup = string(defaultGroupName);
    currentReference = "";

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        if startsWith(line, "properties")
            inPropertiesBlock = true;
            isConstantBlock = contains(line, "Constant");
            currentGroup = string(defaultGroupName);
            currentReference = "";
            continue
        end

        if ~inPropertiesBlock
            continue
        end

        if line == "end"
            inPropertiesBlock = false;
            continue
        end

        if line == ""
            if ~isConstantBlock
                currentGroup = string(defaultGroupName);
                currentReference = "";
            end
            continue
        end

        if startsWith(line, "%")
            comment = strtrim(extractAfter(line, "%"));
            [groupName, reference] = classifyGroupComment(comment);

            if groupName ~= ""
                currentGroup = groupName;
                currentReference = reference;
            end

            continue
        end

        [codePart, commentPart] = splitInlineComment(line);
        codePart = strtrim(codePart);

        if codePart == ""
            continue
        end

        tokens = regexp(codePart, "^([A-Za-z]\w*)\s*(?:=\s*(.*?))?\s*;?$", "tokens", "once");

        if isempty(tokens)
            continue
        end

        property = struct();
        property.name = string(tokens{1});

        if numel(tokens) >= 2
            property.defaultExpression = strtrim(string(tokens{2}));
        else
            property.defaultExpression = "";
        end

        property.description = strtrim(commentPart);
        property.group = currentGroup;
        property.sourceReference = currentReference;
        property.isConstant = isConstantBlock;

        properties(end+1) = property; %#ok<AGROW>
    end
end

function [codePart, commentPart] = splitInlineComment(line)

    inSingleQuotedString = false;
    commentIndex = 0;
    chars = char(line);

    for i = 1:numel(chars)
        if chars(i) == "'"
            inSingleQuotedString = ~inSingleQuotedString;
        elseif chars(i) == "%" && ~inSingleQuotedString
            commentIndex = i;
            break
        end
    end

    if commentIndex == 0
        codePart = string(line);
        commentPart = "";
    else
        codePart = string(chars(1:commentIndex-1));
        commentPart = strtrim(string(chars(commentIndex+1:end)));
    end
end

function [groupName, reference] = classifyGroupComment(comment)

    commentLower = lower(string(comment));
    groupName = "";
    reference = "";

    if startsWith(commentLower, "simplify:")
        groupName = "Mesh simplification";
        reference = strtrim(extractAfter(string(comment), ":"));
    elseif startsWith(commentLower, "smoothsurfacemesh:")
        groupName = "Mesh smoothing";
        reference = strtrim(extractAfter(string(comment), ":"));
    end
end
