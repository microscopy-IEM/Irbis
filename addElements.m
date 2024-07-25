function [updatedCurrentIndex, updatedA] = addElements(currentIndex, A, newPositions, newElements)
    % Validate inputs
    if length(newPositions) ~= length(newElements)
        error('The length of newPositions and newElements must be the same.');
    end
    
    % Ensure new positions are within valid range
    if any(newPositions > length(currentIndex) + 1)
        error('New positions must be within the valid range.');
    end
    
    % Initialize updated arrays
    updatedCurrentIndex = currentIndex;
    updatedA = A;
    
    % Sort new positions and corresponding elements
    [newPositions, sortIdx] = sort(newPositions);
    newElements = newElements(sortIdx);
    
    % Insert new elements
    for i = 1:length(newPositions)
        pos = newPositions(i);
        elem = newElements{i};
        
        % Adjust the positions of existing elements in updatedCurrentIndex and updatedA
        if pos <= length(updatedCurrentIndex)
            updatedCurrentIndex = [updatedCurrentIndex(1:pos-1), 0, updatedCurrentIndex(pos:end)];
            updatedA = [updatedA(1:pos-1), {[]}, updatedA(pos:end)];
        else
            updatedCurrentIndex = [updatedCurrentIndex, 0];
            updatedA = [updatedA, {[]}];
        end
        
        % Insert the new element at the specified position
        updatedCurrentIndex(pos) = pos;
        updatedA{pos} = elem;
    end
    
    % Ensure that elements in updatedA are organized according to updatedCurrentIndex
    % Remove elements corresponding to 0s in updatedCurrentIndex
    nonZeroIndices = updatedCurrentIndex ~= 0;
    updatedCurrentIndex = updatedCurrentIndex(nonZeroIndices);
    updatedA = updatedA(nonZeroIndices);
end

% function [updatedCurrentIndex, updatedA] = addElements(currentIndex, A, newPositions, newElements)
%     % Validate inputs
%     if length(newPositions) ~= length(newElements)
%         error('The length of newPositions and newElements must be the same.');
%     end
% 
%     % Initialize updated arrays
%     updatedCurrentIndex = currentIndex;
%     updatedA = A;
% 
%     % Sort the new positions and corresponding elements
%     [newPositions, sortIdx] = sort(newPositions);
%     newElements = newElements(sortIdx);
% 
%     % Insert new elements
%     for i = 1:length(newPositions)
%         pos = newPositions(i);
%         elem = newElements{i};
% 
%         % Update currentIndex and A by inserting the new position and element
%         updatedCurrentIndex = [updatedCurrentIndex(1:pos-1), pos, updatedCurrentIndex(pos:end)];
%         updatedA = [updatedA(1:pos-1), elem, updatedA(pos:end)];
%     end
% 
%     % Ensure that elements in A are organized according to currentIndex
%     [~, sortIdx] = sort(updatedCurrentIndex);
%     updatedCurrentIndex = updatedCurrentIndex(sortIdx);
%     updatedA = updatedA(sortIdx);
% end