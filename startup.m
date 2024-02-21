currentDirectory = pwd;
currentDirectory = strrep(currentDirectory,'\','/');
message = pyrunfile('githubcheck_startup_py_script.py','message',repo_path = currentDirectory);
disp('YOUR FRIENDLY UNICORN REMINDER')
disp(string(message))