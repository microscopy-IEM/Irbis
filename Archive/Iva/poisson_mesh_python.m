function poisson_pt = poisson_mesh_python(depth,input_name,output_name,path)
    
    pathAdapted = strrep(path,'\','/');
    poisson_pt = pyrunfile('poisson_mesh_py_script.py','output',d=depth,input_name=input_name,output_name=output_name,path=pathAdapted);

end