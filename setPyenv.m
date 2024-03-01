function setPyenv()
    % if isdeployed
        desiredVersion = '3.10'; % Specify the Python version you're looking for
        try
            % Execute 'where python' to find all Python executables
            [~, cmdout] = system('where python');
            
            % Split the output by newlines to get individual paths
            pythonExecutables = strsplit(cmdout, '\n');
            disp(numel(pythonExecutables))
            
            % Initialize pythonPath
            pythonPath = '';
            
            % Loop through the executables to find the desired version
            for i = 1:length(pythonExecutables)
                executable = pythonExecutables{i};
                disp(i)
                disp(executable)
                if contains(executable, '.exe')
                    % Check the version of each executable
                    [~, versionOut] = system(['"' executable '" --version']);
                    if contains(versionOut, ['Python ' desiredVersion])
                        pythonPath = executable;
                        break; % Stop loop once the desired version is found
                    end
                end
            end
            
            % If a matching version was found, set it in pyenv
            if ~isempty(pythonPath)
                pyenv('Version', pythonPath);
                disp(['Python version set to: ' pythonPath]);
            else
                warning(['Python ' desiredVersion ' not found.']);
            end
        catch
            % Error handling
            warning('Failed to set up Python');
        end
    % else
        % Optional: Handle the non-deployed scenario, possibly setting pyenv for development use
    % end
    % Optional: print out pyenv to check and test with py.list
    % disp(pyenv);
    % demo = py.list('demo');
end
