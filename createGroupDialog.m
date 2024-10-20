function groupNames = createGroupDialog(existingGroupNames)
    % Create the main figure window (dialog)
    fig = uifigure('Name', 'Define Groups', 'Position', [500 500 400 300]);

    % Create a grid layout for the entire figure
    mainLayout = uigridlayout(fig, [4, 2],"Scrollable","on");  % Main grid layout for the figure
    mainLayout.RowHeight = {'fit', 'fit', 'fit', 25};
    mainLayout.ColumnWidth = {'1x', '1x'};

    % Instructions label
    instructionLabel = uilabel(mainLayout, 'Text', 'Define Group Names:');
    instructionLabel.Layout.Row = 1;
    instructionLabel.Layout.Column = [1 2]; % Spanning both columns

    % A placeholder for storing the group names (cell array)
    groupNamesFields = {}; % This will be modified in the nested functions
    groupNames = {};

    % A panel to dynamically hold text fields with scroll enabled
    groupPanel = uipanel(mainLayout, 'Title', 'Groups', 'Scrollable', 'on');
    groupPanel.Layout.Row = [2 3]; % Spanning rows 2 and 3
    groupPanel.Layout.Column = [1 2]; % Spanning both columns

    % Grid layout for the group panel (1 row, 2 columns initially)
    groupLayout = uigridlayout(groupPanel, [1, 2]);
    groupLayout.RowHeight = {'fit'};
    groupLayout.ColumnWidth = {'1x', '2x'};

    % Add existing groups if provided
    if nargin > 0 && ~isempty(existingGroupNames)
        for i = 1:numel(existingGroupNames)
            addGroupField(existingGroupNames{i}); % Add pre-defined groups
        end
    end

    % Button to add a new group
    addGroupButton = uibutton(mainLayout, 'Text', 'Add Group');
    addGroupButton.Layout.Row = 4;
    addGroupButton.Layout.Column = 1;
    addGroupButton.ButtonPushedFcn = @(src,event)addGroupField('');

    % Button to finish adding groups
    finishButton = uibutton(mainLayout, 'Text', 'Finish');
    finishButton.Layout.Row = 4;
    finishButton.Layout.Column = 2;
    finishButton.ButtonPushedFcn = @finishGroups;

    % Set a CloseRequestFcn to handle dialog closure
    fig.CloseRequestFcn = @(src, event) cancelDialog(src);

    % Wait for the dialog to close (blocking behavior)
    uiwait(fig); % This pauses execution until the dialog is finished

    % Check if the figure still exists
    if isvalid(fig)
        % If the dialog is closed properly (by pressing Finish)
        % Return the group names
        delete(fig);  % Close the dialog
    else
        % If the dialog was canceled (closed by X button), return empty
        groupNames = [];
    end

    % Nested function to add a group field dynamically
    function addGroupField(existingName)
        % Get the current number of rows (each row holds a group input)
        numRows = size(groupLayout.RowHeight, 2) + 1; % Increment row count

        % Add a new row for the group input
        groupLayout.RowHeight{end+1} = 30; % Add new row for the next group

        % Add a label for the new group
        groupLabel = uilabel(groupLayout, 'Text', ['Group ' num2str(numRows-1)]);
        groupLabel.Layout.Row = numRows;
        groupLabel.Layout.Column = 1;

        % Add a text field for the new group
        groupNameField = uitextarea(groupLayout);
        groupNameField.Layout.Row = numRows;
        groupNameField.Layout.Column = 2;

        % Pre-populate with existing group name if provided
        if ~isempty(existingName)
            groupLabel.Text = ['Group ' num2str(numRows-1) ': ' existingName];
            groupNameField.Value = {existingName}; % Set the existing group name
        end

        % Store reference to the text field in the groupNames array
        groupNamesFields{end+1} = groupNameField;
    end

    % Nested function to finish adding groups and close the dialog
    function finishGroups(~, ~)
        % Retrieve the entered group names
        for i = 1:numel(groupNamesFields)
            groupNames{i} = groupNamesFields{i}.Value{1}; % Extract the actual values
        end

        % Resume after closing the dialog
        uiresume(fig); % Continue the paused execution
    end

    % Function to handle the close request when the user presses the X button
    function cancelDialog(figHandle)
        % Delete the figure and resume the UI so it continues without 'Finish'
        delete(figHandle);
        % uiresume(figHandle);
    end
