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
        
        function plotAllCategories(obj, tables, colX, colY)
            % Method to plot all categories
            for i = 1:numel(obj.CategoryManagers)
                cm = obj.CategoryManagers{i};
                cm.plotCategories(tables, colX, colY);
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
    end
end
