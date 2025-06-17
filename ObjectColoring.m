classdef (Sealed) ObjectColoring 
    methods (Static)
        function colorIndividually(objectHandles, colorData, correspondingRowNames)
            nObjects = numel(objectHandles);
            
            % Loop through each object and update its color based on the corresponding row name
            for i = 1:nObjects
                % Retrieve the object's id from its UserData
                objectID = num2str(objectHandles(i).UserData);  % Assuming this is a string or compatible with row names
                
                % Check if the objectID exists as a row name in the table
                idx = find(strcmp(correspondingRowNames, objectID), 1);  % Find the row that matches the object ID
                
                if ~isempty(idx)
                    % Get the corresponding color from the ColorColumn
                    newColor = colorData{idx};  % Extract the color (assumed to be a 1x3 RGB vector)
                    
                    % Set the object's color to the new value
                    set(objectHandles(i), 'FaceColor', newColor);
                else
                    warning('ID "%s" not found in the table.', objectID);
                end
            end
        end


        function colorUniformly(objectHandles, color)
            % Sets all objects in the collection to the same specified color
            set(objectHandles, 'FaceColor', color);
        end
    end
end


