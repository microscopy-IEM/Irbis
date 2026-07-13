function settings = getDefaultSettings(appData)
    settings.Paths = {' '};
    settings.currentPath = 1;
    settings.GPUprocessing = 0;
    settings.parallelProcessing = 0;
    settings.version = appData.Version; % Version of what? Irbis or settings?
    settings.predefinedFilterSettings = [];

    % Save settings
    settings.askSaveBeforeClosing = 1;
    settings.askSaveBeforeNew = 1;

    % Graphical settings
    settings.backgroundColor = [0 0 0];
    settings.theme = 'dark'; % added 20251214
    settings.lightening = 'dynamic'; % added 20251222 dynamic/static
    settings.adaptiveTracksOn = true;   % whether trajectories are coarsened based on zoom level

    % Python-related settings
    settings.pythonPath = [];
end