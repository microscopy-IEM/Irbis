classdef (Sealed) test_filteringIntegration < matlab.unittest.TestCase

    % Test integration of filtering in ResultsViewer
    % Filtering is set to FilteringStorage
    % This influences data available in TableProcessor and what is shown in the component
    % For summarized table, filtering of full table is applied in TableStore decorator

    properties
        % Define properties for the test class if needed

        appStateManager
        mockApp

        eventCount = 0; % Counter for the number of times the event was emitted
    end


    methods (TestClassSetup)
        function setup(testCase)
            % Setup code that runs before each test
            addpath(fullfile(pwd, '..', '..')); % Adjust path as necessary

            testCase.mockApp = MockApp();
            testCase.appStateManager = AppStateManager(testCase.mockApp);

            testCase.appStateManager.generateTopTableStateManager();
            testCase.appStateManager.storeDataFromStruct(testCase.createTestStruct());
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


        function filteringStorageSendsNotification(testCase)
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();

            listener = addlistener(filteringStorage, 'filtersChanged', @(~, ~) testCase.incrementEventCount());
            
            filteringStorage.addRangeFilter('Value', [10, 20]);
            testCase.verifyNotEmpty(filteringStorage, ...
                'FilteringStorage handle should not be empty after setting up the AppStateManager.');

            testCase.verifyEqual(testCase.eventCount, 1, ...
                'Event should be emitted once after adding a range filter.');

            delete(listener); % Clean up listener
            testCase.resetEventCount(); % Reset the event count for future tests  
            
        end


        function filteringStorageIsEmptyAfterDeletingFilter(testCase)
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();
            testCase.verifyEqual(filteringStorage.returnGroupingNames(), {'Value'}, ...
                'FilteringStorage should have the filter "Value".');
            filteringStorage.deleteGrouping('Value');
            testCase.verifyEmpty(filteringStorage.returnGroupingNames(), ...
                'FilteringStorage should be empty after deleting the filter.');
        end


        function notificationNotRecordedAfterListenerDeleted(testCase)
            % Test that no event is recorded after the listener is deleted
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();

            listener = addlistener(filteringStorage, 'filtersChanged', @(~, ~) testCase.incrementEventCount());
            delete(listener); % Delete the listener immediately

            filteringStorage.addRangeFilter('Value', [10, 20]);
            testCase.verifyEqual(testCase.eventCount, 0, ...
                'Event should not be recorded after listener is deleted.');

            existingFilters = filteringStorage.returnGroupingNames();
            testCase.verifyEqual(existingFilters, {'Value'}, ...
                'FilteringStorage should have the filter "Value" after adding it.');
            filteringStorage.deleteGrouping('Value');
            testCase.verifyEmpty(filteringStorage.returnGroupingNames(), ...
                'FilteringStorage should be empty after deleting the filter.');
        end


        function originalTableStoredInProcessor(testCase)
            [processorHandles, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            testCase.verifyEqual(length(processorHandles), 1, ...
                'processorHandles should be a cell array of length 1 for the full table.');
            testCase.verifyEqual(tableTypes, {'Full'}, ...
                'tableTypes should be a cell array with one element "Full".');

            tableProcessorHandle = processorHandles{1};
            % Check that the FullTableProcessor contains the expected filtered table data

            % Get the table for display (should reflect filters and active columns)
            tableForDisplay = tableProcessorHandle.getTableForDisplay();

            % By default, activeColumns may be empty, so set them to all columns
            if isempty(tableProcessorHandle.activeColumns)
                tableProcessorHandle.setSelectedColumns(tableProcessorHandle.tableStoreHandle.getColumnNames());
                tableForDisplay = tableProcessorHandle.getTableForDisplay();
            end

            % The default test struct loads 'model'/'branch1' as the active modality/branch
            % So, the expected table is:
            expectedTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            testCase.verifyEqual(tableProcessorHandle.filteredTable, expectedTable, ...
                'FullTableProcessor should contain the expected filtered data from createTestStruct for model.branch1.');

            % Check that the table for display matches the expected table
            testCase.verifyEqual(tableForDisplay, expectedTable, ...
                'FullTableProcessor should contain the expected data from createTestStruct for model.branch1.');
        end


        function originalTableStoredInComponent(testCase)
            tableComponent = testCase.appStateManager.topTableStateManagerHandle.tableComponentHandle;

            % The default test struct loads 'model'/'branch1' as the active modality/branch
            % So, the expected table is:
            expectedTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            visualizedTableData = tableComponent.getTableData();

            testCase.verifyEqual(visualizedTableData, expectedTable, ...
                'TableComponent should contain the expected data from createTestStruct for model.branch1.');
        end


        function filteringWorks(testCase)

            % Add a filter to the FilteringStorage and verify the filtered table updates
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();

            % Add a range filter to only include rows where 'Value' is between 2 and 6
            filteringStorage.addRangeFilter('Value', [2, 6]);

            originalTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ... % Numerical column
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ... % Categorical column
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ... % Another numerical column
                'VariableNames', {'Value', 'Category', 'Score'});
                
            isKept = filteringStorage.filter(originalTable);

            testCase.verifyEqual(isKept, [false; true; true; true; true; true; false; false], ...
                'FilteringStorage should correctly filter rows where Value is between 2 and 6.');
        end


        function fullTableProcessorUpdatesTable(testCase)
            [processorHandles, ~] = testCase.appStateManager.getTableProcessorHandles();
            tableProcessorHandle = processorHandles{1};

            % The expected filtered table should only include rows with Value 2, 3, 4, 5, 6
            expectedFilteredTable = table( ...
                [2; 3; 4; 5; 6], ...
                categorical({'B'; 'A'; 'C'; 'B'; 'C'}), ...
                [20.3; 15.8; 30.1; 25.7; 18.2], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            % Get the updated filtered table
            filteredTable = tableProcessorHandle.filteredTable;

            testCase.verifyEqual(filteredTable, expectedFilteredTable, ...
                'Filtered table should only include rows where Value is between 2 and 6.');

            % Set the active columns to all columns before checking table for display
            tableProcessorHandle.setSelectedColumns(tableProcessorHandle.tableStoreHandle.getColumnNames());

            % Also check that the table for display matches the expected filtered table
            tableForDisplay = tableProcessorHandle.getTableForDisplay();
            testCase.verifyEqual(tableForDisplay, expectedFilteredTable, ...
                'Table for display should match the expected filtered table after filtering.');
        end


        function fullTableComponentUpdatesTable(testCase)
            % Add a filter to the FilteringStorage and verify the tableComponent updates
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();

            tableComponent = testCase.appStateManager.topTableStateManagerHandle.tableComponentHandle;

            % The expected filtered table should only include rows with Value 2, 3, 4, 5, 6
            expectedFilteredTable = table( ...
                [2; 3; 4; 5; 6], ...
                categorical({'B'; 'A'; 'C'; 'B'; 'C'}), ...
                [20.3; 15.8; 30.1; 25.7; 18.2], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            visualizedTableData = tableComponent.getTableData();

            testCase.verifyEqual(visualizedTableData, expectedFilteredTable, ...
                'TableComponent should update and show only filtered rows where Value is between 2 and 6.');

            % Now remove the filter and check that the tableComponent returns to original table
            filteringStorage.deleteGrouping('Value');
            expectedOriginalTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            visualizedTableDataAfterDelete = tableComponent.getTableData();

            testCase.verifyEqual(visualizedTableDataAfterDelete, expectedOriginalTable, ...
                'TableComponent should revert to original data after filter is deleted.');
        end


        function pivotedTableProcessorUpdatesTable(testCase)

            filteringRange = [3, 5]; % Define the range for the filter

            % Get the FilteringStorage from the current data store and verify the filter is still present
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();
            filteringStorage.addRangeFilter('Value', filteringRange);
            testCase.appStateManager.changeTopTableType('Pivoted');

            [processorHandles, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            testCase.verifyEqual(length(processorHandles), 1, ...
                'processorHandles should be a cell array of length 1 for the pivoted table.');
            testCase.verifyEqual(tableTypes, {'Pivoted'}, ...
                'tableTypes should be a cell array with one element "Pivoted".');

            tableProcessorHandle = processorHandles{1};

            % disp(tableProcessorHandle.getTableForDisplay());

            % The expected pivoted table: 'Category' as rows, 'Value' as columns, 'Score' as values.
            % We will pivot the original table accordingly.
            originalTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            isKept = [false; false; true; true; true; false; false; false]; % Only keep rows with Value 3, 4, 5

            % Use unstack to pivot: rows=Category, columns=Value, values=Score
            expectedOriginalTable = pivot(originalTable(isKept, :), ...
                'Rows', 'Category', ...
                'Columns', 'Value', ...
                'DataVariable', 'Score', ...
                'Method', 'mean'); % Use mean as aggregation method	
            expectedOriginalTable.Properties.RowNames = string(expectedOriginalTable.Category);
            expectedOriginalTable.Category = []; % Remove the Category column as it is now row names

            pivotedTable = tableProcessorHandle.getTableForDisplay();

            testCase.verifyEqual(pivotedTable, expectedOriginalTable, ...
                'PivotedTableProcessor should contain the expected pivoted data for model.branch1.');

            filteringStorage.deleteGrouping('Value'); % Clean up the filter after test

            % Use unstack to pivot: rows=Category, columns=Value, values=Score
            expectedOriginalTable = pivot(originalTable, ...
                'Rows', 'Category', ...
                'Columns', 'Value', ...
                'DataVariable', 'Score', ...
                'Method', 'mean'); % Use mean as aggregation method
            expectedOriginalTable.Properties.RowNames = string(expectedOriginalTable.Category);
            expectedOriginalTable.Category = []; % Remove the Category column as it is now row names

            pivotedTable = tableProcessorHandle.getTableForDisplay();

            testCase.verifyEqual(pivotedTable, expectedOriginalTable, ...
                'PivotedTableProcessor should contain the expected pivoted data for model.branch1.');

            % % Get the FilteringStorage from the current data store and verify the filter is still present
            % currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            % filteringStorage = currentDataStore.getFilteringStorage();
            % testCase.verifyEqual(filteringStorage.returnGroupingNames(), {'Value'}, ...
            %     'FilteringStorage should still have the "Value" filter after switching to Pivoted table.');
        end


        function pivotedTableComponentUpdatesTable(testCase)
            filteringRange = [3, 5]; % Define the range for the filter

            % Get the FilteringStorage from the current data store and verify the filter is still present
            currentDataStore = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = currentDataStore.getFilteringStorage();
            filteringStorage.addRangeFilter('Value', filteringRange);
            testCase.appStateManager.changeTopTableType('Pivoted');

            tableComponent = testCase.appStateManager.topTableStateManagerHandle.tableComponentHandle;

            % The expected pivoted table: 'Category' as rows, 'Value' as columns, 'Score' as values.
            % We will pivot the original table accordingly.
            originalTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            isKept = [false; false; true; true; true; false; false; false]; % Only keep rows with Value 3, 4, 5

            % Use unstack to pivot: rows=Category, columns=Value, values=Score
            expectedOriginalTable = pivot(originalTable(isKept, :), ...
                'Rows', 'Category', ...
                'Columns', 'Value', ...
                'DataVariable', 'Score', ...
                'Method', 'mean'); % Use mean as aggregation method	
            expectedOriginalTable.Properties.RowNames = string(expectedOriginalTable.Category);
            expectedOriginalTable.Category = []; % Remove the Category column as it is now row names

            visualizedTableData = tableComponent.getTableData();

            testCase.verifyEqual(visualizedTableData, expectedOriginalTable, ...
                'PivotedTableComponent should contain the expected pivoted data for model.branch1.');

            filteringStorage.deleteGrouping('Value'); % Clean up the filter after test

            % Use unstack to pivot: rows=Category, columns=Value, values=Score
            expectedOriginalTable = pivot(originalTable, ...
                'Rows', 'Category', ...
                'Columns', 'Value', ...
                'DataVariable', 'Score', ...
                'Method', 'mean'); % Use mean as aggregation method
            expectedOriginalTable.Properties.RowNames = string(expectedOriginalTable.Category);
            expectedOriginalTable.Category = []; % Remove the Category column as it is now row names
            visualizedTableData = tableComponent.getTableData();
            testCase.verifyEqual(visualizedTableData, expectedOriginalTable, ...
                'PivotedTableComponent should contain the expected pivoted data for model.branch1 after removing filter.');
        end


        function summarizedTableProcessorUpdatesTable(testCase)
            % There will be no columns in the summarized table, unless we have a 'timePoint' column

            tableStoreHandle = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore().getTableStore();
            % add column 'timePoint' to the table store
            tableStoreHandle.addColumn('timePoint', [1; 2; 2; 1; 2; 1; 2; 1]);

            testCase.appStateManager.changeTopTableType('Summarized');
            [processorHandles, tableTypes] = testCase.appStateManager.getTableProcessorHandles();

            testCase.verifyEqual(length(processorHandles), 1, ...
                'processorHandles should be a cell array of length 1 for the summarized table.');
            testCase.verifyEqual(tableTypes, {'Summarized'}, ...
                'tableTypes should be a cell array with one element "Summarized".');
            tableProcessorHandle = processorHandles{1};

            disp('summarizedTableProcessorUpdatesTable - tableProcessorHandle:');
            disp(tableProcessorHandle.rowParameter);
            
            % Set active columns to ['Value_std_over_timePoint_mean', 'Value_mean_over_timePoint_mean', 'Score_mean_over_timePoint_mean']
            activeColumns = {'Value_std_over_timePoint_mean', 'Value_mean_over_timePoint_mean', 'Score_mean_over_timePoint_mean'};
            tableProcessorHandle.setActiveColumns(activeColumns);


            tableForDisplay = tableProcessorHandle.getTableForDisplay();
            disp('summarizedTableProcessorUpdatesTable - tableForDisplay:');
            disp(tableForDisplay);

            summarizedTable = testCase.getSummarizedFromOriginal();
            disp(summarizedTable);
        end
    end


    methods (Access = private)
        function testStruct = createTestStruct(~)
            testStruct = struct();
            testStruct.model.branch1.combinedList = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ... % Numerical column
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ... % Categorical column
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ... % Another numerical column
                'VariableNames', {'Value', 'Category', 'Score'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};

            testStruct.model.branch2.combinedList = table( ...
                [9; 10; 11; 12], ... % Numerical column
                categorical({'B'; 'C'; 'A'; 'C'}), ... % Categorical column
                [12.1; 19.7; 23.5; 16.8], ... % Another numerical column
                'VariableNames', {'Value', 'Category', 'Score'});
            % Create FilteringStorage and add example filters
            branch2FilteringStorage = FilteringStorage();
            % Add a range filter on 'Value' column (e.g., keep values between 10 and 12)
            branch2FilteringStorage.addRangeFilter('Value', [10, 12]);
            % Add a categorical filter on 'Category' column (e.g., keep only 'A' and 'C')
            branch2FilteringStorage.addCategoricalFilter('Category', {'A', 'C'});
            testStruct.model.branch2.storedFilters = {branch2FilteringStorage};
            testStruct.model.branch2.storedCategorizations = {CategorizationStorage()};

            testStruct.tracks.combinedList = table( ...
                [101; 102; 103; 104; 105; 106; 107; 108], ... % Numerical column
                categorical({'X'; 'Y'; 'X'; 'Z'; 'Y'; 'Z'; 'X'; 'Y'}), ... % Categorical column
                [55.2; 63.1; 58.7; 60.5; 62.3; 59.8; 57.6; 61.4], ... % Another numerical column
                'VariableNames', {'TrackID', 'TrackType', 'TrackScore'});
            testStruct.tracks.storedFilters = {FilteringStorage()};
            testStruct.tracks.storedCategorizations = {CategorizationStorage()};
        end


        function incrementEventCount(testCase)
            testCase.eventCount = testCase.eventCount + 1;
        end


        function resetEventCount(testCase)
            testCase.eventCount = 0;
        end


        function summarizedTable = getSummarizedFromOriginal(~)
            originalTable = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ...
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ...
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ...
                'VariableNames', {'Value', 'Category', 'Score'});

            % Group by Category and compute summary statistics over timePoint
            originalTable.timePoint = [1; 2; 2; 1; 2; 1; 2; 1];

            % Get unique categories
            categoriesList = categories(originalTable.Category);
            nCat = numel(categoriesList);

            % Preallocate arrays for summary statistics
            Value_std_over_timePoint_mean = zeros(nCat,1);
            Value_mean_over_timePoint_mean = zeros(nCat,1);
            Score_mean_over_timePoint_mean = zeros(nCat,1);

            for i = 1:nCat
                cat = categoriesList{i};
                idx = originalTable.Category == cat;
                tblCat = originalTable(idx, :);

                % Group by timePoint
                [G, ~] = findgroups(tblCat.timePoint);

                % Calculate mean Value and mean Score for each timePoint in this category
                meanValuePerTimePoint = splitapply(@mean, tblCat.Value, G);
                meanScorePerTimePoint = splitapply(@mean, tblCat.Score, G);
                % Optionally, store or use these values as needed for further analysis

                % Then average these statistics over all timePoints for this category
                Value_std_over_timePoint_mean(i) = std(meanValuePerTimePoint, 'omitnan');
                Value_mean_over_timePoint_mean(i) = mean(meanValuePerTimePoint, 'omitnan');
                Score_mean_over_timePoint_mean(i) = mean(meanScorePerTimePoint, 'omitnan');
            end

            summarizedTable = table( ...
                Value_std_over_timePoint_mean, ...
                Value_mean_over_timePoint_mean, ...
                Score_mean_over_timePoint_mean, ...
                'VariableNames', {'Value_std_over_timePoint_mean', 'Value_mean_over_timePoint_mean', 'Score_mean_over_timePoint_mean'} ...
            );
            summarizedTable.Category = categorical(categoriesList);
            summarizedTable = movevars(summarizedTable, 'Category', 'before', 1);
        end
    end
end