function generatedFiles = generateTutorialSnippets(sourceRoot, outputRoot, includeRoot)
% generateTutorialSnippets Generate heading-free Markdown snippets for tutorials.
%
% The generated snippets are intended for pymdownx.snippets includes inside
% tutorial admonitions. They preserve the step-by-step content, but remove
% Markdown headings from the page outline:
%
%   # Page title       -> removed
%   ## Section title   -> **Section title**
%   ### Section title  -> **Section title**
%
% Screenshot placeholder admonitions are omitted from snippets. Relative
% Markdown links are rewritten for pages in docs/tutorials by default.

    if nargin < 1 || isempty(sourceRoot)
        sourceRoot = fullfile(pwd, "docs", "step-by-step");
    end

    if nargin < 2 || isempty(outputRoot)
        outputRoot = fullfile(pwd, "docs", "_generated", ...
            "snippets", "step-by-step");
    end

    if nargin < 3 || isempty(includeRoot)
        includeRoot = fullfile(pwd, "docs", "tutorials");
    end

    sourceRoot = string(sourceRoot);
    outputRoot = string(outputRoot);
    includeRoot = string(includeRoot);

    if ~isfolder(sourceRoot)
        error("Source folder not found: %s", sourceRoot);
    end

    if ~isfolder(outputRoot)
        mkdir(outputRoot);
    end

    sourceFiles = findMarkdownFiles(sourceRoot);
    generatedFiles = strings(numel(sourceFiles), 1);

    for i = 1:numel(sourceFiles)
        sourceFile = sourceFiles(i);
        relativePath = extractRelativePath(sourceFile, sourceRoot);
        outputFile = fullfile(outputRoot, relativePath);

        outputFolder = fileparts(outputFile);
        if ~isfolder(outputFolder)
            mkdir(outputFolder);
        end

        markdown = fileread(char(sourceFile));
        snippet = transformMarkdownForSnippet(markdown, sourceFile, includeRoot);
        writeTextFile(outputFile, snippet);

        generatedFiles(i) = outputFile;
    end

    fprintf("Generated %d tutorial snippets in:\n%s\n", ...
        numel(generatedFiles), outputRoot);
end

function files = findMarkdownFiles(folder)

    files = strings(0, 1);
    entries = dir(folder);

    for i = 1:numel(entries)
        entry = entries(i);

        if entry.isdir
            if strcmp(entry.name, ".") || strcmp(entry.name, "..")
                continue
            end

            nestedFiles = findMarkdownFiles(fullfile(entry.folder, entry.name));
            files = [files; nestedFiles]; %#ok<AGROW>
        else
            [~, ~, ext] = fileparts(entry.name);

            if strcmpi(ext, ".md")
                files(end+1, 1) = string(fullfile(entry.folder, entry.name)); %#ok<AGROW>
            end
        end
    end
end

function relativePath = extractRelativePath(filePath, rootPath)

    filePath = string(filePath);
    rootPath = string(rootPath);

    if ~endsWith(rootPath, filesep)
        rootPath = rootPath + filesep;
    end

    relativePath = erase(filePath, rootPath);
end

function snippet = transformMarkdownForSnippet(markdown, sourceFile, includeRoot)

    lines = splitlines(string(markdown));
    lines = replace(lines, string(char(65279)), "");
    out = strings(0, 1);
    skippingScreenshotPlaceholder = false;
    previousWasBlank = true;

    for i = 1:numel(lines)
        line = lines(i);

        if skippingScreenshotPlaceholder
            if line == "" || startsWith(line, "    ") || startsWith(line, char(9))
                continue
            end

            skippingScreenshotPlaceholder = false;
        end

        if isScreenshotPlaceholderAdmonition(line)
            skippingScreenshotPlaceholder = true;
            previousWasBlank = true;
            continue
        end

        [isHeading, level, title] = parseMarkdownHeading(line);

        if isHeading && level == 1
            previousWasBlank = true;
            continue
        end

        if isHeading
            line = "**" + title + "**";
        end

        isBlank = line == "";

        if isBlank && previousWasBlank
            continue
        end

        out(end+1, 1) = line; %#ok<AGROW>
        previousWasBlank = isBlank;
    end

    snippet = strjoin(out, newline);

    if snippet ~= ""
        snippet = strip(snippet) + newline;
    end

    snippet = rewriteMarkdownLinksForInclude(snippet, sourceFile, includeRoot);
