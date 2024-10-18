classdef ManualCategorization < GroupingBaseClass 

    methods
        function obj = ManualCategorization(name, categories)
            % categories is a cell array of category names - transformed into the conditions structure
            categories
            length(categories)
            categories{2}
            conditions = getConditionsFromCategoryList(categories);
            obj@GroupingBaseClass(name, conditions);
        end
    end
end