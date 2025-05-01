function generateMermaidUML(folder, outputFile)
    % Generates a Mermaid UML classDiagram from MATLAB class files in a folder.
    % Prompts for folder or file if not provided.
    %
    % Usage:
    %   generateMermaidUML()                 % Prompt for folder and output file
    %   generateMermaidUML(folderPath)       % Prompt for output file
    %   generateMermaidUML(folderPath, file) % Fully automatic
    
        if nargin < 1 || ~isfolder(folder)
            folder = uigetdir(pwd, 'Select folder with class files');
            if isequal(folder, 0)
                return; % User cancelled
            end
        end
    
        if nargin < 2
            [f, p] = uiputfile({'*.mmd'; '*.md'}, 'Save Mermaid diagram as');
            if isequal(f, 0)
                return; % User cancelled
            end
            outputFile = fullfile(p, f);
        end
    
        files = dir(fullfile(folder, '*.m'));
        classes = struct([]);
    
        for i = 1:numel(files)
            filepath = fullfile(files(i).folder, files(i).name);
            lines = readlines(filepath);
    
            className = '';
            superClass = '';
            methods = strings(0);    % FIXED: initialize as string array
            properties = strings(0); % FIXED: initialize as string array
    
            currentSection = '';
    
            for line = lines'
                line = strtrim(line);
    
                if startsWith(line, 'classdef')
                    tokens = regexp(line, 'classdef\s+(\w+)\s*(<\s*(\w+))?', 'tokens');
                    if ~isempty(tokens)
                        className = tokens{1}{1};
                        if numel(tokens{1}) >= 3
                            superClass = tokens{1}{3};
                        else
                            superClass = '';
                        end
                    end
                elseif startsWith(line, 'properties')
                    currentSection = 'properties';
                elseif startsWith(line, 'methods')
                    currentSection = 'methods';
                elseif startsWith(line, 'end')
                    currentSection = '';
                elseif ~isempty(line) && ~startsWith(line, '%')
                    if strcmp(currentSection, 'properties')
                        tokens = regexp(line, '(\w+)', 'tokens');
                        if ~isempty(tokens)
                            properties(end+1) = tokens{1}{1}; %#ok<AGROW>
                        end
                    elseif strcmp(currentSection, 'methods')
                        tokens = regexp(line, 'function\s+[^\s=]*\s*=?\s*(\w+)', 'tokens');
                        if ~isempty(tokens)
                            methods(end+1) = tokens{1}{1}; %#ok<AGROW>
                        end
                    end
                end
            end
    
            if ~isempty(className)
                classes(end+1).name = className; %#ok<AGROW>
                classes(end).super = superClass;
                classes(end).properties = properties;
                classes(end).methods = methods;
            end
        end
    
        % Write Mermaid diagram to file
        fid = fopen(outputFile, 'w');
        fprintf(fid, "```mermaid\n");
        fprintf(fid, "classDiagram\n\n");
    
        for c = classes
            fprintf(fid, "    class %s {\n", c.name);
            for p = c.properties'
                fprintf(fid, "        +%s\n", p);
            end
            for m = c.methods'
                fprintf(fid, "        +%s()\n", m);
            end
            fprintf(fid, "    }\n\n");
        end
    
        for c = classes
            if ~isempty(c.super)
                fprintf(fid, "    %s <|-- %s\n", c.super, c.name);
            end
        end
    
        fprintf(fid, "```\n");
        fclose(fid);
    
        fprintf("✅ Mermaid UML diagram saved to:\n%s\n", outputFile);
    end
    