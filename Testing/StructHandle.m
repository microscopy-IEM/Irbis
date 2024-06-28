classdef StructHandle < handle
    %STRUCTHANDLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
    end
    
    methods
        function obj = StructHandle(data)
            %STRUCTHANDLE Construct an instance of this class
            %   Detailed explanation goes here
            obj.data = data;
        end
    end
end

