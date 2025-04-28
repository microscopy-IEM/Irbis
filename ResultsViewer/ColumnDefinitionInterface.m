classdef ColumnDefinitionInterface < handle
    % Interface for creating and managing derived data columns
    % Provides standardized methods for column creation, editing, and validation
    properties (SetAccess = protected, GetAccess = protected)
        columnName
    end

    methods (Abstract)
        % Configuration
        replaceRules(obj, newRules)
        % Opens a dialog to edit existing creation parameters
        % Internally edits the rules
               
        renameColumn(obj, newName)
        % Rename with a new name
        % Args: newName - string of desired column name

        % Column Operations        
        data = generateColumn(obj, inputData)
        % Generates column data based on defined rules
        % Args: inputData - source data for column generation
        % Returns: column data array
        
        % Validation
        isValid = validateRulesApplicabilityOnData(obj, inputData)
        % Validates if the rules can be applied to the input data
        % Args: inputData - source data for rules validation
        % Returns: logical indicating validity
    end
end