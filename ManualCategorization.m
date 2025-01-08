classdef ManualCategorization < GroupingBaseClass 

    methods
        function obj = ManualCategorization(name, categories)
            % categories is a cell array of category names - transformed into the conditions structure
            % categories
            % length(categories)
            % categories{2}
            conditions = getConditionsFromCategoryList(categories);
            obj@GroupingBaseClass(name, conditions);
        end

        function listArray = editCategoriesAndUpdateTable(obj, listArray)

            columnName = obj.Name;
            % get the old category names
            oldCategoryNames = obj.getCategoryNames;

            % show the user a dialog window with the existing categories
            % allow to rename, delete or add new ones
            [newColumnName, newCategoryNames] = createGroupDialog(columnName, oldCategoryNames);

            if istable(listArray)

            else
                for id = 1:numel(listArray)
                    table = listArray{id};
                    if ismember(columnName,table.Properties.VariableNames)
                        nOld = numel(oldCategoryNames)
                        nNew = numel(newCategoryNames)
                        oldColumn = table.(columnName);
                        % based on the design of the dialog window, it is not possible to have less new than old
                            % but some new might be empty
                        for c = 1:numel(newCategoryNames)
                            if c > nOld
                                disp('new category added')
                            elseif ismember(oldCategoryNames{c},categories(oldColumn))
                                disp(oldCategoryNames{c})
                                disp(class(oldCategoryNames{c}))
                                disp(newCategoryNames{c})
                                if isempty(newCategoryNames{c})
                                    disp('new name empty - delete old')
                                    oldColumn = removecats(oldColumn,oldCategoryNames{c});
                                elseif isequal(oldCategoryNames{c},newCategoryNames{c})
                                    disp('they are the same')
                                else
                                    if ismember(newCategoryNames{c},categories(oldColumn))
                                        oldColumn = mergecats(oldColumn,[newCategoryNames{c}, oldCategoryNames{c}]);
                                    else
                                        oldColumn = renamecats(oldColumn,oldCategoryNames{c},newCategoryNames{c});
                                    end
                                end
                            else
                                disp(['the old name ' oldCategoryNames{c} ' is not in id ' num2str(id)])
                            end
                        end
                        table.(columnName) = oldColumn;
                        if ~isequal(columnName,newColumnName)
                            table.Properties.VariableNames{columnName} = newColumnName;
                            disp(['column ' columnName ' renamed to ' newColumnName])
                        end
                        listArray{id} = table;
                    else
                        disp(['the column is missing in id ' num2str(id)])
                    end
                end

                % Find the indices of empty cells
                emptyCells = cellfun('isempty', newCategoryNames);
                
                % Remove the empty cells
                newCategoryNames(emptyCells) = [];

                obj.Conditions = getConditionsFromCategoryList(newCategoryNames);
            end

            % if a category is renamed
                % rename the existing in the table
                % if the same name already exists, merge the categories

            % if a category is added
                % just add it to the storage

            % if a category is deleted
                % delete it from the table - change to undefined
        end
    end
end