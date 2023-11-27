function n_spines = mesh_cut_and_separate_and_save_plane_python(path)
    
    pathAdapted = strrep(path,'\','/');
    n_spines = pyrunfile('mesh_cut_and_separate_and_save_plane_py_script.py','n_spines',path=pathAdapted);

end