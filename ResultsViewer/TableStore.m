classdef (Sealed) TableStore < handle
    %DataStore Table data storage
    % it is handle because I need to dynamically update the data stored in the object

    properties (Access = private)
        tableData = table();
        userDefinedColumns = {}; % cell array of custom column names (e.g. derived data columns)
        editableColumns = {};  % cell array of editable column names (e.g. derived data columns)
        userColumnDefinitions = {};

        doNormalizationByFirst = false  % whether to normalize the values in the pivot table by the first value in each row (e.g. to show relative changes compared to the first time point)
        % TO OPTIMIZE - this might be replaced for something more complex, but I did not figure out where would be better to keep this information

        pivotedTranformationOn = false % whether we want to tranform pivoted table (for example divide by the first column)
        pivotedTransformationName = '' % name of the transformation applied to the pivoted table
        pivotedTransform = [] % handle for the transformation applied to the pivoted table - struct of two function handles: dataFcn and nameFcn
        pivotedTransformParameter = [] % parameter for the transformation applied to the pivoted table - for example, reference column index or time point
    end

    events
        tableDataChanged
        userColumnDefinitionChanged    % event with event data passed
    end

    methods (Access = public)
        function obj = TableStore()
        end


        %% Set or add table data
            function setTableData(obj, newTableData)
                % set the table data and notify the listeners
                obj.tableData = newTableData;
                notify(obj, 'tableDataChanged');
            end


            function addTableData(obj, newTableData)
                % add the table data and notify the listeners
                obj.tableData = [obj.tableData; newTableData];
                notify(obj, 'tableDataChanged');
            end


            function addColumn(obj, columnName, columnData)
                % add a new column to the table data
                if ~ismember(columnName, obj.tableData.Properties.VariableNames)
                    obj.tableData.(columnName) = columnData;
                    notify(obj, 'tableDataChanged');
                else
                    error('Column %s already exists in the table.', columnName);
                end
            end


            function addExistingUserColumnDefinitions(obj, userColumnDefinitions, columnsToRecalculate, columnsToFreeze)
                % disp('Adding existing user column definitions to the table data...')
                % add existing user-defined columns to the table data
                % columnsToRecalculate - cell array of column names to recalculate (regenerate data)
                % columnsToFreeze - cell array of column names to freeze (remove from user-defined, keep data only)
                for i = 1:numel(userColumnDefinitions)
                    columnName = char(userColumnDefinitions{i}.getColumnName()); % <--- force char
            
                    if ~ismember(columnName, obj.userDefinedColumns) && ~ismember(columnName, columnsToFreeze)
                        obj.userDefinedColumns{end+1} = columnName;
                        obj.userColumnDefinitions{end+1} = userColumnDefinitions{i};
                        if isa(userColumnDefinitions{i}, 'ManualColumnDefinition')
                            obj.editableColumns{end+1} = columnName;
                        end
                    elseif ismember(columnName, obj.userDefinedColumns) && ismember(columnName, columnsToFreeze)
                        % Remove from user-defined columns as it's now frozen (only data are left, definition is thrown away)
                        idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                        obj.userDefinedColumns(idx) = [];
                        obj.userColumnDefinitions(idx) = [];

                        % If it's also editable, remove from editable columns
                        if ismember(columnName, obj.editableColumns)
                            editIdx = find(strcmp(obj.editableColumns, columnName), 1);
                            obj.editableColumns(editIdx) = [];
                        end
                    else
                        % If the column is to be frozen but is not yet in the list, that is ok, do nothing
                        % If the column is not to be frozen and already exists, just leave it there
                        continue;
                    end
            
                    % Reapply the column definition if the name is in columnsToRecalculate
                    if ismember(columnName, columnsToRecalculate)
                        columnData = userColumnDefinitions{i}.generateColumn(obj.tableData);
                        obj.tableData.(columnName) = columnData;
                    end
                end
                notify(obj, 'tableDataChanged');
            end


            %% Get table data or its subset
            function tableData = getTableData(obj)
                % get the table data
                tableData = obj.tableData;
            end


            % function subset = getTableSubsetByType(obj, columnTypes)
            %     varTypes = varfun(@class, obj.tableData, 'OutputFormat', 'cell');
            %     subset = obj.tableData(:, ismember(varTypes, columnTypes));
            % end


            function subset = getTableSubsetByName(obj, columnNames)
                % disp('getTableSubsetByName')
                % disp(class(columnNames))
                % disp(columnNames)
                subset = obj.tableData(:, columnNames);
            end


            function data = getColumnData(obj, columnName)
                % get the data of a specific column
                % differerce from getTableSubsetByName is that this one returns a vector, not a table
                if ismember(columnName, obj.tableData.Properties.VariableNames)
                    data = obj.tableData.(columnName);
                else
                    error('Column %s does not exist in the table.', columnName);
                end
            end



            %% Validate existence of columns
            function [isValid, invalidColumnNames] = validateColumnsExist(obj, columnNames)
                % validate that the specified column names exist in the table
                isValid = all(ismember(columnNames, obj.tableData.Properties.VariableNames));
                invalidColumnNames = columnNames(~ismember(columnNames, obj.tableData.Properties.VariableNames));
            end



            %% Get column names
            function columnNames = getColumnNames(obj)
                if isempty(obj.tableData)
                    columnNames = {};
                else
                    columnNames = obj.tableData.Properties.VariableNames;
                end
            end


           % function columnNames = getColumnNamesOfClass(obj, requestedClasses)
            %     if isempty(obj.tableData)
            %         columnNames = {};
            %     else
            %         varTypes = varfun(@class, obj.tableData, 'OutputFormat', 'cell');
            %         columnNames = obj.tableData.Properties.VariableNames(ismember(varTypes, requestedClasses));
            %     end
            % end


            function columnNames = getColumnNamesByCondition(obj, typeConditions)
                if isempty(obj.tableData)
                    columnNames = {};
                else
                    % Convert conditions to cell array if not already
                    if ~iscell(typeConditions)
                        typeConditions = {typeConditions};
                    end
                    
                    % Convert each condition to function handle if needed
                    typeFcns = cellfun(@(c) TableStore.convertToFunctionHandle(c), typeConditions, 'UniformOutput', false);
                    
                    % Apply each type check function to each column
                    isMatchingType = false(1, width(obj.tableData));
                    for i = 1:width(obj.tableData)
                        for j = 1:length(typeFcns)
                            if typeFcns{j}(obj.tableData{:,i})
                                isMatchingType(i) = true;
                                break;  % Exit inner loop if any condition is met
                            end
                        end
                    end
                    
                    columnNames = obj.tableData.Properties.VariableNames(isMatchingType);
                end
            end


            function columnNames = getPredefinedColumnNamesByCondition(obj, typeCondition)
                columnNames = obj.getColumnNamesByCondition(typeCondition);
                columnNames = setdiff(columnNames, obj.userDefinedColumns);  % exclude custom columns from default columns
                columnNames = setdiff(columnNames, obj.editableColumns);  % exclude editable columns from default columns
            end


            function columnNames = getUserDefinedColumnNames(obj)
                if isempty(obj.userDefinedColumns)
                    columnNames = {};
                else
                    columnNames = obj.userDefinedColumns;
                end
            end


            function columnNames = getEditableColumnNames(obj)
                if isempty(obj.editableColumns)
                    columnNames = {};
                else
                    columnNames = obj.editableColumns;
                end
            end


            %% Get column types
            function columnTypes = getColumnTypes(obj)
                % column types to check for: cell, numeric, categorical, string, char, logical or other

                columnTypes = repmat({'other'}, 1, width(obj.tableData));

                if ~isempty(obj.tableData)
                    for i = 1:width(obj.tableData)
                        col = obj.tableData{:,i};
                        if iscell(col)
                            columnTypes{i} = 'cell';
                        elseif isnumeric(col)
                            columnTypes{i} = 'numeric';
                        elseif iscategorical(col)
                            columnTypes{i} = 'categorical';
                        elseif isstring(col)
                            columnTypes{i} = 'string';
                        elseif ischar(col)
                            columnTypes{i} = 'char';
                        elseif islogical(col)
                            columnTypes{i} = 'logical';
                        end
                    end
                end
            end


            function columnTypes = getColumnTypesForNames(obj, columnNames)
                % Get the types of specified columns in the table
                % If columnNames is not provided, get types for all columns

                if nargin < 2 || isempty(columnNames)
                    columnNames = obj.tableData.Properties.VariableNames;
                end

                % Ensure columnNames exist in the table
                if ~all(ismember(columnNames, obj.tableData.Properties.VariableNames))
                    error('One or more specified column names do not exist in the table.');
                end

                columnTypes = repmat({'other'}, 1, numel(columnNames));

                if ~isempty(obj.tableData)
                    for i = 1:numel(columnNames)
                        col = obj.tableData.(columnNames{i});
                        if iscell(col)
                            columnTypes{i} = 'cell';
                        elseif isnumeric(col)
                            columnTypes{i} = 'numeric';
                        elseif iscategorical(col)
                            columnTypes{i} = 'categorical';
                        elseif isstring(col)
                            columnTypes{i} = 'string';
                        elseif ischar(col)
                            columnTypes{i} = 'char';
                        elseif islogical(col)
                            columnTypes{i} = 'logical';
                        end
                    end
                end
            end


            function columnTypes = getClassOfColumn(obj, columnNames)
                % get the types of the columns in the table
                % Ensure columnNames exist in the table
                if ~all(ismember(columnNames, obj.tableData.Properties.VariableNames))
                    error('One or more specified column names do not exist in the table.');
                end
                if isempty(obj.tableData)
                    columnTypes = {};
                else
                    columnTypes = varfun(@class, obj.tableData(:, columnNames), 'OutputFormat', 'cell');
                end
            end


            %% Edit user-defined columns
            function addUserDefinedColumn(obj, columnName, columnData, userDefinitionHandle)
                % add a user-defined column to the table data
                if ~ismember(columnName, obj.userDefinedColumns)
                    % columnName
                    % class(columnName)
                    obj.userDefinedColumns{end+1} = char(columnName);
                    obj.tableData.(columnName) = columnData;  
                    obj.userColumnDefinitions{end+1} = userDefinitionHandle; % store the user definition object
                    % obj.columnDefinitionStoreHandle.addUserDefinedColumn(columnName, userDefinitionHandle);
                    notify(obj, 'tableDataChanged');
                    obj.notifyUserColumnDefinitionsChange('add', columnName);   % notification for the main app
                else
                    error('Column %s already exists in the table.', columnName);
                end
            end


            function updateUserDefinedColumn(obj, columnName, newColumnData, userDefinitionHandle)
                % update the user-defined column in the table data
                if ismember(columnName, obj.userDefinedColumns)
                    obj.tableData.(columnName) = newColumnData;
                    idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                    obj.userColumnDefinitions{idx} = userDefinitionHandle;
                    notify(obj, 'tableDataChanged');
                    obj.notifyUserColumnDefinitionsChange('update', columnName);   % notification for the main app
                else
                    error('Column %s does not exist in the table.', columnName);
                end
            end


            function userColumnDefinition = getUserColumnDefinition(obj, columnName)
                % get the user-defined column definition object
                if ismember(columnName, obj.userDefinedColumns)
                    idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                    userColumnDefinition = obj.userColumnDefinitions{idx};
                else
                    error('Column %s does not exist in the table.', columnName);
                end
            end


            function numDefinitionsOfType = getNumDefinitionsOfType(obj, definitionType)
                % get the number of user-defined columns of a specific type
                numDefinitionsOfType = 0;
                for i = 1:numel(obj.userColumnDefinitions)
                    if isequal(obj.userColumnDefinitions{i}.getDefinitionType(), definitionType)
                        numDefinitionsOfType = numDefinitionsOfType + 1;
                    end
                end
            end


            %% Edit columns in general
            function removeColumn(obj, columnName)
                % remove the column from the table data
                if ismember(columnName, obj.tableData.Properties.VariableNames)
                    obj.tableData(:, columnName) = [];
                    % remove it also from user-defined, if applicable
                    if ismember(columnName, obj.userDefinedColumns)
                        idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                        obj.userDefinedColumns(idx) = [];
                        obj.userColumnDefinitions(idx) = [];
                        obj.notifyUserColumnDefinitionsChange('remove', columnName);   % notification for the main app
                    end
                    % remove it also from editable, if applicable
                    if ismember(columnName, obj.editableColumns)
                        idx = find(strcmp(obj.editableColumns, columnName), 1);
                        obj.editableColumns(idx) = [];
                    end
                    notify(obj, 'tableDataChanged');
                else
                    error('Column %s does not exist in the table.', columnName);
                end
            end


            function removeColumns(obj, columnNames)    % added to move notification to the end
                % Remove multiple columns from the table data
                if ~iscell(columnNames)
                    columnNames = {columnNames};
                end

                for i = 1:numel(columnNames)
                    columnName = columnNames{i};
                    if ismember(columnName, obj.tableData.Properties.VariableNames)
                        obj.tableData(:, columnName) = [];
                        % Remove it also from user-defined, if applicable
                        if ismember(columnName, obj.userDefinedColumns)
                            idx = find(strcmp(obj.userDefinedColumns, columnName), 1);
                            obj.userDefinedColumns(idx) = [];
                            obj.userColumnDefinitions(idx) = [];
                            obj.notifyUserColumnDefinitionsChange('remove', columnName);   % notification for the main app
                        end
                        % Remove it also from editable, if applicable
                        if ismember(columnName, obj.editableColumns)
                            idx = find(strcmp(obj.editableColumns, columnName), 1);
                            obj.editableColumns(idx) = [];
                        end
                    else
                        % This can happen for throwaway columns - do not do anything
                    end
                end
                notify(obj, 'tableDataChanged');
            end


            function renameColumn(obj, oldName, newName)
                % rename the column in the table data
                % Check if new name is a valid MATLAB variable name
                if ~isvarname(newName)
                    error('New column name "%s" is not a valid MATLAB variable name', newName);
                end

                % Check if new name already exists
                if ismember(newName, obj.tableData.Properties.VariableNames)
                    error('Column name "%s" already exists in the table', newName);
                end
                if ismember(oldName, obj.tableData.Properties.VariableNames)
                    obj.tableData.Properties.VariableNames{strcmp(obj.tableData.Properties.VariableNames, oldName)} = newName;

                    % I also need to rename it in the user-defined columns, if applicable
                    if ismember(oldName, obj.userDefinedColumns)
                        idx = find(strcmp(obj.userDefinedColumns, oldName), 1);
                        obj.userDefinedColumns{idx} = newName;
                        obj.userColumnDefinitions{idx}.renameColumn(newName); % update the user definition object
                        % TO OPTIMIZE - this might become deprecated if I switch columnDefinition to a value object
                        obj.notifyUserColumnDefinitionsChange('rename', newName, oldName);   % notification for the main app
                    end
                    notify(obj, 'tableDataChanged');
                else
                    error('Column %s does not exist in the table.', oldName);
                end
            end


            %% Deal with column editability
            function makeColumnEditable(obj, columnName)
                % make the column editable in the table data
                if ismember(columnName, obj.tableData.Properties.VariableNames) && ~ismember(columnName, obj.editableColumns)
                    % disp('Adding editable column')
                    obj.editableColumns{end+1} = columnName;
                    notify(obj, 'tableDataChanged');
                else
                    % disp('Investigating:')
                    % disp(ismember(columnName, obj.tableData.Properties.VariableNames))
                    % disp(ismember(columnName, obj.editableColumns))
                end
            end


            function columnEditability = getEditabilityOfColumns(obj, columnNames)
                % Returns a boolean array
                columnEditability = ismember(columnNames, obj.editableColumns);
            end


            function editManualColumnValue(obj, columnName, rowName, newValue)
                % Edit the value of a manual column
                if ismember(columnName, obj.editableColumns) && ismember(columnName, obj.tableData.Properties.VariableNames)
                    if ismember(rowName, obj.tableData.Properties.RowNames)
                        obj.tableData{rowName, columnName} = newValue;
                    else
                        error('Row %s does not exist in the table.', rowName);
                    end
                else
                    error('Column %s does not exist or is not editable.', columnName);
                end
            end


            %% Edit/get normalization status
            function setNormalizationStatus(obj, doNormalize)
                obj.doNormalizationByFirst = doNormalize;
                notify(obj, 'tableDataChanged');  % Notify that the data has changed to trigger any necessary updates in the views
            end



            function doNormalize = getNormalizationStatus(obj)
                doNormalize = obj.doNormalizationByFirst;
            end



            %% Edit/get pivoted transformation status
            function setPivotedTransformationStatus(obj, doTransform, transformationName, parameterValue)
                obj.pivotedTranformationOn = doTransform;
                obj.pivotedTransformationName = transformationName;
                obj.pivotedTransformParameter = parameterValue;
                obj.pivotedTransform = TableTransformationMapper.getTransformation(transformationName, parameterValue);
                notify(obj, 'tableDataChanged');  % Notify that the data has changed to trigger any necessary updates in the views
            end



            function setPivotedTransformationParameter(obj, parameterValue)
                % This function can be used to set a parameter for the transformation if needed
                % For example, if the transformation requires a reference value or time point
                obj.pivotedTransformParameter = parameterValue;
                obj.pivotedTransform = TableTransformationMapper.getTransformation(obj.pivotedTransformationName, parameterValue);
                notify(obj, 'tableDataChanged');  % Notify that the data has changed to trigger any necessary updates in the views
            end



            function [doTransform, transform] = getPivotedTransformationStatus(obj)
                doTransform = obj.pivotedTranformationOn;
                transform = obj.pivotedTransform;
            end
    end


    methods (Access = private)
        function notifyUserColumnDefinitionsChange(obj, typeOfChange, columnName, varargin)
            % Notify listeners that user column definitions have changed
            if isequal(typeOfChange, 'remove')
                eventData = ColumnDefinitionEvent(columnName, typeOfChange, []);
            else
                % Here, I assume that this will be called after the change
                userColumnDefinition = obj.getUserColumnDefinition(columnName);
                eventData = ColumnDefinitionEvent(columnName, typeOfChange, userColumnDefinition);
            end

            if isequal(typeOfChange, 'rename') && ~isempty(varargin)
                oldName = varargin{1};  % Old name is passed as an additional argument
                eventData.setOldName(oldName);
            end
            
            % disp(['Notifying user column definition change: ', typeOfChange, ' for column: ', columnName]);
            notify(obj, 'userColumnDefinitionChanged', eventData);
        end
    end


    methods (Static, Access = private)
        function fh = convertToFunctionHandle(condition)
            if ischar(condition)
                fh = str2func(condition);
            else
                fh = condition;
            end
        end
    end
end