classdef Categorization < handle
    properties
        CategorizationName
        Conditions
    end
    
    methods
        function obj = Categorization(categoryName, conditions)
            obj.CategorizationName = categoryName;
            obj.Conditions = conditions;
        end
        
        function listArray = updateTable(obj, listArray, timePoints)
            if istable(listArray)
                table = listArray;
                category = obj.evaluateConditions(table);
                table.(obj.CategorizationName) = categorical(category);
                listArray = table;
            else
                for tp = timePoints
                    table = listArray{tp};
                    if istable(table)
                        category = obj.evaluateConditions(table);
                        table.(obj.CategorizationName) = categorical(category);
                        listArray{tp} = table;
                    end
                end
            end
        end
        
        function obj = renameGroup(obj)
            groups = fieldnames(obj.Conditions);
            numGroups = numel(groups);
            currentNames = cell(numGroups, 1);
            for i = 1:numel(groups)
                currentNames{i} = obj.Conditions.(groups{i}).name;
            end
            prompt = strcat('Enter new name for: ', currentNames);
            dlgTitle = 'Rename Groups';
            dims = [1 50];
            defaultInputs = currentNames;
            newNames = inputdlg(prompt, dlgTitle, dims, defaultInputs);
            if ~isempty(newNames)
                for i = 1:numel(groups)
                    obj.Conditions.(groups{i}).name = newNames{i};
                end


            end
        end
        
        function groupNames = getGroupNames(obj)
            groups = fieldnames(obj.Conditions);
            groupNames = cell(size(groups));
            for i = 1:numel(groups)
                groupNames{i} = obj.Conditions.(groups{i}).name;
            end
        end
        
        function groupConditions = getGroupConditions(obj, groupName)
            groups = fieldnames(obj.Conditions);
            for i = 1:numel(groups)
                if strcmp(obj.Conditions.(groups{i}).name, groupName)
                    groupConditions = obj.Conditions.(groups{i}).conditions;
                    return;
                end
            end
            error('Group name %s not found', groupName);
        end
        
        function obj = updateGroupConditions(obj, groupName, newConditions)
            groups = fieldnames(obj.Conditions);
            for i = 1:numel(groups)
                if strcmp(obj.Conditions.(groups{i}).name, groupName)
                    obj.Conditions.(groups{i}).conditions = newConditions;
                    return;
                end
            end
            error('Group name %s not found', groupName);
        end
        
        function listArray = promptAndUpdateConditions(obj, listArray, timePoints)
            groups = fieldnames(obj.Conditions);
            numGroups = numel(groups);
            for i = 1:numel(groups)
                groupName = obj.Conditions.(groups{i}).name;
                currentConditions = obj.Conditions.(groups{i}).conditions;
                condFields = keys(currentConditions);
                prompt = {};
                defaultInputs = {};
                for j = 1:numel(condFields)
                    condDict = currentConditions(condFields{j});
                    if iscell(condDict)  % Check if it is a list of selected categories
                        prompt{end+1} = sprintf('Selected categories for %s in %s', condFields{j}, groupName);
                        defaultInputs{end+1} = strjoin(condDict, ',');
                    else
                        condKeys = keys(condDict);
                        for k = 1:numel(condKeys)
                            prompt{end+1} = sprintf('%s %s for %s', condKeys{k}, condFields{j}, groupName);
                            defaultInputs{end+1} = num2str(condDict(condKeys{k}));
                        end
                    end
                end
                dlgTitle = sprintf('Update Conditions for %s', groupName);
                dims = [1 50];
                newValues = inputdlg(prompt, dlgTitle, dims, defaultInputs);
                if ~isempty(newValues)
                    newConditions = dictionary(string.empty, {});
                    valueIndex = 1;
                    for j = 1:numel(condFields)
                        condDict = currentConditions(condFields{j});
                        if iscell(condDict)  % Check if it is a list of selected categories
                            newConditions(condFields{j}) = strsplit(newValues{valueIndex}, ',');
                            valueIndex = valueIndex + 1;
                        else
                            condKeys = keys(condDict);
                            newCondDict = dictionary(string.empty, []);
                            for k = 1:numel(condKeys)
                                newCondDict(condKeys{k}) = str2double(newValues{valueIndex});
                                valueIndex = valueIndex + 1;
                            end
                            newConditions(condFields{j}) = {newCondDict};
                        end
                    end
                    obj = obj.updateGroupConditions(groupName, newConditions);
                end
            end
            listArray = obj.updateTable(listArray, timePoints);
        end
        
        function categories = evaluateConditions(obj, table)
            categories = repmat("Uncategorized", height(table), 1);
            fields = fieldnames(obj.Conditions);
            assignin("base","conds",obj.Conditions)
            for i = 1:numel(fields)
                group = fields{i};
                groupName = obj.Conditions.(group).name;
                conds = obj.Conditions.(group).conditions;
                match = true(height(table), 1);
                condFields = keys(conds);
                for j = 1:numel(condFields)
                    condValue = conds(condFields{j});
                    if ~ismember(condFields{j}, table.Properties.VariableNames)
                        error('Categorization:ColumnNotInTable', ...
                            'The column name used in the categorization is not present in the data.');
                    end
                    % if iscell(condValue)  % List of selected categories
                    %     match = match & ismember(table.(condFields{j}), condValue);
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
                        % class(table.(condFields{j}))
                        % class(condValue{1})
                        condValue{1} = categorical(condValue{1});
                        % class(table.(condFields{j}))
                        % class(condValue{1})
                        match = match & ismember(categorical(table.(condFields{j})), condValue{1});
                    end
                end
                categories(match) = groupName;
            end
        end
    end
end