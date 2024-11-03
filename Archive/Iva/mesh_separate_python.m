function n_spines = mesh_separate_python(input_name,path)
    
    pathAdapted = strrep(path,'\','/');
    n_spines = pyrunfile('mesh_separate_py_script.py','n_spines',input_name=input_name,path=pathAdapted);

end