function wrapMermaidToHTML(mmdFile, htmlOutput)
    % Wraps a Mermaid .mmd file into a standalone HTML viewer with pan & zoom
    
        if nargin < 1
            [f, p] = uigetfile('*.md', 'Select Mermaid (.md) file');
            if isequal(f, 0), return; end
            mmdFile = fullfile(p, f);
        end
    
        if nargin < 2
            [f, p] = uiputfile('*.html', 'Save HTML as');
            if isequal(f, 0), return; end
            htmlOutput = fullfile(p, f);
        end
    
        mermaidCode = readlines(mmdFile);
        mermaidCode = mermaidCode(~startsWith(mermaidCode, "```"));  % Strip code fences
    
        fid = fopen(htmlOutput, 'w');
        fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n');
        fprintf(fid, '  <meta charset="utf-8">\n');
        fprintf(fid, '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n');
        fprintf(fid, '  <title>Mermaid Zoomable Diagram</title>\n');
        fprintf(fid, '  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>\n');
        fprintf(fid, '  <script src="https://cdn.jsdelivr.net/npm/panzoom@9.4.0/dist/panzoom.min.js"></script>\n');
        fprintf(fid, '  <style>\n');
        fprintf(fid, '    body, html { margin: 0; padding: 0; height: 100%%; overflow: hidden; }\n');
        fprintf(fid, '    #outer-container { width: 100%%; height: 100%%; overflow: hidden; }\n');
        fprintf(fid, '    #panzoom-container { width: 100%%; height: 100%%; }\n');
        fprintf(fid, '    svg { width: 100%%; height: 100%%; }\n');
        fprintf(fid, '  </style>\n');
        fprintf(fid, '</head>\n<body>\n');
    
        % Diagram container
        fprintf(fid, '<div id="outer-container">\n');
        fprintf(fid, '  <div id="panzoom-container" class="mermaid">\n');
        for i = 1:numel(mermaidCode)
            fprintf(fid, '%s\n', mermaidCode(i));
        end
        fprintf(fid, '  </div>\n</div>\n');
    
        % JS for mermaid + panzoom setup
        fprintf(fid, '<script>\n');
        fprintf(fid, '  mermaid.initialize({ startOnLoad: true });\n');
    
        % Wait for SVG, then attach panzoom
        fprintf(fid, '  document.addEventListener("DOMContentLoaded", () => {\n');
        fprintf(fid, '    const container = document.getElementById("panzoom-container");\n');
        fprintf(fid, '    const checkSVG = setInterval(() => {\n');
        fprintf(fid, '      const svg = container.querySelector("svg");\n');
        fprintf(fid, '      if (svg) {\n');
        fprintf(fid, '        panzoom(svg, {\n');
        fprintf(fid, '          bounds: true,\n');
        fprintf(fid, '          boundsPadding: 0.1,\n');
        fprintf(fid, '          zoomDoubleClickSpeed: 1,\n');
        fprintf(fid, '          smoothScroll: false\n');
        fprintf(fid, '        });\n');
        fprintf(fid, '        clearInterval(checkSVG);\n');
        fprintf(fid, '      }\n');
        fprintf(fid, '    }, 100);\n');
        fprintf(fid, '  });\n');
        fprintf(fid, '</script>\n');
    
        fprintf(fid, '</body>\n</html>\n');
        fclose(fid);
    
        fprintf("Zoomable Mermaid diagram saved to:\n%s\n", htmlOutput);
    end
    