appDirectory = fileparts(mfilename("fullpath"));

subfoldersToAdd = {'Mesh processing toolbox', 'toolbox_fast_marching'};

for folderNum = 1:length(subfoldersToAdd)
    subfolder = subfoldersToAdd{folderNum};
    folderToAdd = fullfile(appDirectory, subfolder);
    allSubfolders = genpath(folderToAdd);
    addpath(allSubfolders);
    disp(['added: ',subfolder])
end
