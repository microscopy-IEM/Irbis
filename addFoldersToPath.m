appDirectory = fileparts(mfilename("fullpath"));

if isdeployed
    return
end

addpath(appDirectory);

% subfoldersToAdd = {'Mesh_processing_toolbox', 'toolbox_fast_marching'};

subfoldersToAdd = {'BioformatsToolbox', 'toolbox_fast_marching', 'UI', 'DialogWindows', 'ResultsViewer', 'gizmo', 'CustomUIComponents', 'registrationHelpers', 'MightyDuck', 'automaticSpineCutting', 'pythonScripts', 'external'};
% ResultsViewer has to be included, because some classes are used in IrbisApp independently.
% Before, we were just adding ResultsViewer when opening ResultsViewer, but this is not enough.
for folderNum = 1:length(subfoldersToAdd)
    subfolder = subfoldersToAdd{folderNum};
    folderToAdd = fullfile(appDirectory, subfolder);
    allSubfolders = genpath(folderToAdd);
    addpath(allSubfolders);
    % disp(['added: ',subfolder])
end
