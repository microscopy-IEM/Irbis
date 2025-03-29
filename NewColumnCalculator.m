classdef (Sealed) NewColumnCalculator

    methods (Static, Access = public)

        function [columnData, columnName] = processUserInputAndReturnNewColumn(existingTable)
            % Create a dialog window for formula input
            prompt = {'New column name:', 'Formula:'};
            dlgTitle = 'Define new column';
            numLines = 1;
            defaultAns = {'', ''};
            input = inputdlg(prompt, dlgTitle, numLines, defaultAns);

            % Check if the user pressed cancel
            if isempty(input)
                columnData = []; 
                columnName = '';
                return;
            end

            % Extract the user input
            newVarName = input{1};
            formulaStr = input{2};

            % Apply the formula
            columnData = NewColumnCalculator.applyFormula(existingTable, newVarName, formulaStr);
            columnName = newVarName;  % Return the new variable name
        end

    end

    methods (Static, Access = private)
        
        function newColumn = applyFormula(existingTable, newVarName, formulaStr)
            % APPLYFORMULA applies a safe user-defined formula to the table.
            % Prevents misuse of eval and restricts operations.

            % Validate the new variable name
            if ~isvarname(newVarName)
                error('"%s" is not a valid MATLAB variable name.', newVarName);
            end
            
            % Get available variables
            varNames = existingTable.Properties.VariableNames;
            fprintf('Applying formula: %s\n', formulaStr);
            fprintf('Available variables: %s\n', strjoin(varNames, ', '));

            % Build the function handle
            try
                % Create anonymous function @(Var1, Var2, ...) -> formula result
                % extract variable names from the formula string
                % Logical indexing to find variable names present in formulaStr
                isUsed = cellfun(@(v) contains(formulaStr, v), varNames);
                usedVarNames = varNames(isUsed);

                funcStr = sprintf('@(%s) %s', strjoin(usedVarNames, ','), formulaStr);      % TO OPTIMIZE: this is a potential security risk (if user inputs a malicious function)
                formulaFunc = str2func(funcStr);

                % Extract column data as function inputs
                inputArgs = cellfun(@(v) existingTable.(v), usedVarNames, 'UniformOutput', false);
                
                % Evaluate the function
                newColumn = formulaFunc(inputArgs{:});

                % Ensure correct size
                if height(existingTable) ~= numel(newColumn)
                    error('Formula output has incorrect dimensions. Ensure it returns a column vector.');
                end
                
                % Assign to new variable
                fprintf('New column "%s" created successfully!\n', newVarName);
            catch ME
                error('Error evaluating formula "%s": %s', formulaStr, ME.message);
            end
        end
    end
end
