classdef test_AppStateManager_storedViewWithSummarizedFiltering < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function setStateRefreshesPivotedFilteringFromRestoredSummarizedTable(testCase)
            mockApp = MockApp();
            appStateManager = AppStateManager(mockApp);
            cleanup = onCleanup(@() testCase.deleteHandles(appStateManager, mockApp));

            appStateManager.generateTopTableStateManager();
            appStateManager.storeDataFromStruct(testCase.createTestStruct());
            appStateManager.changeTopTableType('Pivoted');

            [processors, ~] = appStateManager.getTableProcessorHandles();
            topProcessor = processors{1};
            topProcessor.setGroupedDataParameter('Value');
            topProcessor.setColumnParameter('timePoint');
            topProcessor.setRowParameter('Category');

            testCase.verifyTrue(appStateManager.showSummarizedAndIndicateSuccess(), ...
                'The summarized companion table should be available for categorical pivoted rows.');

            [processors, ~] = appStateManager.getTableProcessorHandles();
            topProcessor = processors{1};
            bottomProcessor = processors{2};

            bottomProcessor.setActiveColumns({'Value_mean_over_timePoint_mean'});

            % The summarized filter keeps categories B and C. The pivoted table
            % should be row-synchronized to those same displayed summarized rows.
            dataStoreHandle = appStateManager.bottomTableStateManagerHandle.getActiveDataStore();
            summarizedFilteringStorage = dataStoreHandle.getSummarizedFilteringStorage('Category');
            summarizedFilteringStorage.addRangeFilter('Value_mean_over_timePoint_mean', [4, 10]);

            testCase.verifyEqual(string(bottomProcessor.filteredTable.Properties.RowNames), ["B"; "C"]);
            testCase.verifyEqual(string(topProcessor.pivotedTable.Properties.RowNames), ["B"; "C"]);

            storedState = appStateManager.getState();

            % Reapplying a stored view rebuilds the table processors. This used to
            % create the synchronizer before the bottom processor restored active
            % columns, so the pivoted row-sync filter was calculated from an empty
            % summarized display and stayed wrong.
            appStateManager.setState(storedState);

            [restoredProcessors, ~] = appStateManager.getTableProcessorHandles();
            restoredTopProcessor = restoredProcessors{1};
            restoredBottomProcessor = restoredProcessors{2};

            testCase.verifyEqual(string(restoredBottomProcessor.filteredTable.Properties.RowNames), ["B"; "C"]);
            testCase.verifyEqual(string(restoredTopProcessor.pivotedTable.Properties.RowNames), ["B"; "C"]);
        end



        function openingBottomTableAppliesPreexistingSummarizedFiltersToPivotedTable(testCase)
            mockApp = MockApp();
            appStateManager = AppStateManager(mockApp);
            cleanup = onCleanup(@() testCase.deleteHandles(appStateManager, mockApp));

            appStateManager.generateTopTableStateManager();
            appStateManager.storeDataFromStruct(testCase.createTestStruct());
            appStateManager.changeTopTableType('Pivoted');

            [processors, ~] = appStateManager.getTableProcessorHandles();
            topProcessor = processors{1};
            topProcessor.setGroupedDataParameter('Value');
            topProcessor.setColumnParameter('timePoint');
            topProcessor.setRowParameter('Category');

            dataStoreHandle = appStateManager.topTableStateManagerHandle.getActiveDataStore();
            summarizedFilteringStorage = dataStoreHandle.getSummarizedFilteringStorage('Category');

            % This filter exists before the summarized table is opened. Opening
            % two-table mode should still apply it to the pivoted row-sync filter,
            % even though the bottom processor has not selected display columns yet.
            summarizedFilteringStorage.addRangeFilter('Value_mean_over_timePoint_mean', [4, 10]);

            testCase.verifyTrue(appStateManager.showSummarizedAndIndicateSuccess(), ...
                'The summarized companion table should open for categorical pivoted rows.');

            [processors, ~] = appStateManager.getTableProcessorHandles();
            restoredTopProcessor = processors{1};

            testCase.verifyEqual(string(restoredTopProcessor.pivotedTable.Properties.RowNames), ["B"; "C"]);
        end
    end



    methods (Access = private)
        function testStruct = createTestStruct(~)
            testStruct = struct();
            testStruct.model.branch1.combinedList = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                categorical([1; 1; 2; 2; 3; 3; 1; 2]), ...
                'VariableNames', {'Value', 'Category', 'timePoint'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};
        end



        function deleteHandles(~, appStateManager, mockApp)
            if isa(appStateManager, 'handle') && isvalid(appStateManager)
                delete(appStateManager);
            end

            if isa(mockApp, 'handle') && isvalid(mockApp)
                delete(mockApp);
            end
        end
    end
end
