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
                if isempty(filterArray)
                    filterArray = arrayfun(@(~) table(), zeros(1, numel(timePoints)), 'UniformOutput', false);
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
            % TO FIX - this version has an ugly patch for groupId, which is double in the main app and categorical in ResultsViewer
            % to avoid errors, it is easiest to do that here, but for the future, it should be unified to one type in both places
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
                        % TEMP FIX - this patch fixes the issue when we have numerical comparators, but the groupId is categorical 
                        % conver the groupId categorical values to double: 
                        if isequal(condFields{j}, 'groupId') && isequal(class(table.(condFields{j})), 'categorical')
                            table.(condFields{j}) = str2double(string(table.(condFields{j})));  % convert to string first to preserve the actual values rather than just indices
                            disp('Applied temporary patch to convert groupId from categorical to double for comparison with numerical conditions');
                        end
                        condDict = condValue{1};
                        condKeys = keys(condDict);
                        for k = 1:numel(condKeys)
                            comparator = condKeys{k};
                            value = condDict(comparator);
                            switch comparator
                                case 'lessThan'
                                    match = match & (table.(condFields{j}) < value);
                                case 'equalOrLessThan'
                                    match = match & (table.(condFields{j}) <= value);
                                case 'greaterThan'
                                    match = match & (table.(condFields{j}) > value);
                                case 'equalOrGreaterThan'
                                    match = match & (table.(condFields{j}) >= value);
                                case 'equals'
                                    match = match & (table.(condFields{j}) == value);
                                case 'notEqual'
                                    match = match & (table.(condFields{j}) ~= value);
                                otherwise
                                    error('Unsupported comparator: %s', comparator);
                            end
                        end
                    else
                        if isequal(condFields{j}, 'groupId') && isequal(class(table.(condFields{j})), 'double')
                            table.(condFields{j}) = categorical(string(table.(condFields{j})));  
                            disp('Applied temporary patch to convert groupId from double to categorical for comparison with categorical conditions');
                        end
                        condValue{1} = categorical(condValue{1});
                        match = match & ismember(categorical(table.(condFields{j})), condValue{1});
                    end
                end
                groups(match) = groupName;
            end
        end    

        % function groups = evaluateConditions(obj, table, initialList)
        %     groups = initialList;
        %     fields = fieldnames(obj.Conditions);
        %     for i = 1:numel(fields)
        %         group = fields{i};
        %         groupName = obj.Conditions.(group).name;
        %         conds = obj.Conditions.(group).conditions;
        %         match = true(height(table), 1);
        %         condFields = keys(conds);
        %         for j = 1:numel(condFields)
        %             condValue = conds(condFields{j});
        %             if isequal(class(condValue{1}),'dictionary')
        %                 condDict = condValue{1};
        %                 condKeys = keys(condDict);
        %                 for k = 1:numel(condKeys)
        %                     comparator = condKeys{k};
        %                     value = condDict(comparator);
        %                     switch comparator
        %                         case 'lessThan'
        %                             match = match & (table.(condFields{j}) < value);
        %                         case 'equalOrLessThan'
        %                             match = match & (table.(condFields{j}) <= value);
        %                         case 'greaterThan'
        %                             match = match & (table.(condFields{j}) > value);
        %                         case 'equalOrGreaterThan'
        %                             match = match & (table.(condFields{j}) >= value);
        %                         case 'equals'
        %                             match = match & (table.(condFields{j}) == value);
        %                         case 'notEqual'
        %                             match = match & (table.(condFields{j}) ~= value);
        %                         otherwise
        %                             error('Unsupported comparator: %s', comparator);
        %                     end
        %                 end
        %             else
        %                 condValue{1} = categorical(condValue{1});
        %                 match = match & ismember(categorical(table.(condFields{j})), condValue{1});
        %             end
        %         end
        %         groups(match) = groupName;
        %     end
        % end    
    end
end