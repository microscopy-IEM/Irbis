function n_spines = mesh_cut_and_separate_python(path)

    pathAdapted = strrep(path,'\','/');
    n_spines = pyrunfile('mesh_cut_and_separate_py_script.py','n_spines',path=pathAdapted);

end