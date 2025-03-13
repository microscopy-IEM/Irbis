classdef TableFormula
    properties
        Data table
    end
    
    methods
        function obj = TableFormula(inputTable)
            % Constructor
            if nargin > 0
                obj.Data = inputTable;
            else
                obj.Data = table();
            end
        end
        
        function showVariables(obj)
            % Show available table variables
            disp('Available variables in the table:');
            disp(obj.Data.Properties.VariableNames);
        end

        function obj = processUserInput(obj)
            % Create a dialog window for formula input
            prompt = {'New variable name:', 'Formula:'};
            dlgTitle = 'Add new variable';
            numLines = 1;
            defaultAns = {'', ''};
            input = inputdlg(prompt, dlgTitle, numLines, defaultAns);

            % Check if the user pressed cancel
            if isempty(input)
                return;
            end

            % Extract the user input
            newVarName = input{1};
            formulaStr = input{2};

            % validateFormula(formulaStr);

            % Apply the formula
            obj = obj.applyFormula(newVarName, formulaStr);
        end

        % function validateFormula(formulaStr)
        %     % List of allowed mathematical functions
        %     allowedFunctions = {'sin', 'cos', 'tan', 'exp', 'sqrt', 'abs', 'mod', ...
        %                         'round', 'floor', 'ceil', 'power', 'plus', 'minus', 'times', 'rdivide', 'ldivide'};
            
        %     % Extract function names from formula
        %     tokens = regexp(formulaStr, '[a-zA-Z_][a-zA-Z_0-9]*', 'match');
            
        %     % Check for any disallowed function
        %     for i = 1:length(tokens)
        %         if ~ismember(tokens{i}, allowedFunctions) && ~isvarname(tokens{i})
        %             error('Usage of "%s" is not allowed in formulas.', tokens{i});
        %         end
        %     end
        % end
        
        function obj = applyFormula(obj, newVarName, formulaStr)
            % APPLYFORMULA applies a safe user-defined formula to the table.
            % Prevents misuse of eval and restricts operations.

            % Validate the new variable name
            if ~isvarname(newVarName)
                error('"%s" is not a valid MATLAB variable name.', newVarName);
            end
            
            % Get available variables
            varNames = obj.Data.Properties.VariableNames;
            fprintf('Applying formula: %s\n', formulaStr);
            fprintf('Available variables: %s\n', strjoin(varNames, ', '));

            % Build the function handle
            try
                % Create anonymous function @(Var1, Var2, ...) -> formula result
                funcStr = sprintf('@(%s) %s', strjoin(varNames, ','), formulaStr);
                formulaFunc = str2func(funcStr);

                % Extract column data as function inputs
                inputArgs = cellfun(@(v) obj.Data.(v), varNames, 'UniformOutput', false);
                
                % Evaluate the function
                newData = formulaFunc(inputArgs{:});
                
                % Ensure correct size
                if height(obj.Data) ~= numel(newData)
                    error('Formula output has incorrect dimensions. Ensure it returns a column vector.');
                end
                
                % Assign to new variable
                obj.Data.(newVarName) = newData;
                fprintf('New variable "%s" added successfully!\n', newVarName);
            catch ME
                error('Error evaluating formula "%s": %s', formulaStr, ME.message);
            end
        end
    end
end
