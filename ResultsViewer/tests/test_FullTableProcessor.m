classdef test_FullTableProcessor < matlab.unittest.TestCase
    properties
        Processor
        MockStateManager
        MockDataStore
    end

    methods (TestMethodSetup)
        function createProcessor(testCase)
            % Create an instance of FullTableProcessor
            testCase.Processor = FullTableProcessor();

            % Create mock objects for dependencies
            import matlab.mock.TestCase;
            [testCase.MockStateManager, ~] = TestCase.createMock();
            [testCase.MockDataStore, ~] = TestCase.createMock();
        end
    end

    methods (Test)
        function testConstructor(testCase)
            % Test that the object is created successfully
            testCase.verifyNotEmpty(testCase.Processor);
        end

        function testSetHandles(testCase)
            % Test setting handles
            testCase.Processor.setHandles(testCase.MockStateManager, testCase.MockDataStore);
            testCase.verifyEqual(testCase.Processor.stateManagerHandle, testCase.MockStateManager);
            testCase.verifyEqual(testCase.Processor.dataStoreHandle, testCase.MockDataStore);
        end

        function testGetTableForDisplayEmpty(testCase)
            % Test getTableForDisplay when no data is set
            tableForDisplay = testCase.Processor.getTableForDisplay();
            testCase.verifyEmpty(tableForDisplay);
        end

        function testStoreSelectedTableCellsList(testCase)
            % Test storing selected table cells
            selectedCells = [1, 2; 3, 4];
            testCase.Processor.storeSelectedTableCellsList(selectedCells);
            testCase.verifyEqual(testCase.Processor.selectedTableCellsList, selectedCells);
        end

        function testGetSelectedTableCellsList(testCase)
            % Test retrieving selected table cells
            selectedCells = [1, 2; 3, 4];
            testCase.Processor.storeSelectedTableCellsList(selectedCells);
            retrievedCells = testCase.Processor.getSelectedTableCellsList();
            testCase.verifyEqual(retrievedCells, selectedCells);
        end

        function testSetSelectedColumns(testCase)
            % Test setting active columns
            columns = {'Column1', 'Column2'};
            testCase.Processor.setSelectedColumns(columns);
            testCase.verifyEqual(testCase.Processor.activeColumns, columns);
        end

        function testGetState(testCase)
            % Test getting the processor state
            columns = {'Column1', 'Column2'};
            selectedCells = [1, 2; 3, 4];
            testCase.Processor.setSelectedColumns(columns);
            testCase.Processor.storeSelectedTableCellsList(selectedCells);
            state = testCase.Processor.getState();
            testCase.verifyEqual(state.activeColumns, columns);
            testCase.verifyEqual(state.selectedTableCellsList, selectedCells);
        end

        function testSetState(testCase)
            % Test setting the processor state
            state.activeColumns = {'Column1', 'Column2'};
            state.selectedTableCellsList = [1, 2; 3, 4];
            testCase.Processor.setState(state);
            testCase.verifyEqual(testCase.Processor.activeColumns, state.activeColumns);
            testCase.verifyEqual(testCase.Processor.selectedTableCellsList, state.selectedTableCellsList);
        end
    end
end