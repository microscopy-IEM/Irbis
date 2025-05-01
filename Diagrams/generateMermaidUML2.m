function generateMermaidUML(folder, outputFile)
    if nargin < 1 || ~isfolder(folder)
        folder = uigetdir(pwd, 'Select folder with class files');
        if isequal(folder, 0), return; end
    end

    if nargin < 2
        [f, p] = uiputfile({'*.md', 'Markdown Files (*.md)'}, 'Save Mermaid diagram as');
        if isequal(f, 0), return; end
        [~, name, ext] = fileparts(f);
        if ~strcmp(ext, '.md')
            f = name + ".md";
        end
        outputFile = fullfile(p, f);
    end

    files = dir(fullfile(folder, '*.m'));
    classes = struct([]);
    eventMap = containers.Map(); % class -> events
    listenerLinks = [];          % struct with .sourceClass and .eventName

    for i = 1:numel(files)
        filepath = fullfile(files(i).folder, files(i).name);
        lines = readlines(filepath);

        className = '';
        superClass = '';
        properties = strings(0);
        methodGroups = struct();
        events = strings(0);

        currentSection = '';
        currentGroup = 'public'; % default method group

        for line = lines'
            line = strtrim(line);

            if startsWith(line, 'classdef')
                tokens = regexp(line, 'classdef\s+(\w+)\s*(<\s*(\w+))?', 'tokens');
                if ~isempty(tokens)
                    className = tokens{1}{1};
                    if numel(tokens{1}) >= 3
                        superClass = tokens{1}{3};
                    end
                end
            elseif startsWith(line, 'properties')
                currentSection = 'properties';
            elseif startsWith(line, 'methods')
                currentSection = 'methods';
                mGroup = regexp(line, 'methods\s*\(([^)]+)\)', 'tokens');
                if ~isempty(mGroup)
                    rawGroup = mGroup{1}{1};
                    currentGroup = regexprep(rawGroup, '\W', '_'); % sanitize to valid field name
                else
                    currentGroup = 'public';
                end
                if ~isfield(methodGroups, currentGroup)
                    methodGroups.(currentGroup) = strings(0);
                end
            elseif startsWith(line, 'events')
                currentSection = 'events';
            elseif startsWith(line, 'end')
                currentSection = '';
            elseif ~isempty(line) && ~startsWith(line, '%')
                switch currentSection
                    case 'properties'
                        tokens = regexp(line, '(\w+)', 'tokens');
                        if ~isempty(tokens)
                            properties(end+1) = tokens{1}{1};
                        end
                    case 'methods'
                        tokens = regexp(line, 'function\s+[^\s=]*\s*=?\s*(\w+)', 'tokens');
                        if ~isempty(tokens)
                            methodGroups.(currentGroup)(end+1) = tokens{1}{1};
                        end
                    case 'events'
                        tokens = regexp(line, '(\w+)', 'tokens');
                        if ~isempty(tokens)
                            events(end+1) = tokens{1}{1};
                        end
                end

                % Detect addlistener usage
                listenerTokens = regexp(line, 'addlistener\s*\([^\)]*''(\w+)''', 'tokens');
                if ~isempty(listenerTokens) && ~isempty(className)
                    listenerLinks(end+1).sourceClass = className; %#ok<AGROW>
                    listenerLinks(end).eventName = listenerTokens{1}{1};
                end
            end
        end

        if ~isempty(className)
            classes(end+1).name = className; %#ok<AGROW>
            classes(end).super = superClass;
            classes(end).properties = properties;
            classes(end).methodGroups = methodGroups;
            classes(end).events = events;
            if ~isempty(events)
                eventMap(className) = events;
            end
        end
    end

    % Write to Mermaid Markdown file
    fid = fopen(outputFile, 'w');
    fprintf(fid, "```mermaid\n");
    fprintf(fid, "classDiagram\n\n");

    for c = classes
        fprintf(fid, "    class %s {\n", c.name);
        for p = c.properties'
            fprintf(fid, "        +%s\n", p);
        end
        groupNames = fieldnames(c.methodGroups);
        for g = groupNames'
            group = g{1};
            methods = c.methodGroups.(group);
            prefix = getAccessPrefix(group);
            for m = methods'
                fprintf(fid, "        %s%s()\n", prefix, m);
            end
        end
        for e = c.events'
            fprintf(fid, "        + EVENT: %s\n", e);
        end
        fprintf(fid, "    }\n\n");
    end

    for c = classes
        if ~isempty(c.super)
            fprintf(fid, "    %s <|-- %s\n", c.super, c.name);
        end
    end

    % Add listener links
    for k = 1:numel(listenerLinks)
        src = listenerLinks(k).sourceClass;
        evt = listenerLinks(k).eventName;
        for ci = 1:numel(classes)
            cls = classes(ci);
            if ismember(evt, cls.events)
                fprintf(fid, "    %s ..> %s : listens to %s\n", src, cls.name, evt);
                break;
            end
        end
    end

    fprintf(fid, "```\n");
    fclose(fid);

    fprintf("Mermaid UML diagram saved to:\n%s\n", outputFile);
end

function prefix = getAccessPrefix(group)
    if contains(group, 'private', 'IgnoreCase', true)
        prefix = '-';
    elseif contains(group, 'protected', 'IgnoreCase', true)
        prefix = '#';
    else
        prefix = '+';
    end
end
