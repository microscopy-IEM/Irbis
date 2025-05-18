function runSelectedTests()
    listPath = fullfile('ResultsViewer', 'tests', 'test_list.txt');

    fid = fopen(listPath, 'r');
    if fid == -1
        error('Could not open %s', listPath);
    end

    % Read each line, ensuring it is a character vector
    files = {};
    while ~feof(fid)
        line = fgetl(fid); % gets a char vector or -1
        if ischar(line) && ~isempty(strtrim(line))
            files{end+1} = strtrim(line); %#ok<AGROW>
        end
    end
    fclose(fid);    

    % Debug print: show what's read
    fprintf('Files read from %s:\n', listPath);
    disp(files');

    % Sanitize: ensure every entry is a valid string or char
    validMask = cellfun(@(f) ischar(f) || (isstring(f) && isscalar(f)), files);
    if ~all(validMask)
        disp('Invalid entries in test list:');
        disp(files(~validMask));
        error('Some entries in the test list are not valid strings.');
    end

    % Add paths
    testFolders = unique(cellfun(@fileparts, files, 'UniformOutput', false));
    for i = 1:numel(testFolders)
        addpath(testFolders{i});
    end

    % Now run the test suite
    suite = matlab.unittest.TestSuite.fromFile(files);
    results = run(suite);
    assertSuccess(results);
end
% function runSelectedTests()
%     listPath = fullfile('ResultsViewer', 'tests', 'test_list.txt');
%     % Add the folder containing the test files to the MATLAB path
%     testsFolder = fileparts(listPath);
%     addpath(genpath(testsFolder));
%     addpath(fullfile(testsFolder, '..', '..'))
%     % Read the file list safely
%     fid = fopen(listPath, 'r');
%     if fid == -1
%         error('Could not open %s', listPath);
%     end

%     files = {};
%     while ~feof(fid)
%         line = fgetl(fid);
%         if ischar(line)
%             line = strtrim(line);
%             if ~isempty(line)
%                 files{end+1} = line; %#ok<AGROW>
%             end
%         end
%     end
%     fclose(fid);

%     % Check for valid file names
%     if isempty(files)
%         error('No valid test files found in %s', listPath);
%     end
%     assert(all(cellfun(@(f) ischar(f) || (isstring(f) && isscalar(f)), files)), ...
%         'All test file entries must be string scalars or character vectors');

%     % Create and run test suite
%     suite = matlab.unittest.TestSuite.fromFile(files);
%     results = run(suite);
%     assertSuccess(results);
% end