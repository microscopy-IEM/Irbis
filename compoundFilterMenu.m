function compoundFilterMenu(T)
    % Create a new figure for grouping window
    groupingFig = uifigure('Name', 'Define Grouping Parameters');
    groupingFig.Position = [100 100 600 400];
    
    % Add a plus button to add dropdown menus
    plusButton = uibutton(groupingFig, 'push', 'Text', '+');
    plusButton.Position = [10 350 30 30];
    plusButton.ButtonPushedFcn = @(btn,event) addDropdown(groupingFig, T);
    
    % Store UI components for dynamic management
    groupingFig.UserData.DropdownY = 300;
    groupingFig.UserData.ComponentHeight = 40;
end

function addDropdown(fig, T)
    % Get the current Y position for the new components
    dropdownY = fig.UserData.DropdownY;
    
    % Create a dropdown for column names
    columnDropdown = uidropdown(fig);
    columnDropdown.Position = [10 dropdownY 150 30];
    columnDropdown.Items = T.Properties.VariableNames;
    
    % Create a dropdown for operators
    operatorDropdown = uidropdown(fig);
    operatorDropdown.Position = [170 dropdownY 100 30];
    operatorDropdown.Items = {'equal', 'less', 'more'};
    
    % Create a text field for user input
    valueField = uieditfield(fig, 'numeric');
    valueField.Position = [280 dropdownY 100 30];
    
    % Create a delete button
    deleteButton = uibutton(fig, 'push', 'Text', 'Delete');
    deleteButton.Position = [390 dropdownY 70 30];
    deleteButton.ButtonPushedFcn = @(btn,event) deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, fig);
    
    % Update the Y position for the next set of components
    fig.UserData.DropdownY = dropdownY - fig.UserData.ComponentHeight;
end

function deleteRow(columnDropdown, operatorDropdown, valueField, deleteButton, fig)
    % Delete the row components
    delete(columnDropdown);
    delete(operatorDropdown);
    delete(valueField);
    delete(deleteButton);
    
    % Optionally, you can adjust the position of other rows here
end