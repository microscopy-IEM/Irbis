function [primaryFolder, fallbackFolder] = getSettingsFolder()
    if ispc
        % Windows: Primary location in AppData\Roaming
        primaryFolder = fullfile(getenv('APPDATA'), 'IrbisApp');
        fallbackFolder = fullfile(getenv('PUBLIC'), 'IrbisApp');
    elseif ismac
        % macOS/iOS: Primary location in ~/Library/Application Support
        primaryFolder = fullfile(getenv('HOME'), 'Library', 'Application Support', 'IrbisApp');
        fallbackFolder = '/Users/Shared/IrbisApp';  % Common shared folder for fallback
    elseif isunix
        % Linux: Primary location in ~/.config
        primaryFolder = fullfile(getenv('HOME'), '.config', 'IrbisApp');
        fallbackFolder = '/usr/share/IrbisApp';  % Common shared folder for fallback
    else
        error('Unsupported operating system');
    end
    
    % Ensure the primary folder exists or create it
    if ~exist(primaryFolder, 'dir')
        mkdir(primaryFolder);
    end
end