% startup.m

% % Define the local repository path and remote branch
% localRepoPath = '/path/to/your/local/repo';
% remoteBranch = 'origin/main';

% Call the function to check the git status
try
    check_git_status;
catch
    warning('An error occurred while checking the git status.');
end

disp('end of the script')