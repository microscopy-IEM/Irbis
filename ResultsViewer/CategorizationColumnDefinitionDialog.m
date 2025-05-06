classdef (Sealed) CategorizationColumnDefinitionDialog 

    methods (Static)
        function [columnName, conditions] = show(columnNames, getColumnFcn, numExistingCategories)
            [columnName, conditions] = CategorizationColumnDefinitionDialog.dialogWindow(columnNames, getColumnFcn, numExistingCategories);
            if isempty(columnName) || isempty(conditions)
                columnName = '';
                conditions = [];
                return;
            end
        end

        function [columnName, conditions] = showExisting(columnNames, getColumnFcn, existingCategorization)
            numExistingCategories = 1;  % This is not necessary, as we are filling in the exiting name anyway
            [columnName, conditions] = CategorizationColumnDefinitionDialog.dialogWindow(columnNames, getColumnFcn, numExistingCategories, existingCategorization);
            if isempty(columnName) || isempty(conditions)
                columnName = '';
                conditions = [];
                return;
            end
        end
    end

    methods (Static, Access = private)
        function [name, conditions] = dialogWindow(varargin)
            % Create a sample table data
            if isempty(varargin)
                tableData = table({'A'; 'B'; 'C'}, [1; 2; 3], [4; 5; 6], 'VariableNames', {'Col1', 'Col2', 'Col3'});
                columnNames = tableData.Properties.VariableNames;
                getColumnFcn = @(colName) tableData.(colName);
                numberOfExistingCategorizations = 0;
            else
                columnNames = varargin{1};
                getColumnFcn = varargin{2};
                numberOfExistingCategorizations = varargin{3};
            end
        
            % Create a new figure for grouping window
            groupingFig = uifigure('Name', 'Define categories their conditions');
            groupingFig.Position = [100 100 600 500];
        
            % Set default return values
            name = '';
            conditions = [];
        
            % Add a close request function to handle dialog closure
            groupingFig.CloseRequestFcn = @(src, event) closeDialog(src);
        
            % Create a main grid layout
            mainGrid = uigridlayout(groupingFig, [4, 1]);
            mainGrid.RowHeight = {40, '1x', 40};
            mainGrid.ColumnWidth = {'1x'};
        
            % Create a panel for load options
            saveLoadGrid = uigridlayout(mainGrid, [1, 3]);
            saveLoadGrid.ColumnWidth = {'1x', 120, 120};
            saveLoadGrid.Layout.Row = 1;
            saveLoadGrid.Layout.Column = 1;

            % Create a panel for naming the categorization
            namingGrid = uigridlayout(mainGrid, [1, 2]);
            namingGrid.ColumnWidth = {120,'1x'};
            namingGrid.Layout.Row = 1;
            namingGrid.Layout.Column = 1;
        
            % Add the field for category name
            nameLabel = uilabel(namingGrid, "Text", "Categorization name");
            nameLabel.Layout.Row = 1;
            nameLabel.Layout.Column = 1;
        
            nameField = uitextarea(namingGrid, "Value", ['Categorization' num2str(numberOfExistingCategorizations+1)]);
            nameField.Layout.Row = 1;
            nameField.Layout.Column = 2;
            nameField.Tooltip = 'Enter the name of the categorization.';
        
            % Create a panel for category panels
            categoryScrollPanel = uipanel(mainGrid,'Scrollable','on');
            categoryScrollPanel.Layout.Row = 2;
            categoryScrollPanel.Layout.Column = 1;
        
            % Create a grid layout inside the scrollable panel
            categoryGrid = uigridlayout(categoryScrollPanel);
            categoryGrid.RowHeight = {'fit'};
            categoryGrid.ColumnWidth = {'1x'};
            categoryGrid.Scrollable = 'on';
        
            % Initialize UserData for storing category panels
            categoryScrollPanel.UserData.CategoryPanels = {};
        
            % Create a grid layout for buttons
            buttonGrid = uigridlayout(mainGrid, [1, 2]);
            buttonGrid.Layout.Row = 3;
            buttonGrid.Layout.Column = 1;
        
            % Add a plus button to add categories
            categoryPlusButton = uibutton(buttonGrid, 'push', 'Text', 'Add category');
            categoryPlusButton.Layout.Row = 1;
            categoryPlusButton.Layout.Column = 1;
            categoryPlusButton.ButtonPushedFcn = @(btn, event) addCategoryPanel(categoryGrid, columnNames, getColumnFcn, categoryScrollPanel);
            categoryPlusButton.Tooltip = 'Define new category.';
        
            % Add a save button
            saveButton = uibutton(buttonGrid, 'push', 'Text', 'Save categorization');
            saveButton.Layout.Row = 1;
            saveButton.Layout.Column = 2;
            saveButton.ButtonPushedFcn = @(btn, event) saveCategories(categoryScrollPanel);
            saveButton.Tooltip = 'Confirm the categorization definition and close the window.';
        
            addCategoryPanel(categoryGrid, columnNames, getColumnFcn, categoryScrollPanel);
            addCategoryPanel(categoryGrid, columnNames, getColumnFcn, categoryScrollPanel);
        
            if nargin > 2
                currentCategorization = varargin{3};
                loadConditionsForRedefinition;
            end
        
            uiwait(groupingFig)
        
            function closeDialog(fig)
                % Set default return values and delete the figure
                name = '';
                conditions = [];
                delete(fig);
            end
        
            function [categoryPanel,criteriaGrid] = addCategoryPanel(categoryGrid, columnNames, getColumnFcn, scrollPanel)
                % Create a panel for the new category
                categoryPanel = uipanel(categoryGrid);
                categoryPanel.Layout.Row = numel(categoryGrid.Children) + 1;
                categoryPanel.Layout.Column = 1;
        
                % Create a grid layout inside the category panel
                panelGrid = uigridlayout(categoryPanel, [2, 3]);
                panelGrid.RowHeight = {30, 'fit'};
                panelGrid.ColumnWidth = {'1x', 100, 100};
        
                % Create a text field for the category name
                categoryNameField = uieditfield(panelGrid, 'text');
                categoryNameField.Layout.Row = 1;
                categoryNameField.Layout.Column = 1;
                categoryNameField.Value = num2str(numel(categoryGrid.Children));
                categoryNameField.Tooltip = 'Enter the category name.';
        
                % Create a delete button for the category
                deleteCategoryButton = uibutton(panelGrid, 'push', 'Text', 'Delete category');
                deleteCategoryButton.Layout.Row = 1;
                deleteCategoryButton.Layout.Column = 2;
                deleteCategoryButton.ButtonPushedFcn = @(btn, event) deleteCategoryPanel(categoryPanel, categoryGrid, scrollPanel);
                deleteCategoryButton.Tooltip = 'Delete the category.';
        
                % Create a grid layout for criteria
                criteriaGrid = uigridlayout(panelGrid);
                criteriaGrid.Layout.Row = 2;
                criteriaGrid.Layout.Column = [1 3];
                criteriaGrid.RowHeight = {};
                criteriaGrid.ColumnWidth = {'1x', 58, '0.5x', 70};
                criteriaGrid.Scrollable = 'on';
        
                % Add a plus button to add criteria for this category
                criteriaPlusButton = uibutton(panelGrid, 'push', 'Text', 'Add criteria');
                criteriaPlusButton.Layout.Row = 1;
                criteriaPlusButton.Layout.Column = 3;
                criteriaPlusButton.ButtonPushedFcn = @(btn, event) addCriteriaRow(criteriaGrid, columnNames, getColumnFcn, categoryPanel);
                criteriaPlusButton.Tooltip = 'Add new criterion for the category definition.';
        
                % Store UI components for dynamic management
                categoryPanel.UserData.CriteriaComponents = {}; % Store criteria components
        
                % Keep track of category panels
                scrollPanel.UserData.CategoryPanels{end+1} = categoryPanel;
        
                n = numel(categoryGrid.Children);
                categoryGrid.RowHeight = [repmat({'fit'}, 1, n), {5000}];
        
                addCriteriaRow(criteriaGrid, columnNames, getColumnFcn, categoryPanel);
            end
        
            function addCriteriaRow(criteriaGrid, columnNames, getColumnFcn, categoryPanel)
                % Get the current row position for the new criteria components
                newRow = size(criteriaGrid.RowHeight, 2) + 1;
        
                % Create a dropdown for column names
                columnDropdown = uidropdown(criteriaGrid);
                columnDropdown.Layout.Row = newRow;
                columnDropdown.Layout.Column = 1;
                columnDropdown.Items = columnNames;
                columnDropdown.ValueChangedFcn = @(dd, event) updateCriteriaRow(dd, criteriaGrid, getColumnFcn, newRow, categoryPanel);
                columnDropdown.Tooltip = 'Select the variable to base the categorization on.';
        
                % Create a dropdown for operators
                operatorDropdown = uidropdown(criteriaGrid, 'Tag', 'operatorDropdown');
                operatorDropdown.Layout.Row = newRow;
                operatorDropdown.Layout.Column = 2;
                % operatorDropdown.Items = {'equals', 'lessThan', 'greaterThan'};
                operatorDropdown.Items = {'=', '<', '<=', '>', '>=','≠'};
                % operatorDropdown.Items = {'<', '<html>&#8804;</html>', '>', '<html>&#8805;</html>', '=', '<html>&#8800;</html>'}; % does not work
                operatorDropdown.ItemsData = {'equals', 'lessThan', 'equalOrLessThan', 'greaterThan', 'equalOrGreaterThan', 'notEqual'};
                operatorDropdown.FontSize = 16;
                % operatorDropdown.FontWeight = 'bold';
        
                % Create a text field for user input
                valueField = uieditfield(criteriaGrid, 'numeric', 'Tag', 'valueField');
                valueField.Layout.Row = newRow;
                valueField.Layout.Column = 3;
        
                % Create a delete button
                deleteButton = uibutton(criteriaGrid, 'push', 'Text', 'Delete');
                deleteButton.Layout.Row = newRow;
                deleteButton.Layout.Column = 4;
                deleteButton.ButtonPushedFcn = @(btn, event) deleteRow(btn, criteriaGrid, categoryPanel);
                deleteButton.Tooltip = 'Delete the criterion.';
        
                % Store the new criteria components
                newRowComponents = {columnDropdown, operatorDropdown, valueField, deleteButton};
                categoryPanel.UserData.CriteriaComponents{end+1} = newRowComponents;
        
                % Adjust the panel size to fit new components
                criteriaGrid.RowHeight{newRow} = 'fit';
                % criteriaGrid.RowHeight{newRow + 1} = 5000;
            end
        
            function updateCriteriaRow(dd, criteriaGrid, getColumnFcn, row, categoryPanel)
                column = dd.Value;
                columnData = getColumnFcn(column);
                if iscategorical(columnData)
                    % Categorical variable
                    updateToCategoricalCriteria(criteriaGrid, row, columnData, categoryPanel);
                else
                    % Numeric variable
                    updateToNumericCriteria(criteriaGrid, row, categoryPanel);
                end
            end
        
            function updateToCategoricalCriteria(criteriaGrid, row, columnData, categoryPanel)
                % Update operator dropdown
                operatorDropdown = findComponent(criteriaGrid, row, 'operatorDropdown');
                operatorDropdown.Items = {'='};
                operatorDropdown.ItemsData = {'equals'};
                criteriaGrid.ColumnWidth = {'1x', 40, '1x', 70};
        
                % Create a new tree with checkboxes for the value field
                cats = sort(categories(columnData));
                valueField = uitree(criteriaGrid, 'Checkbox', 'Tag', 'valueTree');
                valueField.Layout.Row = row;
                valueField.Layout.Column = 3;
        
                % Populate the tree with category nodes
                for i = 1:length(cats)
                    uitreenode(valueField, 'Text', cats{i});
                end
        
                % Delete the old numeric value field
                oldValueField = findComponent(criteriaGrid, row, 'valueField');
                % if isvalid(oldValueField)
                delete(oldValueField);
                % end
        
                % Update CriteriaComponents to reflect the new value field
                updateCriteriaComponents(categoryPanel, row, valueField);
            end
        
            function updateToNumericCriteria(criteriaGrid, row, categoryPanel)
                % Update operator dropdown
                operatorDropdown = findComponent(criteriaGrid, row, 'operatorDropdown');
                operatorDropdown.Items = {'=', '<', '<=', '>', '>=','≠'};
                % operatorDropdown.Items = {'<', '<html>&#8804;</html>', '>', '<html>&#8805;</html>', '=', '<html>&#8800;</html>'};   % does not work
                operatorDropdown.ItemsData = {'equals', 'lessThan', 'equalOrLessThan', 'greaterThan', 'equalOrGreaterThan', 'notEqual'};
                operatorDropdown.FontSize = 16;
                criteriaGrid.ColumnWidth = {'1x', 58, '0.5x', 70};
                % operatorDropdown.FontWeight = 'bold';
        
                % Create a new numeric value field
                valueField = uieditfield(criteriaGrid, 'numeric', 'Tag', 'valueField');
                valueField.Layout.Row = row;
                valueField.Layout.Column = 3;
        
                % Delete the old tree value field
                oldValueTree = findComponent(criteriaGrid, row, 'valueTree');
                % if isvalid(oldValueTree)
                delete(oldValueTree);
                % end
        
                % Update CriteriaComponents to reflect the new value field
                updateCriteriaComponents(categoryPanel, row, valueField);
            end
        
            function updateCriteriaComponents(categoryPanel, row, newComponent)
                % Update the CriteriaComponents to reflect the new component
                criteriaComponents = categoryPanel.UserData.CriteriaComponents;
                for i = 1:length(criteriaComponents)
                    if criteriaComponents{i}{1}.Layout.Row == row
                        criteriaComponents{i}{3} = newComponent;
                        categoryPanel.UserData.CriteriaComponents = criteriaComponents;
                        return;
                    end
                end
            end
        
            function component = findComponent(criteriaGrid, row, tag)
                % Find a component in the criteria grid by row and tag
                component = [];
                for i = 1:length(criteriaGrid.Children)
                    comp = criteriaGrid.Children(i);
                    if comp.Layout.Row == row && strcmp(comp.Tag, tag)
                        component = comp;
                        return;
                    end
                end
            end
        
            function deleteRow(btn, criteriaGrid, categoryPanel)
                row = btn.Layout.Row;
                % Remove the row from the stored components
                criteriaComponents = categoryPanel.UserData.CriteriaComponents;
                for i = length(criteriaComponents):-1:1
                    if criteriaComponents{i}{1}.Layout.Row == row
                        for j = 1:4
                            if isvalid(criteriaComponents{i}{j})
                                delete(criteriaComponents{i}{j});
                            end
                        end
                        criteriaComponents(i) = [];
                        break;
                    end
                end
        
                categoryPanel.UserData.CriteriaComponents = criteriaComponents;
        
                % Adjust row numbers for the remaining components
                for i = 1:length(criteriaComponents)
                    for j = 1:4
                        if criteriaComponents{i}{j}.Layout.Row > row
                            criteriaComponents{i}{j}.Layout.Row = criteriaComponents{i}{j}.Layout.Row - 1;
                        end
                    end
                end
        
                % Update grid layout row heights
                criteriaGrid.RowHeight = repmat({30}, 1, size(criteriaGrid.RowHeight, 2) - 1);
            end
        
            function deleteCategoryPanel(categoryPanel, categoryGrid, scrollPanel)
                % Delete the category panel
                if isvalid(categoryPanel)
                    delete(categoryPanel);
                end
                % Remove the panel from the stored components
                categoryPanels = scrollPanel.UserData.CategoryPanels;
                index = find(cellfun(@(c) c == categoryPanel, categoryPanels));
                if ~isempty(index)
                    categoryPanels(index) = [];
                end
                scrollPanel.UserData.CategoryPanels = categoryPanels;
        
                % Adjust row numbers for the remaining panels
                for i = 1:length(categoryPanels)
                    categoryPanels{i}.Layout.Row = i;
                end
        
                % Update grid layout row heights
                categoryGrid.RowHeight = repmat({'fit'}, 1, length(categoryPanels));
            end
        
            function saveCategories(scrollPanel)
        
                name = string(nameField.Value);
                conditions = saveSortedCategories(scrollPanel, groupingFig);
            end
        
            function loadConditionsForRedefinition()
        
                    categorization = currentCategorization;
        
                    % Load the name of the categorization
                    nameField.Value = categorization.CategorizationName;
        
                    % Clear existing category panels
                    for i = length(categoryScrollPanel.UserData.CategoryPanels):-1:1
                        delete(categoryScrollPanel.UserData.CategoryPanels{i});
                    end
                    categoryScrollPanel.UserData.CategoryPanels = {};
        
                    fields = fieldnames(categorization.Conditions);
                    for i = 1:numel(fields)
                        [categoryPanel,criteriaGrid] = addCategoryPanel(categoryGrid, columnNames, getColumnFcn, categoryScrollPanel);
        
                        group = fields{i};
                        groupName = categorization.Conditions.(group).name;
                        conds = categorization.Conditions.(group).conditions;
                        condFields = keys(conds);
        
                        categoryPanel.Children(1).Children(1).Value = groupName; % Set the category name
        
                        criteriaNum = 1;
                        for j = 1:numel(condFields)
                            condValue = conds(condFields{j});
                            column = condFields{j};
        
                            if ~ismember(column, columnNames)
                                % the column used in definition does not exist in the current table
                                delete(groupingFig)
                                error('Categorization:ColumnNotInTable', ...
                                    'The column name used in the categorization is not present in the data.');
                            end
                            if isequal(class(condValue{1}),'dictionary')
                                condDict = condValue{1};
                                condKeys = keys(condDict);
                                for k = 1:numel(condKeys)
                                    comparator = condKeys{k};
                                    value = condDict(comparator);
                                    categoryPanel.UserData.CriteriaComponents{criteriaNum}{1}.Value = column;
                                    categoryPanel.UserData.CriteriaComponents{criteriaNum}{2}.Value = comparator;
                                    categoryPanel.UserData.CriteriaComponents{criteriaNum}{3}.Value = value;
                                    if ~isequal(k,numel(condKeys))
                                        addCriteriaRow(criteriaGrid, columnNames, getColumnFcn, categoryPanel);
                                    end
                                    criteriaNum = criteriaNum + 1;
                                end
                            else
                                categoryPanel.UserData.CriteriaComponents{criteriaNum}{1}.Value = column;
                                dd = categoryPanel.UserData.CriteriaComponents{criteriaNum}{1};
                                updateCriteriaRow(dd, criteriaGrid, getColumnFcn, criteriaNum, categoryPanel);
                                checkNodesByName(categoryPanel.UserData.CriteriaComponents{criteriaNum}{3},condValue{1});
                                criteriaNum = criteriaNum + 1;
                            end
                            if ~isequal(j,numel(condFields))
                                addCriteriaRow(criteriaGrid, columnNames, getColumnFcn, categoryPanel);
                            end
                        end
                    end
        
            end

            function conditions = saveSortedCategories(scrollPanel, groupingFig)

                % create categories structure to store to Categorization object
                % sorts the structure so that the structure is the same no matter the order of definition
            
                nCategories = length(scrollPanel.UserData.CategoryPanels);
                categoryNames = cell(1, nCategories); % Preallocate cell array
                for i = 1:nCategories
                    categoryNames{i} = scrollPanel.UserData.CategoryPanels{i}.Children(1).Children(1).Value;
                end
            
                [~, indexes] = sort(categoryNames);
                % indexes = indexes(:)
                % size(indexes)
            
                conditions = struct();
                risingNum = 1;
                for i = indexes
                    % disp(i)
                    categoryPanel = scrollPanel.UserData.CategoryPanels{i};
                    categoryName = categoryNames{i}; % Get the category name
                    conditionsDict = dictionary(string.empty, {}); % Initialize with key and value types
            
                    % sort the column names
                    nConditions = length(categoryPanel.UserData.CriteriaComponents);
                    columns = cell(1, nConditions);
                    operators = cell(1, nConditions);
                    for j = 1:nConditions
                        columns{j} = categoryPanel.UserData.CriteriaComponents{j}{1}.Value;
                        operators{j} = categoryPanel.UserData.CriteriaComponents{j}{2}.Value;
                    end
                    [sortedColumns, columnIndexes] = sort(columns);
                    operatorsSortedByColumns = operators(columnIndexes);
            
                    % now, I also need to sort based on the operator, when the column is mentioned more times
                    [~, b, c] = unique(sortedColumns, "stable");
            
                    for elementId = 1:numel(b)
                        elementCount = sum(c == elementId);
                        if elementCount > 1
                            % column more than once -> sort
                            relevantOperators = operatorsSortedByColumns(b(elementId):b(elementId)+elementCount-1);
                            [~, operatorIndexes] = sort(relevantOperators);
                            relevantColumnIndexes = columnIndexes(b(elementId):b(elementId)+elementCount-1);
                            columnIndexes(b(elementId):b(elementId)+elementCount-1) = relevantColumnIndexes(operatorIndexes);
                        end
                    end
            
                    for j = columnIndexes
                        rowComponents = categoryPanel.UserData.CriteriaComponents{j};
                        % column = rowComponents{1}.Value;
                        % operator = rowComponents{2}.Value;
                        column = columns{j};
                        operator = operators{j};
            
                        % Check if the value field is a uitree (for categorical variables)
                        if strcmp(rowComponents{3}.Type, 'uicheckboxtree')
                            checkedNodes = rowComponents{3}.CheckedNodes;
                            value = {checkedNodes.Text}; % Save as cell array
                            conditionsDict(column) = {value};
                        else
                            value = rowComponents{3}.Value;
                            operatorValueDict = dictionary(operator, value);
                            if isKey(conditionsDict, column)
                                innerDict = conditionsDict(column);
                                innerDict = innerDict{1};
                                % innerDict
                                isConfigured(innerDict)
                                % operator
                                if isKey(innerDict, operator)
                                    disp('overwriting the same condition');
                                end
                                innerDict(operator) = value;
                                conditionsDict(column) = {innerDict};
                            else
                                conditionsDict(column) = {operatorValueDict};
                            end
                        end
                    end
                    categoryStruct.name = categoryName;
                    categoryStruct.conditions = conditionsDict;
                    conditions.(['group' num2str(risingNum)]) = categoryStruct;
                    risingNum = risingNum + 1;
                end
                % assignin('base', 'cats', conditions); % Save to workspace for further use
                % disp(conditions)
            
                uiresume(groupingFig);
                delete(groupingFig);
            end 
        end
    end
end