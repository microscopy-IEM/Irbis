classdef (Abstract) testParent_AppStateManager < matlab.unittest.TestCase
    properties
        appStateManager
        mockApp
    end

    methods(TestMethodSetup)
        function setup(testCase)
            % Set up fresh instances for each test
            addpath(fullfile(pwd, '..', '..')) % Adding the parent directory to the path
            %   otherwise, it cannot access FilteringStorage etc
            testCase.mockApp = MockApp();
            testCase.appStateManager = AppStateManager(testCase.mockApp);
        end
    end

    methods(TestMethodTeardown)
        function teardown(testCase)
            delete(testCase.appStateManager);
            delete(testCase.mockApp);
        end
    end

    methods (Access = protected)
        function testStruct = createTestModelStruct(~)
            % Creates a test structure with model data
            testStruct = struct();
            testStruct.model.branch1.combinedList = table([1;2], 'VariableNames', {'Value'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};
        end

        function testStruct = createTestTracksStruct(~)
            % Creates a test structure with tracks data
            testStruct = struct();
            testStruct.tracks.combinedList = table([1;2], 'VariableNames', {'Value'});
            testStruct.tracks.storedFilters = {FilteringStorage()};
            testStruct.tracks.storedCategorizations = {CategorizationStorage()};
        end

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

        function verifyModalityState(testCase, expectedModality, expectedBranch)
            % Helper to verify modality and branch state
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), expectedModality);
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), expectedBranch);
        end
    end
end
