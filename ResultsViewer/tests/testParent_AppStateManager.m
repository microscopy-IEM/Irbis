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

        function verifyModalityState(testCase, expectedModality, expectedBranch)
            % Helper to verify modality and branch state
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), expectedModality);
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), expectedBranch);
        end
    end
end
