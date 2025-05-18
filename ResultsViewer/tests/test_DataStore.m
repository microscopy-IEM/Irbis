classdef test_DataStore < matlab.unittest.TestCase
    properties
        defaultTableData = table([1; 2; 3; 4], {'A'; 'B'; 'C'; 'D'}, ...
                                 categorical({'Group1'; 'Group1'; 'Group2'; 'Group2'}), ...
                                 [10.5; 20.3; 30.1; 40.2], ...
                                 'VariableNames', {'Numbers', 'Letters', 'Groups', 'Values'});
        defaultCategorization
        categorizationColumnName = 'NumericalCategorization';
        dataStoreHandle
    end


    methods (TestClassSetup)
        function createDefaultCategorization(testCase)
            % Create an instance of TableStore before each test

            % Define the default categorization
            conditions = struct();

            thresholdNumbers = 3;
            thresholdValues = 20;

            innerDictionaryNumberLow = dictionary("lessThan", thresholdNumbers);
            innerDictionaryValuesLow = dictionary("lessThan", thresholdValues);
            innerDictionaryNumbersHigh = dictionary("equalOrGreaterThan", thresholdNumbers);
            innerDictionaryValuesHigh = dictionary("equalOrGreaterThan", thresholdValues);

            outerDictionaryLowLow = dictionary("Numbers", {innerDictionaryNumberLow}, "Values", {innerDictionaryValuesLow});
            outerDictionaryHighHigh = dictionary("Numbers", {innerDictionaryNumbersHigh}, "Values", {innerDictionaryValuesHigh});
            outerDictionaryLowHigh = dictionary("Numbers", {innerDictionaryNumberLow}, "Values", {innerDictionaryValuesHigh});
            outerDictionaryHighLow = dictionary("Numbers", {innerDictionaryNumbersHigh}, "Values", {innerDictionaryValuesLow});

            conditions.group1.name = 'LowLow';
            conditions.group1.conditions = outerDictionaryLowLow;
            conditions.group2.name = 'HighHigh';
            conditions.group2.conditions = outerDictionaryHighHigh;
            conditions.group3.name = 'LowHigh';
            conditions.group3.conditions = outerDictionaryLowHigh;
            conditions.group4.name = 'HighLow';
            conditions.group4.conditions = outerDictionaryHighLow;

            % Create Categorization object
            testCase.defaultCategorization = Categorization(testCase.categorizationColumnName, conditions);
        end
    end


    methods (Test)
        function createTableStore(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            testCase.verifyEqual(testCase.defaultTableData, tableStoreHandle.getTableData());
        end

        function checkColumnNames(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            columnNames = tableStoreHandle.getColumnNames();
            testCase.verifyEqual(columnNames, testCase.defaultTableData.Properties.VariableNames);
        end

        function createDataStore(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Verify that the DataStore object is created successfully
            testCase.verifyNotEmpty(testCase.dataStoreHandle);
            testCase.verifyEqual(testCase.dataStoreHandle.getTableStore(), tableStoreHandle);
            testCase.verifyEqual(testCase.dataStoreHandle.getFilteringStorage(), FilteringStorage());
        end

        function hasSummarizedTableStore(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            testCase.verifyFalse(testCase.dataStoreHandle.hasSummarizedTableStore('Groups'));
        end

        function addSummarizedTableStore(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Add a summarized table store
            testCase.dataStoreHandle.addSummarizedTableStore('Groups');

            % Verify that the summarized table store is added successfully
            testCase.verifyTrue(testCase.dataStoreHandle.hasSummarizedTableStore('Groups'));
        end

        function addSummarizedWithoutTimepoint(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Add a summarized table store
            testCase.dataStoreHandle.addSummarizedTableStore('Groups');

            % Add a filter to the filtering storage
            % testCase.dataStoreHandle.getFilteringStorage().addRangeFilter('Numbers', [0.9, 2.5]);

            summarized = testCase.dataStoreHandle.getSummarizedTableStore('Groups');
            statColNames = summarized.getColumnNames();

            % IMPORTANT: No columns are made in summarized if timePoint column is not present

            % Verify that the statistical column names are not empty
            testCase.verifyFalse(any(ismember('timePoint', tableStoreHandle.getColumnNames())));
            testCase.verifyEmpty(statColNames);
        end

        function addTimepointColumnAndCheckSummarized(testCase) 
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Add a timepoint column to the table store
            timePointData = categorical([1; 2; 1; 2]);
            testCase.dataStoreHandle.getTableStore().addColumn('timePoint', timePointData);

            % Add a summarized table store
            testCase.dataStoreHandle.addSummarizedTableStore('Groups');

            % Verify that the timepoint column is added successfully
            testCase.verifyTrue(any(ismember('timePoint', testCase.dataStoreHandle.getTableStore().getColumnNames())));

            % Add a filter to the filtering storage
            % testCase.dataStoreHandle.getFilteringStorage().addRangeFilter('Numbers', [0.9, 2.5]);

            summarized = testCase.dataStoreHandle.getSummarizedTableStore('Groups');
            statColNames = summarized.getColumnNames();

            % Verify that the statistical column names are not empty
            testCase.verifyTrue(any(ismember('timePoint', tableStoreHandle.getColumnNames())));
            testCase.verifyNotEmpty(statColNames);
        end


        function checkSummarized(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Add a timepoint column to the table store
            timePointData = categorical([1; 2; 1; 2]);
            testCase.dataStoreHandle.getTableStore().addColumn('timePoint', timePointData);

            % Add a summarized table store
            testCase.dataStoreHandle.addSummarizedTableStore('Groups');

            % Add a filter to the filtering storage
            % testCase.dataStoreHandle.getFilteringStorage().addRangeFilter('Numbers', [0.9, 2.5]);

            summarized = testCase.dataStoreHandle.getSummarizedTableStore('Groups');
            % columns = summarized.getColumnNames();
            % assignin("base", "columns", columns)
            columnNameToTest = 'Values_mean_over_timePoint_mean';
            expectedTable = table([15.4; 35.15], 'VariableNames', {columnNameToTest}, 'RowNames', {'Group1', 'Group2'});
            outputTable = summarized.getTableSubsetByName(columnNameToTest);

            % Check approximate equality
            testCase.verifyEqual(outputTable.(columnNameToTest), expectedTable.(columnNameToTest), 'AbsTol', 1e-10);
            testCase.verifyEqual(outputTable.Properties.RowNames, expectedTable.Properties.RowNames);
            testCase.verifyEqual(outputTable.Properties.VariableNames, expectedTable.Properties.VariableNames); 
        end


        function addFilterAndCheckSummarized(testCase)
            % Create an instance of TableStore before each test
            tableStoreHandle = TableStore();
            tableStoreHandle.setTableData(testCase.defaultTableData);

            % Create DataStore object
            testCase.dataStoreHandle = DataStore(tableStoreHandle, FilteringStorage());

            % Add a timepoint column to the table store
            timePointData = categorical([1; 2; 1; 2]);
            testCase.dataStoreHandle.getTableStore().addColumn('timePoint', timePointData);

            % Add a summarized table store
            testCase.dataStoreHandle.addSummarizedTableStore('Groups');

            % Add a filter to the filtering storage
            testCase.dataStoreHandle.getFilteringStorage().addRangeFilter('Numbers', [0.9, 2.5]);

            summarized = testCase.dataStoreHandle.getSummarizedTableStore('Groups');
            columnNameToTest = 'Values_mean_over_timePoint_mean';
            expectedTable = table([15.4], 'VariableNames', {columnNameToTest}, 'RowNames', {'Group1'});
            outputTable = summarized.getTableSubsetByName(columnNameToTest);

            % Check approximate equality
            testCase.verifyEqual(outputTable.(columnNameToTest), expectedTable.(columnNameToTest), 'AbsTol', 1e-10);
            testCase.verifyEqual(outputTable.Properties.RowNames, expectedTable.Properties.RowNames);
        end
    end
end