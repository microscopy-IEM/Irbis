function settings = getDefaultSettings(appData)
    settings.Paths = {' '};
    settings.currentPath = 1;
    settings.GPUprocessing = 0;
    settings.parallelProcessing = 0;
    settings.renderingQuality = 3;
    settings.version = appData.Version;
    settings.backgroundColor = [0 0 0];
    settings.predefinedFilterSettings = [];
    settings.pythonPath = [];
    settings.askSaveBeforeClosing = 1;
    settings.askSaveBeforeNew = 1;
end