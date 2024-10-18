classdef ManualCategorizationStorage < GroupingStorageBaseClass
    properties (Dependent)
        ManualCategorizations
    end

    methods
        function value = get.ManualCategorizations(obj)
            value = obj.Groupings;
        end
    end
end
