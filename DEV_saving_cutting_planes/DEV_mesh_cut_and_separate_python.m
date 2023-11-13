function [n_spines,array] = DEV_mesh_cut_and_separate_python()
    
[n_spines,array] = pyrunfile('mesh_cut_and_separate_py_script.py','outcome');

end