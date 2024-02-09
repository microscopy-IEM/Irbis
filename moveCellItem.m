function array = moveCellItem(array, oldPosition, newPosition)
    % Check if positions are within the bounds of the cell array
    if oldPosition < 1 || oldPosition > length(array) || newPosition < 1 || newPosition > length(array)
        error('Positions are out of the array bounds.');
    end
    
    % Extract the cell item to move
    itemToMove = array(oldPosition); % Note the use of parentheses to keep the cell wrapper
    
    % If moving forward in the list
    if newPosition > oldPosition
        % Shift cells between the old and new positions left
        array(oldPosition:newPosition-1) = array(oldPosition+1:newPosition);
    % If moving backward in the list
    elseif oldPosition > newPosition
        % Shift cells between the new and old positions right
        array(newPosition+1:oldPosition) = array(newPosition:oldPosition-1);
    else
        % If oldPosition and newPosition are the same, do nothing
        return;
    end
    
    % Place the cell item in its new position
    array(newPosition) = itemToMove; % Use parentheses to insert the cell without unwrapping
end
