classdef test_FormulaColumnDefinition < matlab.unittest.TestCase
    % Unit tests for the FormulaColumnDefinition class

    methods (Test)
        function testConstructorValidInputs(testCase)
            % Test constructor with valid inputs
            columnName = "newColumn";
            formulaString = "Var1 + Var2";
            obj = FormulaColumnDefinition(columnName, formulaString);

            testCase.verifyEqual(obj.getColumnName(), columnName);
            testCase.verifyEqual(obj.getRules(), formulaString);
            testCase.verifyEqual(obj.getDefinitionType(), 'formula');
        end

        function testConstructorInvalidColumnName(testCase)
            % Test constructor with invalid column name
            formulaString = "Var1 + Var2";
            invalidColumnName = "123Invalid";

            testCase.verifyError(@() FormulaColumnDefinition(invalidColumnName, formulaString), ...
                'MATLAB:invalidVariableName');
        end

        function testgetRequiredColumnNamesWithFunctions(testCase)
            % Test getRequiredColumnNames method with functions in the formula
            formulaString = "sin(Var1) + log(Var2) - Var3";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            % Test with provided column names
            columnNames = ["Var1", "Var2", "Var3", "Var4"];
            requiredColumns = obj.getRequiredColumnNames(columnNames);
            expectedColumns = ["Var1", "Var2", "Var3"];

            testCase.verifyEqual(sort(requiredColumns), sort(expectedColumns));
        end

        function testgetRequiredColumnNamesWithNestedFunctions(testCase)
            % Test getRequiredColumnNames method with nested functions in the formula
            formulaString = "sin(log(Var1)) + exp(Var2) - sqrt(Var3)";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            % Test with subset of column names
            columnNames = ["Var1", "Var2"];
            requiredColumns = obj.getRequiredColumnNames(columnNames);
            expectedColumns = ["Var1", "Var2"];

            testCase.verifyEqual(sort(requiredColumns), sort(expectedColumns));
        end

        function testgetRequiredColumnNamesWithRepeatedVariables(testCase)
            % Test getRequiredColumnNames method with repeated variables in the formula
            formulaString = "Var1 + Var1 * Var2 - Var3 / Var1";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            % Test with all available columns
            columnNames = ["Var1", "Var2", "Var3"];
            requiredColumns = obj.getRequiredColumnNames(columnNames);
            expectedColumns = ["Var1", "Var2", "Var3"];

            testCase.verifyEqual(sort(requiredColumns), sort(expectedColumns));
        end

        function testgetRequiredColumnNamesWithNoVariables(testCase)
            % Test getRequiredColumnNames method with no variables in the formula
            formulaString = "42 + sin(pi)";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            columnNames = ["Var1", "Var2"];
            requiredColumns = obj.getRequiredColumnNames(columnNames);
            expectedColumns = string.empty();

            testCase.verifyEqual(requiredColumns, expectedColumns);
        end

        function testgetRequiredColumnNamesWithEdgeCases(testCase)
            % Test getRequiredColumnNames method with edge cases in the formula
            formulaString = "Var1 + _Var2 - Var_3 + Var4_5";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            % Test with mixed available columns
            columnNames = ["Var1", "_Var2", "OtherVar"];
            requiredColumns = obj.getRequiredColumnNames(columnNames);
            expectedColumns = ["Var1", "_Var2"];

            testCase.verifyEqual(sort(requiredColumns), sort(expectedColumns));
        end

        function testgetRequiredColumnNamesWithNoColumnNames(testCase)
            % Test getRequiredColumnNames method without providing column names
            formulaString = "Var1 + Var2";
            obj = FormulaColumnDefinition("newColumn", formulaString);

            requiredColumns = obj.getRequiredColumnNames();
            expectedColumns = ["Var1", "Var2"];

            testCase.verifyEqual(sort(requiredColumns), sort(expectedColumns));
        end

        function testGenerateColumnValidFormula(testCase)
            % Test generateColumn with valid formula
            columnName = "newColumn";
            formulaString = "Var1 + Var2";
            obj = FormulaColumnDefinition(columnName, formulaString);

            % Create input data
            inputData = table((1:5)', (6:10)', 'VariableNames', {'Var1', 'Var2'});

            % Generate column
            data = obj.generateColumn(inputData);

            % Verify output
            expectedData = (1:5)' + (6:10)';
            testCase.verifyEqual(data, expectedData);
        end

        function testGenerateColumnWithSinFunction(testCase)
            % Test generateColumn with sin() function
            columnName = "newColumn";
            formulaString = "sin(Var1)";
            obj = FormulaColumnDefinition(columnName, formulaString);

            % Create input data
            inputData = table((0:pi/4:pi)', 'VariableNames', {'Var1'});

            % Generate column
            data = obj.generateColumn(inputData);

            % Verify output
            expectedData = sin((0:pi/4:pi)');
            testCase.verifyEqual(data, expectedData, 'AbsTol', 1e-10);
        end

        function testGenerateColumnWithLogFunction(testCase)
            % Test generateColumn with log() function
            columnName = "newColumn";
            formulaString = "log(Var1)";
            obj = FormulaColumnDefinition(columnName, formulaString);

            % Create input data
            inputData = table((1:5)', 'VariableNames', {'Var1'});

            % Generate column
            data = obj.generateColumn(inputData);

            % Verify output
            expectedData = log((1:5)');
            testCase.verifyEqual(data, expectedData, 'AbsTol', 1e-10);
        end

        function testGenerateColumnWithComplexFormula(testCase)
            % Test generateColumn with a complex formula
            columnName = "newColumn";
            formulaString = "sin(Var1) + log(Var2)";
            obj = FormulaColumnDefinition(columnName, formulaString);

            % Create input data
            inputData = table((1:5)', (6:10)', 'VariableNames', {'Var1', 'Var2'});

            % Generate column
            data = obj.generateColumn(inputData);

            % Verify output
            expectedData = sin((1:5)') + log((6:10)');
            testCase.verifyEqual(data, expectedData, 'AbsTol', 1e-10);
        end

        function testGenerateColumnInvalidFormula(testCase)
            % Test generateColumn with invalid formula
            columnName = "newColumn";
            formulaString = "InvalidVar + Var2";
            obj = FormulaColumnDefinition(columnName, formulaString);

            % Create input data
            inputData = table((1:5)', (6:10)', 'VariableNames', {'Var1', 'Var2'});

            % Verify error
            testCase.verifyError(@() obj.generateColumn(inputData), 'MATLAB:InvalidFormula');
        end

        function testRenameColumn(testCase)
            % Test renaming the column
            columnName = "oldColumn";
            formulaString = "Var1 + Var2";
            obj = FormulaColumnDefinition(columnName, formulaString);

            newName = "newColumn";
            obj.renameColumn(newName);

            testCase.verifyEqual(obj.getColumnName(), newName);
        end

        function testReplaceRules(testCase)
            % Test replacing the formula rules
            columnName = "newColumn";
            formulaString = "Var1 + Var2";
            obj = FormulaColumnDefinition(columnName, formulaString);

            newRules = "Var1 * Var2";
            obj.replaceRules(newRules);

            testCase.verifyEqual(obj.getRules(), newRules);
        end
    end
end