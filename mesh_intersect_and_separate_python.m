function n_objects = mesh_intersect_and_separate_python(path)

    pathAdapted = strrep(path,'\','/');    
    n_objects = pyrunfile('mesh_intersect_and_separate_py_script.py','n_objects',path=pathAdapted);

end