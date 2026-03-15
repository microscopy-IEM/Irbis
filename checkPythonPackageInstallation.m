function checkPythonPackageInstallation(fig)
    % List of packages to check
    packages = ["numpy", "trimesh", "scipy", "manifold3d", "networkx", "open3d", "pymeshfix", "skimage"];

    % Loop through and check each package
    missing_packages = [];
    for pkg = packages
        is_installed = pyrun("import importlib.util; result = importlib.util.find_spec('" + pkg + "') is not None", "result");
        if is_installed
            disp(pkg + " is installed.");
        else
            disp(pkg + " is NOT installed.");
            missing_packages = [missing_packages, pkg];
        end
    end

    % Display message if any packages are missing
    if ~isempty(missing_packages)
        msg = "The following Python packages are missing and need to be installed:" + newline;
        for pkg = missing_packages
            msg = msg + " - " + pkg + newline;
        end
        msg = msg + "Please install these packages before continuing.";
        disp(msg);
        % Create a dialog box to display the message
        uialert(fig, msg, 'Missing Python packages');
    else
        disp("All required Python packages are installed.");
    end
end
