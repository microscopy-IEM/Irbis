classdef test_TableStore < matlab.unittest.TestCase
    properties
        TableStoreObj
    end

    properties (SharedTestFixtures)
        DefaultTableData = table([1; 2; 3; 4], {'A'; 'B'; 'C'; 'D'}, ...
                                 categorical({'Group1'; 'Group1'; 'Group2'; 'Group2'}), ...
                                 [10.5; 20.3; 30.1; 40.2], ...
                                 'VariableNames', {'Numbers', 'Letters', 'Groups', 'Values'});
        DefaultCategorization
    end

    methods (TestMethodSetup)
        function createTableStore(testCase)
            % Create an instance of TableStore before each test
            testCase.TableStoreObj = TableStore();

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
            testCase.DefaultCategorization = Categorization('NumericalCategorization', conditions);
        end
    end

    methods (Test)
        function testSetTableData(testCase)
            % Test setting table data
            newTableData = table([1; 2; 3], {'A'; 'B'; 'C'}, 'VariableNames', {'Numbers', 'Letters'});
            testCase.TableStoreObj.setTableData(newTableData);
            testCase.verifyEqual(testCase.TableStoreObj.getTableData(), newTableData);
        end

        function testAddTableData(testCase)
            % Test adding table data
            initialTableData = table([1; 2], {'A'; 'B'}, 'VariableNames', {'Numbers', 'Letters'});
            additionalTableData = table(3, {'C'}, 'VariableNames', {'Numbers', 'Letters'});
            expectedTableData = [initialTableData; additionalTableData];

            testCase.TableStoreObj.setTableData(initialTableData);
            testCase.TableStoreObj.addTableData(additionalTableData);

            testCase.verifyEqual(testCase.TableStoreObj.getTableData(), expectedTableData);
        end

        function testGetColumnNames(testCase)
            % Test retrieving column names
            tableData = table([1; 2; 3], {'A'; 'B'; 'C'}, 'VariableNames', {'Numbers', 'Letters'});
            testCase.TableStoreObj.setTableData(tableData);

            expectedColumnNames = {'Numbers', 'Letters'};
            testCase.verifyEqual(testCase.TableStoreObj.getColumnNames(), expectedColumnNames);
        end

        function testGetTableSubsetByName(testCase)
            % Test retrieving a subset of the table by column names
            tableData = table([1; 2; 3], {'A'; 'B'; 'C'}, 'VariableNames', {'Numbers', 'Letters'});
            testCase.TableStoreObj.setTableData(tableData);

            subset = testCase.TableStoreObj.getTableSubsetByName({'Letters'});
            expectedSubset = table({'A'; 'B'; 'C'}, 'VariableNames', {'Letters'});

            testCase.verifyEqual(subset, expectedSubset);
        end

        function testAddUserDefinedColumn(testCase)
            % Test adding a user-defined column
            tableData = table([1; 2; 3], 'VariableNames', {'Numbers'});
            testCase.TableStoreObj.setTableData(tableData);

            newColumnName = 'Squares';
            newColumnData = [1; 4; 9];
            testCase.TableStoreObj.addUserDefinedColumn(newColumnName, newColumnData, []);

            testCase.verifyEqual(testCase.TableStoreObj.getTableData().Squares, newColumnData);
            testCase.verifyTrue(ismember(newColumnName, testCase.TableStoreObj.getUserDefinedColumnNames()));
        end

        function testRemoveColumn(testCase)
            % Test removing a column
            tableData = table([1; 2; 3], {'A'; 'B'; 'C'}, 'VariableNames', {'Numbers', 'Letters'});
            testCase.TableStoreObj.setTableData(tableData);

            testCase.TableStoreObj.removeColumn('Letters');
            expectedTableData = table([1; 2; 3], 'VariableNames', {'Numbers'});

            testCase.verifyEqual(testCase.TableStoreObj.getTableData(), expectedTableData);
        end
    end
end
