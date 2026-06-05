function generateStructureOverviewDocs(sourceFile, outputFile)
% generateStructureOverviewDocs Generate MkDocs page from %#DOC_* comments.
%
% Supported format:
%
% %#DOC_SECTION info; Title: Info
% % Description: General metadata about the file.
%
% %#DOC_FIELD info.saveTimestamp; Type: datetime; Unit:
% % Description: Timestamp when the structure was last saved.
%
% Optional keys:
%   Type, Unit, Description, Link

    if nargin < 1 || isempty(sourceFile)
        sourceFile = which("getBaseStruct");
    end

    if nargin < 2 || isempty(outputFile)
        outputFile = fullfile(pwd, "docs", "reference", "output-file-structure.md");
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found.");
    end

    outputFolder = fileparts(outputFile);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    text = fileread(sourceFile);
    lines = splitlines(string(text));

    [page, sections] = parseDocBlocks(lines);
    markdown = renderStructureMarkdown(page, sections, sourceFile);

    writeTextFile(outputFile, markdown);

    fprintf("Generated documentation:\n%s\n", outputFile);
end

function [page, sections] = parseDocBlocks(lines)

    page = struct( ...
        "title", "Output file structure", ...
        "description", "" ...
    );

    sections = struct( ...
        "id", {}, ...
        "title", {}, ...
        "description", {}, ...
        "fields", {} ...
    );

    currentSectionId = "";

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        if startsWith(line, "%#DOC_PAGE")
            content = extractAfter(line, "%#DOC_PAGE");
            [~, meta] = parseTaggedLine(content);

            page.title = getMetaValue(meta, "title", page.title);
            page.description = getMetaValue(meta, "description", getNearbyDescription(lines, i));

        elseif startsWith(line, "%#DOC_SECTION")
            content = extractAfter(line, "%#DOC_SECTION");
            [sectionId, meta] = parseTaggedLine(content);

            section.title = getMetaValue(meta, "title", sectionId);
            section.id = sectionId;
            section.description = getMetaValue(meta, "description", getNearbyDescription(lines, i));
            section.fields = struct( ...
                "path", {}, ...
                "type", {}, ...
                "unit", {}, ...
                "description", {}, ...
                "link", {} ...
            );

            sections(end+1) = section; %#ok<AGROW>
            currentSectionId = sectionId;

        elseif startsWith(line, "%#DOC_FIELD")
            content = extractAfter(line, "%#DOC_FIELD");
            [fieldPath, meta] = parseTaggedLine(content);

            field.path = fieldPath;
            field.type = getMetaValue(meta, "type", "");
            field.unit = getMetaValue(meta, "unit", "");
            field.description = getMetaValue(meta, "description", getNearbyDescription(lines, i));
            field.link = getMetaValue(meta, "link", "");

            sectionId = currentSectionId;
            if sectionId == ""
                sectionId = extractBefore(fieldPath + ".", ".");
            end

            sectionIndex = findSectionIndex(sections, sectionId);

            if isempty(sectionIndex)
                section.id = sectionId;
                section.title = sectionId;
                section.description = "";
                section.fields = field;
                sections(end+1) = section; %#ok<AGROW>
            else
                sections(sectionIndex).fields(end+1) = field;
            end
        end
    end
end

function [itemId, meta] = parseTaggedLine(content)

    content = strtrim(content);
    parts = strtrim(split(content, ";"));

    itemId = parts(1);
    meta = containers.Map("KeyType", "char", "ValueType", "char");

    for i = 2:numel(parts)
        part = parts(i);
        if part == ""
            continue
        end

        tokens = regexp(part, "^([^:=]+)\s*[:=]\s*(.*)$", "tokens", "once");
        if isempty(tokens)
            continue
        end

        key = lower(strtrim(tokens{1}));
        value = strtrim(tokens{2});

        meta(char(key)) = char(value);
    end
end

function description = getNearbyDescription(lines, startIndex)

    descriptionLines = strings(0, 1);
    inDescription = false;

    for i = startIndex+1:min(startIndex+20, numel(lines))
        line = strtrim(lines(i));

        if startsWith(line, "%#DOC_")
            break
        end

        if ~startsWith(line, "%")
            break
        end

        cleaned = strtrim(extractAfter(line, "%"));

        if startsWith(cleaned, "Description:")
            inDescription = true;
            firstLine = strtrim(extractAfter(cleaned, "Description:"));

            if firstLine ~= ""
                descriptionLines(end+1) = firstLine; %#ok<AGROW>
            end

        elseif inDescription
            if cleaned == ""
                descriptionLines(end+1) = ""; %#ok<AGROW>
            else
                descriptionLines(end+1) = cleaned; %#ok<AGROW>
            end
        end
    end

    description = strjoin(descriptionLines, newline);
