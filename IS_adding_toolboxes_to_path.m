appDirectory = fileparts(mfilename("fullpath"));

% subfoldersToAdd = {'Mesh_processing_toolbox', 'toolbox_fast_marching'};

subfoldersToAdd = {'toolbox_fast_marching', 'UI', 'DialogWindows', 'ResultsViewer', 'gizmo'};
% ResultsViewer has to be included, because some classes are used in IrbisApp independently (such as user-defined columns)
    % before, we were just adding it when opening ResultsViewer, but this is not enough
for folderNum = 1:length(subfoldersToAdd)
    subfolder = subfoldersToAdd{folderNum};
    folderToAdd = fullfile(appDirectory, subfolder);
    allSubfolders = genpath(folderToAdd);
    addpath(allSubfolders);
    % disp(['added: ',subfolder])
end
