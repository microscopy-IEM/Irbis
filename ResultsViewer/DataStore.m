classdef DataStore < handle

    properties (Access = private)
        tableStoreHandle TableStore = TableStore()
        summarizedTablesStruct struct

        columnDefinitionChangeListener

        filteringStorageHandle FilteringStorage = FilteringStorage()
        summarizedFilteringStruct struct
    end

    events
        userColumnDefinitionChanged
    end

    methods
        function obj = DataStore(tableStoreHandle, filteringStorageHandle)
            if nargin > 0
                obj.tableStoreHandle = tableStoreHandle;
                obj.summarizedTablesStruct = struct();
                obj.filteringStorageHandle = filteringStorageHandle;
                obj.summarizedFilteringStruct = struct();

                obj.columnDefinitionChangeListener = addlistener(obj.tableStoreHandle, 'userColumnDefinitionChanged', @(src, event) obj.notifyUserColumnDefinitionChange(src, event));
            end
        end

        function obj = addSummarizedTableStore(obj, columnName)
            columnNames = obj.tableStoreHandle.getColumnNames();
            columnData = obj.tableStoreHandle.getTableData();

            if ~ismember(columnName, columnNames)
                error('Column %s does not exist in the table', columnName)
            end
            if ~iscategorical(columnData.(columnName))
                error('Column %s is not categorical', columnName)
            end

            % I input a decorator instead of the raw table store - because I want to include the categorization on the full table
            wrappedTableStoreHandle = TableStoreWrappedInFilter(obj.tableStoreHandle, obj.filteringStorageHandle);
            obj.summarizedTablesStruct.(columnName) = SummarizedTableStore(columnName, wrappedTableStoreHandle, []);

            obj.summarizedFilteringStruct.(columnName) = FilteringStorage();
        end

        function hasSummary = hasSummarizedTableStore(obj, columnName)
            hasSummary = isfield(obj.summarizedTablesStruct, columnName);
        end

        function store = getTableStore(obj)
            store = obj.tableStoreHandle;
        end

        function store = getFilteringStorage(obj)
            store = obj.filteringStorageHandle;
        end

        function store = getSummarizedTableStore(obj, columnName)
            if ~obj.hasSummarizedTableStore(columnName)
                obj.addSummarizedTableStore(columnName);
            end
            store = obj.summarizedTablesStruct.(columnName);
        end

        function filteringStore = getSummarizedFilteringStorage(obj, columnName)
            if ~obj.hasSummarizedTableStore(columnName)
                obj.addSummarizedTableStore(columnName);
            end
            filteringStore = obj.summarizedFilteringStruct.(columnName);    % I am calling it filteringStore and not filteringStorage, because FilteringStorage is a class name
        end

        function obj = removeSummarizedTableStore(obj, columnName)
            if obj.hasSummarizedTableStore(columnName)
                obj.summarizedTablesStruct = rmfield(obj.summarizedTablesStruct, columnName);
            end
        end
    end


    methods (Access = private)
        function notifyUserColumnDefinitionChange(obj, src, event)
            % Notify the user about the column definition change
            % This method is called when a column definition change occurs
            % It creates a ColumnDefinitionEvent and notifies the listeners

            % columnName = event.name;
            % typeOfChange = event.typeOfChange;
            % userDefinitionObject = event.userDefinitionObject;

            % columnDefinitionEvent = ColumnDefinitionEvent(columnName, typeOfChange, userDefinitionObject);
            disp(['Column definition changed: ', event.name, ' - ', event.typeOfChange]);
            notify(obj, 'userColumnDefinitionChanged', event);
        end
    end

end