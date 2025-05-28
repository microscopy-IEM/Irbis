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

        function clickFromTopReplicatesToBottom(testCase)
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
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint'});
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
    end
end