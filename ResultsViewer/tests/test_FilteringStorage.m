classdef (Sealed) test_FilteringStorage < matlab.unittest.TestCase

    properties
        filteringStorage
        tableStoreHandle
        dataStoreHandle
        tableProcessorHandle

        logicalFlag = false; % Flag to check if event was emitted
        eventCount = 0; % Counter for the number of times the event was emitted
    end

    methods (TestMethodSetup)
        function setup(testCase)
            % Set up fresh instances for each test
            addpath(fullfile(pwd, '..', '..')) % Adding the parent directory to the path
            %   otherwise, it cannot access FilteringStorage etc
            testCase.filteringStorage = FilteringStorage();

            tableStoreConstruction = TableStore();
            tableData = table(...
                categorical({'A'; 'B'; 'C'; 'A'}), ...
                {'Row1'; 'Row2'; 'Row3'; 'Row4'}, ...
                [1.1; 2.2; 3.3; 4.4], ...
                'VariableNames', {'Category', 'Description', 'Value'});
            tableStoreConstruction.setTableData(tableData);
            testCase.tableStoreHandle = tableStoreConstruction;

            testCase.dataStoreHandle = DataStore(testCase.tableStoreHandle, testCase.filteringStorage);
            % I need to setup the controllers

            testCase.tableProcessorHandle = FullTableProcessor();
            testCase.tableProcessorHandle.setHandles(MockTableStateManager, testCase.dataStoreHandle);

        end
    end

    methods (Test)
        function addingRangeFilter(testCase)
            % Test adding a range filter
            testCase.resetFlag(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.setFlagTrue());
            testCase.addTeardown(@() delete(listener));
            testCase.filteringStorage.addRangeFilter('Value', [1.5, 3.5]);
            testCase.verifyEqual(testCase.filteringStorage.getConditions('Value'), [1.5, 3.5], 'Range filter not set correctly');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, [2.2; 3.3], 'Filtered table not updated correctly after adding range filter');
            testCase.verifyTrue(testCase.logicalFlag, 'Event not emitted after adding range filter');
        end

        function addingCategoricalFilter(testCase)
            % Test adding a categorical filter
            testCase.resetFlag(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.setFlagTrue());
            testCase.addTeardown(@() delete(listener));
            testCase.filteringStorage.addCategoricalFilter('Category', {'A', 'B'});
            testCase.verifyEqual(testCase.filteringStorage.getConditions('Category'), categorical({'A', 'B'}), 'Categorical filter not set correctly');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Category, categorical({'A'; 'B'; 'A'}), 'Filtered table not updated correctly after adding categorical filter');
            testCase.verifyTrue(testCase.logicalFlag, 'Event not emitted after adding categorical filter');
        end

        function addTwoFilters(testCase)
            % Test adding two filters
            testCase.resetFlag(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.setFlagTrue());
            testCase.addTeardown(@() delete(listener));

            testCase.resetEventCount(); % Reset the event count before adding the filter
            secondListener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.incrementEventCount());
            testCase.addTeardown(@() delete(secondListener));

            testCase.filteringStorage.addRangeFilter('Value', [1.5, 3.5]);
            testCase.filteringStorage.addCategoricalFilter('Category', {'A', 'B'});
            testCase.verifyEqual(testCase.filteringStorage.getConditions('Value'), [1.5, 3.5], 'Range filter not set correctly');
            testCase.verifyEqual(testCase.filteringStorage.getConditions('Category'), categorical({'A', 'B'}), 'Categorical filter not set correctly');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, 2.2, 'Filtered table not updated correctly after adding range filter');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Category, categorical({'B'}), 'Filtered table not updated correctly after adding categorical filter');
            testCase.verifyTrue(testCase.logicalFlag, 'Event not emitted after adding two filters');
            testCase.verifyEqual(testCase.eventCount, 2, 'Event count not incremented correctly after adding two filters');
        end

        function removeFilter(testCase)
            % Test removing a filter
            testCase.resetEventCount(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.incrementEventCount());
            testCase.addTeardown(@() delete(listener));
            testCase.filteringStorage.addRangeFilter('Value', [1.5, 3.5]);
            testCase.filteringStorage.deleteGrouping('Value');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, [1.1; 2.2; 3.3; 4.4], 'Filtered table not updated correctly after removing filter');
            testCase.verifyEqual(testCase.eventCount, 2, 'Event not emitted after removing filter');
        end

        function changeFilterActivation(testCase)
            % Test changing filter activation
            testCase.resetEventCount(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.incrementEventCount());
            testCase.addTeardown(@() delete(listener));
            testCase.filteringStorage.addRangeFilter('Value', [1.5, 3.5]);
            testCase.filteringStorage.inactivateFilter('Value');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, [1.1; 2.2; 3.3; 4.4], 'Filtered table not updated correctly after deactivating filter');
            testCase.verifyFalse(testCase.filteringStorage.getActivationStatus('Value'), 'Filter activation status not updated correctly after deactivating filter');
            testCase.filteringStorage.activateFilter('Value');
            testCase.verifyTrue(testCase.filteringStorage.getActivationStatus('Value'), 'Filter activation status not updated correctly after reactivating filter');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, [2.2; 3.3], 'Filtered table not updated correctly after reactivating filter');
            testCase.verifyEqual(testCase.eventCount, 3, 'Event count not incremented correctly after changing filter activation');
        end

        function updateFilter(testCase)
            % Test updating a filter
            testCase.resetEventCount(); % Reset the flag before adding the filter
            listener = addlistener(testCase.tableProcessorHandle, 'tableForDisplayChanged', @(~, ~) testCase.incrementEventCount());
            testCase.addTeardown(@() delete(listener));
            testCase.filteringStorage.addRangeFilter('Value', [1.5, 3.5]);
            testCase.filteringStorage.updateFilter('Value', [2.0, 3.0]);
            testCase.verifyEqual(testCase.filteringStorage.getConditions('Value'), [2.0, 3.0], 'Filter not updated correctly');
            testCase.verifyEqual(testCase.tableProcessorHandle.filteredTable.Value, 2.2, 'Filtered table not updated correctly after updating filter');
            testCase.verifyEqual(testCase.eventCount, 2, 'Event count not incremented correctly after updating filter');
        end

    end

    methods (Access = private)
        function setFlagTrue(testCase)
            testCase.logicalFlag = true;
        end 

        function resetFlag(testCase)
            testCase.logicalFlag = false;
        end

        function incrementEventCount(testCase)
            testCase.eventCount = testCase.eventCount + 1;
        end

        function resetEventCount(testCase)
            testCase.eventCount = 0;
        end
    end
end