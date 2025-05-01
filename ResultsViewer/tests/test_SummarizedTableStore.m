classdef test_SummarizedTableStore < matlab.mock.TestCase

    properties
        mockTableStore
        behavior
        store
    end

    methods (TestMethodSetup)
        function setupMocks(testCase)
            [testCase.mockTableStore, testCase.behavior] = testCase.createMock( ...
                'Superclass', ?MockHandle, ...
                'AddedMethods', ["getColumnNames", "getColumnTypes", ...
                                 "getColumnTypesForNames", "getTableSubsetByName"], ...
                'AddedEvents', "tableDataChanged");

            % Default mock returns
            testCase.assignOutputsWhen(withExactInputs(testCase.behavior.getColumnNames), ...
                {'group', 'col1', 'col2', 'timePoint'});

            testCase.assignOutputsWhen(withExactInputs(testCase.behavior.getColumnTypes), ...
                {'categorical', 'numeric', 'numeric', 'numeric'});

            testCase.assignOutputsWhen(withAnyInputs(testCase.behavior.getColumnTypesForNames), ...
                {'numeric'});

            testCase.assignOutputsWhen(withAnyInputs(testCase.behavior.getTableSubsetByName), ...
                table(rand(5,1), 'VariableNames', {'timePoint'}));

        end
    end

    methods (Test)
        function testConstructorInitializesProperties(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.verifyEqual(testCase.store.groupingName, 'group');
            testCase.verifyNotEmpty(testCase.store.parentColumnNames);
            testCase.verifyNotEmpty(testCase.store.parentColumnTypes);
            testCase.verifyGreaterThan(numel(testCase.store.columnDefinitionHandles), 0);
        end

        function testAddColumnDefinitionIncreasesCount(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            initialCount = numel(testCase.store.columnDefinitionHandles);

            def = createMockColumnDefinition(testCase, 'myCol', 'param');
            testCase.store.addColumnDefinition(def);

            testCase.verifyEqual(numel(testCase.store.columnDefinitionHandles), initialCount + 1);
        end

        function testGetNumberOfColumnsOfType(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.verifyGreaterThan(testCase.store.getNumberOfColumnsOfType("StatisticalColumnDefinition"), 0);
        end

        function testGetStatisticalColumnNames(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            names = testCase.store.getStatisticalColumnNames();
            testCase.verifyTrue(iscell(names));
            testCase.verifyGreaterThan(numel(names), 0);
        end

        function testGetParentNames(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.verifyEqual(testCase.store.getParentNames(), testCase.store.parentColumnNames);
        end

        function testGetColumnNamesIncludesUserDefined(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.store.userDefinedColumnNames = {'extra'};
            names = testCase.store.getColumnNames();
            testCase.verifyTrue(ismember('extra', names));
        end

        function testGetStatisticalColumnNamesForParent(testCase)
            def = createMockColumnDefinition(testCase, 'testCol', 'col1');
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.store.columnDefinitionHandles = {def};
            result = testCase.store.getStatisticalColumnNamesForParent('col1');
            testCase.verifyEqual(result, {'testCol'});
        end

        function testGetTableSubsetByNameGeneratesMissingColumns(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            % Clear the cache
            testCase.store.cachedTableData = table();

            % Add mock column
            def = createMockColumnDefinition(testCase, 'generatedCol', 'col1');
            testCase.assignOutputsWhen(withAnyInputs(def.getRequiredColumnNames), {'col1'});
            testCase.assignOutputsWhen(withAnyInputs(def.generateColumn), rand(5,1));
            testCase.store.columnDefinitionHandles = {def};

            subset = testCase.store.getTableSubsetByName({'generatedCol'});
            testCase.verifyEqual(subset.Properties.VariableNames, {'generatedCol'});
        end

        function testUpdateTableDataModifiesState(testCase)
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.store.parentColumnNames = {'col1'}; % simulate stale list

            testCase.assignOutputsWhen(withExactInputs(testCase.behavior.getColumnNames), ...
                {'group', 'col2', 'timePoint'});
            testCase.assignOutputsWhen(withExactInputs(testCase.behavior.getColumnTypesForNames), ...
                {'numeric'});

            % Add listener for event checking
            eventFired = false;
            addlistener(testCase.store, 'tableDataChanged', @(~,~) assignin('base', 'eventFired', true));

            testCase.store.updateTableData();

            testCase.verifyTrue(any(strcmp(testCase.store.parentColumnNames, 'col2')));
            eventFired = evalin('base', 'eventFired');
            testCase.verifyTrue(eventFired);
        end

        function testRemoveParentColumnAndItsChildren(testCase)
            def = createMockColumnDefinition(testCase, 'childCol', 'col1');
            testCase.store = SummarizedTableStore('group', testCase.mockTableStore, []);
            testCase.store.parentColumnNames = {'col1'};
            testCase.store.parentColumnTypes = {'numeric'};
            testCase.store.columnDefinitionHandles = {def};

            testCase.store.removeParentColumnAndItsChildren('col1');

            testCase.verifyEmpty(testCase.store.columnDefinitionHandles);
            testCase.verifyEmpty(testCase.store.parentColumnNames);
        end
    end
end

function mockDef = createMockColumnDefinition(testCase, colName, paramName)
    [mockDef, defBehavior] = testCase.createMock( ...
        'AddedMethods', ["getColumnName", "getDataParameter", "getRequiredColumnNames", "generateColumn"]);

    testCase.assignOutputsWhen(withAnyInputs(defBehavior.getColumnName), colName);
    testCase.assignOutputsWhen(withAnyInputs(defBehavior.getDataParameter), paramName);
end
