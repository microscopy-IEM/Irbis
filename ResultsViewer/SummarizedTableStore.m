classdef SummarizedTableStore < handle
    % stores rules for all columns where rows are of certain category

    properties
        groupingName % name of the column whose groups are on individual rows
        parentColumnNames = {}; % stores all columns available in the parent table
        parentColumnTypes = {}; % stores all types of columns available in the parent table
        columnDefinitionHandles = {}; % stores all defnitions of columns derived from the parent table
        userDefinedColumns = {};
        editableColumns = {};
        editedValueMap = {}; % this is a dictionary for manually assigned values and corresponding row names
            % cells are matched with editableColumns names

        tableStoreHandle    % handle to table store wrapped in filter
        userColumnDefinitions = {}; % handle to the user column definitions (NOT STORE)

        cachedTableData = table(); % stores the summarized table data

        rowNames = {}; % stores the names of the rows in the table

        % TO IMPLEMENT - before the ModalityDataStore is saved, clean the listeners and other temp variables
    end

    properties (Transient)
        tableStoreListener
    end




    events
        tableDataChanged % event to notify when the table data changes
    end




    methods
        function obj = SummarizedTableStore(groupingName, tableStoreHandle, userColumnDefinitions)
            % Constructor for SummarizedTableStore class
            obj.groupingName = groupingName;
            obj.tableStoreHandle = tableStoreHandle;
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~)updateTableData(obj));
            
            if ~isempty(userColumnDefinitions)
                obj.userColumnDefinitions = userColumnDefinitions;
            end

            allColumnNames = tableStoreHandle.getColumnNames();
            isGroupingColumn = strcmp(allColumnNames, groupingName);
            obj.parentColumnNames = allColumnNames(~isGroupingColumn);
            allColumnTypes = tableStoreHandle.getColumnTypes();
            obj.parentColumnTypes = allColumnTypes(~isGroupingColumn);

            % TO IMPLEMENT - needs to listen for changes in the parent table

            obj.createDefaultColumnDefinitions();
            obj.extractRowNames();
        end



        function createDefaultColumnDefinitions(obj, varargin)
            if ~ismember('timePoint', obj.parentColumnNames)
                % Do not create default column definitions if 'timePoint' is not present
                return;
            end
            if nargin == 1
                parentColumnNamesToUse = obj.parentColumnNames;
                parentColumnTypesToUse = obj.parentColumnTypes;
            elseif nargin == 2
                parentColumnNamesToUse = varargin{1};
                parentColumnTypesToUse = obj.tableStoreHandle.getColumnTypesForNames(parentColumnNamesToUse);
            else
                error('Invalid number of input arguments.')
            end

            for i = 1:length(parentColumnNamesToUse)
                % skip timePoint column
                if strcmp(parentColumnNamesToUse{i}, 'timePoint')
                    continue;
                end
                columnName = parentColumnNamesToUse{i};
                columnType = parentColumnTypesToUse{i};
                columnParameter = 'timePoint';
                switch columnType
                    case 'numeric'  % TO OPTMIZE - this includes also fields with more than just one number (basePoint, ...)
                        % For numeric columns, use mean as the default aggregation function
                        innerAggregationFunction = 'mean';
                        outerAggregationFunctions = {'mean', 'std', 'cv', 'min', 'max', 'observationCount', 'slope', 'RSquared', 'stdResiduals', 'cvResiduals', 'pearsonR'};  % TO OPTIMIZE - this is just a quick fix, I need to decide which functions to offer for numeric columns
                        for j = 1:length(outerAggregationFunctions)
                            % Create a new column definition for each outer aggregation function
                            definitionHandle = StatisticalColumnDefinition();
                            outerAggregationFunction = outerAggregationFunctions{j};
                            definitionHandle.defineRulesProgrammatically(obj.groupingName, columnName, outerAggregationFunction, columnParameter, innerAggregationFunction);
                            obj.addColumnDefinition(definitionHandle);
                            % disp('Adding column definition for:')
                            % disp(definitionHandle.getColumnName())
                        end
                    case 'categorical'   % not adding string or char, because mode does not seem to work for them
                        % For categorical columns, use mode as the default aggregation function
                        outerAggregationFunction = 'mode';
                        definitionHandle = StatisticalColumnDefinition();
                        definitionHandle.defineRulesProgrammatically(obj.groupingName, columnName, outerAggregationFunction);
                        obj.addColumnDefinition(definitionHandle);
                        % disp('Adding column definition for:')
                        % disp(definitionHandle.getColumnName())
                    otherwise
                        % Do not add any columns
                end
            end
        end



        function addColumnDefinition(obj, columnDefinitionHandle)
            % Add a column definition to the store
            obj.columnDefinitionHandles{end+1} = columnDefinitionHandle;
        end



        function addUserDefinedColumn(obj, columnName, newData, columnDefinitionHandle)
            % Add a user-defined column to the store
            if ~ismember(columnName, obj.userDefinedColumns)
                obj.userDefinedColumns{end+1} = char(columnName);
                obj.cachedTableData.(columnName) = newData;
                obj.userColumnDefinitions{end+1} = columnDefinitionHandle;

                notify(obj, 'tableDataChanged');
            else 
                % Column already exists, do not add it again
                error('Column "%s" already exists in the table.', columnName);
            end
        end



        function updateUserDefinedColumn(obj, columnName, newData, userDefinitionHandle)
            % Update the data of a user-defined column
            if ismember(columnName, obj.userDefinedColumns)
                obj.cachedTableData.(columnName) = newData;
                idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                obj.userColumnDefinitions{idx} = userDefinitionHandle;
                notify(obj, 'tableDataChanged');
            else
                error('Column "%s" does not exist in the table.', columnName);
            end
        end



        function makeColumnEditable(obj, columnName)
            % Make a column editable in the store
            if ismember(columnName, obj.userDefinedColumns) && ~ismember(columnName, obj.editableColumns)   
                % NOTE: with this, I assume that editable columns are always user defined
                obj.editableColumns{end+1} = columnName;
                obj.editedValueMap{end+1} = dictionary; % unconfigured in case I need to store different value types for differnt columns
                notify(obj, 'tableDataChanged');
            end
        end



        function idx = getEditableColumnIdx(obj, columnName)
            % Get the index of an editable column
            idx = find(strcmp(obj.editableColumns, columnName), 1);
            if isempty(idx)
                error('Column "%s" is not editable.', columnName);
            end
        end



        function editManualColumnValue(obj, columnName, rowName, newValue)
            % Edit the value of a manual column
            if ismember(columnName, obj.editableColumns) && ismember(columnName, obj.cachedTableData.Properties.VariableNames)
                % disp('Editing column value');
                % disp('rowName')
                % disp(rowName)
                % disp('rowNames')
                % disp(obj.cachedTableData.Properties.RowNames)
                if ismember(rowName, obj.rowNames)
                    rowNum = obj.getRowNumCorrespondingToName(rowName);
                    obj.cachedTableData{rowNum, columnName} = newValue;
                    idx = obj.getEditableColumnIdx(columnName);
                    obj.editedValueMap{idx}(rowName) = newValue; % store the value in the dictionary
                    % disp(obj.editedValueMap{idx})
                else
                    error('Row %s does not exist in the table.', rowName);
                end
            else
                error('Column %s does not exist or is not editable.', columnName);
            end
            % disp(obj.editedValueMap)
        end



        function columnCount = getNumberOfColumnsOfType(obj, type)
            % Get the number of columns of a specific type
            columnCount = sum(cellfun(@(x) isa(x, type), obj.columnDefinitionHandles));
        end



        function columnEditability = getEditabilityOfColumns(obj, columnNames)
            % Returns a boolean array
            columnEditability = ismember(columnNames, obj.editableColumns);
        end



        function columnNames = getStatisticalColumnNames(obj)
            % Get the names of all columns in the store
            columnNames = cellfun(@(x) x.getColumnName(), obj.columnDefinitionHandles, 'UniformOutput', false);
        end



        function columnNames = getColumnNamesByCondition(obj, typeConditions)
            % Get the names of columns that match a specific condition
            % TO OPTIMIZE - this is just a quick fix so that I can call the method from UserColumnDefinitionFactory
                % I do not want to implement this the basic way because it would require generating every column
            if isequal(typeConditions, {'iscategorical', 'isnumeric'})
                columnNames = obj.getColumnNames();
                % TO OPTIMIZE - this is also not fully precise, as the formula might create strings etc.
            else
                columnNames = {};
            end
        end



        function parentNames = getParentNames(obj)
            % Get the names of all parent columns
            parentNames = obj.parentColumnNames;
        end



        function columnNames = getColumnNames(obj)
            statisticalColumnNames = obj.getStatisticalColumnNames();
            columnNames = [statisticalColumnNames, obj.userDefinedColumns];
        end


        
        function columnNames = getStatisticalColumnNamesForParent(obj, parentName)
            % Get the names of all statistical columns for a specific parent column
            columnNames = cellfun(@(x) x.getColumnName(), obj.columnDefinitionHandles, 'UniformOutput', false);
            isParentColumn = cellfun(@(x) strcmp(x.getDataParameter(), parentName), obj.columnDefinitionHandles);
            columnNames = columnNames(isParentColumn);
        end



        function columnNames = getUserDefinedColumnNames(obj)
            if isempty(obj.userDefinedColumns)
                columnNames = {};
            else
                columnNames = obj.userDefinedColumns;
            end
        end



        function columnNames = getEditableColumnNames(obj)
            if isempty(obj.editableColumns)
                columnNames = {};
            else
                columnNames = obj.editableColumns;
            end
        end



        function userColumnDefinition = getUserColumnDefinition(obj, columnName)
            % Get the user column definition for a specific column name
            if ismember(columnName, obj.userDefinedColumns)
                idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                if ~isempty(idx)
                    userColumnDefinition = obj.userColumnDefinitions{idx};
                else
                    error('Column %s does not exist in the user-defined columns.', columnName);
                end
            else
                error('Column %s is not a user-defined column.', columnName);
            end
        end



        function numDefinitionsOfType = getNumDefinitionsOfType(obj, definitionType)
            % get the number of user-defined columns of a specific type
            numDefinitionsOfType = 0;
            for i = 1:numel(obj.userColumnDefinitions)
                if isequal(obj.userColumnDefinitions{i}.getDefinitionType(), definitionType)
                    numDefinitionsOfType = numDefinitionsOfType + 1;
                end
            end
        end



        function [isValid, invalidColumnNames] = validateColumnsExist(obj, columnNames)
            % validate that the specified column names exist in the table
            existingColumnNames = obj.getColumnNames();
            invalidColumnNames = setdiff(columnNames, existingColumnNames);
            isValid = isempty(invalidColumnNames);
        end



        function subset = getTableSubsetByName(obj, columnNames)

            % Check if all requested columns exist in the cached data
            missingColumns = setdiff(columnNames, obj.cachedTableData.Properties.VariableNames);

            if ~isempty(missingColumns)
                missingUserDefinedColumns = intersect(cellstr(missingColumns), cellstr(obj.userDefinedColumns));
                for i = length(missingUserDefinedColumns):-1:1
                    colName = missingUserDefinedColumns{i};
                    % Remove the column from the cached data - this should not happen as missingColumns are not in the cachedTableData
                    % if ismember(colName, obj.cachedTableData.Properties.VariableNames)
                    %     obj.cachedTableData.(colName) = [];
                    % end

                    % Create the column using its definition
                    defIdx = find(cellfun(@(x) strcmp(x.getColumnName(), colName), obj.userColumnDefinitions));
                    if ~isempty(defIdx)
                        existingColumnNames = obj.getColumnNames();
                        requiredColumnNames = obj.userColumnDefinitions{defIdx}.getRequiredColumnNames(existingColumnNames);
                        requiredTableSubset = obj.getTableSubsetByName(requiredColumnNames);    % user-defined columns are based on the summarized table
                        newData = obj.userColumnDefinitions{defIdx}.generateColumn(requiredTableSubset);
                        obj.cachedTableData.(colName) = newData;
                    end
                    % Remove the column from the cached data
                    % Create from the userDefinedColumnRules

                    if ismember(colName, obj.editableColumns)
                        idx = obj.getEditableColumnIdx(colName);
                        editedValues = obj.editedValueMap{idx};
                        usedRowNames = keys(editedValues);
                        for k = 1:length(usedRowNames)
                            rowName = usedRowNames{k};
                            if ismember(rowName, obj.rowNames)
                                % disp('the row name is in rowNames')
                                rowNum = obj.getRowNumCorrespondingToName(rowName);
                                obj.cachedTableData{rowNum, colName} = editedValues(rowName);
                            end
                        end
                    end
                end
                % Find the column definitions for missing columns

                missingPredefinedColumns = setdiff(cellstr(missingColumns), cellstr(obj.userDefinedColumns));
                for i = 1:length(missingPredefinedColumns)
                    colName = missingPredefinedColumns{i};
                    defIdx = find(cellfun(@(x) strcmp(x.getColumnName(), colName), obj.columnDefinitionHandles));
                    
                    if ~isempty(defIdx)
                        % Calculate the column using its definition
                        requiredColumnNames = obj.columnDefinitionHandles{defIdx}.getRequiredColumnNames();
                        requiredTableSubset = obj.tableStoreHandle.getTableSubsetByName(requiredColumnNames);
                        newData = obj.columnDefinitionHandles{defIdx}.generateColumn(requiredTableSubset);
                        obj.cachedTableData.(colName) = newData;
                    end
                end
            end
            subset = obj.cachedTableData(:, columnNames);
            subset.Properties.RowNames = obj.rowNames;
        end



        function updateTableData(obj)
            % check which columns are missing and create them

            allColumnNames = obj.tableStoreHandle.getColumnNames();
            isGroupingColumn = strcmp(allColumnNames, obj.groupingName);
            updatedParentColumnNames = allColumnNames(~isGroupingColumn);

            removedColumns = setdiff(obj.parentColumnNames, updatedParentColumnNames);  % get columns in old (first argument) but not in new (second argument) list
            for i = 1:length(removedColumns)
                obj.removeParentColumnAndItsChildren(removedColumns{i});
            end

            addedColumns = setdiff(updatedParentColumnNames, obj.parentColumnNames);  % get columns in new (second argument) but not in old (first argument) list
            obj.parentColumnNames = [obj.parentColumnNames, addedColumns];
            addedColumnTypes = obj.tableStoreHandle.getColumnTypesForNames(addedColumns);
            obj.parentColumnTypes = [obj.parentColumnTypes, addedColumnTypes];
            obj.createDefaultColumnDefinitions(addedColumns);
            obj.extractRowNames();

            obj.cachedTableData = table();  % clear the cached data - done because filtering may have changed

            % I have to keep the information about the manually set columns

            notify(obj, 'tableDataChanged');
        end



        function removeParentColumnAndItsChildren(obj, parentName)
            % Remove a parent column and its child columns from the store
            
            % Remove these columns from cachedTableData, if they exist
            % childColumnNames = obj.getStatisticalColumnNamesForParent(parentName);
            % for j = 1:length(childColumnNames)
            %     if ismember(childColumnNames{j}, obj.cachedTableData.Properties.VariableNames)
            %         obj.cachedTableData.(childColumnNames{j}) = [];
            %     end
            % end

            % Find indices of column definitions related to the removed parent column
            childIndices = find(cellfun(@(x) strcmp(x.getDataParameter(), parentName), obj.columnDefinitionHandles));
            
            % Remove these column definitions from columnDefinitionHandles
            obj.columnDefinitionHandles(childIndices) = [];

            % Remove the parent column from parentColumnNames and parentColumnTypes
            idx = strcmp(obj.parentColumnNames, parentName);
            obj.parentColumnNames(idx) = [];
            obj.parentColumnTypes(idx) = [];

        end



        function removeColumn(obj, columnName)
            % remove the column from the table data - this happens in any case
            % the column does not need to be in the table (different in TableStore)
            if ismember(columnName, obj.cachedTableData.Properties.VariableNames)
                obj.cachedTableData(:, columnName) = [];
            end

            % continue based on the type of column
            if ismember(columnName, obj.userDefinedColumns)
                % Remove the column from userDefinedColumns and userColumnDefinitions
                idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                obj.userDefinedColumns(idx) = [];
                obj.userColumnDefinitions(idx) = [];
            else
                % Check if the column is predefined
                idx = find(cellfun(@(x) strcmp(x.getColumnName(), columnName), obj.columnDefinitionHandles), 1);
                if ~isempty(idx)
                    % Remove the column definition from columnDefinitionHandles
                    obj.columnDefinitionHandles(idx) = [];
                end
            end

            % Notify listeners about the change
            notify(obj, 'tableDataChanged');
        end



        function renameColumn(obj, oldName, newName)
            if ~isvarname(newName)
                error('"%s" is not a valid MATLAB variable name.', newName);
            end

            newNameInPredefined = any(cellfun(@(x) strcmp(x.getColumnName(), newName), obj.columnDefinitionHandles));
            newNameInUserDefined = any(strcmp(obj.userDefinedColumns, newName));
            if newNameInPredefined || newNameInUserDefined
                error('A predefined column with the name "%s" already exists.', newName);
            end

            if ismember(oldName, obj.userDefinedColumns)
                % Rename the column in userDefinedColumns and userColumnDefinitions
                idx = find(strcmp(obj.userDefinedColumns, oldName), 1);
                obj.userDefinedColumns{idx} = newName;
                obj.userColumnDefinitions{idx}.renameColumn(newName);
            else
                % NOTE: This should not happen, as the names are coding the content and as such should not be changed
                error('Column "%s" is not a user-defined column.', oldName);
            end

            notify(obj, 'tableDataChanged');
        end



        function extractRowNames(obj)
            % get and store row names from the parent table to be able to combine them with calculated columns later
            parentTable = obj.tableStoreHandle.getTableSubsetByName(obj.groupingName);
            % disp(size(parentTable))
            if ~isempty(parentTable)
                % Check if the grouping column is categorical
                if iscategorical(parentTable.(obj.groupingName))
                    % TO OPTIMIZE - this might not be correct at all times - be careful
                    obj.rowNames = string(unique(parentTable.(obj.groupingName)));  % categories() returns also the filtered out names
                else
                    % TO OPTIMIZE - this needs to be adjusted if we want something else than categorical as rows
                    error('Grouping column is not categorical.')
                end
            else
                % nothing happens, no data
            end
        end


        
        function rowNum = getRowNumCorrespondingToName(obj, rowName)
            % Get the row number corresponding to a specific row name
            if ismember(rowName, obj.rowNames)
                rowNum = find(strcmp(obj.rowNames, rowName));
            else
                error('Row name "%s" does not exist in the table.', rowName);
            end
        end



        function regenerateListeners(obj)
            % Regenerate the listeners - no longer valid when ModalityDataStore is reloaded from file

            % We have to call the TableStoreWrappedInFilter to regenerate its listeners, as it is not valid anymore when the ModalityDataStore is reloaded from file
            if isa(obj.tableStoreHandle, 'TableStoreWrappedInFilter') && isvalid(obj.tableStoreHandle)
                obj.tableStoreHandle.regenerateListeners();
            end

            obj.deleteTableStoreListener();
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~)updateTableData(obj));

        end



        function deleteListeners(obj)
            % Delete runtime listeners owned by this summarized table store and its wrapped table store before serialization.
            if isa(obj.tableStoreHandle, 'TableStoreWrappedInFilter') && isvalid(obj.tableStoreHandle)
                obj.tableStoreHandle.deleteListeners();
            end

            obj.deleteTableStoreListener();
        end
    end



    methods (Access = ?matlab.unittest.TestCase)
        function deleteTableStoreListener(obj)
            % Delete the listener that watches the wrapped table store.
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end

            obj.tableStoreListener = [];
        end
    end
end