end

function value = getMetaValue(meta, key, defaultValue)

    key = lower(string(key));

    if isKey(meta, char(key))
        value = string(meta(char(key)));
    else
        value = string(defaultValue);
    end
end

function idx = findSectionIndex(sections, sectionId)

    idx = [];

    for i = 1:numel(sections)
        if sections(i).id == sectionId
            idx = i;
            return
        end
    end
end

function markdown = renderStructureMarkdown(page, sections, sourceFile)

    out = strings(0, 1);

    out(end+1) = "# " + page.title;
    out(end+1) = "";

    if page.description ~= ""
        out = appendParagraph(out, page.description);
    end

    out(end+1) = "## Structure overview";
    out(end+1) = "";
    out(end+1) = "- `Irbis file`";

    for i = 1:numel(sections)
        out(end+1) = "  - `" + sections(i).id + "`";
    end

    out(end+1) = "";

    for i = 1:numel(sections)
        section = sections(i);

        out(end+1) = "## " + section.title;
        out(end+1) = "";

        if section.description ~= ""
            out = appendParagraph(out, section.description);
        end

        for j = 1:numel(section.fields)
            field = section.fields(j);

            line = "- `" + field.path + "`";

            if field.type ~= ""
                line = line + " *(" + field.type + ")*";
            end

            if field.description ~= ""
                shortDescription = replace(field.description, newline, " ");
                line = line + " - " + shortDescription;
            end

            out(end+1) = line;

            if field.unit ~= ""
                out(end+1) = "  - Unit: `" + field.unit + "`";
            end

            if field.link ~= ""
                [~, name, ~] = fileparts(field.link);
                linkText = regexprep(name, "-", " ");
                out(end+1) = "    - See: [" + linkText + "](" + field.link + ")";
            end
        end

        out(end+1) = "";
    end

    out(end+1) = "---";
    out(end+1) = "";
    out(end+1) = "*This page was generated automatically from: `" + string(sourceFile) + "`.*";
    out(end+1) = "";
    out(end+1) = "***Generated:** " + string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")) + "*";
    out(end+1) = "";
    out(end+1) = "*Do not edit this file manually. Edit the documentation comments in the source file and regenerate the documentation.*";

    markdown = strjoin(out, newline);
end

% function markdown = renderStructureMarkdown(sections)

%     out = strings(0, 1);

%     out(end+1) = "# Output file structure";
%     out(end+1) = "";
%     out(end+1) = "This page describes the main structure of an Irbis output file.";
%     out(end+1) = "";
%     out(end+1) = "Detailed table column definitions are described on separate reference pages.";
%     out(end+1) = "";

%     out(end+1) = "## Structure overview";
%     out(end+1) = "";
%     out(end+1) = "```text";
%     out(end+1) = "Irbis file";

%     for i = 1:numel(sections)
%         out(end+1) = "├── " + sections(i).id;
%     end

%     out(end+1) = "```";
%     out(end+1) = "";

%     for i = 1:numel(sections)
%         section = sections(i);

%         out(end+1) = "## " + section.title;
%         out(end+1) = "";

%         if section.description ~= ""
%             out(end+1) = section.description;
%             out(end+1) = "";
%         end

%         for j = 1:numel(section.fields)
%             field = section.fields(j);

%             out(end+1) = "??? info """ + field.path + """";
%             out(end+1) = "";

%             if field.description ~= ""
%                 out(end+1) = "    " + field.description;
%                 out(end+1) = "";
%             end

%             if field.type ~= ""
%                 out(end+1) = "    - Type: `" + field.type + "`";
%             end

%             if field.unit ~= ""
%                 out(end+1) = "    - Unit: `" + field.unit + "`";
%             end

%             if field.link ~= ""
%                 [~, name, ext] = fileparts(field.link);
%                 linkText = regexprep(name, "-", " ");
%                 out(end+1) = "    - See: [" + linkText + "](" + field.link + ")";
%             end

%             out(end+1) = "";
%         end
%     end

%     markdown = strjoin(out, newline);
% end

function out = appendParagraph(out, textBlock)

    lines = splitlines(string(textBlock));

    for i = 1:numel(lines)
        out(end+1) = lines(i); %#ok<AGROW>
    end

    out(end+1) = "";
end

function writeTextFile(filePath, text)

    fid = fopen(filePath, "w");

    if fid == -1
        error("Could not open file for writing: %s", filePath);
    end

    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
end