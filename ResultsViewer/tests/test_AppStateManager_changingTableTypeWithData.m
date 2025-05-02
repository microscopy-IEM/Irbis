classdef test_AppStateManager_changingTableTypeWithData < testParent_AppStateManager
    methods (TestMethodSetup)
        function generateTableStateManagerAndLoadData(testCase)
            testCase.appStateManager.generateTopTableStateManager();
            testCase.appStateManager.storeDataFromStruct(testCase.createTestModelStruct());
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            delete(testCase.appStateManager);
        end
    end

    methods (Test)
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