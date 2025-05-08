classdef MockDataStore < handle

    properties
        tableStoreHandle TableStore = TableStore()
        filteringStorageHandle FilteringStorage = FilteringStorage()

        summarizedTablesStruct struct
        summarizedFilteringStruct struct
    end

    methods
        function obj = MockDataStore()
            % Constructor for MockDataStore
            % Initialize properties or perform any setup if needed
        end

        function initialize(obj)
            tableStoreConstruction = TableStore();
            tableData = table(...
                categorical({'A'; 'B'; 'C'; 'A'}), ...
                {'Row1'; 'Row2'; 'Row3'; 'Row4'}, ...
                [1.1; 2.2; 3.3; 4.4], ...
                'VariableNames', {'Category', 'Description', 'Value'});
            tableStoreConstruction.setTableData(tableData);
            obj.tableStoreHandle = tableStoreConstruction;
        end
    end

end