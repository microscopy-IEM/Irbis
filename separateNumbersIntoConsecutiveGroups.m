function groups = separateNumbersIntoConsecutiveGroups(array)
    % Initialize the first group with the first element of the array
    groups = {array(1)};
    currentGroupIndex = 1;
    
    % Iterate over the array starting from the second element
    for i = 2:length(array)
        if array(i) == array(i-1) + 1
            % If the current element is consecutive, add it to the current group
            groups{currentGroupIndex} = [groups{currentGroupIndex}, array(i)];
        else
            % If not consecutive, start a new group
            currentGroupIndex = currentGroupIndex + 1;
            groups{currentGroupIndex} = array(i);
        end
    end
end
