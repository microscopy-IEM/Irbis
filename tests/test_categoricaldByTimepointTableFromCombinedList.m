classdef test_categoricaldByTimepointTableFromCombinedList < matlab.unittest.TestCase
    methods (Test)
        function testValidInput(testCase)
            % Create a sample combinedList table
            combinedList = table(categorical({'T1'; 'T1'; 'T2'; 'T2'; 'T3'; 'T3'}), ...
                categorical({'A'; 'B'; 'C'; 'D'; 'E'; 'F'}), ...
                [10; 20; 30; 40; 50; 60], ...
                'VariableNames', {'timePoint', 'groupId', 'attribute'});

            % Define the categorical parameter and attribute
            categoricalParameter = 'groupId';
            attribute = 'attribute';

            % Call the function
            resultTable = categoricaldByTimepointTableFromCombinedList(combinedList, categoricalParameter, attribute);

            % Verify the result

            disp(resultTable)
            expectedData = [10 30 50; 20 40 60];
            
            testCase.verifyEqual(resultTable.Variables, expectedData);
        end

        function testEmptyInput(testCase)
            % Test with an empty combinedList
            emptyList = table(categorical([]), [], [], 'VariableNames', {'timePoint', 'groupId', 'attribute'});
            categoricalParameter = 'timePoint';
            attribute = 'attribute';
            resultTableEmpty = categoricaldByTimepointTableFromCombinedList(emptyList, categoricalParameter, attribute);

            % Verify the result
            testCase.verifyEmpty(resultTableEmpty);
        end

        function testMissingColumns(testCase)
            % Test with missing required columns
            missingColumnsList = table(categorical({'T1'; 'T2'}), [1; 2], NaN(2, 1), 'VariableNames', {'timePoint', 'groupId', 'attribute'});
            categoricalParameter = 'timePoint';
            attribute = 'attribute';
            resultTableMissingColumns = categoricaldByTimepointTableFromCombinedList(missingColumnsList, categoricalParameter, attribute);

            % Verify the result
            testCase.verifyEmpty(resultTableMissingColumns);
        end

        % function testGroupIdZero(testCase)
        %     % Test with groupId as 0
        %     groupIdZeroList = table(categorical({'T1'; 'T2'}), [0; 2], [10; 20], 'VariableNames', {'timePoint', 'groupId', 'attribute'});
        %     categoricalParameter = 'timePoint';
        %     attribute = 'attribute';
        %     resultTableGroupIdZero = categoricaldByTimepointTableFromCombinedList(groupIdZeroList, categoricalParameter, attribute);

        %     % Verify the result
        %     expectedData = [NaN 20];
        %     testCase.verifyEqual(resultTableGroupIdZero.Variables, expectedData);
        % end

        function testNonNumericAttribute(testCase)
            % Test with non-numeric attribute
            combinedList = table(...
                categorical({'T1'; 'T1'; 'T2'; 'T2'; 'T3'; 'T3'}), ...
                [1; 2; 1; 2; 1; 2], ...
                categorical({'A'; 'B'; 'C'; 'D'; 'E'; 'F'}), ...
                'VariableNames', {'timePoint', 'groupId', 'attribute'});

            categoricalParameter = 'timePoint';
            attribute = 'attribute';
            resultTable = categoricaldByTimepointTableFromCombinedList(combinedList, categoricalParameter, attribute);

            % Verify the result
            expectedData = categorical({'A', 'C', 'E'; 'B', 'D', 'F'});
            testCase.verifyEqual(resultTable.Variables, expectedData);
        end

        function testSingleGroupId(testCase)
            % Test with a single groupId
            combinedList = table(...
                categorical({'T1'; 'T2'; 'T3'}), ...
                [1; 1; 1], ...
                [10; 20; 30], ...
                'VariableNames', {'timePoint', 'groupId', 'attribute'});

            categoricalParameter = 'timePoint';
            attribute = 'attribute';
            resultTable = categoricaldByTimepointTableFromCombinedList(combinedList, categoricalParameter, attribute);

            % Verify the result
            expectedData = [10 20 30];
            testCase.verifyEqual(resultTable.Variables, expectedData);
        end
    end
end