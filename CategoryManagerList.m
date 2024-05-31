classdef CategoryManagerList < handle
    properties
        CategoryManagers % Cell array to store instances of CategoryManager
    end
    
    methods
        function obj = CategoryManagerList()
            % Constructor to initialize the list
            obj.CategoryManagers = {};
        end
        
        function addCategoryManager(obj, categoryManager)
            % Method to add a new CategoryManager instance to the list
            obj.CategoryManagers{end+1} = categoryManager;
            disp(obj.CategoryManagers)
        end
        
        function displayCategories(obj)
            % Method to display all categories
            fprintf('Categories:\n');
            for i = 1:numel(obj.CategoryManagers)
                cm = obj.CategoryManagers{i};
                fprintf('Category %d: %s\n', i, cm.CategoryName);
                disp('Parameters:');
                disp(cm.Conditions);
            end
        end
        
        function updateAllTables(obj, tables, timePoints)
            % Method to update all tables for all CategoryManagers
            for i = 1:numel(obj.CategoryManagers)
                cm = obj.CategoryManagers{i};
                tables = cm.updateTable(tables, timePoints);
            end
        end
        
        function promptAndUpdateAllConditions(obj, tables, timePoints)
            % Method to prompt and update conditions for all CategoryManagers
            for i = 1:numel(obj.CategoryManagers)
                cm = obj.CategoryManagers{i};
                cm.promptAndUpdateConditions(tables, timePoints);
            end
        end

        function deleteCategoryManager(obj, categoryName)
            % Method to delete a CategoryManager instance by category name
            idx = obj.findCategoryManagerIndexByName(categoryName);
            if idx > 0
                % Explicitly delete the CategoryManager instance
                delete(obj.CategoryManagers{idx});
                % Remove the reference from the cell array
                obj.CategoryManagers(idx) = [];
                fprintf('CategoryManager with name "%s" has been deleted.\n', categoryName);
            else
                fprintf('CategoryManager with name "%s" not found.\n', categoryName);
            end
        end

        function idx = findCategoryManagerIndexByName(obj, categoryName)
            % Helper method to find the index of a CategoryManager by its name
            idx = -1;
            for i = 1:numel(obj.CategoryManagers)
                if strcmp(obj.CategoryManagers{i}.CategoryName, categoryName)
                    idx = i;
                    return;
                end
            end
        end
    end
end
