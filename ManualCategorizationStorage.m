classdef ManualCategorizationStorage < GroupingStorageBaseClass
    properties (Dependent)
        ManualCategorizations
    end

    methods
        function value = get.ManualCategorizations(obj)
            value = obj.Groupings;
        end

        function listArray = editSelectedCategorization(obj, name, listArray)
            idx = obj.findGroupingIndexByName(name);
            grouping = obj.Groupings{idx};
            listArray = grouping.editCategoriesAndUpdateTable(listArray);
        end
    end
end
