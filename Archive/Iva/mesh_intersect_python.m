function mesh_intersect_python(path)

    pathAdapted = strrep(path,'\','/');    
    pyrunfile('mesh_intersect_py_script.py',path=pathAdapted);

end