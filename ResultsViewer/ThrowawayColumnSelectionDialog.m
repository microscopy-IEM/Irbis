
% ThrowawayColumnSelectionDialog.m
classdef ThrowawayColumnSelectionDialog < handle
    properties (Access = private)
        UIFigure
        ModalityDropDown
        BranchDropDown
        CheckBoxTree
        MissingColumnsCheckBoxTree
        ApplyButton
        CancelButton

        appStateManagerHandle
        selectionStateHandle
    end

    methods
        function obj = ThrowawayColumnSelectionDialog(appStateManager, selectionState)
            obj.appStateManagerHandle = appStateManager;
            obj.selectionStateHandle = selectionState;
            obj.buildUI();
        end

        function show(obj)
            obj.UIFigure.Visible = 'on';
            uiwait(obj.UIFigure);
        end
    end

methods (Access = private)
        function buildUI(obj)
            obj.UIFigure = uifigure('Name', 'Select column to exclude from storing', 'Position', [100 100 300 500], ...
            'Visible', 'off');

            % Modality Dropdown
            uilabel(obj.UIFigure, 'Text', 'Modality:', 'Position', [10 470 60 22]);
            obj.ModalityDropDown = uidropdown(obj.UIFigure, ...
                'Position', [80 470 100 22], ...
                'Items', obj.appStateManagerHandle.getAvailableModalities(), ...
                'ValueChangedFcn', @(src, evt)obj.refreshBranchAndCheckboxes());

            % Branch Dropdown
            uilabel(obj.UIFigure, 'Text', 'Branch:', 'Position', [10 440 60 22]);
            obj.BranchDropDown = uidropdown(obj.UIFigure, ...
                'Position', [80 440 100 22], ...
                'ValueChangedFcn', @(src, evt)obj.refreshCheckboxes());

            % List of checkboxes - ticked columns are excluded from storing
            obj.CheckBoxTree = uitree(obj.UIFigure, 'checkbox',...
                'Position', [10 170 280 260], ...
                'CheckedNodesChangedFcn', @(src, evt)obj.storeCurrentColumnSelection());

            % List of checkboxes for columns that are excluded but not present in the table
            uilabel(obj.UIFigure, 'Text', 'Missing excluded columns:', 'Position', [10 141 200 22]);
            obj.MissingColumnsCheckBoxTree = uitree(obj.UIFigure, 'checkbox', ...
                'Position', [10 45 280 95], ...
                'CheckedNodesChangedFcn', @(src, evt)obj.storeCurrentColumnSelection());

            % Buttons
            obj.CancelButton = uibutton(obj.UIFigure, ...
                'Text', 'Cancel', ...
                'Position', [30 10 100 30], ...
                'ButtonPushedFcn', @(btn, event)obj.closeDialog());

            obj.ApplyButton = uibutton(obj.UIFigure, ...
                'Text', 'Apply', ...
                'Position', [160 10 100 30], ...
                'ButtonPushedFcn', @(btn,event) obj.onApply());

            % On closing the dialog window
            obj.UIFigure.CloseRequestFcn = @(src, event)obj.closeDialog();

            obj.refreshBranchAndCheckboxes();
        end

        function refreshBranchAndCheckboxes(obj)
            modality = obj.ModalityDropDown.Value;
            branches = obj.appStateManagerHandle.getAvailableBranches(modality);

            if isempty(branches)
                obj.BranchDropDown.Items = {};
                obj.BranchDropDown.Enable = 'off';
            else
                obj.BranchDropDown.Items = branches;
                obj.BranchDropDown.Value = branches{1};
                obj.BranchDropDown.Enable = 'on';
            end

            obj.refreshCheckboxes();
        end

        function refreshCheckboxes(obj)
            % Remove existing nodes if present
            if ~isempty(obj.CheckBoxTree.Children) && isvalid(obj.CheckBoxTree)
                % obj.storeCurrentColumnSelection();  % store here, because afterwards, the selection will be lost
                delete(obj.CheckBoxTree.Children);
            end

            modalityDataStoreHandle = obj.appStateManagerHandle.getModalityDataStore();

            modality = obj.ModalityDropDown.Value;
            branch = obj.BranchDropDown.Value;

            if isempty(branch)
                modalityPath = {modality};
            else
                modalityPath = {modality, branch};
            end
            dataStoreHandle = modalityDataStoreHandle.getModalityData(modalityPath);
            tableStoreHandle = dataStoreHandle.getTableStore();
            columnNames = tableStoreHandle.getColumnNames();

            if obj.selectionStateHandle.hasSelection(modality, branch)
                preSelected = obj.selectionStateHandle.getSelection(modality, branch);
            else
                preSelected = {};
            end

            for i = 1:numel(columnNames)
                col = columnNames{i};
                uitreenode(obj.CheckBoxTree, 'Text', col);
            end

            checkNodesByName(obj.CheckBoxTree, preSelected);

            % Find columns in preSelected but not in columnNames
            missingColumns = setdiff(preSelected, columnNames);

            % Add missing columns to the MissingColumnsCheckBoxTree
            if ~isempty(obj.MissingColumnsCheckBoxTree.Children) && isvalid(obj.MissingColumnsCheckBoxTree)
                delete(obj.MissingColumnsCheckBoxTree.Children);
            end

            for i = 1:numel(missingColumns)
                col = missingColumns{i};
                uitreenode(obj.MissingColumnsCheckBoxTree, 'Text', col);
            end

            checkNodesByName(obj.MissingColumnsCheckBoxTree, missingColumns);
        end

        function onApply(obj)
            % obj.storeCurrentColumnSelection();

            uiresume(obj.UIFigure);
            delete(obj.UIFigure);
        end

        function closeDialog(obj)
            if isvalid(obj.UIFigure)
                uiresume(obj.UIFigure);  % In case showDialog is blocking
                delete(obj.UIFigure);
            end
        end

        function storeCurrentColumnSelection(obj)
            modality = obj.ModalityDropDown.Value;
            branch = obj.BranchDropDown.Value;

            % Extract checked column names
            checkedNodes = obj.CheckBoxTree.CheckedNodes;
            selectedCols = arrayfun(@(n) n.Text, checkedNodes, 'UniformOutput', false);

            % Combine checked columns from both CheckBoxTree and MissingColumnsCheckBoxTree
            checkedMissingNodes = obj.MissingColumnsCheckBoxTree.CheckedNodes;
            missingCols = arrayfun(@(n) n.Text, checkedMissingNodes, 'UniformOutput', false);

            % Merge the selected columns and excluded columns
            selectedCols = unique([selectedCols; missingCols]);

            obj.selectionStateHandle.setSelection(modality, branch, selectedCols);
        end
    end
end