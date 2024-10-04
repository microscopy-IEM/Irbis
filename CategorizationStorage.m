classdef CategorizationStorage < handle
    properties
        Categorizations % Cell array to store instances of Categorization
    end
    
    methods
        function obj = CategorizationStorage()
            % Constructor to initialize the list
            obj.Categorizations = {};
        end
        
        function addCategorization(obj, categorization)
            % Method to add a new Categorization instance to the list
            obj.Categorizations{end+1} = categorization;
            disp(obj.Categorizations)
        end

        function replaceCategorization(obj, categorization)
            idx = obj.findCategorizationIndexByName(categorization.CategorizationName);
            obj.Categorizations{idx} = categorization;
            disp(obj.Categorizations)
        end
        
        function displayCategories(obj)
            % Method to display all categories
            fprintf('Categories:\n');
            for i = 1:numel(obj.Categorizations)
                cm = obj.Categorizations{i};
                fprintf('Category %d: %s\n', i, cm.CategorizationName);
                disp('Parameters:');
                disp(cm.Conditions);
            end
        end

        function categorizationNames = returnCategorizationNames(obj)
            categorizationNames = cell(1, numel(obj.Categorizations));
            for i = 1:numel(obj.Categorizations)
                cm = obj.Categorizations{i};
                categorizationNames{i} = char(cm.CategorizationName);
            end
        end

        function categorization = returnCategorization(obj,categorizationName)
            idx = obj.findCategorizationIndexByName(categorizationName);
            categorization = obj.Categorizations{idx};
        end
        
        function listArray = updateAllTables(obj, listArray, timePoints, varargin)
            % disp('in updateAllTables in CategorizationStorage')
            % Method to update all tables for all Categorizations

            % if a categorization name is specified, update only that column, otherwise update all
            if ~isempty(varargin)
                categorizationName = varargin{1};
                idx = obj.findCategorizationIndexByName(categorizationName);
                if idx > 0
                    % this enables updating only one column if the name is specified in input and if it exists in storage
                        % if name not defined or categorization not in storage (idx = -1), return will not be activated 
                            % the rest of the code will therefore be executed -> all categorization columns recalculated
                    cm = obj.Categorizations{idx};
                    listArray = cm.updateTable(listArray, timePoints);
                    return
                end
            end
            for i = 1:numel(obj.Categorizations)
                cm = obj.Categorizations{i};
                listArray = cm.updateTable(listArray, timePoints);
            end
        end
        
        function promptAndUpdateAllConditions(obj, listArray, timePoints)
            % Method to prompt and update conditions for all Categorizations
            for i = 1:numel(obj.Categorizations)
                cm = obj.Categorizations{i};
                listArray = cm.promptAndUpdateConditions(listArray, timePoints);
            end
        end

        function listArray = promptAndUpdateSpecificCategorization(obj, categorizationName, listArray, timePoints)
            idx = obj.findCategorizationIndexByName(categorizationName);
            if idx > 0
                listArray = obj.Categorizations{idx}.promptAndUpdateConditions(listArray, timePoints);
            else
                fprintf('Categorization with name "%s" not found.\n', categorizationName);
            end
        end

        function deleteCategorization(obj, categorizationName)
            % Method to delete a Categorization instance by category name
            idx = obj.findCategorizationIndexByName(categorizationName);
            if idx > 0
                % % Explicitly delete the Categorization instance
                % delete(obj.Categorizations{idx});
                % Remove the reference from the cell array
                obj.Categorizations(idx) = [];
                fprintf('Categorization with name "%s" has been deleted.\n', categorizationName);
            else
                fprintf('Categorization with name "%s" not found.\n', categorizationName);
            end
        end

        function idx = findCategorizationIndexByName(obj, categorizationName)
            % Helper method to find the index of a Categorization by its name
            idx = -1;
            for i = 1:numel(obj.Categorizations)
                if strcmp(obj.Categorizations{i}.CategorizationName, categorizationName)
                    idx = i;
                    return;
                end
            end
        end

        function numCategorizations = getNumberOfCategorizations(obj)
            % Method to get the number of Categorizations currently stored
            numCategorizations = numel(obj.Categorizations);
        end

        function renameCategoryNames(obj, categorizationName)
            % Method to rename category names for a specific categorization
            
            % Find the index of the categorization with the specified name
            idx = obj.findCategorizationIndexByName(categorizationName);
            if idx > 0
                % Get the Categorization object
                categorization = obj.Categorizations{idx};
                
                % Prompt user for new names
                categorization.renameGroup();
                
                fprintf('Category names for "%s" updated successfully.\n', categorizationName);
            else
                fprintf('Categorization with name "%s" not found.\n', categorizationName);
            end
        end 

        function thresholds = getThresholdsForCategorization(obj, categorizationName)
            idx = obj.findCategorizationIndexByName(categorizationName);
            columnName = strrep(categorizationName,'Groups','');
            if idx > 0
                conditions = obj.Categorizations{idx}.Conditions;
                thresholds = [];
                for i = 1:numel(fieldnames(conditions))
                    fieldName = ['group' num2str(i-1)];
                    if isfield(conditions, fieldName) && isfield(conditions.(fieldName), 'conditions')
                        innerDict = conditions.(fieldName).conditions(columnName);
                        innerDict = innerDict{1};
                        if isKey(innerDict, 'lessThan')
                            thresholds = [thresholds, innerDict('lessThan')];
                        end
                    end
                end

                % Check if the length is less than 3
                while numel(thresholds) < 3
                    % Repeat the last number to get exactly 3 numbers
                    lastThreshold = thresholds(end);
                    thresholds = [thresholds, lastThreshold];
                end
            else
                fprintf('Categorization with name "%s" not found.\n', categorizationName);
                thresholds = [];
            end
        end
 
    end
end