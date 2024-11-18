classdef GroupIdFiltering < Filtering
    properties 
        FilteredVariable
    end

    methods
        function obj = GroupIdFiltering(name, conditions, active, filteredVariable)
            obj@Filtering(name, conditions, active);

            obj.FilteredVariable = filteredVariable;
        end
    end
end