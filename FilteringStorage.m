classdef FilteringStorage < GroupingStorageBaseClass
    properties (Dependent)
        Filters
    end

    methods
        function value = get.Filters(obj)
            value = obj.Groupings;
        end

        function addRangeFilter(obj, columnName, range)
            conditions = struct();
            groupConditions = dictionary();
            operatorValueDict = dictionary(...
                'greaterThan', range(1), ...
                'lessThan', range(2));
            groupConditions(columnName) = {operatorValueDict};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);

            filterObj = Filtering(columnName,conditions);
            obj.Groupings{end+1} = filterObj;
        end

        function addCategoricalFilter(obj, columnName, categories)
            groupConditions = dictionary();
            groupConditions(columnName) = {categories};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);
            filterObj = Filtering(columnName,conditions);
            obj.Groupings{end+1} = filterObj;
        end

        function organizedConditions = getConditions(obj, columnName)
            filter = obj.returnGrouping(columnName);
            conditions = filter.Conditions.('group1').conditions(columnName);
            conditions = conditions{1};
            if iscell(conditions)
                organizedConditions = conditions;
            else
                organizedConditions = [conditions('greaterThan'),conditions('lessThan')];
            end
        end
    end
end