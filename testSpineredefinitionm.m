tolerance = 0.00001;
% % Check if each row in originalSpine has a close match in cut
% for i = 1:size(originalSpine, 1)
%     % Calculate the absolute difference between the current row and all rows in cut
%     diffs = abs(cut - originalSpine(i, :));
%     % Check if any row in cut is within the tolerance for all columns
%     is_match = any(all(diffs <= tolerance, 2));
%     % Store the result for this row
%     all_rows_present(i) = is_match;
% end

% Define tolerance
% tolerance = 0.1;

% Initialize a cell array to store matching row pairs
matchingRows = {};

% Check each row in originalSpine for a close match in cut
for i = 1:size(originalSpine, 1)
    % Calculate the absolute difference between the current row and all rows in cut
    diffs = abs(cut - originalSpine(i, :));
    % Find rows in cut within the tolerance for all columns
    is_match = all(diffs <= tolerance, 2);
    
    % If a match is found, store the pairs
    if any(is_match)
        matched_rows = cut(is_match, :); % Rows in `cut` that match the current row in `originalSpine`
        matchingRows{end+1} = struct('OriginalRow', originalSpine(i, :), 'MatchingRows', matched_rows);
    end
end

% Display matching rows
if ~isempty(matchingRows)
    disp('Matching rows within tolerance:')
    % for k = 1:numel(matchingRows)
    %     disp(['Original row: ', mat2str(matchingRows{k}.OriginalRow)]);
    %     disp(['Matching row(s) in cut:']);
    %     disp(matchingRows{k}.MatchingRows);
    % end

    disp(numel(matchingRows))
else
    disp('No matching rows found within the specified tolerance.');
end
