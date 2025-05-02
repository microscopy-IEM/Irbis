classdef test_AppStateManager_changingTableType < testParent_AppStateManager
    methods (Test)
        function initialTableStateManagerIsEmpty(testCase)
            testCase.verifyEmpty(testCase.appStateManager.topTableStateManagerHandle, ...
                'Initially, AppStateManager should report no table state manager.');
        end

        function initialTableProcessorsAreEmpty(testCase)
            [processorHandles, processorTypes] = testCase.appStateManager.getTableProcessorHandles();
            testCase.verifyEmpty(processorHandles, ...
                'Initially, AppStateManager should report no table processors.');
            testCase.verifyEmpty(processorTypes, ...
                'Initially, AppStateManager should report no corresponding table types.');
        end

        function generateTableStateManager(testCase)
            testCase.appStateManager.generateTopTableStateManager();
            testCase.verifyNotEmpty(testCase.appStateManager.topTableStateManagerHandle, ...
                'After generating table state manager, AppStateManager should have a table state manager.');
        end

        function loadData(testCase)
            testCase.appStateManager.storeDataFromStruct(testCase.createTestModelStruct());
            activeDataStoreHandle = testCase.appStateManager.activeDataStoreHandle;
            testCase.verifyNotEmpty(activeDataStoreHandle, ...
                'After loading data, there should be activeDataStoreHandle.');
            testCase.verifyClass(activeDataStoreHandle, 'DataStore', ...
                'After loading data, activeDataStoreHandle should be of type DataStore.');
            tableStore = activeDataStoreHandle.getTableStore();
            tableData = tableStore.getTableData();
            testCase.verifyNotEmpty(tableData, ...
                'After loading data, there should be table data.')
        end

        function changingTableTypeGeneratesTableStateManager(testCase)
            % NOTE: TableStateManager and FilteringMenuStateManager are asking app for grid layout
            %       this needs to be mocked in the MockApp
            testCase.appStateManager.changeTopTableType('Full');
            testCase.verifyNotEmpty(testCase.appStateManager.topTableStateManagerHandle, ...
                'After changing table type, AppStateManager should have a table state manager.');
        end

        function changingTableTypeGeneratesTableProcessorFull(testCase)
            testCase.appStateManager.changeTopTableType("Full");
            [processorHandles, processorTypes] = testCase.appStateManager.getTableProcessorHandles();
            % verify that there is only one processor and that it is of type 'Full'
            testCase.verifyEqual(length(processorHandles), 1, ...
                'After changing table type, AppStateManager should have one table processor.');
            testCase.verifyEqual(length(processorTypes), 1, ...
                'After changing table type, AppStateManager should have one corresponding table type.');
            testCase.verifyClass(processorHandles{1}, 'FullTableProcessor', ...
                'After changing table type to Full, AppStateManager should have a table processor of class ''FullTableProcessor''.');
            testCase.verifyEqual(processorTypes{1}, "Full", ...
                'After changing table type, AppStateManager should have a table processor of type ''Full''.');
                % BE CAREFUL: we are using sting for the table type, not char
        end

        function changingTableTypeGeneratesTableProcessorPivoted(testCase)
            testCase.appStateManager.changeTopTableType("Pivoted");
            [processorHandles, processorTypes] = testCase.appStateManager.getTableProcessorHandles();
            % verify that there is only one processor and that it is of type 'Full'
            testCase.verifyEqual(length(processorHandles), 1, ...
                'After changing table type, AppStateManager should have one table processor.');
            testCase.verifyEqual(length(processorTypes), 1, ...
                'After changing table type, AppStateManager should have one corresponding table type.');
            testCase.verifyClass(processorHandles{1}, 'PivotedTableProcessor', ...
                'After changing table type to Pivoted, AppStateManager should have a table processor of class ''PivotedTableProcessor''.');
            testCase.verifyEqual(processorTypes{1}, "Pivoted", ...
                'After changing table type, AppStateManager should have a table processor of type ''Pivoted''.');
        end

        % function changingTableTypeGeneratesTableProcessorSummarized(testCase)   % This errors if there are no data - it expects a column but that one is empty
        %     testCase.appStateManager.changeTopTableType("Summarized");
        %     [processorHandles, processorTypes] = testCase.appStateManager.getTableProcessorHandles();
        %     % verify that there is only one processor and that it is of type 'Full'
        %     testCase.verifyEqual(length(processorHandles), 1, ...
        %         'After changing table type, AppStateManager should have one table processor.');
        %     testCase.verifyEqual(length(processorTypes), 1, ...
        %         'After changing table type, AppStateManager should have one corresponding table type.');
        %     testCase.verifyClass(processorHandles{1}, 'SummarizedTableProcessor', ...
        %         'After changing table type to Summarized, AppStateManager should have a table processor of class ''SummarizedTableProcessor''.');
        %     testCase.verifyEqual(processorTypes{1}, "Summarized", ...
        %         'After changing table type, AppStateManager should have a table processor of type ''Summarized''.');
        % end
    end
end