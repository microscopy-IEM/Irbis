function [name,conditions] = categorizationDefinitionWindow(varargin)
    % Create a sample table data
    if isempty(varargin)
        tableData = table({'A'; 'B'; 'C'}, [1; 2; 3], [4; 5; 6], 'VariableNames', {'Col1', 'Col2', 'Col3'});
    else
        tableData = varargin{1};
    end

    % Create a new figure for grouping window
    groupingFig = uifigure('Name', 'Define Categories and Grouping Parameters');
    groupingFig.Position = [100 100 600 500];

    % Create a main grid layout
    mainGrid = uigridlayout(groupingFig, [3, 1]);
    mainGrid.RowHeight = {40,'1x', 40};
    mainGrid.ColumnWidth = {'1x'};

    % Create a panel for naming the categorization
    namingGrid = uigridlayout(mainGrid, [1, 2]);
    namingGrid.Layout.Row = 1;
    namingGrid.Layout.Column = 1;

    % Add the field for category name
    nameLabel = uilabel(namingGrid,"Text","Categorization name");
    nameLabel.Layout.Row = 1;
    nameLabel.Layout.Column = 1;

    nameField = uitextarea(namingGrid,"Value","Categorization1");
    nameField.Layout.Row = 1;
    nameField.Layout.Column = 2;

    % Create a panel for category panels
    categoryScrollPanel = uipanel(mainGrid, 'Scrollable', 'on');
    categoryScrollPanel.Layout.Row = 2;
    categoryScrollPanel.Layout.Column = 1;

    % Create a grid layout inside the scrollable panel
    categoryGrid = uigridlayout(categoryScrollPanel);
    categoryGrid.RowHeight = {'fit'};
    categoryGrid.ColumnWidth = {'1x'};

    % Initialize UserData for storing category panels
    categoryScrollPanel.UserData.CategoryPanels = {};

    % Create a grid layout for buttons
    buttonGrid = uigridlayout(mainGrid, [1, 3]);
    buttonGrid.Layout.Row = 3;
    buttonGrid.Layout.Column = 1;

    % Add a plus button to add categories
    categoryPlusButton = uibutton(buttonGrid, 'push', 'Text', 'Add Category');
    categoryPlusButton.Layout.Row = 1;
    categoryPlusButton.Layout.Column = 1;
    categoryPlusButton.ButtonPushedFcn = @(btn,event) addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);

    % Add a save button
    saveButton = uibutton(buttonGrid, 'push', 'Text', 'Save Categories');
    saveButton.Layout.Row = 1;
    saveButton.Layout.Column = 2;
    saveButton.ButtonPushedFcn = @(btn,event) saveCategories(categoryScrollPanel);

    % Add a delete all categories button
    deleteAllButton = uibutton(buttonGrid, 'push', 'Text', 'Delete All Categories');
    deleteAllButton.Layout.Row = 1;
    deleteAllButton.Layout.Column = 3;
    deleteAllButton.ButtonPushedFcn = @(btn,event) deleteAllCategories(categoryGrid, categoryScrollPanel);

    addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);
    addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);
    uiwait(groupingFig)


    function addCategoryPanel(categoryGrid, tableData, scrollPanel)
        % Create a panel for the new category
        categoryPanel = uipanel(categoryGrid);
        categoryPanel.Layout.Row = numel(categoryGrid.Children) + 1;
        categoryPanel.Layout.Column = 1;
    
        % Create a grid layout inside the category panel
        panelGrid = uigridlayout(categoryPanel, [2, 2]);
        panelGrid.RowHeight = {30, 'fit'};
        panelGrid.ColumnWidth = {'1x', 70};
    
        % Create a text field for the category name
        categoryNameField = uieditfield(panelGrid, 'text');
        categoryNameField.Layout.Row = 1;
        categoryNameField.Layout.Column = 1;
        categoryNameField.Value = num2str(numel(categoryGrid.Children));
    
        % Create a delete button for the category
        deleteCategoryButton = uibutton(panelGrid, 'push', 'Text', 'Delete Category');
        deleteCategoryButton.Layout.Row = 1;
        deleteCategoryButton.Layout.Column = 2;
        deleteCategoryButton.ButtonPushedFcn = @(btn,event) deleteCategoryPanel(categoryPanel, categoryGrid, scrollPanel);
    
        % Create a grid layout for criteria
        criteriaGrid = uigridlayout(panelGrid);
        criteriaGrid.Layout.Row = 2;
        criteriaGrid.Layout.Column = [1 2];
        criteriaGrid.RowHeight = {'fit'};
        criteriaGrid.ColumnWidth = {'1x', 100, 100, 100, 70};
    
        % Add a plus button to add criteria for this category
        criteriaPlusButton = uibutton(criteriaGrid, 'push', 'Text', 'Add Criteria');
        criteriaPlusButton.Layout.Row = 1;
        criteriaPlusButton.Layout.Column = 5;
        criteriaPlusButton.ButtonPushedFcn = @(btn,event) addCriteriaRow(criteriaGrid, tableData, categoryPanel);
    
        % Store UI components for dynamic management
        categoryPanel.UserData.CriteriaComponents = {}; % Store criteria components
    
        % Keep track of category panels
        scrollPanel.UserData.CategoryPanels{end+1} = categoryPanel;

        addCriteriaRow(criteriaGrid, tableData, categoryPanel);
    end
    
    function addCriteriaRow(criteriaGrid, tableData, categoryPanel)
        % Get the current row position for the new criteria components
        newRow = size(criteriaGrid.RowHeight, 2) + 1;
    
        % Create a dropdown for column names
        columnDropdown = uidropdown(criteriaGrid);
        columnDropdown.Layout.Row = newRow;
        columnDropdown.Layout.Column = 1;
        columnDropdown.Items = tableData.Properties.VariableNames;
    
        % Create a dropdown for operators
        operatorDropdown = uidropdown(criteriaGrid);
        operatorDropdown.Layout.Row = newRow;
        operatorDropdown.Layout.Column = 2;
        operatorDropdown.Items = {'equals', 'lessThan', 'greaterThan'};
    
        % Create a text field for user input
        valueField = uieditfield(criteriaGrid, 'numeric');
        valueField.Layout.Row = newRow;
        valueField.Layout.Column = 3;
    
        % Create a delete button
        deleteButton = uibutton(criteriaGrid, 'push', 'Text', 'Delete');
        deleteButton.Layout.Row = newRow;
        deleteButton.Layout.Column = 4;
        deleteButton.ButtonPushedFcn = @(btn,event) deleteRow(btn, criteriaGrid, categoryPanel);
    
        % Store the new criteria components
        newRowComponents = {columnDropdown, operatorDropdown, valueField, deleteButton};
        categoryPanel.UserData.CriteriaComponents{end+1} = newRowComponents;
    
        % Adjust the panel size to fit new components
        criteriaGrid.RowHeight{newRow} = 'fit';
    end
    
    function deleteRow(btn, criteriaGrid, categoryPanel)
        row = btn.Layout.Row;
        % Remove the row from the stored components
        criteriaComponents = categoryPanel.UserData.CriteriaComponents;
        for i = length(criteriaComponents):-1:1
            if criteriaComponents{i}{1}.Layout.Row == row
                for j = 1:4
                    delete(criteriaComponents{i}{j});
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
        delete(categoryPanel);
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
    
    function deleteAllCategories(categoryGrid, scrollPanel)
        % Delete all category panels
        categoryPanels = scrollPanel.UserData.CategoryPanels;
        for i = 1:length(categoryPanels)
            delete(categoryPanels{i});
        end
        % Clear the stored panels
        scrollPanel.UserData.CategoryPanels = {};
        % Update grid layout row heights
        categoryGrid.RowHeight = {'fit'};
    end
    
    function saveCategories(scrollPanel)
        conditions = struct();
        for i = 1:length(scrollPanel.UserData.CategoryPanels)
            categoryPanel = scrollPanel.UserData.CategoryPanels{i};
            categoryName = categoryPanel.Children(1).Children(1).Value; % Get the category name
            conditionsDict = dictionary(string.empty, dictionary()); % Initialize with key and value types
            for j = 1:length(categoryPanel.UserData.CriteriaComponents)
                rowComponents = categoryPanel.UserData.CriteriaComponents{j};
                column = rowComponents{1}.Value;
                operator = rowComponents{2}.Value;
                value = rowComponents{3}.Value;
                operatorValueDict = dictionary(operator, value);
                if isKey(conditionsDict, column)
                    innerDict = conditionsDict(column);
                    if isKey(innerDict, operator)
                        disp('overwriting the same condition');
                    end
                    innerDict(operator) = value;
                    conditionsDict(column) = innerDict;
                else
                    conditionsDict(column) = operatorValueDict;
                end
            end
            categoryStruct.name = categoryName;
            categoryStruct.conditions = conditionsDict;
            conditions.(['group' num2str(i)]) = categoryStruct;
        end
        assignin('base', 'categories', conditions); % Save to workspace for further use
        disp(conditions)

        name = nameField.Value;

        uiresume(groupingFig);
        delete(groupingFig);
    end

end
