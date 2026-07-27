function docs = extractDocPageSections(sourceFile, defaultTitle, defaultDescription)
% extractDocPageSections Parse generic %DOC_PAGE and %DOC_SECTION blocks.
%
% Supported format:
%
% %DOC_PAGE pageId; Title: Page title; Description: Page description.
%
% %DOC_SECTION sectionId; Title: Section title
% % Description: Section description.
% % Additional description lines can continue as comments.

    if nargin < 2 || isempty(defaultTitle)
        defaultTitle = "Documentation";
    end

    if nargin < 3
        defaultDescription = "";
    end

    if isempty(sourceFile) || ~isfile(sourceFile)
        error("Source file not found: %s", sourceFile);
    end

    lines = splitlines(string(fileread(sourceFile)));

    docs = struct( ...
        "id", "", ...
        "title", string(defaultTitle), ...
        "description", string(defaultDescription), ...
        "sections", struct("id", {}, "title", {}, "description", {}) ...
    );

    currentSectionIndex = [];
    currentBlock = "";

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        if startsWith(line, "%DOC_PAGE")
            content = extractAfter(line, "%DOC_PAGE");
            [pageId, meta] = parseTaggedLine(content);

            docs.id = pageId;
            docs.title = getMetaValue(meta, "title", docs.title);
            docs.description = getMetaValue(meta, "description", docs.description);
            currentSectionIndex = [];
            currentBlock = "page";

        elseif startsWith(line, "%DOC_SECTION")
            content = extractAfter(line, "%DOC_SECTION");
            [sectionId, meta] = parseTaggedLine(content);

            section = struct();
            section.id = sectionId;
            section.title = getMetaValue(meta, "title", sectionId);
            section.description = getMetaValue(meta, "description", "");

            docs.sections(end+1) = section;
            currentSectionIndex = numel(docs.sections);
            currentBlock = "section";

        elseif startsWith(line, "%") && currentBlock == "page"
            cleaned = strtrim(extractAfter(line, "%"));

            if startsWith(cleaned, "Description:")
                docs.description = strtrim(extractAfter(cleaned, "Description:"));
            elseif cleaned ~= "" && ~startsWith(cleaned, "DOC_")
                if docs.description ~= ""
                    docs.description = docs.description + newline;
                end

                docs.description = docs.description + cleaned;
            end

        elseif startsWith(line, "%") && currentBlock == "section" && ~isempty(currentSectionIndex)
            cleaned = strtrim(extractAfter(line, "%"));

            if startsWith(cleaned, "Description:")
                docs.sections(currentSectionIndex).description = strtrim(extractAfter(cleaned, "Description:"));
            elseif cleaned ~= "" && ~startsWith(cleaned, "DOC_")
                if docs.sections(currentSectionIndex).description ~= ""
                    docs.sections(currentSectionIndex).description = docs.sections(currentSectionIndex).description + newline;
                end

                docs.sections(currentSectionIndex).description = docs.sections(currentSectionIndex).description + cleaned;
            end

        elseif line ~= ""
            currentSectionIndex = [];
            currentBlock = "";
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

function value = getMetaValue(meta, key, defaultValue)

    key = lower(string(key));

    if isKey(meta, char(key))
        value = string(meta(char(key)));
    else
        value = string(defaultValue);
    end
end
