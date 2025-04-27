classdef SummarizedTableStore < handle
    % stores rules for all columns where rows are of certain category

    properties
        groupingName % name of the column whose groups are on individual rows
        parentColumnNames = {}; % stores all columns available in the parent table
        parentColumnTypes = {}; % stores all types of columns available in the parent table
        columnDefinitionHandles = {}; % stores all defnitions of columns derived from the parent table
        userDefinedColumnNames = {};

        tableStoreHandle
        userColumnDefinitionsHandle = []; % handle to the user column definition store

        cachedTableData = table(); % stores the summarized table data

        tableStoreListener
    end

    events
        tableDataChanged % event to notify when the table data changes
    end

    methods
        function obj = SummarizedTableStore(groupingName, tableStoreHandle, userColumnDefinitionsHandle)
            % Constructor for SummarizedTableStore class
            obj.groupingName = groupingName;
            obj.tableStoreHandle = tableStoreHandle;
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~)updateTableData(obj));
            obj.userColumnDefinitionsHandle = userColumnDefinitionsHandle;

            allColumnNames = tableStoreHandle.getColumnNames();
            isGroupingColumn = strcmp(allColumnNames, groupingName);
            obj.parentColumnNames = allColumnNames(~isGroupingColumn);
            allColumnTypes = tableStoreHandle.getColumnTypes();
            obj.parentColumnTypes = allColumnTypes(~isGroupingColumn);

            % TO IMPLEMENT - needs to listen for changes in the parent table

            obj.createDefaultColumnDefinitions();
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
                    case 'numeric'  % TO OPTMIZE - this includes also fields with more than just one number (cuttingPlaneCentre, ...)
                        % For numeric columns, use mean as the default aggregation function
                        innerAggregationFunction = 'mean';
                        outerAggregationFunctions = {'mean', 'std', 'min', 'max', 'observationCount', 'slope', 'RSquared'};
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

        function columnCount = getNumberOfColumnsOfType(obj, type)
            % Get the number of columns of a specific type
            columnCount = sum(cellfun(@(x) isa(x, type), obj.columnDefinitionHandles));
        end

        function columnNames = getStatisticalColumnNames(obj)
            % Get the names of all columns in the store
            columnNames = cellfun(@(x) x.getColumnName(), obj.columnDefinitionHandles, 'UniformOutput', false);
        end

        function parentNames = getParentNames(obj)
            % Get the names of all parent columns
            parentNames = obj.parentColumnNames;
        end

        function columnNames = getColumnNames(obj)
            statisticalColumnNames = obj.getStatisticalColumnNames();
            columnNames = [statisticalColumnNames, obj.userDefinedColumnNames];
        end

        function columnNames = getStatisticalColumnNamesForParent(obj, parentName)
            % Get the names of all statistical columns for a specific parent column
            columnNames = cellfun(@(x) x.getColumnName(), obj.columnDefinitionHandles, 'UniformOutput', false);
            isParentColumn = cellfun(@(x) strcmp(x.getDataParameter(), parentName), obj.columnDefinitionHandles);
            columnNames = columnNames(isParentColumn);
        end

        function subset = getTableSubsetByName(obj, columnNames)

            % Check if all requested columns exist in the cached data
            missingColumns = setdiff(columnNames, obj.cachedTableData.Properties.VariableNames);

            if ~isempty(missingColumns)
                missingUserDefinedColumns = intersect(missingColumns, obj.userDefinedColumnNames);
                for i = length(missingUserDefinedColumns):-1:1
                    colName = missingUserDefinedColumns{i};
                    % Remove the column from the cached data
                    % Create from the userDefinedColumnRules
                end
                % Find the column definitions for missing columns

                missingPredefinedColumns = setdiff(missingColumns, obj.userDefinedColumnNames);
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

            obj.cachedTableData = table();  % clear the cached data - done because filtering may have changed

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
    end

end