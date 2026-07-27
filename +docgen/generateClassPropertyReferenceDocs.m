function generateClassPropertyReferenceDocs(sourceFile, outputFile, className, defaultTitle, defaultDescription, defaults, defaultGroupName, missingDefaultsDescription)
% generateClassPropertyReferenceDocs Generate Markdown from class docs and properties.
%
% The page combines generic %DOC_PAGE/%DOC_SECTION comments with property
% metadata extracted from the class properties block.

    if nargin < 3 || isempty(className)
        [~, className] = fileparts(sourceFile);
    end

    className = string(className);

    if nargin < 4 || string(defaultTitle) == ""
        defaultTitle = className + " parameters";
    end

    if nargin < 5
        defaultDescription = "";
    end

    if nargin < 6 || isempty(defaults)
        defaults = getConstructorDefaults(className);
    end

    if nargin < 7 || string(defaultGroupName) == ""
        defaultGroupName = "Parameters";
    end

    if nargin < 8 || string(missingDefaultsDescription) == ""
        missingDefaultsDescription = "These parameters are included in the default parameter structure but were not found in the parsed properties block.";
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found: %s", sourceFile);
    end

    pageDocs = docgen.extractDocPageSections(sourceFile, defaultTitle, defaultDescription);
    classProperties = docgen.extractClassPropertyMetadata(sourceFile, defaultGroupName);
    classProperties = classProperties(~[classProperties.isConstant]);

    defaultNames = string(fieldnames(defaults));
    classProperties = keepDefaultParameters(classProperties, defaultNames);
    missingNames = setdiff(defaultNames, string({classProperties.name}), "stable");

    lines = renderMarkdown(pageDocs, classProperties, defaults, missingNames, missingDefaultsDescription, sourceFile);

    outputFolder = fileparts(outputFile);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    writeTextFile(outputFile, strjoin(lines, newline));

    fprintf("Generated documentation:\n%s\n", outputFile);
end

function defaults = getConstructorDefaults(className)

    obj = feval(className);
    propertyNames = string(properties(obj));

    defaults = struct();

    for i = 1:numel(propertyNames)
        defaults.(char(propertyNames(i))) = obj.(propertyNames(i));
    end
end

function classProperties = keepDefaultParameters(classProperties, defaultNames)

    if isempty(classProperties)
        return
    end

    propertyNames = string({classProperties.name});
    keepMask = ismember(propertyNames, defaultNames);
    classProperties = classProperties(keepMask);
end

function lines = renderMarkdown(pageDocs, classProperties, defaults, missingNames, missingDefaultsDescription, sourceFile)

    lines = strings(0, 1);

    lines(end+1) = "# " + pageDocs.title;
    lines(end+1) = "";

    if pageDocs.description ~= ""
        lines(end+1) = pageDocs.description;
        lines(end+1) = "";
    end

    lines(end+1) = "!!! note";
    lines(end+1) = "    The main app UI is stored in `.mlapp` files, so this generated page uses code-level parameter names and property comments rather than extracting UI labels.";
    lines(end+1) = "";

    for i = 1:numel(pageDocs.sections)
        section = pageDocs.sections(i);

        lines(end+1) = "## " + section.title;
        lines(end+1) = "";

        if section.description ~= ""
            sectionLines = splitlines(section.description);

            for j = 1:numel(sectionLines)
                lines(end+1) = sectionLines(j);
            end

            lines(end+1) = "";
        end
    end

    lines(end+1) = "## Parameters";
    lines(end+1) = "";

    groupNames = unique(string({classProperties.group}), "stable");

    for i = 1:numel(groupNames)
        groupName = groupNames(i);
        groupProperties = classProperties(string({classProperties.group}) == groupName);

        lines(end+1) = "### " + groupName;
        lines(end+1) = "";

        reference = firstNonEmpty(string({groupProperties.sourceReference}));
        if reference ~= ""
            lines(end+1) = "Source reference: <" + reference + ">";
            lines(end+1) = "";
        end

        lines(end+1) = "| Parameter | Default | Description |";
        lines(end+1) = "|---|---:|---|";

        for j = 1:numel(groupProperties)
            classProperty = groupProperties(j);
            defaultValue = defaults.(classProperty.name);
            description = classProperty.description;

            if description == ""
                description = "No property comment provided.";
            end

            lines(end+1) = "| `" + escapeMarkdown(classProperty.name) + "`" + ...
                " | `" + escapeMarkdown(formatValue(defaultValue)) + "`" + ...
                " | " + escapeMarkdown(description) + " |";
        end

        lines(end+1) = "";
    end

    if ~isempty(missingNames)
        lines(end+1) = "## Undocumented exported parameters";
        lines(end+1) = "";
        lines(end+1) = missingDefaultsDescription;
        lines(end+1) = "";

        for i = 1:numel(missingNames)
            lines(end+1) = "- `" + escapeMarkdown(missingNames(i)) + "`";
        end

        lines(end+1) = "";
    end

    lines(end+1) = "---";
    lines(end+1) = "";
    lines(end+1) = "*This page was generated automatically from: `" + string(sourceFile) + "`.*";
    lines(end+1) = "";
    lines(end+1) = "***Generated:** " + string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")) + "*";
    lines(end+1) = "";
    lines(end+1) = "*Do not edit this file manually. Edit the property comments in the source file and regenerate the documentation.*";
end

function value = firstNonEmpty(values)

    value = "";

    for i = 1:numel(values)
        if values(i) ~= ""
            value = values(i);
            return
        end
    end
end

function out = formatValue(value)

    if ischar(value)
        out = "'" + string(value) + "'";
    elseif isstring(value)
        if isscalar(value)
            out = """" + value + """";
        else
            out = "[" + strjoin("""" + value + """", ", ") + "]";
        end
    elseif islogical(value)
        out = lower(string(mat2str(value)));
    elseif isnumeric(value)
        out = string(mat2str(value));
    elseif iscell(value)
        out = "cell array";
    else
        out = string(class(value));
    end
end

function out = escapeMarkdown(in)
    out = string(in);
    out = replace(out, "|", "\|");
    out = replace(out, newline, " ");
end

function writeTextFile(filePath, text)

    fid = fopen(filePath, "w");

    if fid == -1
        error("Could not open file for writing: %s", filePath);
    end

    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
end
