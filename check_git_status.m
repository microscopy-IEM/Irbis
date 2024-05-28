function check_git_status()
    % This function checks if the local repository is up to date with the remote repository.
    % localRepoPath: The path to the local git repository.
    % remoteBranch: The remote branch to compare against (e.g., 'origin/main').

    % Fetch the latest changes from the remote repository
    [status, fetchOutput] = system('git fetch');

    if status ~= 0
        error('Failed to fetch from the remote repository: %s', fetchOutput);
    end

    % Check the status of the local branch compared to the remote branch
    [status, statusOutput] = system('git status -uno');

    if status ~= 0
        error('Failed to get the status of the repository: %s', statusOutput);
    end

    % Check for untracked files and uncommitted changes
    [status, changesOutput] = system('git status --porcelain');
    if status ~= 0
        error('Failed to get the status of the repository: %s', changesOutput);
    end

    uncommittedChanges = ~isempty(strtrim(changesOutput));

    % Parse the output to determine if the local repository is up to date
    if contains(statusOutput, 'Your branch is up to date')
        disp('The local repository is up to date with the remote repository.');
        % close_all_open_documents
        % pull(gitrepo)
        % disp('Changes pulled.')
    elseif contains(statusOutput, 'Your branch is behind')
        if uncommittedChanges
            choice = questdlg('There are uncommitted changes. Do you want to pull the remote changes anyway?', ...
                'Uncommitted Changes', ...
                'Yes', 'No', 'No');
            if strcmp(choice, 'Yes')
                close_all_open_documents
                pull(gitrepo)
                disp('Changes pulled.')
            else
                disp('Pull operation aborted by the user.');
            end
        else
            disp('The local repository is behind the remote repository. I am pulling the changes now.');
            notifyUser('The local repository is behind the remote repository. I am pulling the changes now.');
            close_all_open_documents
            pull(gitrepo)
            disp('Changes pulled.')
        end
    elseif contains(statusOutput, 'Your branch is ahead')
        disp('The local repository is ahead of the remote repository.');
        notifyUser('The local repository is ahead of the remote repository.');
    elseif contains(statusOutput, 'have diverged')
        disp('The local and remote repositories have diverged.');
        notifyUser('The local and remote repositories have diverged.');
    else
        disp('The status of the local repository is unclear. Please check manually.');
    end
end

function notifyUser(message)
    % This function notifies the user with the given message.
    % Customize this function to use any notification method you prefer.
    % For simplicity, we use a simple dialog box here.
    disp(message);
    msgbox(message, 'Git Status Notification');
end

function close_all_open_documents()
    % This function closes all open documents in the Matlab editor.
    allDocs = matlab.desktop.editor.getAll;
    for i = 1:numel(allDocs)
        allDocs(i).close;
    end
    disp('All open editor documents have been closed.');
end