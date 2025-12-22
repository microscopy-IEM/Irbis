function settings = getDefaultSettings(appData)
    settings.Paths = {' '};
    settings.currentPath = 1;
    settings.GPUprocessing = 0;
    settings.parallelProcessing = 0;
    settings.renderingQuality = 3;
    settings.version = appData.Version; % Version of what? Irbis or settings?
    settings.backgroundColor = [0 0 0];
    settings.predefinedFilterSettings = [];
    settings.pythonPath = [];
    settings.pymeshlabVersion = [];
    settings.askSaveBeforeClosing = 1;
    settings.askSaveBeforeNew = 1;
    settings.theme = 'dark'; % added 20251214
    settings.lightening = 'dynamic'; % added 20251222 dynamic/static
end