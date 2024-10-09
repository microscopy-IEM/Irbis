function groupNames = createGroupDialog()
    % Create the main figure window (dialog)
    fig = uifigure('Name', 'Define Groups', 'Position', [500 500 400 300]);

    % Create a grid layout for the entire figure
    mainLayout = uigridlayout(fig, [4, 2],"Scrollable","on");  % Main grid layout for the figure
    mainLayout.RowHeight = {'fit', 'fit', 'fit', '25'};
    mainLayout.ColumnWidth = {'1x', '1x'};

    % Instructions label
    instructionLabel = uilabel(mainLayout, 'Text', 'Define Group Names:');
    instructionLabel.Layout.Row = 1;
    instructionLabel.Layout.Column = [1 2]; % Spanning both columns

    % A placeholder for storing the group names (cell array)
    groupNames = {}; % This will be modified in the nested functions

    % A panel to dynamically hold text fields with scroll enabled
    groupPanel = uipanel(mainLayout, 'Title', 'Groups', 'Scrollable', 'on');
    groupPanel.Layout.Row = [2 3]; % Spanning rows 2 and 3
    groupPanel.Layout.Column = [1 2]; % Spanning both columns

    % Grid layout for the group panel (1 row, 2 columns initially)
    groupLayout = uigridlayout(groupPanel, [1, 2]);
    groupLayout.RowHeight = {'fit'};
    groupLayout.ColumnWidth = {'1x', '2x'};

    % Button to add a new group
    addGroupButton = uibutton(mainLayout, 'Text', 'Add Group');
    addGroupButton.Layout.Row = 4;
    addGroupButton.Layout.Column = 1;
    addGroupButton.ButtonPushedFcn = @addGroupField;

    % Button to finish adding groups
    finishButton = uibutton(mainLayout, 'Text', 'Finish');
    finishButton.Layout.Row = 4;
    finishButton.Layout.Column = 2;
    finishButton.ButtonPushedFcn = @finishGroups;

    % Wait for the dialog to close (blocking behavior)
    uiwait(fig); % This pauses execution until the dialog is finished

    % Nested function to add a group field dynamically
    function addGroupField(~, ~)
        % Get the current number of rows (each row holds a group input)
        numRows = size(groupLayout.RowHeight, 2) + 1; % Increment row count

        % Add a new row for the group input
        groupLayout.RowHeight{end+1} = 'fit'; % Add new row for the next group

        % Add a label for the new group
        groupLabel = uilabel(groupLayout, 'Text', ['Group ' num2str(numRows-1)]);
        groupLabel.Layout.Row = numRows;
        groupLabel.Layout.Column = 1;

        % Add a text field for the new group
        groupNameField = uitextarea(groupLayout);
        groupNameField.Layout.Row = numRows;
        groupNameField.Layout.Column = 2;

        % Store reference to the text field in the groupNames array
        groupNames{end+1} = groupNameField;
    end

    % Nested function to finish adding groups and close the dialog
    function finishGroups(~, ~)
        % Retrieve the entered group names
        for i = 1:numel(groupNames)
            groupNames{i} = groupNames{i}.Value{1}; % Extract the actual values
        end

        % Resume after closing the dialog
        uiresume(fig); % Continue the paused execution

        % Close the dialog (delete the figure)
        delete(fig);
    end
end
