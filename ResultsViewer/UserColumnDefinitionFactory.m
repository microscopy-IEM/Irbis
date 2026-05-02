classdef (Sealed) UserColumnDefinitionFactory

    methods (Static)
        function columnDefinitionObject = create(definitionType, tableStoreHandle)

            columnDefinitionObject = [];

            switch definitionType
                case 'categorization'
                    % display user interface to create a new column
                    columnNames = tableStoreHandle.getColumnNames();
                    getColumnFcn = @(colName) table2array(tableStoreHandle.getTableSubsetByName(colName));
                    numExistingCategories = tableStoreHandle.getNumDefinitionsOfType(definitionType);

                    [name, conditions] = CategorizationColumnDefinitionDialog.show(columnNames, getColumnFcn, numExistingCategories); % open the dialog to define the new column
        
                    % extract the categorization and store it
                    if ~isempty(name) && ~isempty(conditions)
                        columnDefinitionObject = Categorization(name, conditions);
                    end
                    
            case 'formula'
                % display user interface to create a new column
                [name, formula] = FormulaColumnDefinitionDialog.show(); % open the dialog to define the new column
                
                if ~isempty(name) && ~isempty(formula)
                    columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                end

            case 'merged'

                categoricalOrNumericColumnNames = tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});

                if ~isempty(categoricalOrNumericColumnNames)    
                    [name, formula] = MergedColumnDefinitionDialog.show(categoricalOrNumericColumnNames);

                    if ~isempty(name) && ~isempty(formula)
                        % create the column definition object
                        columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                        columnDefinitionObject.setDefinitionType('merged');
                    end
                end

            case 'manual'

                [name, groupNames] = ManualColumnDefinitionDialog.show(); 

                if ~isempty(name) && ~isempty(groupNames)
                    % create the column definition object
                    columnDefinitionObject = ManualColumnDefinition(name, groupNames);
                end
            end
        end


        function columnDefinitionObject = redefine(definitionType, tableStoreHandle, existingColumnDefinitionObject)

            columnDefinitionObject = [];
            oldName = existingColumnDefinitionObject.getColumnName();

            switch definitionType

                case 'categorization'
                    columnNames = tableStoreHandle.getColumnNames();
                    getColumnFcn = @(colName) tableStoreHandle.getColumnData(colName);

                    [newName, newRules] = CategorizationColumnDefinitionDialog.showExisting(columnNames, getColumnFcn, userColumnDefinition);

                    if isempty(newName) || isempty(newRules)
                        columnDefinitionObject = [];
                        return
                        % if user cancelled the process, just return empty array - this should stop upstream processing if checked for
                    end

                    if isequal(newName, oldName)
                        existingColumnDefinitionObject.replaceRules(conditions);
                        columnDefinitionObject = existingColumnDefinitionObject;
                        % as the categorizationDefinition is a handle object, this returns the same handle as was provided
                        % TO OPTIMIZE - in the future, possibly change it from handle to pass-by-value object
                    else
                        columnDefinitionObject = Categorization(newName, newRules);
                    end

                case 'formula'
                    existingRules = existingColumnDefinitionObject.getRules();
                    [newName, newRules] = FormulaColumnDefinitionDialog.showExisting(oldName, existingRules);

                    if isempty(newName) || isempty(newRules)
                        columnDefinitionObject = [];
                        return
                        % if user cancelled the process, just return empty array - this should stop upstream processing if checked for
                    end

                    if isequal(newName, oldName)
                        existingColumnDefinitionObject.replaceRules(newRules);
                        columnDefinitionObject = existingColumnDefinitionObject;
                    else
                        columnDefinitionObject = FormulaColumnDefinition(newName, newRules);
                    end

                case 'merged'
                    categoricalOrNumericColumnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});

                    if isempty(categoricalOrNumericColumnNames)
                        columnDefinitionObject = [];
                        return
                    end
                    
                    [newName, newRules] = MergedColumnDefinitionDialog.showExisting(categoricalOrNumericColumnNames, oldName);

                    if isempty(newName) || isempty(newRules)
                        columnDefinitionObject = [];
                        return
                    end

                    if isequal(newName, oldName)
                        % if the name is the same, the rules did not change -> stop further processing
                        columnDefinitionObject = [];
                        return
                    else
                        columnDefinitionObject = FormulaColumnDefinition(newName, newRules);
                        columnDefinitionObject.setDefinitionType('merged');
                    end

                case 'manual'
                    existingGroupNames = existingColumnDefinitionObject.getGroupNames(); 
                    [newName, newRules] = ManualColumnDefinitionDialog.showExisting(oldName, existingGroupNames); 
                    
                    if isempty(newName) || isempty(newRules)
                        columnDefinitionObject = [];
                        return
                    end
                    
                    if isequal(newName, existingColumnDefinitionObject.getColumnName())
                        % columnDefinitionObject = existingColumnDefinitionObject.replaceRules(newRules);
                        existingColumnDefinitionObject.replaceRules(newRules);
                        columnDefinitionObject = existingColumnDefinitionObject;
                        % rules exchanged within the shared handle class
                    else
                        newRules = newRules(~cellfun('isempty', newRules)); % Filter out empty group names
                        columnDefinitionObject = ManualColumnDefinition(newName, newRules);
                    end    
            end
        end
    end
end