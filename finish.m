disp('I am closing')

currentDirectory = pwd;
currentDirectory = strrep(currentDirectory,'\','/');
pyrunfile('githubcheck_finish_py_script.py',repo_path=currentDirectory)