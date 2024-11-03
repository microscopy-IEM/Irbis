function checkAndHandlePythonPackage(fig,settingsAppData,packageName)
    % Check if a Python package is installed

    pymeshlabVersion = '2023.12.post2';
    try
        py.importlib.import_module(packageName);
        disp([packageName ' is installed.']);
        % uialert(fig,'Pymeshlab is already installed.','success');

        % Special handling for the pymeshlab package to ensure version 2023.12.post2
        if strcmp(packageName, 'pymeshlab')
            % Retrieve version of the installed pymeshlab package
            version = char(py.importlib.metadata.version(packageName));
            
            if ~strcmp(version, pymeshlabVersion)
                disp(['Updating ' packageName ' to version ' pymeshlabVersion '.']);
                
                % Update the package to the required version
                commandStr = sprintf('"%s" -m pip install --upgrade %s==%s', pyenv().Executable, packageName, pymeshlabVersion);
                [status, cmdout] = system(commandStr);
                if status == 0
                    disp([packageName ' has been updated successfully.']);
                else
                    disp('Failed to update the package. Please check the error message:');
                    disp(cmdout);
                end
            else
                disp([packageName ' is already up to date.']);
            end
        end
    catch
        choice = questdlg([packageName ' is not installed. Would you like to install it, change the Python executable, or cancel?'], ...
            'Package Not Found', ...
            'Install', 'Change Python Executable', 'Cancel', ...
            'Cancel');
        
        switch choice
            case 'Install'
                % version = '2022.2.post4';
                if strcmp(packageName, 'pymeshlab')
                    version = pymeshlabVersion;
                    commandStr = sprintf('"%s" -m pip install %s==%s', pyenv().Executable, packageName, version);
                else
                    commandStr = sprintf('"%s" -m pip install %s', pyenv().Executable, packageName);
                end
                [status, cmdout] = system(commandStr);
                if status == 0
                    disp([packageName ' has been installed successfully.']);
                else
                    disp('Failed to install the package. Please check the error message:');
                end
                disp(cmdout);
                % uialert(fig,'You need to reset the app to apply the changes.','Warning');
            case 'Change Python Executable'
                % Prompt the user to select a new Python executable
                [file, path] = uigetfile({'python.exe'}, 'Select Python Executable');
                if isequal(file, 0) || isequal(path, 0)
                    disp('Operation cancelled. Python executable not changed.');
                else
                    pythonExecutablePath = fullfile(path, file);
                    settingsAppData.pythonPath = pythonExecutablePath;
                    disp(['Python environment will be updated to use: ', pythonExecutablePath]);
                    uialert(fig,'You need to reset the app to apply the changes.','Warning')
                    % pyenv('Version', pythonExecutablePath);
                    % disp(['Python environment updated to use: ', pythonExecutablePath]);
                end
            case 'Cancel'
                disp('Operation cancelled.');
        end
    end
end
