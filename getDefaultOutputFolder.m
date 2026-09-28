function outputFolder = getDefaultOutputFolder()
    if ispc
        % Windows: Look for the Documents folder in the user's profile
        outputFolder = fullfile(getenv('USERPROFILE'), 'Documents');
    else
        % Linux or macOS: Use the home directory as the default output folder, and go to the "Documents" subfolder if it exists
        outputFolder = fullfile(getenv('HOME'), 'Documents');
        if ~isfolder(outputFolder)
            % If the "Documents" folder doesn't exist, use the home directory instead
            outputFolder = getenv('HOME');
        end
    end

    if ~isfolder(outputFolder)
        % Return an empty char array if the output folder doesn't exist
        outputFolder = '';
    end
end