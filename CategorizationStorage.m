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
            % disp(obj.Categorizations)
        end

        function replaceCategorization(obj, categorization)
            name = categorization.getColumnName();
            idx = obj.findCategorizationIndexByName(name);
            obj.Categorizations{idx} = categorization;
            % disp(obj.Categorizations)
        end

        function renameCategorization(obj, existingCategorizationName, newCategorizationName)
            % Find the index of the existing categorization by name
            idx = obj.findCategorizationIndexByName(existingCategorizationName);
            
            if idx > 0
                % Get the existing categorization
                existingCategorization = obj.Categorizations{idx};
                existingCategorization.renameColumn(newCategorizationName);

                fprintf('Categorization "%s" has been renamed to "%s".\n', existingCategorizationName, newCategorizationName);
            else
                fprintf('Categorization with name "%s" not found.\n', existingCategorizationName);
            end
        end

        function newCategorization = copyCategorization(obj, existingCategorizationName, newCategorizationName)
            % Method to copy an existing categorization and assign a new name
            % existingCategorizationName: The name of the categorization to copy
            % newCategorizationName: The name to give the copied categorization
        
            % Find the index of the existing categorization by name
            idx = obj.findCategorizationIndexByName(existingCategorizationName);
            
            if idx > 0
                % Get the existing categorization
                existingCategorization = obj.Categorizations{idx};
                
                % Create a deep copy of the existing categorization
                % Assuming Categorization is a handle class, we must manually copy properties
                newCategorization = Categorization(newCategorizationName, existingCategorization.Conditions);
                
                % Add the new categorization to the list
                obj.addCategorization(newCategorization);
                
                fprintf('Categorization "%s" has been copied to "%s".\n', existingCategorizationName, newCategorizationName);
            else
                fprintf('Categorization with name "%s" not found.\n', existingCategorizationName);
            end
        end

        function categorizationNames = returnCategorizationNames(obj)
            categorizationNames = cell(1, numel(obj.Categorizations));
            for i = 1:numel(obj.Categorizations)
                cm = obj.Categorizations{i};
                categorizationNames{i} = char(cm.getColumnName());
            end
        end

        function categorization = returnCategorization(obj,categorizationName)
            idx = obj.findCategorizationIndexByName(categorizationName);
            categorization = obj.Categorizations{idx};
        end

        function categorizationList = getCategorizationList(obj) % TO OPTIMIZE - update in main app class
            % Method to return the list of Categorizations
            categorizationList = obj.Categorizations;
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
                if strcmp(obj.Categorizations{i}.getColumnName(), categorizationName)
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