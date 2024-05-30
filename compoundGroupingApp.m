function CompoundGroupingApp(varargin)
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
    mainGrid = uigridlayout(groupingFig, [2, 1]);
    mainGrid.RowHeight = {'1x', 50};
    mainGrid.ColumnWidth = {'1x'};

    % Create a panel for category panels
    categoryScrollPanel = uipanel(mainGrid, 'Scrollable', 'on');
    categoryScrollPanel.Layout.Row = 1;
    categoryScrollPanel.Layout.Column = 1;

    % Create a grid layout inside the scrollable panel
    categoryGrid = uigridlayout(categoryScrollPanel);
    categoryGrid.RowHeight = {'fit'};
    categoryGrid.ColumnWidth = {'1x'};

    % Initialize UserData for storing category panels
    categoryScrollPanel.UserData.CategoryPanels = {};

    % Create a grid layout for buttons
    buttonGrid = uigridlayout(mainGrid, [1, 2]);
    buttonGrid.Layout.Row = 2;
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
end

function addCategoryPanel(categoryGrid, tableData, scrollPanel)
    % Create a panel for the new category
    % categoryPanel = uipanel(categoryGrid, 'Title', 'New Category');
    categoryPanel = uipanel(categoryGrid);
    categoryPanel.Layout.Row = numel(categoryGrid.Children) + 1;
    categoryPanel.Layout.Column = 1;

    % Create a grid layout inside the category panel
    panelGrid = uigridlayout(categoryPanel, [2, 1]);
    panelGrid.RowHeight = {30, 'fit'};
    panelGrid.ColumnWidth = {'1x'};

    % Create a text field for the category name
    categoryNameField = uieditfield(panelGrid, 'text');
    categoryNameField.Layout.Row = 1;
    categoryNameField.Layout.Column = 1;
    categoryNameField.Value = num2str(numel(categoryGrid.Children));

    % Create a grid layout for criteria
    criteriaGrid = uigridlayout(panelGrid);
    criteriaGrid.Layout.Row = 2;
    criteriaGrid.Layout.Column = 1;
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
                delete(criteriaComponents{i}{j})
            end
            criteriaComponents(i) = [];
            break;
        end
    end


    % % Delete the row components
    % children = criteriaGrid.Children;
    % for i = 1:length(children)
    %     if children(i).Layout.Row == row
    %         delete(children(i));
    %     end
    % end

    categoryPanel.UserData.CriteriaComponents = criteriaComponents;

    % Adjust row numbers for the remaining components
    for i = 1:length(criteriaComponents)
        % i
        % rowN = criteriaComponents{i}{1}.Layout.Row
        for j = 1:4
            if criteriaComponents{i}{j}.Layout.Row > row
                criteriaComponents{i}{j}.Layout.Row = criteriaComponents{i}{j}.Layout.Row - 1;
            end
        end
        % rowN2 = criteriaComponents{i}{1}.Layout.Row
    end

    % Update grid layout row heights
    criteriaGrid.RowHeight = repmat({30}, 1, size(criteriaGrid.RowHeight, 2) - 1);
end

function saveCategories(scrollPanel)
    categories = struct();
    for i = 1:length(scrollPanel.UserData.CategoryPanels)
        categoryPanel = scrollPanel.UserData.CategoryPanels{i};
        categoryName = categoryPanel.Children(1).Children(1).Value; % Get the category name
        conditionsDict = dictionary(string.empty, dictionary()); % Initialize with key and value types
        for j = 1:length(categoryPanel.UserData.CriteriaComponents)
            rowComponents = categoryPanel.UserData.CriteriaComponents{j};
            column = rowComponents{1}.Value;
            operator = rowComponents{2}.Value;
            value = rowComponents{3}.Value;
            operatorValueDict = dictionary(operator,value);
            if isKey(conditionsDict, column)
                innerDict = conditionsDict(column);
                if isKey(innerDict,operator)
                    disp('overwriting the same condition')
                end
                innerDict(operator) = value;
                conditionsDict(column) = innerDict;
            else
                conditionsDict(column) = operatorValueDict; 
            end
        end
        categoryStruct.name = categoryName;
        categoryStruct.conditions = conditionsDict;
        categories.(categoryName) = categoryStruct;
    end
    assignin('base', 'categories', categories); % Save to workspace for further use
    disp(categories);
end





% function compoundFilterMenu(T)
%     % Create a new figure for grouping window
%     groupingFig = uifigure('Name', 'Define Grouping Parameters');
%     groupingFig.Position = [100 100 600 400];
% 
%     % Add a plus button to add dropdown menus
%     plusButton = uibutton(groupingFig, 'push', 'Text', '+');
%     plusButton.Position = [10 350 30 30];
%     plusButton.ButtonPushedFcn = @(btn,event) addDropdown(groupingFig, T);
% 
%     % Store UI components for dynamic management
%     groupingFig.UserData.DropdownY = 300;
%     groupingFig.UserData.ComponentHeight = 40;
% end
% 
% function addDropdown(fig, T)
%     % Get the current Y position for the new components
%     dropdownY = fig.UserData.DropdownY;
% 
%     % Create a dropdown for column names
%     columnDropdown = uidropdown(fig);
%     columnDropdown.Position = [10 dropdownY 150 30];
%     columnDropdown.Items = T.Properties.VariableNames;
% 
%     % Create a dropdown for operators
%     operatorDropdown = uidropdown(fig);
%     operatorDropdown.Position = [170 dropdownY 100 30];
%     operatorDropdown.Items = {'equal', 'less', 'more'};
% 
%     % Create a text field for user input
%     valueField = uieditfield(fig, 'numeric');
%     valueField.Position = [280 dropdownY 100 30];
% 
%     % Create a delete button
%     deleteButton = uibutton(fig, 'push', 'Text', 'Delete');
%     deleteButton.Position = [390 dropdownY 70 30];
%     deleteButton.ButtonPushedFcn = @(btn,event) deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, fig);
% 
%     % Update the Y position for the next set of components
%     fig.UserData.DropdownY = dropdownY - fig.UserData.ComponentHeight;
% end
% 
% function deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, fig)
%     % Delete the row components
%     delete(columnDropdown);
%     delete(operatorDropdown);
%     delete(valueField);
%     delete(deleteButton);
% 
%     % Optionally, you can adjust the position of other rows here
% end