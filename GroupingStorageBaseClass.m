classdef GroupingStorageBaseClass < handle
    properties
        Groupings
    end

    methods
        function obj = GroupingStorageBaseClass()
            % Constructor to initialize the list
            obj.Groupings = {};
        end

        function addGrouping(obj, grouping)
            % Method to add a new Grouping instance to the list
            obj.Groupings{end+1} = grouping;
            disp(obj.Groupings)
        end

        function deleteGrouping(obj, name)
            % Method to delete a Grouping instance by category name
            idx = obj.findGroupingIndexByName(name);
            if idx > 0
                % % Explicitly delete the Grouping instance
                % delete(obj.Groupings{idx});
                % Remove the reference from the cell array
                obj.Groupings(idx) = [];
                % fprintf('Grouping with name "%s" has been deleted.\n', name);
            else
                % fprintf('Grouping with name "%s" not found.\n', name);
            end
        end

        function listArray = renameGrouping(obj, name, newName, listArray)
            idx = obj.findGroupingIndexByName(name);
            if idx > 0
                disp(obj.Groupings{idx})
                grouping = obj.Groupings{idx};
                grouping.Name = newName;
            end
            if istable(listArray)
                table = listArray;
                if ismember(name, table.Properties.VariableNames)
                    table.Properties.VariableNames{strcmp(table.Properties.VariableNames, name)} = newName;
                else
                    disp(['column ' name ' does not exist in the table'])
                end
                listArray = table;
            else
                for i = 1:numel(listArray)
                    table = listArray{i};
                    if ismember(name, table.Properties.VariableNames)
                        table.Properties.VariableNames{strcmp(table.Properties.VariableNames, name)} = newName;
                    else
                        disp(['column ' name ' does not exist in the table' num2str(i)])
                    end
                    listArray{i} = table;
                end
            end
        end

        function numGroupings = getNumberOfGroupings(obj)
            % Method to get the number of Groupings currently stored
            numGroupings = numel(obj.Groupings);
        end  

        function names = returnGroupingNames(obj)
            names = cell(1, numel(obj.Groupings));
            for i = 1:numel(obj.Groupings)
                cm = obj.Groupings{i};
                names{i} = char(cm.Name);
            end
        end

        function grouping = returnGrouping(obj,name)
            idx = obj.findGroupingIndexByName(name);
            grouping = obj.Groupings{idx};
        end

        function categoryNames = returnCategoryNames(obj, name)
            idx = obj.findGroupingIndexByName(name);
            grouping = obj.Groupings{idx};
            categoryNames = grouping.getCategoryNames;
        end

        function listArray = updateAllTables(obj, listArray, timePoints)
            % Method to update all tables for all Groupings
            disp('in updateAllTables')
            for i = 1:numel(obj.Groupings)
                cm = obj.Groupings{i};
                listArray = cm.updateTable(listArray, timePoints);
            end
        end

        function idx = findGroupingIndexByName(obj, name)
            % Helper method to find the index of a Grouping by its name
            idx = -1;
            for i = 1:numel(obj.Groupings)
                if strcmp(obj.Groupings{i}.Name, name)
                    idx = i;
                    return;
                end
            end
        end
    end
end