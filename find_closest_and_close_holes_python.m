function find_closest_and_close_holes_python(original_name,input_name,output_name,path)

    pathAdapted = strrep(path,'\','/');
    pyrunfile('find_closest_and_close_holes_py_script.py',original_name=original_name,input_name=input_name,output_name=output_name,path=pathAdapted);

end