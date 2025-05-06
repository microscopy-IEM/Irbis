classdef Categorization < handle
    properties
        CategorizationName
        Conditions
        definitionType = 'categorization'
    end
    
    methods
        function obj = Categorization(categoryName, conditions)
            obj.CategorizationName = categoryName;
            obj.Conditions = conditions;
        end

        function definitionType = getDefinitionType(obj)
            % Returns the definition type of the column
            % Returns: string indicating the definition type
            definitionType = obj.definitionType;
        end

        function columnName = getColumnName(obj)
            % Returns the name of the column
            % Returns: string of the column name
            columnName = obj.CategorizationName;
        end

        function conditions = getConditions(obj)
            conditions = obj.Conditions;
        end

        function conditions = getRules(obj)
            % The same as getConditions, added for compatibility with other classes
            conditions = obj.Conditions;
        end

        function obj = replaceRules(obj, newRules)
            % Opens a dialog to edit existing creation parameters
            % Internally edits the rules
            obj.Conditions = newRules;
        end

        function data = generateColumn(obj, inputData)
            % Generates column data based on defined rules
            % Args: inputData - source data for column generation
            % Returns: column data array
            
            if istable(inputData)
                data = categorical(obj.evaluateConditions(inputData));
            else
                data = cell(size(inputData, 1), 1);
                for i = 1:size(inputData, 1)
                    data{i} = categorical(obj.evaluateConditions(inputData{i}));
                end
            end
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

        function columnNames = getRequiredColumns(obj)
            % Returns a list of column names required for evaluation
            % Returns: cell array of unique column names
            columnNames = {};
            fields = fieldnames(obj.Conditions);
            for i = 1:numel(fields)
                conds = obj.Conditions.(fields{i}).conditions;
                condFields = keys(conds);
                columnNames = [columnNames; condFields(:)];
            end
            columnNames = unique(columnNames);
        end
    end
end