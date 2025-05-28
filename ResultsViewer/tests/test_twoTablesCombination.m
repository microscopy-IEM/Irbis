classdef (Sealed) test_twoTablesCombination < matlab.unittest.TestCase

    properties
        appStateManager
        mockApp
        
        eventCount = 0;     % Number of times an event is emitted
    end

    methods (TestClassSetup)
        function setup(testCase)
            % Setup code that runs before each test
            addpath(fullfile(pwd, '..', '..')); % Adjust path as necessary

            testCase.mockApp = MockApp();
            testCase.appStateManager = AppStateManager(testCase.mockApp);

            testCase.appStateManager.generateTopTableStateManager();
            testCase.appStateManager.storeDataFromStruct(testCase.createTestStruct());

            % Change top table type to 'Pivoted'
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

        function createBottomTable(testCase)
            % the row parameter must first be categorical to be able to create a bottom table
                % decision because it is easier to get values for groups created from categorical variables
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            topTableProcessor.setRowParameter('Category'); % Set row parameter to categorical column
            
            isShown = testCase.appStateManager.showSummarizedAndIndicateSuccess();
            
            testCase.verifyTrue(isShown, 'Bottom table should be created successfully');
        end

        function clickFromTopReplicationIfBottomEmpty(testCase)
            [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), 'Bottom table should not have any selected cells initially');

            testCase.verifyEqual(length(processors), 2, 'Expected two processors for top and bottom tables');
            testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted');
            testCase.verifyEqual(tableTypes{2}, 'Summarized', 'Expected bottom table type to be Summarized');

            % Register listener for top table selection change
            tempListener = bottomTableProcessor.addlistener('tableSelectionSetProgrammatically', @(src, event) testCase.incrementEventCount());
            % bottomTableProcessor.addlistener('tableSelectionSetProgrammatically', @(src, event) testCase.incrementEventCount());
            selection = [1, 1]; % This has to be a n x 2 array
            topTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            % Check if bottom table is updated correctly
            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), ...
                'Bottom table should not have any selected cells when it is empty');
        end

        function clickFromTopReplicatesToBottom(testCase)
            [processors, tableTypes] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, zeros(0,2), 'Bottom table should not have any selected cells initially');

            testCase.verifyEqual(length(processors), 2, 'Expected two processors for top and bottom tables');
            testCase.verifyEqual(tableTypes{1}, 'Pivoted', 'Expected top table type to be Pivoted');
            testCase.verifyEqual(tableTypes{2}, 'Summarized', 'Expected bottom table type to be Summarized');

            % Now, I need to activate some columns in the bottom table
            colummsToActivate = {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'};
            bottomTableProcessor.setActiveColumns(colummsToActivate);
            testCase.verifyEqual(bottomTableProcessor.activeColumns, colummsToActivate, 'Bottom table should have the specified columns activated');
            testCase.verifyEqual(bottomTableProcessor.filteredTable.Properties.VariableNames, colummsToActivate, ...
                'Bottom table should have the specified columns in its filtered table');
            disp(bottomTableProcessor.filteredTable.Properties.VariableNames);

            % Register listener for top table selection change
            tempListener = topTableProcessor.addlistener('tableSelectionSyncRequired', @(src, event) testCase.incrementEventCount());
            % bottomTableProcessor.addlistener('tableSelectionSetProgrammatically', @(src, event) testCase.incrementEventCount());
            selection = [1, 1]; % This has to be a n x 2 array
            topTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click

            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            % Only the row selection will be kept, all columns will be selected
            % Check if bottom table is updated correctly
            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList(1), selection(1), ...
                'Bottom table should have the same selected cells as top table');
            % Build expected selection: for each row in selection, select all columns in the bottom table
            numRows = size(selection, 1);
            numCols = numel(colummsToActivate);
            expectedSelection = zeros(numRows * numCols, 2);
            for i = 1:numRows
                expectedSelection((i-1)*numCols+1:i*numCols, :) = [repmat(selection(i,1), numCols, 1), (1:numCols)'];
            end
            % disp('Expected selection for bottom table:');
            % disp(expectedSelection)
            % disp('Actual selection for bottom table:');
            % disp(bottomTableProcessor.selectedTableCellsList);
            testCase.verifyEqual(bottomTableProcessor.selectedTableCellsList, expectedSelection, ...
                'Bottom table should have all columns selected for each selected row');
        end

        function clickFromBottomReplicatesToTop(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            testCase.verifyEqual(topTableProcessor.selectedTableCellsList, [1, 1], 'Top table should have selection from previous test');

            % Register listener for bottom table selection change
            tempListener = bottomTableProcessor.addlistener('tableSelectionSyncRequired', @(src, event) testCase.incrementEventCount());
            selection = zeros(0, 2); % This has to be a n x 2 array
            bottomTableProcessor.storeSelectedTableCellsList(selection);   % this is the same thing that is called from within the component upon click
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on selection change');
            testCase.resetEventCount();
            delete(tempListener);

            % Check if top table is updated correctly
            testCase.verifyEqual(topTableProcessor.selectedTableCellsList, selection, ...
                'Top table should have the same selected cells as bottom table');
        end

        function rowParameterChangeFromTop(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            % Register listener for row parameter change
            tempListener = topTableProcessor.addlistener('rowParameterChanged', @(src, event) testCase.incrementEventCount());
            
            % Change row parameter in top table
            newRowParameter = 'AnotherCategory';
            topTableProcessor.setRowParameter(newRowParameter);
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on row parameter change');
            testCase.resetEventCount();
            delete(tempListener);

            % Check if bottom table has the same row parameter
            testCase.verifyEqual(bottomTableProcessor.rowParameter, newRowParameter, ...
                'Bottom table should have the same row parameter as top table');

            % disp(bottomTableProcessor.filteredTable)
            % disp(bottomTableProcessor.filteredTable.Properties.VariableNames)

            existingRowNames = categories(categorical({'first'; 'first'; 'second'; 'second'; 'third'; 'third'; 'first'; 'second'}));

            testCase.verifyTrue(isequal(sort(bottomTableProcessor.filteredTable.Properties.RowNames), sort(existingRowNames)), ...
                'Bottom table should not have any columns selected after changing row parameter');
        end


        function rowParameterChangeFromBottom(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            topTableProcessor = processors{1};
            bottomTableProcessor = processors{2};

            % Register listener for row parameter change
            tempListener = bottomTableProcessor.addlistener('rowParameterChanged', @(src, event) testCase.incrementEventCount());
            
            % Change row parameter in bottom table
            newRowParameter = 'Category';
            bottomTableProcessor.setRowParameter(newRowParameter);
            
            testCase.verifyEqual(testCase.eventCount, 1, 'Expected one event to be emitted on row parameter change');
            testCase.resetEventCount();
            delete(tempListener);

            % Check if top table has the same row parameter
            testCase.verifyEqual(topTableProcessor.rowParameter, newRowParameter, ...
                'Top table should have the same row parameter as bottom table');

            % disp(topTableProcessor.pivotedTable)
            % disp(topTableProcessor.pivotedTable.Properties.VariableNames)

            existingRowNames = categories(categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}));

            testCase.verifyTrue(isequal(sort(topTableProcessor.pivotedTable.Properties.RowNames), sort(existingRowNames)), ...
                'Top table should not have any columns selected after changing row parameter');
        end


        function filterBottomTable(testCase)
            [processors, ~] = testCase.appStateManager.getTableProcessorHandles();
            bottomTableProcessor = processors{2};

            % disp(bottomTableProcessor.filteredTable)
            summarizedTableBeforeFiltering = table(...
                [3.5; 5; 5], ...
                [0.6364; 3.7072; 8.4146], ...
                'VariableNames', {'Value_mean_over_timePoint_mean', 'Score_std_over_timePoint_mean'}, ...
                'RowNames', {'A'; 'B'; 'C'});
            testCase.verifyEqual(round(bottomTableProcessor.filteredTable), round(summarizedTableBeforeFiltering), ...
                'Bottom table should have the expected summarized data before filtering');
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

            % disp(bottomTableProcessor.filteredTable)
        end
    end
    

    methods (Access = private)
        function testStruct = createTestStruct(~)
            testStruct = struct();
            testStruct.model.branch1.combinedList = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ... % Numerical column
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ... % Categorical column
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ... % Another numerical column
                categorical([1; 1; 2; 2; 3; 3; 1; 2]), ... % New categorical column with values 1, 2, or 3
                categorical({'first'; 'second'; 'third'; 'second'; 'first'; 'third'; 'third'; 'first'}), ... % New categorical column with time points
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint', 'AnotherCategory'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};

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
    end
end