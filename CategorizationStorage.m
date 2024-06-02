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
        
        function updateAllTables(obj, listArray, timePoints)
            % Method to update all tables for all Categorizations
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
                % Explicitly delete the Categorization instance
                delete(obj.Categorizations{idx});
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
        
    end
end

% classdef CategorizationStorage < handle
%     properties
%         Categorizations % Cell array to store instances of Categorization
%     end
% 
%     methods
%         function obj = CategorizationStorage()
%             % Constructor to initialize the list
%             obj.Categorizations = {};
%         end
% 
%         function addCategorization(obj, categorization)
%             % Method to add a new Categorization instance to the list
%             obj.Categorizations{end+1} = categorization;
%             disp(obj.Categorizations)
%         end
% 
%         function displayCategories(obj)
%             % Method to display all categories
%             fprintf('Categories:\n');
%             for i = 1:numel(obj.Categorizations)
%                 cm = obj.Categorizations{i};
%                 fprintf('Category %d: %s\n', i, cm.CategorizationName);
%                 disp('Parameters:');
%                 disp(cm.Conditions);
%             end
%         end
% 
%         function categorizationNames = returnCategorizationNames(obj)
%             categorizationNames = cell(1,numel(obj.Categorizations));
%             for i = 1:numel(obj.Categorizations)
%                 cm = obj.Categorizations{i};
%                 categorizationNames{i} = char(cm.CategorizationName);
%             end
%         end
% 
%         function updateAllTables(obj, listArray, timePoints)
%             % Method to update all tables for all Categorizations
%             for i = 1:numel(obj.Categorizations)
%                 cm = obj.Categorizations{i};
%                 listArray = cm.updateTable(listArray, timePoints);
%             end
%         end
% 
%         function promptAndUpdateAllConditions(obj, listArray, timePoints)
%             % Method to prompt and update conditions for all Categorizations
%             for i = 1:numel(obj.Categorizations)
%                 cm = obj.Categorizations{i};
%                 cm.promptAndUpdateConditions(listArray, timePoints);
%             end
%         end
% 
%         function listArray = promptAndUpdateSpecificCategorization(obj,categorizationName,listArray,timePoints)
%             idx = findCategorizationIndexByName(obj,categorizationName);
%             listArray = obj.Categorizations{idx}.promptAndUpdateConditions;
%         end
% 
%         function deleteCategorization(obj, categorizationName)
%             % Method to delete a Categorization instance by category name
%             idx = obj.findCategorizationIndexByName(categorizationName);
%             if idx > 0
%                 % Explicitly delete the Categorization instance
%                 delete(obj.Categorizations{idx});
%                 % Remove the reference from the cell array
%                 obj.Categorizations(idx) = [];
%                 fprintf('Categorization with name "%s" has been deleted.\n', categorizationName);
%             else
%                 fprintf('Categorization with name "%s" not found.\n', categorizationName);
%             end
%         end
% 
%         function idx = findCategorizationIndexByName(obj, categorizationName)
%             % Helper method to find the index of a Categorization by its name
%             idx = -1;
%             for i = 1:numel(obj.Categorizations)
%                 if strcmp(obj.Categorizations{i}.CategorizationName, categorizationName)
%                     idx = i;
%                     return;
%                 end
%             end
%         end
%     end
% end
