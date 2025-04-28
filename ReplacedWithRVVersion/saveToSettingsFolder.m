function saveToSettingsFolder(data, filename, fig)
    % saves data with a specified filename to the settings folder
    % 
    % filename - string with a corresponding extension (such as .mat)

    [primaryFolder, fallbackFolder] = getSettingsFolder;

    % Define the primary data file path
    dataFile = fullfile(primaryFolder, filename);
    
    % Try to save data to the primary folder, use fallback if it fails
    try
        save(dataFile,'data');  % Attempt to save the data
        disp(['Data saved successfully in ', primaryFolder]);
    catch ME
        % If primary location fails, try the fallback folder
        disp(['Failed to save data in ', primaryFolder, '. Attempting to save in fallback folder...']);
        
        % Ensure the fallback folder exists or create it
        if ~exist(fallbackFolder, 'dir')
            mkdir(fallbackFolder);
        end
        
        % Define the fallback data file path
        fallbackDataFile = fullfile(fallbackFolder, filename);
        
        try
            save(fallbackDataFile,'data');  % Save to fallback folder
            disp(['Data saved successfully in fallback folder: ', fallbackFolder]);
        catch fallbackME
            % If both locations fail, show an error message
            warning(['Failed to save data in both primary and fallback locations: ', fallbackME.message]);
            
            % Optional: Notify the user via an alert dialog (if GUI is present)
            uialert(fig, ['Error saving data: ', fallbackME.message], 'Data Save Error', 'Icon', 'error');
        end
    end
end