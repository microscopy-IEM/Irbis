classdef test_AppStateManager_dataLoading < testParent_AppStateManager
    methods (Test)
        function testInitialStateIsEmpty(testCase)
            testCase.verifyEmpty(testCase.appStateManager.getAvailableModalities(), ...
                'Initially, AppStateManager should report no available modalities.');
            testCase.verifyEqual(testCase.appStateManager.getActiveModality(), '', ...
                'Initially, AppStateManager should report no active modality.');
            testCase.verifyEqual(testCase.appStateManager.getActiveBranch(), '', ...
                'Initially, AppStateManager should report no active branch.');
        end

        function testStoreDataFromStructSetsModalityAndBranch(testCase)
            testStruct = testCase.createTestModelStruct();
            testCase.appStateManager.storeDataFromStruct(testStruct);
            testCase.verifyModalityState('model', 'branch1');
        end

        function testStoreDataFromStructWithModelOnly(testCase)
            testStruct = testCase.createTestModelStruct();
            testCase.appStateManager.storeDataFromStruct(testStruct);
            
            % Verify modalities and branches
            testCase.verifyEqual(testCase.appStateManager.getAvailableModalities(), {'model'});
            testCase.verifyEqual(testCase.appStateManager.getAvailableBranches('model'), {'branch1'});
            testCase.verifyModalityState('model', 'branch1');
        end

        function testStoreDataFromStructWithTracksOnly(testCase)
            testStruct = testCase.createTestTracksStruct();
            testCase.appStateManager.storeDataFromStruct(testStruct);
            
            % Verify modalities and branches
            testCase.verifyEqual(testCase.appStateManager.getAvailableModalities(), {'tracks'});
            testCase.verifyEqual(testCase.appStateManager.getAvailableBranches('tracks'), {});
            testCase.verifyModalityState('tracks', '');
        end

        function testAppendLoadedData(testCase)
            % Load initial data
            initialStruct = testCase.createTestModelStruct();
            testCase.appStateManager.storeDataFromStruct(initialStruct);
            
            % Create and append new data
            newBranchStruct = struct();
            newBranchStruct.model.branch2.combinedList = table([3;4], {'C';'D'}, 'VariableNames', {'ID', 'Label'});
            newBranchStruct.model.branch2.storedFilters = {FilteringStorage()};
            newBranchStruct.model.branch2.storedCategorizations = CategorizationStorage();
            
            % Create mock BatchLoader
            mockLoader = struct('appendLoadedData', @(existingData) testCase.mergeMockData(existingData, newBranchStruct));
            
            % Append data
            testCase.appStateManager.appendLoadedData(mockLoader);
            
            % Verify combined data
            branches = testCase.appStateManager.getAvailableBranches('model');
            testCase.verifyEqual(sort(branches), {'branch1'; 'branch2'});
        end

        function testLoadInvalidData(testCase)
            % Test with empty struct
            emptyStruct = struct();
            testCase.appStateManager.storeDataFromStruct(emptyStruct);
            testCase.verifyEmpty(testCase.appStateManager.getAvailableModalities());
            
            % Test with invalid modality structure
            invalidStruct.invalidModality.data = table();
            testCase.appStateManager.storeDataFromStruct(invalidStruct);
            testCase.verifyEmpty(testCase.appStateManager.getAvailableModalities());
        end

        function testEventEmittedWhenChangingModality(testCase)
            ev = false;
            addlistener(testCase.appStateManager, 'modalityPathChanged', @(~,~) assignin('caller', 'ev', true));
            notify(testCase.mockApp, 'modalityChangedByUser');
            testCase.verifyTrue(ev);
        end

        function testGetAvailableBranches(testCase)
            testStruct = testCase.createTestModelStruct();
            testCase.appStateManager.storeDataFromStruct(testStruct);
            branches = testCase.appStateManager.getAvailableBranches('model');
            testCase.verifyEqual(branches, {'branch1'});
        end
    end

    methods (Access = private)
        function mergedData = mergeMockData(~, existingData, newData)
            % Helper to simulate BatchLoader's appendLoadedData
            mergedData = existingData;
            if isfield(newData, 'model')
                branches = fieldnames(newData.model);
                for i = 1:length(branches)
                    mergedData.model.(branches{i}) = newData.model.(branches{i});
                end
            end
        end
    end
end
