classdef ValueChangedEventData < event.EventData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        NewValue
    end

    methods
        function eventData = ValueChangedEventData(newValue)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            eventData.NewValue = newValue;
        end
    end
end