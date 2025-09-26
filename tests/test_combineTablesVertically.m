classdef test_combineTablesVertically < matlab.unittest.TestCase
    
    methods(Test)
        
        function testSameVariables(testCase)
            T1 = table([1; 2], {'A'; 'B'}, 'VariableNames', {'Num', 'Char'});
            T2 = table([3; 4], {'C'; 'D'}, 'VariableNames', {'Num', 'Char'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 2);
            testCase.verifyEqual(result.Num, [1; 2; 3; 4]);
            testCase.verifyEqual(result.Char, {'A'; 'B'; 'C'; 'D'});
        end
        
        function testDifferentVariables(testCase)
            T1 = table([1; 2], 'VariableNames', {'A'});
            T2 = table([3; 4], 'VariableNames', {'B'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 2);
        end
        
        function testPartialOverlap(testCase)
            T1 = table([1; 2], {'A'; 'B'}, 'VariableNames', {'Num', 'Char'});
            T2 = table([3; 4], [true; false], 'VariableNames', {'Num', 'Logic'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 3);
            testCase.verifyEqual(result.Num, [1; 2; 3; 4]);
        end
        
        function testEmptyTables(testCase)
            T1 = table.empty(0, 2);
            T1.Properties.VariableNames = {'A', 'B'};
            T1.Properties.VariableTypes = {'double', 'string'};
            
            T2 = table([1; 2], ["X"; "Y"], 'VariableNames', {'A', 'B'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 2);
            testCase.verifyEqual(width(result), 2);
        end
        
        function testDifferentDataTypes(testCase)
            T1 = table([1; 2], ["A"; "B"], 'VariableNames', {'Num', 'Str'});
            T2 = table([3; 4], categorical({'B'; 'C'}), 'VariableNames', {'Num', 'Cat'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 3);
            testCase.verifyEqual(result.Num, [1; 2; 3; 4]);
        end
        
        function testMultiColumnDoubleArrays(testCase)
            % Test tables with double arrays of different column sizes
            T1 = table([1 2 3; 4 5 6], [10; 20], 'VariableNames', {'Matrix', 'Scalar'});
            T2 = table([7 8; 9 10], [30; 40], 'VariableNames', {'Matrix', 'Scalar'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 2);
            testCase.verifyEqual(result.Matrix(1,:), [1 2 3]);
            testCase.verifyEqual(result.Matrix(3,:), [7 8]);
            testCase.verifyEqual(result.Scalar, [10; 20; 30; 40]);
        end
        
        function testCellArraysWithDifferentContent(testCase)
            % Test cell arrays containing different types of data
            T1 = table({[1 2]; 'text'}, 'VariableNames', {'CellData'});
            T2 = table({struct('a', 1); [3 4 5]}, 'VariableNames', {'CellData'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 1);
            testCase.verifyEqual(result.CellData{1}, [1 2]);
            testCase.verifyEqual(result.CellData{2}, 'text');
        end
        
        function testTablesWithMixedNumericTypes(testCase)
            % Test tables with different numeric types (single, double, int32)
            T1 = table(single([1; 2]), int32([10; 20]), 'VariableNames', {'Single', 'Int32'});
            T2 = table(double([3; 4]), int16([30; 40]), 'VariableNames', {'Double', 'Int16'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 4);
            testCase.verifyEqual(sum(ismissing(result.Single)), 2);
            testCase.verifyEqual(sum(ismissing(result.Double)), 2);
        end
        
        function testTableWithDatetimeAndDuration(testCase)
            % Test tables with datetime and duration variables
            T1 = table(datetime([2023 2024], 1, 1), duration([1; 2], 0, 0), 'VariableNames', {'Date', 'Duration'});
            T2 = table(categorical({'A'; 'B'}), [10; 20], 'VariableNames', {'Category', 'Value'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 4);
            testCase.verifyClass(result.Date, 'datetime');
            testCase.verifyClass(result.Duration, 'duration');
        end
        
        function testLargeTablesPerformance(testCase)
            % Test performance with larger tables
            n = 1000;
            T1 = table(rand(n, 3), randi(100, n, 1), 'VariableNames', {'Data', 'ID'});
            T2 = table(rand(n, 2), string(repmat('test', n, 1)), 'VariableNames', {'Values', 'Text'});
            
            tic;
            result = combineTablesVertically(T1, T2);
            elapsed = toc;
            
            testCase.verifyEqual(height(result), 2*n);
            testCase.verifyEqual(width(result), 4);
            testCase.verifyLessThan(elapsed, 5); % Should complete in less than 5 seconds
        end
        
        function testBothTablesEmpty(testCase)
            % Test when both tables are empty
            T1 = table.empty(0, 2);
            T1.Properties.VariableNames = {'A', 'B'};
            T1.Properties.VariableTypes = {'double', 'string'};
            
            T2 = table.empty(0, 2);
            T2.Properties.VariableNames = {'C', 'D'};
            T2.Properties.VariableTypes = {'logical', 'categorical'};
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 0);
            testCase.verifyEqual(width(result), 4);
        end
        
        function testTablesWithIdenticalVariableNamesButDifferentOrder(testCase)
            % Test tables with same variables but different order
            T1 = table([1; 2], {'A'; 'B'}, [10; 20], 'VariableNames', {'Num', 'Char', 'Val'});
            T2 = table({'C'; 'D'}, [30; 40], [3; 4], 'VariableNames', {'Char', 'Val', 'Num'});
            
            result = combineTablesVertically(T1, T2);
            
            testCase.verifyEqual(height(result), 4);
            testCase.verifyEqual(width(result), 3);
            testCase.verifyEqual(result.Num, [1; 2; 3; 4]);
            testCase.verifyEqual(result.Char, {'A'; 'B'; 'C'; 'D'});
            testCase.verifyEqual(result.Val, [10; 20; 30; 40]);
        end
    end
end