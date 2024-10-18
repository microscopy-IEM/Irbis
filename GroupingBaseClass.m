classdef GroupingBaseClass < handle
    properties
        Name
        Conditions
    end

    methods
        function obj = GroupingBaseClass(name, conditions)
            obj.Name = name;
            obj.Conditions = conditions;
        end

        function categoryNames = getCategoryNames(obj)
            groups = fieldnames(obj.Conditions);
            categoryNames = cell(size(groups));
            for i = 1:numel(groups)
                categoryNames{i} = obj.Conditions.(groups{i}).name;
            end
        end

        function groupConditions = getGroupConditions(obj, groupName)
            groups = fieldnames(obj.Conditions);
            for i = 1:numel(groups)
                if isequal(obj.Conditions.(groups{i}).name, groupName)
                    groupConditions = obj.Conditions.(groups{i}).conditions;
                    return;
                end
            end
            error('Group name %s not found', groupName);
        end

        function listArray = updateTable(obj, listArray, timePoints)
            if istable(listArray)
                disp('listArray is a table')
                table = listArray;
                category = obj.evaluateConditions(table);
                table.(obj.Name) = categorical(category);
                listArray = table;
            else
                for tp = timePoints
                    table = listArray{tp};
                    category = obj.evaluateConditions(table);
                    table.(obj.Name) = categorical(category);
                    listArray{tp} = table;
                end
            end
        end

        function filterArray = updateFilterTable(obj, listArray, filterArray, timePoints)
            if istable(listArray)
                listTable = listArray;
                filterTable = filterArray;
                category = obj.evaluateConditions(listTable);
                filterTable.(obj.Name) = logical(category);
                filterArray = filterTable;
            else
                if isempty(listArray)
                    return
                end
                for tp = timePoints
                    listTable = listArray{tp};
                    filterTable = filterArray{tp};
                    category = obj.evaluateConditions(listTable);
                    filterTable.(obj.Name) = logical(category);
                    filterArray{tp} = filterTable;
                end
            end
        end

        function groups = evaluateConditions(obj, table, initialList)
            groups = initialList;
            fields = fieldnames(obj.Conditions);
            for i = 1:numel(fields)
                group = fields{i};
                groupName = obj.Conditions.(group).name;
                conds = obj.Conditions.(group).conditions;
                match = true(height(table), 1);
                condFields = keys(conds);
                for j = 1:numel(condFields)
                    condValue = conds(condFields{j});
                    if isequal(class(condValue{1}),'dictionary')
                        condDict = condValue{1};
                        condKeys = keys(condDict);
                        for k = 1:numel(condKeys)
                            comparator = condKeys{k};
                            value = condDict(comparator);
                            switch comparator
                                case 'lessThan'
                                    match = match & (table.(condFields{j}) < value);
                                case 'greaterThan'
                                    match = match & (table.(condFields{j}) > value);
                                case 'equals'
                                    match = match & (table.(condFields{j}) == value);
                                otherwise
                                    error('Unsupported comparator: %s', comparator);
                            end
                        end
                    else
                        condValue{1} = categorical(condValue{1});
                        match = match & ismember(categorical(table.(condFields{j})), condValue{1});
                    end
                end
                groups(match) = groupName;
            end
        end    
    end
end