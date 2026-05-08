function [containsSynapse, intersectionVolume] = find_intersection_volume_python(spine_data, synapse_data)

    output = pyrunfile('find_intersection_volume_py_script.py','output', ...
        spine_data=spine_data, ...
        synapse_data=synapse_data);

    containsSynapse = logical(output{'contains_synapse'});
    intersectionVolume = double(output{'intersection_volume'});

end

% function results = find_intersection_volume_python(spine_name,synapses_name,path)
% 
%     pathAdapted = strrep(path,'\','/');
%     results = pyrunfile('find_intersection_volume_py_script.py','results',spine_name=spine_name,synapses_name=synapses_name,path=pathAdapted);
% 
% end