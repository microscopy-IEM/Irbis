function CompoundGroupingApp
    % Create a sample table data
    tableData = table({'A'; 'B'; 'C'}, [1; 2; 3], [4; 5; 6], 'VariableNames', {'Col1', 'Col2', 'Col3'});

    % Create a new figure for grouping window
    groupingFig = uifigure('Name', 'Define Categories and Grouping Parameters');
    groupingFig.Position = [100 100 600 500];

    % Add a plus button to add categories
    categoryPlusButton = uibutton(groupingFig, 'push', 'Text', 'Add Category');
    categoryPlusButton.Position = [10 450 100 30];
    categoryPlusButton.ButtonPushedFcn = @(btn,event) addCategoryPanel(groupingFig, tableData);

    % Store UI components for dynamic management
    groupingFig.UserData.CategoryY = 400;
    groupingFig.UserData.ComponentHeight = 50;
    groupingFig.UserData.CategoryPanels = {}; % Store category panels
    groupingFig.UserData.CategoryPlusButton = categoryPlusButton; % Store the button for repositioning
end

function addCategoryPanel(fig, tableData)
    % Get the current Y position for the new category panel
    categoryY = fig.UserData.CategoryY;

    % Create a panel for the new category
    categoryPanel = uipanel(fig, 'Title', 'New Category');
    categoryPanel.Position = [10 categoryY 580 100];

    % Create a text field for the category name
    categoryNameField = uieditfield(categoryPanel, 'text');
    categoryNameField.Position = [10 50 200 30];
    categoryNameField.Placeholder = 'Enter category name';

    % Add a plus button to add criteria for this category
    criteriaPlusButton = uibutton(categoryPanel, 'push', 'Text', 'Add Criteria');
    criteriaPlusButton.Position = [10 10 100 30];
    criteriaPlusButton.ButtonPushedFcn = @(btn,event) addCriteriaRow(categoryPanel, tableData, fig);

    % Store UI components for dynamic management
    categoryPanel.UserData.CriteriaY = 10;
    categoryPanel.UserData.ComponentHeight = 40;
    categoryPanel.UserData.CriteriaComponents = {}; % Store criteria components

    % Update the Y position for the next category panel
    fig.UserData.CategoryY = categoryY - 110; % Adjust to ensure space between panels

    % Keep track of category panels
    fig.UserData.CategoryPanels{end+1} = categoryPanel;

    % Adjust the position of the Add Category button
    adjustButtonPosition(fig);
end

function addCriteriaRow(categoryPanel, tableData, fig)
    % Get the current Y position for the new criteria components
    criteriaY = categoryPanel.Position(4) - 40 - categoryPanel.UserData.ComponentHeight * (length(categoryPanel.UserData.CriteriaComponents) + 1);

    % Create a dropdown for column names
    columnDropdown = uidropdown(categoryPanel);
    columnDropdown.Position = [220 criteriaY 100 30];
    columnDropdown.Items = tableData.Properties.VariableNames;

    % Create a dropdown for operators
    operatorDropdown = uidropdown(categoryPanel);
    operatorDropdown.Position = [330 criteriaY 100 30];
    operatorDropdown.Items = {'equal', 'less', 'more'};

    % Create a text field for user input
    valueField = uieditfield(categoryPanel, 'numeric');
    valueField.Position = [440 criteriaY 100 30];

    % Create a delete button
    deleteButton = uibutton(categoryPanel, 'push', 'Text', 'Delete');
    deleteButton.Position = [550 criteriaY 70 30];
    deleteButton.ButtonPushedFcn = @(btn,event) deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, categoryPanel, fig);

    % Adjust the panel size to fit new components
    categoryPanel.Position(4) = categoryPanel.Position(4) + categoryPanel.UserData.ComponentHeight;

    % Store the new criteria components
    newRowComponents = {columnDropdown, operatorDropdown, valueField, deleteButton};
    categoryPanel.UserData.CriteriaComponents{end+1} = newRowComponents;

    % Update the Y position for the next set of components
    categoryPanel.UserData.CriteriaY = categoryPanel.UserData.CriteriaY - categoryPanel.UserData.ComponentHeight;

    % Adjust the position of all category panels below this one
    adjustPanelPositions(categoryPanel, categoryPanel.UserData.ComponentHeight, fig);
end

function deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, categoryPanel, fig)
    % Get the index of the row to delete
    criteriaComponents = categoryPanel.UserData.CriteriaComponents;
    rowIndex = find(cellfun(@(c) isequal(c, {columnDropdown, operatorDropdown, valueField, deleteButton}), criteriaComponents));

    % Delete the row components
    delete(columnDropdown);
    delete(operatorDropdown);
    delete(valueField);
    delete(deleteButton);

    % Remove the row from the stored components
    categoryPanel.UserData.CriteriaComponents(rowIndex) = [];

    % Rearrange remaining rows
    criteriaY = categoryPanel.Position(4) - categoryPanel.UserData.ComponentHeight * 2; % Initial Y position for the first row
    for i = 1:length(categoryPanel.UserData.CriteriaComponents)
        rowComponents = categoryPanel.UserData.CriteriaComponents{i};
        rowComponents{1}.Position(2) = criteriaY;
        rowComponents{2}.Position(2) = criteriaY;
        rowComponents{3}.Position(2) = criteriaY;
        rowComponents{4}.Position(2) = criteriaY;
        criteriaY = criteriaY - categoryPanel.UserData.ComponentHeight;
    end

    % Update the Y position for the next set of components
    categoryPanel.UserData.CriteriaY = criteriaY + categoryPanel.UserData.ComponentHeight;

    % Adjust the panel size to fit new components
    categoryPanel.Position(4) = 100 + length(categoryPanel.UserData.CriteriaComponents) * categoryPanel.UserData.ComponentHeight;

    % Adjust the position of the category panel and all below it
    adjustPanelPositions(categoryPanel, -categoryPanel.UserData.ComponentHeight, fig);
end

function adjustPanelPositions(modifiedPanel, deltaY, fig)
    % Adjust the position of all category panels below the modified one
    for i = 1:length(fig.UserData.CategoryPanels)
        categoryPanel = fig.UserData.CategoryPanels{i};
        if categoryPanel.Position(2) < modifiedPanel.Position(2)
            categoryPanel.Position(2) = categoryPanel.Position(2) - deltaY;
        end
    end

    % Adjust the position of the Add Category button
    adjustButtonPosition(fig);
end

function adjustButtonPosition(fig)
    % Find the lowest point of all category panels
    minY = fig.UserData.CategoryY;
    for i = 1:length(fig.UserData.CategoryPanels)
        categoryPanel = fig.UserData.CategoryPanels{i};
        if categoryPanel.Position(2) < minY
            minY = categoryPanel.Position(2);
        end
    end

    % Set the Add Category button position below the lowest category panel
    fig.UserData.CategoryPlusButton.Position(2) = minY - 60;
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