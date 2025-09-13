projectRoot = "C:\Users\sveco\Documents\Irbis";

% Create target build options object, set build properties and build.
buildOpts = compiler.build.StandaloneApplicationOptions(fullfile(projectRoot, "IrbisStart.mlapp"));
buildOpts.AdditionalFiles = [fullfile(projectRoot, "attach_objects_py_script.py"), fullfile(projectRoot, "attach_objects_trimesh_py_script.py"), fullfile(projectRoot, "find_intersection_volume_py_script.py"), fullfile(projectRoot, "fix_mesh_py_script.py"), fullfile(projectRoot, "mesh_intersect_and_separate_py_script.py"), fullfile(projectRoot, "mesh_intersect_and_separate_trimesh_py_script.py"), fullfile(projectRoot, "mesh_subtract_and_separate_and_save_plane_py_script.py"), fullfile(projectRoot, "mesh_subtract_and_separate_and_save_plane_trimesh_py_script.py"), fullfile(projectRoot, "mesh_subtract_cylinder_and_find_closest_py_script.py"), fullfile(projectRoot, "mesh_subtract_cylinder_and_find_closest_trimesh_py_script.py"), fullfile(projectRoot, "reconstruct_mesh_open3d_py_script.py"), fullfile(projectRoot, "reconstruct_mesh_py_script.py"), fullfile(projectRoot, "voxelizeMesh_py_script.py")];
buildOpts.AutoDetectDataFiles = true;
buildOpts.OutputDir = fullfile(projectRoot, "IrbisStart Standalone Application", "output", "build");
buildOpts.ObfuscateArchive = false;
buildOpts.Verbose = true;
buildOpts.EmbedArchive = true;
buildOpts.ExecutableIcon = fullfile(projectRoot, "icons", "irbis logo vect.png");
buildOpts.ExecutableName = "Irbis";
buildOpts.ExecutableSplashScreen = fullfile(projectRoot, "icons", "installScreen.png");
buildOpts.ExecutableVersion = "1.0";
buildOpts.TreatInputsAsNumeric = false;
buildResult = compiler.build.standaloneApplication(buildOpts);


% Create package options object, set package properties and package.
packageOpts = compiler.package.InstallerOptions(buildResult);
packageOpts.ApplicationName = "Irbis";
packageOpts.AuthorName = "Stepan Kortus, Iva Svecova";
packageOpts.InstallerIcon = fullfile(projectRoot, "icons", "irbis logo vect.png");
packageOpts.InstallerLogo = fullfile(projectRoot, "icons", "installScreen.png");
packageOpts.OutputDir = fullfile(projectRoot, "IrbisStart Standalone Application", "output", "package");
packageOpts.Verbose = true;
compiler.package.installer(buildResult, "Options", packageOpts);