classdef test_pivotTable < matlab.unittest.TestCase
    methods (Test)
        function testBasicPivotWithoutGrouping(testCase)
            % Create sample data
            data = table([1; 2; 3; 4; 5; 6; 7; 8; 9; 10], ...
                         [1; 1; 2; 2; 3; 3; 4; 4; 5; 5], ...
                         [10; 20; 30; 40; 50; 60; 70; 80; 90; 100], ...
                         'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table([15; 35; 55; 75; 95], 'RowNames', {'1'; '2'; '3'; '4'; '5'}, ...
                             'VariableNames', {'1'; '2'; '3'; '4'; '5'});
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar');
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithRowGrouping(testCase)
            % Create sample data
            data = table([1; 2; 3; 4; 5; 6; 7; 8; 9; 10], ...
                         [1; 1; 2; 2; 3; 3; 4; 4; 5; 5], ...
                         [10; 20; 30; 40; 50; 60; 70; 80; 90; 100], ...
                         'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table([15; 35; 55; 75; 95], 'RowNames', {'1'; '3'; '5'; '7'; '9'}, ...
                             'VariableNames', {'1'; '2'; '3'; '4'; '5'});
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar', [1, 10, 2], []);
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithColumnGrouping(testCase)
            % Create sample data
            data = table([1; 2; 3; 4; 5; 6; 7; 8; 9; 10], ...
                         [1; 1; 2; 2; 3; 3; 4; 4; 5; 5], ...
                         [10; 20; 30; 40; 50; 60; 70; 80; 90; 100], ...
                         'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table([15; 35; 55; 75; 95], 'RowNames', {'1'; '2'; '3'; '4'; '5'}, ...
                             'VariableNames', {'1'; '3'; '5'});
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar', [], [1, 5, 2]);
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithBothRowAndColumnGrouping(testCase)
            % Create sample data
            data = table([1; 2; 3; 4; 5; 6; 7; 8; 9; 10], ...
                         [1; 1; 2; 2; 3; 3; 4; 4; 5; 5], ...
                         [10; 20; 30; 40; 50; 60; 70; 80; 90; 100], ...
                         'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table([15; 35; 55; 75; 95], 'RowNames', {'1'; '3'; '5'; '7'; '9'}, ...
                             'VariableNames', {'1'; '3'; '5'});
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar', [1, 10, 2], [1, 5, 2]);
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithNonNumericData(testCase)
            % Create sample data
            data2 = table({'A'; 'A'; 'B'; 'B'; 'C'; 'C'; 'D'; 'D'; 'E'; 'E'}, ...
                          {'X'; 'Y'; 'X'; 'Y'; 'X'; 'Y'; 'X'; 'Y'; 'X'; 'Y'}, ...
                          [10; 20; 30; 40; 50; 60; 70; 80; 90; 100], ...
                          'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table([10; 30; 50; 70; 90], 'RowNames', {'A'; 'B'; 'C'; 'D'; 'E'}, ...
                             'VariableNames', {'X'; 'Y'});
            % Test
            actual = pivotTable(data2, 'RowVar', 'ColVar', 'DataVar');
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithEmptyData(testCase)
            % Create empty data
            data = table([], [], [], 'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table();
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar');
            testCase.verifyEqual(actual, expected);
        end

        function testPivotWithSingleRowAndColumn(testCase)
            % Create sample data
            data = table(1, 1, 10, 'VariableNames', {'RowVar', 'ColVar', 'DataVar'});
            % Expected result
            expected = table(10, 'RowNames', {'1'}, 'VariableNames', {'1'});
            % Test
            actual = pivotTable(data, 'RowVar', 'ColVar', 'DataVar');
            testCase.verifyEqual(actual, expected);
        end
    end
end