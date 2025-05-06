classdef FormulaColumnDefinition < ColumnDefinitionInterface

    properties (Access = private)
        formulaString string
        definitionType = 'formula'
    end

    methods
        function obj = FormulaColumnDefinition(columnName, formulaString)
            % Constructor for FormulaColumnDefinition
            % Args: columnName - string of the new column name
            %        formulaString - string of the formula to be applied
            
            if ~isvarname(columnName)
                error('MATLAB:invalidVariableName', '"%s" is not a valid MATLAB variable name.', columnName);
            end
            
            obj.columnName = columnName;
            obj.formulaString = formulaString;
        end

        function definitionType = getDefinitionType(obj)
            % Returns the definition type of the column
            % Returns: string indicating the definition type
            definitionType = obj.definitionType;
        end

        function columnName = getColumnName(obj)
            columnName = obj.columnName;
        end

        function rules = getRules(obj)
            % Returns the rules for the column
            % Returns: string of the formula string
            rules = obj.formulaString;
        end

        function setDefinitionType(obj, newType)
            % Sets the definition type of the column
            % Args: newType - string indicating the new definition type
            obj.definitionType = newType;
        end
        
        function replaceRules(obj, newRules)
            % Internally edits the rules
            % Args: newRules - string of the new formula string
            obj.formulaString = newRules;
        end
               
        function renameColumn(obj, newName)
            % Rename with a new name
            % Args: newName - string of desired column name
            if ~isvarname(newName)
                error('"%s" is not a valid MATLAB variable name.', newName);
            end
            obj.columnName = newName;
        end

        % Column Operations        
        function data = generateColumn(obj, inputData)
            % Generates column data based on defined rules
            % Args: inputData - source data for column generation
            % Returns: column data array
            % Validate the new variable name

            % Get available variables
            varNames = inputData.Properties.VariableNames;
            fprintf('Applying formula: %s\n', obj.formulaString);
            fprintf('Available variables: %s\n', strjoin(varNames, ', '));

            % Build the function handle
            try
                % Create anonymous function @(Var1, Var2, ...) -> formula result
                % extract variable names from the formula string
                % Logical indexing to find variable names present in obj.formulaString
                isUsed = cellfun(@(v) contains(obj.formulaString, v), varNames);
                usedVarNames = varNames(isUsed);

                funcStr = sprintf('@(%s) %s', strjoin(usedVarNames, ','), obj.formulaString);      % TO OPTIMIZE: this is a potential security risk (if user inputs a malicious function)
                formulaFunc = str2func(funcStr);

                % Extract column data as function inputs
                inputArgs = cellfun(@(v) inputData.(v), usedVarNames, 'UniformOutput', false);
                
                % Evaluate the function
                data = formulaFunc(inputArgs{:});

                if ischar(data) || isstring(data)
                    data = categorical(data);  % Convert to categorical from text
                end

                % Ensure correct size
                if height(inputData) ~= numel(data)
                    error('Formula output has incorrect dimensions. Ensure it returns a column vector.');
                end
                
                % Assign to new variable
                fprintf('New column "%s" created successfully!\n', obj.columnName);
            catch ME
                error('MATLAB:InvalidFormula', 'Error evaluating formula "%s": %s', obj.formulaString, ME.message);
            end
        end


        % Get Required Column Names
        function requiredColumns = getRequiredColumns(obj)
            % Returns a list of column names required for formula evaluation
            % Returns: cell array of required column names

            % Use regular expressions to extract variable names from the formula string
            % Exclude function calls by ensuring they are not followed by '('
            pattern = '(?<!\.)\b[a-zA-Z_]\w*\b(?!\s*\()'; % Matches valid MATLAB variable names not preceded by '.' and not followed by '('
            tokens = regexp(char(obj.formulaString), pattern, 'match');

            % Remove duplicates to get unique variable names
            requiredColumns = unique(tokens);
        end

        
        % Validation
        function isValid = validateRulesApplicabilityOnData(obj, inputData)
        % Validates if the rules can be applied to the input data
        % Args: inputData - source data for rules validation
        % Returns: logical indicating validity
        end
    end

end