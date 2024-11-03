function n_spines = mesh_reconstruct_and_separate_python(depth,input_name,path)
    
    pathAdapted = strrep(path,'\','/');
    n_spines = pyrunfile('mesh_reconstruct_and_separate_py_script.py','n_spines',d=depth,input_name=input_name,path=pathAdapted);

end