classdef AppStateManagerTest < matlab.unittest.TestCase
    properties
        appStateManager
        mockApp
    end
    
    methods (TestMethodSetup)
        function setup(testCase)
            % Create mock app
            testCase.mockApp = mockApp();
            % Create AppStateManager instance
            testCase.appStateManager = AppStateManager(testCase.mockApp);
        end
    end
    
    methods (Test)
        function testStoreDataFromStruct_Model(testCase)
            % Create test data structure for model
            testData = struct();
            testData.model.branch1.combinedList = table([1;2], 'VariableNames', {'Value'});
            testData.model.branch1.storedFilters = FilteringStorage();
            testData.model.branch1.storedCategorizations = CategorizationStorage();
            
            % Store data
            testCase.appStateManager.storeDataFromStruct(testData);
            
            % Verify modalities and branches
            actModalities = testCase.appStateManager.getAvailableModalities();
            testCase.verifyEqual(actModalities, {'model'});
            
            actBranches = testCase.appStateManager.getAvailableBranches('model');
            testCase.verifyEqual(actBranches, {'branch1'});
            
            % Verify active modality and branch
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), 'model');
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), 'branch1');
        end
        
        function testStoreDataFromStruct_Tracks(testCase)
            % Create test data structure for tracks
            testData = struct();
            testData.tracks.combinedList = table([1;2], 'VariableNames', {'Value'});
            testData.tracks.storedFilters = FilteringStorage();
            testData.tracks.storedCategorizations = CategorizationStorage();
            
            % Store data
            testCase.appStateManager.storeDataFromStruct(testData);
            
            % Verify modalities
            actModalities = testCase.appStateManager.getAvailableModalities();
            testCase.verifyEqual(actModalities, {'tracks'});
            
            % Verify active modality
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), 'tracks');
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), '');
        end
        
        function testStoreDataFromStruct_Combined(testCase)
            % Create test data structure with both model and tracks
            testData = struct();
            testData.model.branch1.combinedList = table([1;2], 'VariableNames', {'Value'});
            testData.model.branch1.storedFilters = FilteringStorage();
            testData.model.branch1.storedCategorizations = CategorizationStorage();
            
            testData.tracks.combinedList = table([3;4], 'VariableNames', {'Value'});
            testData.tracks.storedFilters = FilteringStorage();
            testData.tracks.storedCategorizations = CategorizationStorage();
            
            % Store data
            testCase.appStateManager.storeDataFromStruct(testData);
            
            % Verify modalities
            actModalities = sort(testCase.appStateManager.getAvailableModalities());
            testCase.verifyEqual(actModalities, {'model'; 'tracks'});
            
            % Verify model is set as initial modality
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), 'model');
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), 'branch1');
        end
    end
end

