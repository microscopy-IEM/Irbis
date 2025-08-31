classdef ArrayReordering
    methods(Static)

        function indexes = reorderElements(arrayLength, translatedIndexes, direction)
            if isempty(translatedIndexes)
                return;
            end

            indexes = 1:arrayLength;

            connectedGroups = ArrayReordering.separateNumbersIntoConsecutiveGroups(translatedIndexes);
            for i = 1:numel(connectedGroups)
                currentGroup = connectedGroups{i};
                firstIdx = currentGroup(1);
                lastIdx = currentGroup(end);
                if isequal(direction, 'up')
                    % this means that the element preceeding the group will have to move at the current last position within the group
                    if firstIdx > 1
                        indexes = ArrayReordering.moveArrayElement(indexes, firstIdx-1, lastIdx);
                    end      
                elseif isequal(direction, 'down')
                    % this means that the element following the group will have to move at the current first position within the group
                    if lastIdx < arrayLength
                        indexes = ArrayReordering.moveArrayElement(indexes, lastIdx+1, firstIdx);
                    end                            
                end
            end
        end



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


        
        function array = moveArrayElement(array, oldPosition, newPosition)
            % moving one element from position oldPosition to newPosition equals moving the elements in between one position up or down
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
            array(newPosition) = itemToMove;
        end
    end
end