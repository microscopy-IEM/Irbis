function close_holes_python(input_name,output_name,path)

    pathAdapted = strrep(path,'\','/');
    pyrunfile('close_holes_py_script.py',input_name=input_name,output_name=output_name,path=pathAdapted);

end