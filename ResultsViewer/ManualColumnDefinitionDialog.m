classdef (Sealed) ManualColumnDefinitionDialog

    methods (Static)
        function [columnName, groupNames] = show()

            [columnName, groupNames] = ManualColumnDefinitionDialog.createGroupDialog();
            % Check if the user pressed cancel
            if isempty(columnName) || isempty(groupNames)
                columnName = '';
                groupNames = [];
                return;
            end

            % Remove empty cells from groupNames
            groupNames = groupNames(~cellfun('isempty', groupNames));
        end

        function [columnName, groupNames] = showExisting(existingCategorizationName, existingGroupNames)
            % Show the dialog with existing categorization name and group names
            [columnName, groupNames] = ManualColumnDefinitionDialog.createGroupDialog(existingCategorizationName, existingGroupNames);
            % Check if the user pressed cancel
            if isempty(columnName) || isempty(groupNames)
                columnName = '';
                groupNames = [];
                return;
            end

            % Do not remove empty cells, because we need to know if user wanted to delete some
        end
    end

    methods (Static, Access = private)
        function [categorizationName, groupNames] = createGroupDialog(existingCategorizationName, existingGroupNames)
            % Create the main figure window (dialog)
            fig = uifigure('Name', 'Define new manual categorization', 'Position', [500 500 400 350]);
        
            % Create a grid layout for the entire figure
            mainLayout = uigridlayout(fig, [5, 2], "Scrollable", "on");  % Main grid layout for the figure
            mainLayout.RowHeight = {30, 'fit', 'fit', 'fit', 25};
            mainLayout.ColumnWidth = {'1x', '1x'};
        
            % Categorization name label
            nameLabel = uilabel(mainLayout, 'Text', 'Categorization name:');
            nameLabel.Layout.Row = 1;
            nameLabel.Layout.Column = 1;
        
            % Categorization name text field
            nameField = uitextarea(mainLayout);
            nameField.Layout.Row = 1;
            nameField.Layout.Column = 2;
        
            % A placeholder for storing the group names (cell array)
            groupNamesFields = {}; % This will be modified in the nested functions
            groupNames = {};
            categorizationName = '';
        
            % A panel to dynamically hold text fields with scroll enabled
            groupPanel = uipanel(mainLayout, 'Title', 'Define groups:', 'Scrollable', 'on');
            groupPanel.Layout.Row = [2 4]; % Spanning rows 3 and 4
            groupPanel.Layout.Column = [1 2]; % Spanning both columns
        
            % Grid layout for the group panel (1 row, 2 columns initially)
            groupLayout = uigridlayout(groupPanel, [1, 2]);
            groupLayout.RowHeight = {'fit'};
            groupLayout.ColumnWidth = {'1x', '2x'};
        
            % Fill in existing categorization name
            if nargin > 0 && ~isempty(existingCategorizationName)
                nameField.Value{1} = existingCategorizationName;
            end
        
            % Add existing groups if provided
            if nargin > 0 && ~isempty(existingGroupNames)
                for existingGroupIdx = 1:numel(existingGroupNames)
                    addGroupField(existingGroupNames{existingGroupIdx}); % Add pre-defined groups
                end
            end
        
            % Button to add a new group
            addGroupButton = uibutton(mainLayout, 'Text', 'Add group');
            addGroupButton.Layout.Row = 5;
            addGroupButton.Layout.Column = 1;
            addGroupButton.ButtonPushedFcn = @(src,event)addGroupField('');
        
            % Button to finish adding groups
            finishButton = uibutton(mainLayout, 'Text', 'Finish');
            finishButton.Layout.Row = 5;
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
                groupLabel = uilabel(groupLayout, 'Text', ['Group ' num2str(numRows-1) ' – name:']);
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
                categorizationName = nameField.Value{1};
                % Resume after closing the dialog
                uiresume(fig); % Continue the paused execution
            end
        
            % Function to handle the close request when the user presses the X button
            function cancelDialog(figHandle)
                % Delete the figure and resume the UI so it continues without 'Finish'
                delete(figHandle);
            end
        end
    end
end