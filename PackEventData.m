classdef PackEventData < event.EventData
    % Class enabling passing data between custom components and main app. 
    % The input is supposed to be structure with all needed fields. 
    
    properties
        Data    % structure
    end

    methods
        function eventData = PackEventData(data)
            eventData.Data = data;
        end
    end
end