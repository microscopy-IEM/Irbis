function pythonExe = initializePython()
    % This function initializes the Python environment for MATLAB. 
    % It checks if a bundled Python environment is already installed in the user's local application data folder. 
    % If not, it extracts the appropriate Python archive based on the operating system and sets up the environment. 
    % Finally, it configures MATLAB to use this Python environment.

    % Where the environment should live permanently
    localAppDataFolder = getLocalAppDataFolder();
    installDir = fullfile(localAppDataFolder, "python");

    if ispc
        pythonExe = fullfile(installDir, "python.exe");
    else
        pythonExe = fullfile(installDir, "bin", "python");
    end

    % First launch -> install Python
    if ~isfile(pythonExe)

        % Get the correct name based on the platform
        if ispc
            archiveName = "irbis-python-win64.tar.gz";
        elseif ismac
            archiveName = "irbis-python-mac.tar.gz";
        else
            archiveName = "irbis-python-linux.tar.gz";
        end

        % find the bundled Python folder in the ctfroot
        archive = which(archiveName);

        if ~isfile(archive)
            error("Bundled Python archive not found.");
        end

        if isfolder(installDir)
            rmdir(installDir, "s");
        end

        mkdir(installDir);

        untar(archive, installDir);

        % Run extraction - this does not work for me on Windows, I get Permission denied error on some dll file
        % Therefore, it is skipped and we hope that the Python environment is usable without it
        if ~ispc
            try
                runCondaUnpack(installDir);
            catch ME
                error("Failed to unpack the conda environment: %s", ME.message);
            end
        end
    end

    % Configure MATLAB
    pe = pyenv;

    if pe.Status == "Loaded"

        if ~strcmpi(string(pe.Executable), pythonExe)

            if pe.ExecutionMode == "OutOfProcess"
                terminate(pe);
            else
                error("Wrong Python already loaded.");
            end

        end

    end

    pyenv(Version = pythonExe, ExecutionMode = "OutOfProcess");
end




function runCondaUnpack(envFolder)

    arguments
        envFolder (1,1) string
    end

    % Run conda-unpack to fix the environment after moving it to a new location
    % For some reason, this does not work on Windows, so we skip it there
    if ispc
        return
    end

    unpackExe = fullfile(envFolder, "bin", "conda-unpack");

    if ~isfile(unpackExe)
        error("conda-unpack not found: %s", unpackExe);
    end

    [status, output] = system(sprintf('"%s"', unpackExe));

    if status ~= 0
        error("conda-unpack failed:%s%s", newline, output);
    end
end