function mesh = find_closest_and_close_holes_python(mesh_data)

    assignin("base","mesh_data",mesh_data)

    max_hole_size=1000;
    match_threshold=0.1;
    early_stop_threshold=0.85;
    min_sample_size=50;

    % Call the Python function with the required arguments
    [output, matches] = pyrunfile('find_closest_and_close_holes_py_script.py', ...
                       ["output", "matches"], ...
                       mesh_data=mesh_data, ...
                       max_hole_size=max_hole_size, ...
                       match_threshold=match_threshold, ...
                       early_stop_threshold=early_stop_threshold, ...
                       min_sample_size=min_sample_size);

    % Extract vertices and faces
    vertices = double(output{'vertices'});
    faces = double(output{'faces'}) + 1;
    mesh = surfaceMesh(vertices, faces);

    disp('matches')
    disp(matches)

end

% function find_closest_and_close_holes_python(original_name,input_name,output_name,path)
% 
%     pathAdapted = strrep(path,'\','/');
%     pyrunfile('find_closest_and_close_holes_py_script.py',original_name=original_name,input_name=input_name,output_name=output_name,path=pathAdapted);
% 
% end