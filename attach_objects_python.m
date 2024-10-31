function [joined_vertices, joined_faces] = attach_objects_python(mesh_data)

    joined_dict = pyrunfile('attach_objects_py_script.py',"joined_dict",mesh_data=mesh_data);

    % Access the vertices and faces from the Python dictionary
    joined_vertices = double(joined_dict{'vertices'});
    joined_faces = double(joined_dict{'faces'}) + 1;    % needs to be converted to Matlab's numbering from 1 instead of Python's from 0

end

% function attach_objects_python(objectNumber,path)
% 
%     pathAdapted = strrep(path,'\','/');
%     pyrunfile('attach_objects_py_script.py',objectNumber=objectNumber,path=pathAdapted);
% 
% end