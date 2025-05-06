classdef ManualColumnDefinition < ColumnDefinitionInterface

    properties (Access = private)
        groupNames
        definitionType = 'manual'
    end

    methods
        function obj = ManualColumnDefinition(columnName, groupNames)
            % Constructor for ManualColumnDefinition
            % Args: columnName - string of the new column name
            %        formulaString - string of the formula to be applied
            
            if ~isvarname(columnName)
                error('"%s" is not a valid MATLAB variable name.', columnName);
            end
            
            obj.columnName = columnName;
            obj.groupNames = groupNames;
        end

        function definitionType = getDefinitionType(obj)
            % Returns the definition type of the column
            % Returns: string indicating the definition type
            definitionType = obj.definitionType;
        end

        function columnName = getColumnName(obj)
            columnName = obj.columnName;
        end

        function groupNames = getGroupNames(obj)
            % Returns the group names for the column
            % Returns: string array of group names
            groupNames = obj.groupNames;
        end
        
        function replaceRules(obj, newRules)
        % Internally edits the rules

            obj.groupNames = newRules;
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
            % Create an empty categorical column with specified categories
            data = categorical(strings(height(inputData), 1), obj.groupNames);
        end


        function columnNames = getRequiredColumns(~, existingColumnNames)
            if isempty(existingColumnNames)
                columnNames = string.empty;
            else
                columnNames = existingColumnNames{1};
                % manualColumnDefinition does not need any columns, but it will get the length of the table from the first column
            end
        end
        
        % Validation
        function isValid = validateRulesApplicabilityOnData(obj, inputData)
        % Validates if the rules can be applied to the input data
        % Args: inputData - source data for rules validation
        % Returns: logical indicating validity
        end
    end

end