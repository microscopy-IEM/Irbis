classdef ManualColumnDefinition < ColumnDefinitionInterface

    properties (Access = private)
        groupNames
        definitionType = 'manual'
        defaultGroupName = ''
    end

    methods
        function obj = ManualColumnDefinition(columnName, groupNames, defaultGroupName)
            % Constructor for ManualColumnDefinition
            % Args: columnName - string of the new column name
            %        formulaString - string of the formula to be applied
            
            if ~isvarname(columnName)
                error('"%s" is not a valid MATLAB variable name.', columnName);
            end
            
            obj.columnName = columnName;
            obj.groupNames = groupNames;
            if nargin < 3
                defaultGroupName = '';
            end
            obj.defaultGroupName = ManualColumnDefinition.sanitizeDefaultGroupName(defaultGroupName, groupNames);
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

        function defaultGroupName = getDefaultGroupName(obj)
            % Returns the default group name for new entries
            defaultGroupName = obj.defaultGroupName;
        end
        
        function replaceRules(obj, newRules, newDefaultGroupName)
        % Internally edits the rules

            obj.groupNames = newRules;
            if nargin < 3
                newDefaultGroupName = obj.defaultGroupName;
            end
            obj.defaultGroupName = ManualColumnDefinition.sanitizeDefaultGroupName(newDefaultGroupName, newRules);
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
            % Fill by selected default category; empty default means undefined values.
            defaultGroup = ManualColumnDefinition.sanitizeDefaultGroupName(obj.defaultGroupName, obj.groupNames);

            if isempty(defaultGroup)
                data = categorical(strings(height(inputData), 1), obj.groupNames);
            else
                data = categorical(repmat(string(defaultGroup), height(inputData), 1), obj.groupNames);
            end
        end


        function columnNames = getRequiredColumnNames(~, existingColumnNames)
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

    methods (Static, Access = private)
        function sanitizedDefault = sanitizeDefaultGroupName(defaultGroupName, groupNames)
            if isempty(defaultGroupName)
                sanitizedDefault = '';
                return;
            end

            groupNames = string(groupNames);
            defaultGroupName = string(defaultGroupName);
            if numel(defaultGroupName) > 1
                defaultGroupName = defaultGroupName(1);
            end

            if any(strcmp(groupNames, defaultGroupName))
                sanitizedDefault = char(defaultGroupName);
            else
                sanitizedDefault = '';
            end
        end
    end

end