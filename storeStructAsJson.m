function storeStructAsJson(structToStore, fullpath)
    % Convert to JSON
    encoded = jsonencode(structToStore, "PrettyPrint", true)

    if nargin < 2 || isempty(fullpath)
        % If no path is provided, ask user where to save
        [filename, pathname] = uiputfile('*.json', 'Save JSON file as');
        if isequal(filename,0) || isequal(pathname,0)
            disp('User canceled saving.');
            return
        end
        fullpath = fullfile(pathname, filename);
    end
    fid = fopen(fullpath, 'w');
    fprintf(fid, '%s', encoded);
    fclose(fid);
    disp(['Saved to ', fullpath]);
end
