function settings = getDefaultSettingsRV()
    % TO OPTIMIZE - rename to getResultsViewerSettingsConfig or something similar?
    settings.showDialogForSummarized = false;
    settings.binNumberInPivotedRows = 10;
    settings.binNumberInPivotedColumns = 10;
    settings.storedViews = ViewConfigurationStore();
    settings.throwawayColumnSelectionState = ThrowawayColumnSelectionState();
end