classdef ValueChangedEventData < event.EventData
    
    properties
        NewValue
    end

    methods
        function eventData = ValueChangedEventData(newValue)
            eventData.NewValue = newValue;
        end


    end
end