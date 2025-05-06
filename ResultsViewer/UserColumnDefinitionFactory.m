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
    end
end