end

function tf = isScreenshotPlaceholderAdmonition(line)

    trimmed = strtrim(line);
    tf = startsWith(trimmed, "!!! example") && ...
        contains(lower(trimmed), "screenshot placeholder");
end

function [isHeading, level, title] = parseMarkdownHeading(line)

    line = strtrim(replace(string(line), string(char(65279)), ""));
    tokens = regexp(char(line), "^(#{1,6})\s+(.+?)\s*$", ...
        "tokens", "once");

    if isempty(tokens)
        isHeading = false;
        level = 0;
        title = "";
        return
    end

    isHeading = true;
    level = numel(tokens{1});
    title = string(tokens{2});
end

function markdown = rewriteMarkdownLinksForInclude(markdown, sourceFile, ...
        includeRoot)

    if markdown == ""
        return
    end

    text = char(markdown);
    pattern = "(!?\[[^\]]*\]\()([^)#]+)(#[^)]*)?(\))";
    [starts, ends, tokens] = regexp(text, pattern, "start", "end", ...
        "tokens");

    if isempty(starts)
        return
    end

    for i = numel(starts):-1:1
        token = tokens{i};
        target = string(token{2});

        if isExternalMarkdownTarget(target)
            continue
        end

        rewrittenTarget = rewriteMarkdownTarget(target, sourceFile, ...
            includeRoot);

        if rewrittenTarget == target
            continue
        end

        replacement = string(token{1}) + rewrittenTarget;

        if numel(token) >= 3
            replacement = replacement + string(token{3});
        end

        replacement = replacement + string(token{end});
        text = [text(1:starts(i)-1), char(replacement), text(ends(i)+1:end)];
    end

    markdown = string(text);
end

function tf = isExternalMarkdownTarget(target)

    target = strtrim(string(target));
    tf = target == "" || startsWith(target, "#") || ...
        ~isempty(regexp(char(target), "^[a-zA-Z][a-zA-Z0-9+.-]*:", ...
        "once"));
end

function rewrittenTarget = rewriteMarkdownTarget(target, sourceFile, ...
        includeRoot)

    sourceFolder = fileparts(char(sourceFile));
    targetFile = fullfile(sourceFolder, char(target));

    if ~isfile(targetFile)
        rewrittenTarget = target;
        return
    end

    targetInfo = dir(targetFile);
    includeInfo = dir(includeRoot);

    targetPath = string(fullfile(targetInfo.folder, targetInfo.name));
    includePath = string(includeInfo(1).folder);

    rewrittenTarget = normalizeMarkdownPath( ...
        relativePathBetween(includePath, targetPath));
end

function relativePath = relativePathBetween(fromFolder, toFile)

    fromParts = splitPath(fromFolder);
    toParts = splitPath(toFile);

    commonCount = 0;
    maxCommon = min(numel(fromParts), numel(toParts));

    for i = 1:maxCommon
        if ~strcmpi(fromParts(i), toParts(i))
            break
        end

        commonCount = i;
    end

    upCount = numel(fromParts) - commonCount;
    relativeParts = [repmat("..", upCount, 1); toParts(commonCount+1:end)];

    if isempty(relativeParts)
        relativePath = ".";
    else
        relativePath = fullfile(relativeParts{:});
    end
end

function parts = splitPath(pathValue)

    pathValue = string(pathValue);
    parts = split(pathValue, filesep);
    parts(parts == "") = [];
end

function pathValue = normalizeMarkdownPath(pathValue)

    pathValue = string(pathValue);
    pathValue = replace(pathValue, "\", "/");
end

function writeTextFile(filePath, text)

    fid = fopen(char(filePath), "w");

    if fid == -1
        error("Could not open file for writing: %s", filePath);
    end

    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
end
