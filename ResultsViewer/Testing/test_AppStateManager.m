classdef test_AppStateManager < matlab.mock.TestCase

    properties
        AppMock         % Mock object for the application handle dependency
        AppStateManager % Instance of the class under test
    end

    methods (TestMethodSetup)
        function setup(testCase)
            % Create a mock app handle with necessary methods and events
            % This simulates the application that AppStateManager interacts with.
            import matlab.mock.TestCase

            [testCase.AppMock, behavior] = testCase.createMock(...
                'AddedMethods', {'getActiveModality', 'getActiveBranch'}, ...
                'AddedEvents', {'modalityChanged', 'branchChanged'}, ...
                'Superclass', ?handle ... % Use handle superclass for events
            );

            % Import necessary mock actions
            import matlab.mock.actions.AssignOutputs

            % Define default behavior for the mock app's methods using AssignOutputs.
            % This simulates the state the app might report initially or when queried.
            when(withAnyInputs(behavior.getActiveModality), AssignOutputs('model'));
            when(withAnyInputs(behavior.getActiveBranch), AssignOutputs('branch1'));

            % Create the AppStateManager instance, injecting the mock app handle.
            testCase.AppStateManager = AppStateManager(testCase.AppMock);
        end
    end

    methods (Test)
        function testInitialStateIsEmpty(testCase)
            % Verify that a newly created AppStateManager instance manages no data,
            % regardless of the state reported by the (mock) application.
            testCase.verifyEmpty(testCase.AppStateManager.getAvailableModalities(), ...
                'Initially, AppStateManager should report no available modalities.');
            testCase.verifyEqual(testCase.AppStateManager.getActiveModality(), '', ...
                'Initially, AppStateManager should report no active modality.');
            % Assuming AppStateManager tracks its own active branch, independent of the app's initial branch
             testCase.verifyEqual(testCase.AppStateManager.getActiveBranch(), '', ...
                'Initially, AppStateManager should report no active branch.');
        end

        function testStoreDataFromStructSetsModalityAndBranch(testCase)
            % Prepare a simple test structure with data for one modality and branch.
            % Assumes FilteringStorage and CategorizationStorage are valid classes/constructors.
            testStruct.model.branch1.combinedList = table([1;2], {'A';'B'}, 'VariableNames', {'ID', 'Label'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = CategorizationStorage();

            % Store
            testCase.AppStateManager.storeDataFromStruct(testStruct);

            % Test expected state
            testCase.verifyEqual(testCase.AppStateManager.getActiveModality(), 'model');
            testCase.verifyEqual(testCase.AppStateManager.getActiveBranch(), 'branch1');
        end

        function testEventEmittedWhenChangingModality(testCase)
            % Prepare listener
            ev = false;
            addlistener(testCase.AppStateManager, 'modalityPathChanged', @(~,~) assignin('caller', 'ev', true));

            % Trigger event via mock app
            notify(testCase.AppMock, 'modalityChanged');

            % Check if event was triggered
            testCase.verifyTrue(ev);
        end

        function testGetAvailableBranches(testCase)
            % Load test data
            testStruct.model.branch1.combinedList = table([1;2], {'A';'B'}, 'VariableNames', {'ID', 'Label'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = CategorizationStorage();

            testCase.AppStateManager.storeDataFromStruct(testStruct);

            branches = testCase.AppStateManager.getAvailableBranches('model');
            testCase.verifyEqual(branches, {'branch1'});
        end
    end
end
