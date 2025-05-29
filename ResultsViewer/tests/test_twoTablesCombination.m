classdef (Sealed) test_twoTablesCombination < matlab.unittest.TestCase

    properties
        appStateManager
        mockApp
        
        eventCount = 0;     % Number of times an event is emitted
    end

    methods (TestClassSetup)
        % Class setup runs only once before the first test (vs TestMethodSetup)

        function setup(testCase)

            % Add the parent Irbis file to path, in case it is not already there
            addpath(fullfile(pwd, '..', '..'));

            testCase.mockApp = MockApp();
            testCase.appStateManager = AppStateManager(testCase.mockApp);

            testCase.appStateManager.generateTopTableStateManager();
            testCase.appStateManager.storeDataFromStruct(testCase.createTestStruct());

            % Change top table type to 'Pivoted'
            % Atm, the two table setup works only if the top is Pivoted and the bottom Summarized
            testCase.appStateManager.changeTopTableType('Pivoted');
        end
    end



    methods (Test)
        function checkTopTableExistence(testCase)
            [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            testCase.verifyEqual(length(processors), 1, 'Expected one processor for top table');
            testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted');

            columnParameter = processors{1}.columnParameter;
            testCase.verifyEqual(columnParameter, 'timePoint', 'Expected column parameter to be timePoint');
        end


        function summarizedTableNotPossibleForNumericColumn(testCase)
            % Check that a bottom table cannot be created for a numeric column
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};

            testCase.verifyEqual(topTableProcessor.rowParameter, 'Value', 'Expected row parameter to be Value initially');

            bottomTableCreatedSuccessfully = testCase.appStateManager.showSummarizedAndIndicateSuccess();
            
            testCase.verifyFalse(bottomTableCreatedSuccessfully, 'Bottom table should not be created for numeric column');
        end


        function bottomTableGetsCreated(testCase)
            % the row parameter must first be categorical to be able to create a bottom table
                % decision because it is easier to get values for groups created from categorical variables
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            topTableProcessor.setRowParameter('Category');
            
            bottomTableCreatedSuccessfully = testCase.appStateManager.showSummarizedAndIndicateSuccess();
            
            testCase.verifyTrue(bottomTableCreatedSuccessfully, 'Bottom table should be created successfully');
        end


        function selectionFromTopIfBottomTableEmpty(testCase)
            [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(length(processors), 2, 'Expected two processors for top and bottom tables');
            testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted');
            testCase.verifyEqual(tableTypes{2}, 'Summarized', 'Expected bottom table type to be Summarized');

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), 'Bottom table should not have any selected cells initially');

            % Listen for even that the bottom processor emits to update the component
            tempListener = bottomTableProcessor.addlistener('tableSelectionSetProgrammatically', @(src, event) testCase.incrementEventCount());
            selection = [1, 1]; % This has to be a n x 2 array
            topTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), ...
                'Bottom table should not have any selected cells when it is empty');
        end


        function selectionFromTopReplicatesToBottom(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), 'Bottom table should not have any selected cells initially');

            % Now, I need to activate some columns in the bottom table
            colummsToActivate = {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'};
            bottomTableProcessor.setActiveColumns(colummsToActivate);
            testCase.verifyEqual(bottomTableProcessor.activeColumns, colummsToActivate, 'Bottom table should have the specified columns activated');
            testCase.verifyEqual(bottomTableProcessor.filteredTable.Properties.VariableNames, colummsToActivate, ...
                'Bottom table should have the specified columns in its filtered table');

            % Listen for the event that the top processor emits to update the bottom processor
            tempListener = topTableProcessor.addlistener('tableSelectionSyncRequired', @(src, event) testCase.incrementEventCount());
            selection = [1, 1]; % This has to be a n x 2 array
            topTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click

            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            % Only the row selection will be preserved in the bottom table, all columns will be selected - because the columns have different meaning
            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList(1), selection(1), ...
                'Bottom table should have the same selected rows as top table');

            % Calculate expected selection: for each row in selection, select all columns in the bottom table
            % TO OPTIMIZE - this code a potential candidate for a separate function
            numRows = size(selection, 1);
            numCols = numel(colummsToActivate);
            expectedSelection = zeros(numRows * numCols, 2);
            for i = 1:numRows
                expectedSelection((i-1)*numCols+1:i*numCols, :) = [repmat(selection(i,1), numCols, 1), (1:numCols)'];
            end

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, expectedSelection, ...
                'Bottom table should have all columns selected for each selected row');
        end


        function selectionFromBottomReplicatesToTop(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(topTableProcessor.selectedTableCellsList, [1, 1], 'Top table should have selection from previous test');

            % Listen for event that the bottom processor emits to update the component
            tempListener = bottomTableProcessor.addlistener('tableSelectionSyncRequired', @(src, event) testCase.incrementEventCount());
            selection = zeros(0, 2); % This has to be a n x 2 array
            bottomTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            testCase.verifyEqual(topTableProcessor.selectedTableCellsList, selection, ...
                'Top table should have the same selected cells as bottom table');
        end
        

        function rowParameterChangeFromTop(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            tempListener = topTableProcessor.addlistener('rowParameterChanged', @(src, event) testCase.incrementEventCount());

            newRowParameter = 'AnotherCategory';
            topTableProcessor.setRowParameter(newRowParameter);
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on row parameter change');
            testCase.resetEventCount();
            delete(tempListener);

            testCase.verifyEqual(bottomTableProcessor.rowParameter, newRowParameter, ...
                'Bottom table should have the same row parameter as top table');

            existingRowNames = categories(categorical({'first'; 'first'; 'second'; 'second'; 'third'; 'third'; 'first'; 'second'}));

            testCase.verifyTrue(isequal(sort(bottomTableProcessor.filteredTable.Properties.RowNames), sort(existingRowNames)), ...
                'Bottom table should have the same row names as the new row parameter');
        end


        function rowParameterChangeFromBottom(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            tempListener = bottomTableProcessor.addlistener('rowParameterChanged', @(src, event) testCase.incrementEventCount());
            
            newRowParameter = 'Category';
            bottomTableProcessor.setRowParameter(newRowParameter);
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on row parameter change');
            testCase.resetEventCount();
            delete(tempListener);

            testCase.verifyEqual(topTableProcessor.rowParameter, newRowParameter, ...
                'Top table should have the same row parameter as bottom table');

            existingRowNames = categories(categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}));

            testCase.verifyTrue(isequal(sort(topTableProcessor.pivotedTable.Properties.RowNames), sort(existingRowNames)), ...
                'Top table should have the same row names as the new row parameter');
        end


        function filterBottomTable(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            bottomTableProcessor = processors{2};

            summarizedTableBeforeFiltering = table(...
                [3.5; 5; 5], ...
                [0.6364; 3.7072; 8.4146], ...
                'VariableNames', {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'}, ...
                'RowNames', {'A'; 'B'; 'C'});

            % Added rounding to comparison, because I am not sure how much the summarization gets rounded
            testCase.verifyEqual(round(bottomTableProcessor.filteredTable), round(summarizedTableBeforeFiltering), ...
                'Bottom table should have the expected summarized data before filtering');

            % Check that it matches the visualzed table
            bottomTableComponentHandle = testCase.appStateManager.bottomTableStateManagerHandle.tableComponentHandle;
            shownTable = bottomTableComponentHandle.getTableData();

            testCase.verifyEqual(round(shownTable), round(bottomTableProcessor.filteredTable), ...
                'Bottom table component should show the summarized data before filtering');

            % Get filtering storage and apply a range filter on 'Value_mean_over_timePoint_mean'
            summarizedDataStoreHandle = testCase.appStateManager.bottomTableStateManagerHandle.getActiveDataStore();
            rowParameter = 'Category';
            summarizedFilteringStorage = summarizedDataStoreHandle.getSummarizedFilteringStorage(rowParameter);
            summarizedFilteringStorage.addRangeFilter('Value_mean_over_timePoint_mean', [4, 10]);

            summarizedTableAfterFiltering = table(...
                [5; 5], ...
                [3.7072; 8.4146], ...
                'VariableNames', {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'}, ...
                'RowNames', {'B'; 'C'});

            testCase.verifyEqual(round(bottomTableProcessor.filteredTable), round(summarizedTableAfterFiltering), ...
                'Bottom table should have the expected summarized data after filtering');

            % get table from the component and check that it mathches the filtered table
            shownTable = bottomTableComponentHandle.getTableData();

            testCase.verifyEqual(round(shownTable), round(bottomTableProcessor.filteredTable), ...
                'Bottom table component should show the filtered summarized data');
        end


        function switchBranchAndTestUpdates(testCase)
            % switch branch to branch2
                % the app uses changeBranchForUserSelected to switch branches
                % the problem is that it then asks the app for the branch - I will need to mock that
            testCase.mockApp.setBranch('branch2');
            testCase.appStateManager.changeBranchForUserSelected();     % this would normally be a listener callback

            [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            testCase.verifyEqual(length(processors), 2, 'Expected two processors for top and bottom tables after branch switch');

            testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted after branch switch');
            testCase.verifyEqual(tableTypes{2}, 'Summarized', 'Expected bottom table type to be Summarized after branch switch');

            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            % There is a default filter applied on Value and Category columns
            dataStoreHandle = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = dataStoreHandle.getFilteringStorage();

            existingFilterNames = filteringStorage.returnGroupingNames();
            testCase.verifyEqual(existingFilterNames, {'Value', 'Category'}, 'Expected a filter on Value column for branch2');
            filterRange = filteringStorage.getConditions('Value');
            testCase.verifyEqual(filterRange, [10, 12], 'Expected filter on Value column to be [10, 12] for branch2');

            expectedTopTableData = table(...
                [NaN; 12], ...
                [NaN; 10], ...
                [11; NaN], ...
                'VariableNames', {'1', '2', '3'}, ...
                'RowNames', {'A'; 'C'});

            testCase.verifyEqual(round(topTableProcessor.pivotedTable, 4), round(expectedTopTableData, 4), ...
                'Top table should have the expected data after branch switch');

            expectedBottomTableData = table(...
                [11; 11], ...
                [0; 2.0506], ...
                'VariableNames', {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'}, ...
                'RowNames', {'A'; 'C'});

            testCase.verifyEqual(round(bottomTableProcessor.filteredTable, 4), round(expectedBottomTableData, 4), ...
                'Bottom table should have the expected summarized data after branch switch');
        end


        function confirmAbsenceOfSummarizedTableFilters(testCase)
            % Check that there are no filters in the summarized filtering storage for the currently selected branch2
            summarizedDataStoreHandle = testCase.appStateManager.bottomTableStateManagerHandle.getActiveDataStore();
            rowParameter = 'Category';
            summarizedFilteringStorage = summarizedDataStoreHandle.getSummarizedFilteringStorage(rowParameter);
            existingFilterNames = summarizedFilteringStorage.returnGroupingNames();
            testCase.verifyEmpty(existingFilterNames, 'Summarized filtering storage should not have any filters for branch2');
        end


        function deactivateFilters(testCase)
            % Turn off the categorical filter on 'Category' column and numeric filter on 'Value' in branch2
            dataStoreHandle = testCase.appStateManager.topTableStateManagerHandle.getActiveDataStore();
            filteringStorage = dataStoreHandle.getFilteringStorage();

            % Check that the filter exists before turning it off
            existingFilterNames = filteringStorage.returnGroupingNames();
            testCase.verifyTrue(ismember('Category', existingFilterNames), 'Expected a filter on Category column for branch2');
            testCase.verifyTrue(ismember('Value', existingFilterNames), 'Expected a filter on Value column for branch2');

            tempListener = filteringStorage.addlistener('filtersChanged', @(src, event) testCase.incrementEventCount());

            % both of these filters exclude the row with B - we need to deactivate both
            filteringStorage.inactivateFilter('Category');
            filteringStorage.inactivateFilter('Value'); % Also turn off the Value filter

            testCase.verifyEqual(testCase.eventCount, 2, 'Expected one event to be emitted on filter change per filter');
            testCase.resetEventCount();
            delete(tempListener);

            % The tables should now have 3 rows instead of 2
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            % Check that the top table has the expected data after branch switch
            expectedTopTableData = table(...
                [NaN; 9; 12], ...
                [NaN; NaN; 10], ...
                [11; NaN; NaN], ...
                'VariableNames', {'1', '2', '3'}, ...
                'RowNames', {'A'; 'B'; 'C'});

            testCase.verifyEqual(round(topTableProcessor.pivotedTable, 4), round(expectedTopTableData, 4), ...
                'Top table should have the expected data after branch switch');

            expectedBottomTableData = table(...
                [11; 9; 11], ...
                [0; 0; 2.0506], ...
                'VariableNames', {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'}, ...
                'RowNames', {'A'; 'B'; 'C'});

            testCase.verifyEqual(round(bottomTableProcessor.filteredTable, 4), round(expectedBottomTableData, 4), ...
                'Bottom table should have the expected summarized data after branch switch');
        end


        % TO FIX: this one does not work, because column names are not the same and they do not get updated in correct order
        % function modalityGetsSwitched(testCase)
        %     % Switch modality to 'tracks'
        %     testCase.mockApp.setModality('tracks');
        %     testCase.appStateManager.changeModalityForUserSelected();

        %     [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
        %     testCase.verifyEqual(length(processors), 1, 'Expected one processor for top table after modality switch');
        %     testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted after modality switch');

        %     topTableProcessor = processors{1};

        %     disp(topTableProcessor.pivotedTable)
        %     % Check that the top table has the expected data
        %     % expectedTopTableData = table(...
        %     %     [101; 102; 103; 104; 105; 106; 107; 108], ...
        %     %     categorical({'X'; 'Y'; 'X'; 'Z'; 'Y'; 'Z'; 'X'; 'Y'}), ...
        %     %     [55.2; 63.1; 58.7; 60.5; 62.3; 59.8; 57.6; 61.4], ...
        %     %     'VariableNames', {'TrackID', 'TrackType', 'TrackScore'});

        %     % testCase.verifyEqual(round(topTableProcessor.pivotedTable, 4), round(expectedTopTableData, 4), ...
        %     %     'Top table should have the expected data after modality switch');
        % end
    end
    

    methods (Access = private)

        function testStruct = createTestStruct(~)
            testStruct = struct();

            % Default branch of model
            testStruct.model.branch1.combinedList = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ... % Numerical column
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ... % Categorical column
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ... % Another numerical column
                categorical([1; 1; 2; 2; 3; 3; 1; 2]), ... % New categorical column with values 1, 2, or 3
                categorical({'first'; 'second'; 'third'; 'second'; 'first'; 'third'; 'third'; 'first'}), ... % New categorical column with time points
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint', 'AnotherCategory'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};

            % Second branch of model
            testStruct.model.branch2.combinedList = table( ...
                [9; 10; 11; 12], ... % Numerical column
                categorical({'B'; 'C'; 'A'; 'C'}), ... % Categorical column
                [12.1; 19.7; 23.5; 16.8], ... % Another numerical column
                categorical([1; 2; 3; 1]), ... % timePoint categorical column with values 1, 2, 3, 1
                categorical({'first'; 'second'; 'third'; 'second'}), ... % Another categorical column
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint', 'AnotherCategory'});
            % Create FilteringStorage and add example filters
            branch2FilteringStorage = FilteringStorage();
            % Add a range filter on 'Value' column (e.g., keep values between 10 and 12)
            branch2FilteringStorage.addRangeFilter('Value', [10, 12]);
            % Add a categorical filter on 'Category' column (e.g., keep only 'A' and 'C')
            branch2FilteringStorage.addCategoricalFilter('Category', {'A', 'C'});
            testStruct.model.branch2.storedFilters = {branch2FilteringStorage};
            testStruct.model.branch2.storedCategorizations = {CategorizationStorage()};

            % Tracks data
            testStruct.tracks.combinedList = table( ...
                [101; 102; 103; 104; 105; 106; 107; 108], ... % Numerical column
                categorical({'X'; 'Y'; 'X'; 'Z'; 'Y'; 'Z'; 'X'; 'Y'}), ... % Categorical column
                [55.2; 63.1; 58.7; 60.5; 62.3; 59.8; 57.6; 61.4], ... % Another numerical column
                'VariableNames', {'TrackID', 'TrackType', 'TrackScore'});
            testStruct.tracks.storedFilters = {FilteringStorage()};
            testStruct.tracks.storedCategorizations = {CategorizationStorage()};
        end


        function incrementEventCount(testCase)
            % Method used in listeners to detect when an event is emitted
            testCase.eventCount = testCase.eventCount + 1;
        end


        function resetEventCount(testCase)
            % Method to reset the event count
            testCase.eventCount = 0;
        end
    end
end