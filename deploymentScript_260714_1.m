projectRoot = "C:\Users\iva.svecova\Documents\MMPack";

% Create target build options object, set build properties and build.
buildOpts = compiler.build.StandaloneApplicationOptions(fullfile(projectRoot, "IrbisStart.mlapp"));
buildOpts.AdditionalFiles = [fullfile(projectRoot, "BioformatsToolbox"), fullfile(projectRoot, "CustomUIComponents", "icons"), fullfile(projectRoot, "icons"), fullfile(projectRoot, "pythonBundled"), fullfile(projectRoot, "pythonScripts")];
buildOpts.AutoDetectDataFiles = true;
buildOpts.OutputDir = fullfile(projectRoot, "IrbisPackaged", "output", "build");
buildOpts.SupportPackages = "none";
buildOpts.ObfuscateArchive = false;
buildOpts.Verbose = true;
buildOpts.EmbedArchive = true;
buildOpts.ExecutableIcon = fullfile(projectRoot, "icons", "irbis logo vect.png");
buildOpts.ExecutableName = "IrbisApp";
buildOpts.ExecutableSplashScreen = fullfile(projectRoot, "icons", "icon.png");
buildOpts.ExecutableVersion = "1.0";
buildOpts.TreatInputsAsNumeric = false;
buildResult = compiler.build.standaloneApplication(buildOpts);


% Create package options object, set package properties and package.
packageOpts = compiler.package.InstallerOptions(buildResult);
packageOpts.ApplicationName = "Irbis";
packageOpts.AuthorName = "Stepan Kortus, Iva Svecova";
packageOpts.AuthorCompany = "Institute of Experimental Medicine, CAS";
packageOpts.InstallerIcon = fullfile(projectRoot, "icons", "irbis logo vect.png");
packageOpts.InstallerLogo = fullfile(projectRoot, "icons", "installScreenR.png");
packageOpts.InstallerName = "IrbisInstaller";
packageOpts.InstallerSplash = fullfile(projectRoot, "icons", "icon.png");
packageOpts.OutputDir = fullfile(projectRoot, "IrbisPackaged", "output", "package");
packageOpts.Verbose = true;
compiler.package.installer(buildResult, "Options", packageOpts);