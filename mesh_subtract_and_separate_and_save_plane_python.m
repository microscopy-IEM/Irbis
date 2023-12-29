function n_objects = mesh_subtract_and_separate_and_save_plane_python(path)
    
    pathAdapted = strrep(path,'\','/');
    n_objects = pyrunfile('mesh_subtract_and_separate_and_save_plane_py_script.py','n_objects',path=pathAdapted);

end