end


% function groupNames = createGroupDialog()
%     % Create the main figure window (dialog)
%     fig = uifigure('Name', 'Define Groups', 'Position', [500 500 400 300]);
% 
%     % Create a grid layout for the entire figure
%     mainLayout = uigridlayout(fig, [4, 2],"Scrollable","on");  % Main grid layout for the figure
%     mainLayout.RowHeight = {'fit', 'fit', 'fit', 25};
%     mainLayout.ColumnWidth = {'1x', '1x'};
% 
%     % Instructions label
%     instructionLabel = uilabel(mainLayout, 'Text', 'Define Group Names:');
%     instructionLabel.Layout.Row = 1;
%     instructionLabel.Layout.Column = [1 2]; % Spanning both columns
% 
%     % A placeholder for storing the group names (cell array)
%     groupNamesFields = {}; % This will be modified in the nested functions
%     groupNames = {};
% 
%     % A panel to dynamically hold text fields with scroll enabled
%     groupPanel = uipanel(mainLayout, 'Title', 'Groups', 'Scrollable', 'on');
%     groupPanel.Layout.Row = [2 3]; % Spanning rows 2 and 3
%     groupPanel.Layout.Column = [1 2]; % Spanning both columns
% 
%     % Grid layout for the group panel (1 row, 2 columns initially)
%     groupLayout = uigridlayout(groupPanel, [1, 2]);
%     groupLayout.RowHeight = {'fit'};
%     groupLayout.ColumnWidth = {'1x', '2x'};
% 
%     % Button to add a new group
%     addGroupButton = uibutton(mainLayout, 'Text', 'Add Group');
%     addGroupButton.Layout.Row = 4;
%     addGroupButton.Layout.Column = 1;
%     addGroupButton.ButtonPushedFcn = @addGroupField;
% 
%     % Button to finish adding groups
%     finishButton = uibutton(mainLayout, 'Text', 'Finish');
%     finishButton.Layout.Row = 4;
%     finishButton.Layout.Column = 2;
%     finishButton.ButtonPushedFcn = @finishGroups;
% 
%     % Set a CloseRequestFcn to handle dialog closure
%     fig.CloseRequestFcn = @(src, event) cancelDialog(src);
% 
%     % Wait for the dialog to close (blocking behavior)
%     uiwait(fig); % This pauses execution until the dialog is finished
% 
%     % Check if the figure still exists
%     if isvalid(fig)
%         % If the dialog is closed properly (by pressing Finish)
%         % Return the group names
%         delete(fig);  % Close the dialog
%     else
%         % If the dialog was canceled (closed by X button), return empty
%         groupNames = [];
%     end
% 
%     % Nested function to add a group field dynamically
%     function addGroupField(~, ~)
%         % Get the current number of rows (each row holds a group input)
%         numRows = size(groupLayout.RowHeight, 2) + 1; % Increment row count
% 
%         % Add a new row for the group input
%         groupLayout.RowHeight{end+1} = 30; % Add new row for the next group
% 
%         % Add a label for the new group
%         groupLabel = uilabel(groupLayout, 'Text', ['Group ' num2str(numRows-1)]);
%         groupLabel.Layout.Row = numRows;
%         groupLabel.Layout.Column = 1;
% 
%         % Add a text field for the new group
%         groupNameField = uitextarea(groupLayout);
%         groupNameField.Layout.Row = numRows;
%         groupNameField.Layout.Column = 2;
% 
%         % Store reference to the text field in the groupNames array
%         groupNamesFields{end+1} = groupNameField;
%     end
% 
%     % Nested function to finish adding groups and close the dialog
%     function finishGroups(~, ~)
%         % Retrieve the entered group names
%         for i = 1:numel(groupNamesFields)
%             groupNames{i} = groupNamesFields{i}.Value{1}; % Extract the actual values
%         end
% 
%         % Resume after closing the dialog
%         uiresume(fig); % Continue the paused execution
%     end
% 
%     % Function to handle the close request when the user presses the X button
%     function cancelDialog(figHandle)
%         % Delete the figure and resume the UI so it continues without 'Finish'
%         delete(figHandle);
%         uiresume(figHandle);
%     end
% end
