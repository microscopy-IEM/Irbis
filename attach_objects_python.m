function attach_objects_python(objectNumber,path)

    pathAdapted = strrep(path,'\','/');
    pyrunfile('attach_objects_py_script.py',objectNumber=objectNumber,path=pathAdapted);

end