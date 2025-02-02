classdef SummarizedTableClass < handle

    properties
        rowParameterName    % string/char - name of the categorical parameter that forms rows
        summarizedTable     % table - table with summarized data, can contain statistics column or categorizations
        groupCategorizations     % CategorizationStorage object - object containing defition of categorizations present in the table
        groupFilters        % FilteringStorage object - object containing filters applied based on groups based on the summarized table
        tableStructure      % structure - contains structure capturing the columns of the table, used for populating checkboxTree
            % PURPOSE: the checkboxTree should show only 'mean', 'min', etc. within 'volume by timePoint' instead of 'mean_volume_by_timePoint'
            % the full name is also stored to be added to the NodeData
    end

    methods
        function obj = SummarizedTableClass(rowParameterName, summarizedTable, groupCategorizations, groupFilters)
            % Constructor for SummarizedTableClass
            obj.rowParameterName = rowParameterName;

            % add column 'excluded' to the table and store it
            if ~ismember('excluded', summarizedTable.Properties.VariableNames)
                summarizedTable.excluded = false(height(summarizedTable), 1);
            end

            obj.summarizedTable = summarizedTable;
            if ~isempty(groupCategorizations) && isa(groupCategorizations, 'CategorizationStorage')
                obj.groupCategorizations = groupCategorizations;
            else
                obj.groupCategorizations = CategorizationStorage();
            end
            if ~isempty(groupFilters) && isa(groupFilters, 'FilteringStorage')
                obj.groupFilters = groupFilters;
            else
                obj.groupFilters = FilteringStorage();
            end

            obj.extractTableStructure(summarizedTable);
        end


        function extendTable(obj, newTable)
            % Extends the summarized table with new columns (input as table)

            % Raise an error if the tables do not have the same number of rows
            assert(height(obj.summarizedTable) == height(newTable), 'Tables must have the same number of columns');
            obj.summarizedTable = horzcat(obj.summarizedTable, newTable);
        end


        function extractTableStructure(obj, summarizedTable)
            % Extracts the structure of the table to be used for populating the checkboxTree
            % The structure contains only the statistical columns 
                % Explanation - this is because the categorization columns can contains gaps 
                % -> cannot be used in the same way in the struct
            % The structure contains only the first part of the column names, e.g. 'mean' instead of 'mean_volume_by_timePoint'
            % The full name is also stored to be added to the NodeData
            categorizationNames = obj.groupCategorizations.returnCategorizationNames();

            for i = 1:width(summarizedTable)
                colName = summarizedTable.Properties.VariableNames{i};
                if ~strcmp(colName, 'excluded') && ~ismember(colName, categorizationNames)
                    % Extract the structure of the column name
                    splitColName = strsplit(colName, '_');
                    if numel(splitColName) > 1  % The column name contains '_' -> it's a statistical column
                        dataParameter = strrep(colName, [splitColName{1} '_'], ''); % assumes name of type 'mean_volume_by_timePoint'
                        % dataParameter = [splitColName{2} '_by_' splitColName{3}];
                        obj.tableStructure.(dataParameter).(splitColName{1}) = colName;
                        % The full column name is stored to be added to the NodeData
                    else
                        % This should not happen
                        disp(['Column name ' colName ' does not contain "_".']);
                    end
                end
            end
        end


        function addCategorization(obj, categorization)
            % Adds a categorization to the groupCategorizations object and to the table
            obj.groupCategorizations.addCategorization(categorization);

            % Update the summarized table with the new categorization
            obj.summarizedTable = categorization.updateTable(obj.summarizedTable, {});
        end


        function replaceCategorization(obj, categorization)
            % Replaces an existing categorization in the groupCategorizations object and in the table
            obj.groupCategorizations.replaceCategorization(categorization);

            % Update the summarized table with the updated categorization
            obj.summarizedTable = categorization.updateTable(obj.summarizedTable, {});
        end


        function copyCategorization(obj, oldCategorizationName, newCategorizationName)
            % Copies an existing categorization and assigns a new name
            categorization = obj.groupCategorizations.copyCategorization(oldCategorizationName, newCategorizationName);

            % Update the summarized table with the new categorization
            obj.summarizedTable = categorization.updateTable(obj.summarizedTable, {});
        end


        function deleteCategorization(obj, categorizationName)
            % Deletes a categorization from the groupCategorizations object and from the table
            obj.groupCategorizations.deleteCategorization(categorizationName);
            obj.summarizedTable.(categorizationName) = [];
        end


        function addFilter(obj, columnName, conditions)
            % Adds a filter to the groupFilters object and to the table
            if isnumeric(conditions) && numel(conditions) == 2
                % Range filter if it's a numeric array with two elements
                obj.groupFilters.addRangeFilter(columnName, conditions);
            else
                % Categorical filter if it's a cell array or string array
                obj.groupFilters.addCategoricalFilter(columnName, conditions);
            end
            
            % Update the 'excluded' column in the summarized table
            obj.updateExcluded();
        end

        
        function updateFilter(obj, columnName, newCondition)
            % Updates a filter in the groupFilters object and in the table
            obj.groupFilters.updateFilter(columnName, newCondition);
            
            % Update the 'excluded' column in the summarized table
            obj.updateExcluded();
        end
        

        function changeFilterActivation(obj, columnName, active)
            % Changes the activation status of a filter in the groupFilters object
            if active
                obj.groupFilters.activateFilter(columnName);
            else
                obj.groupFilters.inactivateFilter(columnName);
            end

            % Update the 'excluded' column in the summarized table
            obj.updateExcluded();
        end


        function deleteFilter(obj, columnName)
            % Deletes a filter from the groupFilters object and from the table
            obj.groupFilters.deleteGrouping(columnName);
            
            % Update the 'excluded' column in the summarized table
            obj.updateExcluded();
        end


        function updateExcluded(obj)
            % Updates the 'excluded' column in the summarized table based on the filters
            filterTable = obj.groupFilters.updateAllFilterTables(obj.summarizedTable, table(), {});
            logicalList = logical(all(table2array(filterTable),2));
            obj.summarizedTable.excluded = logicalList;
        end
    end

end