classdef test_FullTableProcessor < matlab.unittest.TestCase

    properties
        processor
        mockStateManager
        mockDataStore
    end

    methods (TestClassSetup)
        function addPaths(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end


    methods (TestMethodSetup)
        function createprocessor(testCase)
            % Create an instance of FullTableProcessor
            testCase.processor = FullTableProcessor();
            testCase.mockStateManager = MockTableStateManager();
            testCase.mockDataStore = MockDataStore();
        end
    end


    methods (Test)
        function testConstructor(testCase)
            % Test that the object is created successfully
            testCase.verifyNotEmpty(testCase.processor);
        end


        function testSetHandles(testCase)
            % Test setting handles
            testCase.processor.setHandles(testCase.mockStateManager, testCase.mockDataStore);
            testCase.verifyEqual(testCase.processor.stateManagerHandle, testCase.mockStateManager);
            testCase.verifyEqual(testCase.processor.dataStoreHandle, testCase.mockDataStore);
        end


        function testGetTableForDisplayEmpty(testCase)
            % Test getTableForDisplay when no data is set
            tableForDisplay = testCase.processor.getTableForDisplay();
            testCase.verifyEmpty(tableForDisplay);
        end


        function testStoreSelectedTableCellsList(testCase)
            % Test storing selected table cells
            selectedCells = [1, 2; 3, 4];
            testCase.processor.storeSelectedTableCellsList(selectedCells);
            testCase.verifyEqual(testCase.processor.selectedTableCellsList, selectedCells);
        end


        function testGetSelectedTableCellsList(testCase)
            % Test retrieving selected table cells
            selectedCells = [1, 2; 3, 4];
            testCase.processor.storeSelectedTableCellsList(selectedCells);
            retrievedCells = testCase.processor.getSelectedTableCellsList();
            testCase.verifyEqual(retrievedCells, selectedCells);
        end


        function testSetSelectedColumns(testCase)
            % Test setting active columns
            columns = {'Column1', 'Column2'};
            testCase.processor.setSelectedColumns(columns);
            testCase.verifyEqual(testCase.processor.activeColumns, columns);
        end


        function testGetState(testCase)
            % Test getting the processor state
            columns = {'Column1', 'Column2'};
            selectedCells = [1, 2; 3, 4];
            testCase.processor.setSelectedColumns(columns);
            testCase.processor.storeSelectedTableCellsList(selectedCells);
            state = testCase.processor.getState();
            testCase.verifyEqual(state.activeColumns, columns);
            testCase.verifyEqual(state.selectedTableCellsList, selectedCells);
        end
        

        function testSetState(testCase)
            % Test setting the processor state
            state.activeColumns = {'Column1', 'Column2'};
            state.selectedTableCellsList = [1, 2; 3, 4];
            testCase.processor.setState(state);
            testCase.verifyEqual(testCase.processor.activeColumns, state.activeColumns);
            testCase.verifyEqual(testCase.processor.selectedTableCellsList, state.selectedTableCellsList);
        end
    end
end