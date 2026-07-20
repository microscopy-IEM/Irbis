classdef TableStoreWrappedInFilter < handle
    % FilteredTableStore A wrapper for TableStore that applies a filter function to the data (something like a decorator pattern)
    % IMPORTANT - need to be up to date with TableStore

    properties (Access = private)
        tableStoreHandle   % The original TableStore object
        filteringStorageHandle   % A function handle to apply as a filter

    end

    properties (Access = private, Transient)
        tableStoreListener  % Listener for the tableDataChanged event from the original TableStore.
        filteringStorageListener  % Listener for the filtersChanged event from the filtering storage.
    end

    events
        tableDataChanged
    end

    methods
        function obj = TableStoreWrappedInFilter(tableStoreHandle, filteringStorageHandle)
            % TO FIX - possibly instantiated multiple times (notify(obj, 'tableDataChanged') is done twice instead of once)
            if ~isa(tableStoreHandle, 'TableStore')
                error('Expected a TableStore object');
            end
            obj.tableStoreHandle = tableStoreHandle;
            % pass the event further
            obj.deleteTableStoreListener();
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~) notify(obj, 'tableDataChanged'));

            obj.filteringStorageHandle = filteringStorageHandle;
            % if the filters change, this also means that the data has changed
            obj.deleteFilteringStorageListener();
            obj.filteringStorageListener = addlistener(obj.filteringStorageHandle, 'filtersChanged', @(~, ~) notify(obj, 'tableDataChanged'));
        end
    end

    methods (Access = public)
        %% Set or add table data
        function setTableData(obj, newTableData)
            obj.tableStoreHandle.setTableData(newTableData);
        end

        function addTableData(obj, newTableData)
            obj.tableStoreHandle.addTableData(newTableData);
        end

        %% Get table data or its subset
        function tableData = getTableData(obj)
            tableData = obj.tableStoreHandle.getTableData();

            % apply filtering before returning the data
            if ~isempty(obj.filteringStorageHandle)
                isKept = obj.filteringStorageHandle.filter(tableData);
                if ~isempty(isKept)
                    tableData = tableData(isKept, :);
                end
            end
        end

        % function subset = getTableSubsetByType(obj, columnTypes)
        %     subset = obj.tableStoreHandle.getTableSubsetByType(columnTypes);

        %     % apply filtering before returning the data
        %     if ~isempty(obj.filteringStorageHandle)
        %         isKept = obj.filteringStorageHandle.filter(subset);
        %         if ~isempty(isKept)
        %             subset = subset(isKept, :);
        %         end
        %     end
        % end

        function subset = getTableSubsetByName(obj, columnNames)
            tableData = obj.tableStoreHandle.getTableData();
            % I first ask for the whole table instead of subset, to make sure I have all the columns for the filtering

            % apply filtering before returning the data
            if ~isempty(obj.filteringStorageHandle)
                isKept = obj.filteringStorageHandle.filter(tableData);
                if ~isempty(isKept)
                    subset = tableData(isKept, columnNames);
                else
                    subset = tableData(:, columnNames);
                end
            end
        end

        %% Get column names
        function columnNames = getColumnNames(obj)
            columnNames = obj.tableStoreHandle.getColumnNames();
        end

        % function columnNames = getColumnNamesOfClass(obj, requestedClasses)
        %     columnNames = obj.tableStoreHandle.getColumnNamesOfClass(requestedClasses);
        % end

        function columnNames = getColumnNamesByCondition(obj, typeConditions)
            columnNames = obj.tableStoreHandle.getColumnNamesByCondition(typeConditions);
        end

        function columnNames = getPredefinedColumnNamesByCondition(obj, typeCondition)
            columnNames = obj.tableStoreHandle.getPredefinedColumnNamesByCondition(typeCondition);
        end

        function columnNames = getUserDefinedColumnNames(obj)
            columnNames = obj.tableStoreHandle.getUserDefinedColumnNames();
        end

        function columnNames = getEditableColumnNames(obj)
            columnNames = obj.tableStoreHandle.getEditableColumnNames();
        end

        %% Get column types
        function columnTypes = getColumnTypes(obj)
            columnTypes = obj.tableStoreHandle.getColumnTypes();
        end

        function columnTypes = getColumnTypesForNames(obj, columnNames)
            columnTypes = obj.tableStoreHandle.getColumnTypesForNames(columnNames);
        end

        function columnTypes = getClassOfColumn(obj, columnNames)
            columnTypes = obj.tableStoreHandle.getClassOfColumn(columnNames);
        end

        %% Edit user-defined columns
        function addUserDefinedColumn(obj, columnName, columnData, userDefinitionObject)
            obj.tableStoreHandle.addUserDefinedColumn(columnName, columnData, userDefinitionObject);
        end

        function updateUserDefinedColumn(obj, columnName, newColumnData, userDefinitionHandle)
            obj.tableStoreHandle.updateUserDefinedColumn(columnName, newColumnData, userDefinitionHandle);
        end

        function userColumnDefinition = getUserColumnDefinition(obj, columnName)
            userColumnDefinition = obj.tableStoreHandle.getUserColumnDefinition(columnName);
        end

        function numDefinitionsOfType = getNumDefinitionsOfType(obj, definitionType)
            numDefinitionsOfType = obj.tableStoreHandle.getNumDefinitionsOfType(definitionType);
        end

        %% Edit columns in general
        function removeColumn(obj, columnName)
            obj.tableStoreHandle.removeColumn(columnName);
        end

        function renameColumn(obj, oldName, newName)
            obj.tableStoreHandle.renameColumn(oldName, newName);
        end

        %% Deal with column editability
        function makeColumnEditable(obj, columnName)
            obj.tableStoreHandle.makeColumnEditable(columnName);
        end

        function columnEditability = getEditabilityOfColumns(obj, columnNames)
            columnEditability = obj.tableStoreHandle.getEditabilityOfColumns(columnNames);
        end

        function editManualColumnValue(obj, columnName, rowName, newValue)
            obj.tableStoreHandle.editManualColumnValue(columnName, rowName, newValue);
        end

        %% Regenerate listeners when the ModalityDataStore is reloaded from file
        function regenerateListeners(obj)
            % Regenerate the listeners - no longer valid when ModalityDataStore is reloaded from file
            obj.deleteTableStoreListener();
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~) notify(obj, 'tableDataChanged'));

            obj.deleteFilteringStorageListener();
            obj.filteringStorageListener = addlistener(obj.filteringStorageHandle, 'filtersChanged', @(~, ~) notify(obj, 'tableDataChanged'));
        end



        function deleteListeners(obj)
            % Delete runtime listeners owned by this wrapper before serialization.
            obj.deleteTableStoreListener();
            obj.deleteFilteringStorageListener();
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



        function deleteFilteringStorageListener(obj)
            % Delete the listener that watches the filtering storage.
            if ~isempty(obj.filteringStorageListener) && isvalid(obj.filteringStorageListener)
                delete(obj.filteringStorageListener);
            end

            obj.filteringStorageListener = [];
        end
    end
end
