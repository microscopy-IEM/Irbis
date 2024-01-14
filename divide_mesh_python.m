function divide_mesh_python(pointA,pointB,depth,path)
    
    pathAdapted = strrep(path,'\','/');
    pyrunfile('divide_mesh_py_script.py',pointA=pointA,pointB=pointB,d=depth,path=pathAdapted);

end