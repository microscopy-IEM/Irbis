classdef CategoryManager
    properties
        CategoryName
        Conditions
    end
    
    methods
        function obj = CategoryManager(categoryName, conditions)
            % Constructor to initialize the category manager
            obj.CategoryName = categoryName;
            obj.Conditions = conditions;
        end
        
        function listArray = updateTable(obj, listArray, timePoints)
            % Method to update the table with the category
            % listArray: cell array of tables, each cell for one time point
            % timePoints: array of time points that should be accessed

            % Get the table for each time point
            for tp = timePoints
                table = listArray{tp};
                
                % Apply the condition function to each row
                category = arrayfun(@(row) evaluateConditions(table(row, :), obj.Conditions), 1:height(table), 'UniformOutput', false);
                
                % Add the category as a new column to the table
                table.(obj.CategoryName) = categorical(category);
                
                % Update the cell array with the modified table
                listArray{tp} = table;
            end
        end
        
       function obj = renameGroup(obj)
            % Method to rename groups in the conditions structure via dialog window
            groups = fieldnames(obj.Conditions);
            numGroups = numel(groups);
            
            % Get current group names
            currentNames = cell(numGroups, 1);
            for i = 1:numel(groups)
                currentNames{i} = obj.Conditions.(groups{i}).name;
            end
            
            % Create input dialog
            prompt = strcat('Enter new name for: ', currentNames);
            dlgTitle = 'Rename Groups';
            dims = [1 50]; % Dimensions for input fields
            defaultInputs = currentNames;
            
            % Show dialog and get user input
            newNames = inputdlg(prompt, dlgTitle, dims, defaultInputs);
            
            % Update group names if user provided new names
            if ~isempty(newNames)
                for i = 1:numel(groups)
                    obj.Conditions.(groups{i}).name = newNames{i};
                end
            end
        end
        
        function groupNames = getGroupNames(obj)
            % Method to get all group names
            groups = fieldnames(obj.Conditions);
            groupNames = cell(size(groups));
            for i = 1:numel(groups)
                groupNames{i} = obj.Conditions.(groups{i}).name;
            end
        end
        
        function groupConditions = getGroupConditions(obj, groupName)
            % Method to get conditions for a specific group by name
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
            % Method to update conditions for a specific group
            groups = fieldnames(obj.Conditions);
            for i = 1:numel(groups)
                if strcmp(obj.Conditions.(groups{i}).name, groupName)
                    obj.Conditions.(groups{i}).conditions = newConditions;
                    return;
                end
            end
            error('Group name %s not found', groupName);
        end
        
        function obj = promptAndUpdateConditions(obj, listArray, timePoints)
            % Method to prompt user for new conditions and update tables
            groups = fieldnames(obj.Conditions);
            numGroups = numel(groups);
            
            for i = 1:numel(groups)
                groupName = obj.Conditions.(groups{i}).name;
                currentConditions = obj.Conditions.(groups{i}).conditions;
                condFields = fieldnames(currentConditions);
                
                prompt = {};
                defaultInputs = {};
                for j = 1:numel(condFields)
                    prompt{end+1} = sprintf('%s for %s', condFields{j}, groupName);
                    defaultInputs{end+1} = num2str(currentConditions.(condFields{j}).value);
                end
                
                dlgTitle = sprintf('Update Conditions for %s', groupName);
                dims = [1 50]; % Dimensions for input fields
                
                % Show dialog and get user input
                newValues = inputdlg(prompt, dlgTitle, dims, defaultInputs);
                
                % Update conditions if user provided new values
                if ~isempty(newValues)
                    newConditions = currentConditions;
                    for j = 1:numel(condFields)
                        newConditions.(condFields{j}).value = str2double(newValues{j});
                    end
                    obj = obj.updateGroupConditions(groupName, newConditions);
                end
            end
            
            % Redo table updating with the new conditions
            % TO FIX - needs to be done when the function is called to get listArray out
            listArray = obj.updateTable(listArray, timePoints);
        end
    end
end

function category = evaluateConditions(row, conditions)
    fields = fieldnames(conditions);
    for i = 1:numel(fields)
        group = fields{i};
        groupName = conditions.(group).name;
        conds = conditions.(group).conditions;
        match = true;
        
        condFields = fieldnames(conds);
        for j = 1:numel(condFields)
            cond = condFields{j};
            comparator = conds.(cond).comparator;
            value = conds.(cond).value;
            
            % Check the condition
            switch comparator
                case 'lessThan'
                    if row.(cond) >= value
                        match = false;
                        break;
                    end
                case 'moreThan'
                    if row.(cond) <= value
                        match = false;
                        break;
                    end
                % Add more comparators as needed
                otherwise
                    error('Unsupported comparator: %s', comparator);
            end
        end
        
        if match
            category = groupName;
            return;
        end
    end
    category = 'Uncategorized'; % Default category if no conditions match
end

