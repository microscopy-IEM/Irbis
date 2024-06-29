function [name, conditions] = categorizationDefinitionWindow(varargin)
    % Create a sample table data
    if isempty(varargin)
        tableData = table({'A'; 'B'; 'C'}, [1; 2; 3], [4; 5; 6], 'VariableNames', {'Col1', 'Col2', 'Col3'});
        numberOfExistingCategorizations = 0;
        storedCategorizations = CategorizationStorage();
    else
        tableData = varargin{1};
        numberOfExistingCategorizations = varargin{2};
        storedCategorizations = varargin{3};
    end

    % Create a new figure for grouping window
    groupingFig = uifigure('Name', 'Define Categories and Grouping Parameters');
    groupingFig.Position = [100 100 600 500];

    % Create a main grid layout
    mainGrid = uigridlayout(groupingFig, [4, 1]);
    mainGrid.RowHeight = {40, 40, '1x', 40};
    mainGrid.ColumnWidth = {'1x'};

    % Create a panel for load options
    saveLoadGrid = uigridlayout(mainGrid, [1, 3]);
    saveLoadGrid.ColumnWidth = {'1x', 120, 120};
    saveLoadGrid.Layout.Row = 1;
    saveLoadGrid.Layout.Column = 1;

    % Add dropdown to select saved settings
    loadDropdown = uidropdown(saveLoadGrid, 'Items', {'No settings to choose from'});
    loadDropdown.Layout.Row = 1;
    loadDropdown.Layout.Column = 1;
    loadDropdown.Tooltip = 'Select saved settings to load.';
    loadedItems = storedCategorizations.returnCategorizationNames;
    % loadedItems{end+1} = 'Select settings to load...';
    loadDropdown.Items = loadedItems;
    % loadDropdown.Value = 'Select settings to load...';
    % loadDropdown.ValueChangedFcn = @(src,event) loadDropdownValueChanged(src);

    % Add Delete and Load buttons

    loadButton = uibutton(saveLoadGrid, 'push', 'Text', 'Load Settings');
    loadButton.Layout.Row = 1;
    loadButton.Layout.Column = 2;
    loadButton.ButtonPushedFcn = @(btn, event) loadSettings();
    loadButton.Tooltip = 'Load the currently selected settings.';

    deleteSavedSettingsButton = uibutton(saveLoadGrid, 'push', 'Text', 'Delete Settings');
    deleteSavedSettingsButton.Layout.Row = 1;
    deleteSavedSettingsButton.Layout.Column = 3;
    deleteSavedSettingsButton.ButtonPushedFcn = @(btn, event) deleteSavedSettings();
    deleteSavedSettingsButton.Tooltip = 'Delete the currently selected settings from the stored settings.';

    % Create a panel for naming the categorization
    namingGrid = uigridlayout(mainGrid, [1, 2]);
    namingGrid.ColumnWidth = {120,'1x'};
    namingGrid.Layout.Row = 2;
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
    categoryScrollPanel.Layout.Row = 3;
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
    buttonGrid.Layout.Row = 4;
    buttonGrid.Layout.Column = 1;

    % Add a plus button to add categories
    categoryPlusButton = uibutton(buttonGrid, 'push', 'Text', 'Add category');
    categoryPlusButton.Layout.Row = 1;
    categoryPlusButton.Layout.Column = 1;
    categoryPlusButton.ButtonPushedFcn = @(btn, event) addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);
    categoryPlusButton.Tooltip = 'Define new category.';

    % Add a save button
    saveButton = uibutton(buttonGrid, 'push', 'Text', 'Save categorization');
    saveButton.Layout.Row = 1;
    saveButton.Layout.Column = 2;
    saveButton.ButtonPushedFcn = @(btn, event) saveCategories(categoryScrollPanel);
    saveButton.Tooltip = 'Confirm the categorization definition and close the window.';

    addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);
    addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);
    uiwait(groupingFig)

    function [categoryPanel,criteriaGrid] = addCategoryPanel(categoryGrid, tableData, scrollPanel)
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
        criteriaGrid.ColumnWidth = {'1x', 100, '1x', 70};
        criteriaGrid.Scrollable = 'on';

        % Add a plus button to add criteria for this category
        criteriaPlusButton = uibutton(panelGrid, 'push', 'Text', 'Add criteria');
        criteriaPlusButton.Layout.Row = 1;
        criteriaPlusButton.Layout.Column = 3;
        criteriaPlusButton.ButtonPushedFcn = @(btn, event) addCriteriaRow(criteriaGrid, tableData, categoryPanel);
        criteriaPlusButton.Tooltip = 'Add new criterion for the category definition.';

        % Store UI components for dynamic management
        categoryPanel.UserData.CriteriaComponents = {}; % Store criteria components

        % Keep track of category panels
        scrollPanel.UserData.CategoryPanels{end+1} = categoryPanel;

        n = numel(categoryGrid.Children);
        categoryGrid.RowHeight = [repmat({'fit'}, 1, n), {5000}];

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
        columnDropdown.ValueChangedFcn = @(dd, event) updateCriteriaRow(dd, criteriaGrid, tableData, newRow, categoryPanel);
        columnDropdown.Tooltip = 'Select the variable to base the categorization on.';

        % Create a dropdown for operators
        operatorDropdown = uidropdown(criteriaGrid, 'Tag', 'operatorDropdown');
        operatorDropdown.Layout.Row = newRow;
        operatorDropdown.Layout.Column = 2;
        operatorDropdown.Items = {'equals', 'lessThan', 'greaterThan'};

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

    function updateCriteriaRow(dd, criteriaGrid, tableData, row, categoryPanel)
        column = dd.Value;
        if iscategorical(tableData.(column))
            % Categorical variable
            updateToCategoricalCriteria(criteriaGrid, row, tableData.(column), categoryPanel);
        else
            % Numeric variable
            updateToNumericCriteria(criteriaGrid, row, categoryPanel);
        end
    end

    function updateToCategoricalCriteria(criteriaGrid, row, columnData, categoryPanel)
        % Update operator dropdown
        operatorDropdown = findComponent(criteriaGrid, row, 'operatorDropdown');
        operatorDropdown.Items = {'equals'};

        % Create a new tree with checkboxes for the value field
        cats = categories(columnData);
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
        operatorDropdown.Items = {'equals', 'lessThan', 'greaterThan'};

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
        conditions = struct();
        for i = 1:length(scrollPanel.UserData.CategoryPanels)
            categoryPanel = scrollPanel.UserData.CategoryPanels{i};
            categoryName = categoryPanel.Children(1).Children(1).Value; % Get the category name
            conditionsDict = dictionary(string.empty, {}); % Initialize with key and value types
            for j = 1:length(categoryPanel.UserData.CriteriaComponents)
                rowComponents = categoryPanel.UserData.CriteriaComponents{j};
                column = rowComponents{1}.Value;
                operator = rowComponents{2}.Value;

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
            conditions.(['group' num2str(i)]) = categoryStruct;
        end
        assignin('base', 'cats', conditions); % Save to workspace for further use
        disp(conditions)

        name = nameField.Value;

        uiresume(groupingFig);
        delete(groupingFig);
    end

    function loadSettings()
            categorizations = storedCategorizations.Categorizations;
            disp(categorizations);

            % Clear existing category panels
            for i = length(categoryScrollPanel.UserData.CategoryPanels):-1:1
                delete(categoryScrollPanel.UserData.CategoryPanels{i});
            end
            categoryScrollPanel.UserData.CategoryPanels = {};

            id = storedCategorizations.findCategorizationIndexByName(loadDropdown.Value);
            category = categorizations{id};
            fields = fieldnames(category.Conditions);
            for i = 1:numel(fields)
                [categoryPanel,criteriaGrid] = addCategoryPanel(categoryGrid, tableData, categoryScrollPanel);

                group = fields{i};
                groupName = category.Conditions.(group).name;
                conds = category.Conditions.(group).conditions;
                condFields = keys(conds);

                categoryPanel.Children(1).Children(1).Value = groupName; % Set the category name

                criteriaNum = 1;
                for j = 1:numel(condFields)
                    condValue = conds(condFields{j});
                    column = condFields{j};
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
                                addCriteriaRow(criteriaGrid, tableData, categoryPanel);
                            end
                            criteriaNum = criteriaNum + 1;
                        end
                    else
                        categoryPanel.UserData.CriteriaComponents{criteriaNum}{1}.Value = column;
                        dd = categoryPanel.UserData.CriteriaComponents{criteriaNum}{1};
                        updateCriteriaRow(dd,criteriaGrid,tableData,criteriaNum,categoryPanel);
                        checkNodesByName(categoryPanel.UserData.CriteriaComponents{criteriaNum}{3},condValue{1});
                        criteriaNum = criteriaNum + 1;
                    end
                    if ~isequal(j,numel(condFields))
                        addCriteriaRow(criteriaGrid, tableData, categoryPanel);
                    end
                end
            end

    end

    function deleteSavedSettings()
        storedCategorizations.deleteCategorization(loadDropdown.Value);
        idToDelete = strcmp(loadDropdown.Items,loadDropdown.Value);
        loadDropdown.Items(idToDelete) = [];
    end

    % function checkNodesByName(tree, nodeNames)
    %     checkedNodes = [];
    %     for i = 1:length(nodeNames)
    %         % Find the node with the specific name
    %         nodeName = nodeNames{i};
    %         node = findobj(tree.Children, 'Text', nodeName);
    %         % get(node)
    % 
    %         % Check if the node is found and check the box
    %         if ~isempty(node)
    %             checkedNodes = [checkedNodes,node];
    %         else
    %             warning('Node with name "%s" not found.', nodeName);
    %         end
    %     end
    %     tree.CheckedNodes = checkedNodes;
    % end

    % function loadDropdownValueChanged(src)
    %     % Get the selected value
    %     selectedValue = src.Value;
    % 
    %     % Check if the selected value is not 'Select settings to load...'
    %     if ~strcmp(selectedValue, 'Select settings to load...')
    %         % Process the selected value
    %         loadSettings
    % 
    %         % Reset the dropdown value back to 'Select settings to load...'
    %         src.Value = 'Select settings to load...';
    %     end
    % end

end