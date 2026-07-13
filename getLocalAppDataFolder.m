function [primaryFolder, fallbackFolder] = getLocalAppDataFolder()

    if ispc
        % Windows: AppData\Local
        primaryFolder = fullfile(getenv('LOCALAPPDATA'), 'IrbisApp');
        fallbackFolder = fullfile(getenv('PUBLIC'), 'IrbisApp');

    elseif ismac
        % macOS: ~/Library/Application Support
        % There is no equivalent distinction between Roaming and Local.
        primaryFolder = fullfile(getenv('HOME'), 'Library', 'Application Support', 'IrbisApp');
        fallbackFolder = '/Users/Shared/IrbisApp';

    elseif isunix
        % Linux: ~/.local/share according to XDG Base Directory specification
        primaryFolder = fullfile(getenv('HOME'), '.local', 'share', 'IrbisApp');
        fallbackFolder = '/usr/local/share/IrbisApp';

    else
        error('Unsupported operating system.');
    end

    if ~isfolder(primaryFolder)
        mkdir(primaryFolder);
    end

end