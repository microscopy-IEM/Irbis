classdef (Abstract) SpecialEffect 
    properties
        effectDuration
    end

    methods (Abstract)
        apply(obj, renderer)
    end
end