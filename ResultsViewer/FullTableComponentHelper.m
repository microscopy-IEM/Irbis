classdef FullTableComponentHelper < handle

    properties (Access = private)
        dataStoreHandle
        tableStoreHandle
        stateManagerHandle

        componentHandle
        treeHandle

        activeColumns

        templateNames = {}
        templates = {}

        tableStoreListener
        stateManagerListener

        templateFileName = 'IrbisApp_columnDefinitionTemplates_fullTable.mat'
            % this could be a constant, but that requires putting the class name in front of it and that is too long 
            % and I am goo lazy to do that
    end

    events
        tableDataChanged
        templatesChanged
    end

    methods
        function obj = FullTableComponentHelper()
        end

        function setHandles(obj, stateManagerHandle, dataStoreHandle, componentHandle)
            % set the handles for the tree and other components
            obj.stateManagerHandle = stateManagerHandle;
            obj.stateManagerListener = addlistener(obj.stateManagerHandle, 'newModalityLoaded', @(~,~)replaceData(obj));

            obj.componentHandle = componentHandle;
            obj.treeHandle = obj.componentHandle.getTreeHandle();

            obj.dataStoreHandle = dataStoreHandle;
            obj.loadData();

            % I will add template loading here - in the future, it can be potentially moved elsewhere based on what are templates specific for
            obj.loadInternallyStoredTemplates();
        end

        function setState(obj, processorState)
            % set the state of the processor
            if isfield(processorState, 'activeColumns')
                obj.activeColumns = processorState.activeColumns;
            end
            obj.checkNodesByNodeData(obj.treeHandle, obj.activeColumns);
        end

        function delete(obj)
            % delete the listeners
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
        end


        function calculateTreeData(obj)
            % disp('calculateTreeData called');
            delete(obj.treeHandle.Children); % delete all nodes in the tree
            obj.treeHandle.CheckedNodes = []; % clear checked nodes
            % numeric parameters
            columnNamesNumeric = obj.tableStoreHandle.getPredefinedColumnNamesByCondition('isnumeric');
            if ~isempty(columnNamesNumeric)
                numericalNode = uitreenode(obj.treeHandle,'Text','numerical');
                for i = 1:length(columnNamesNumeric)
                    name = columnNamesNumeric{i};
                    node = uitreenode(numericalNode,'Text', name, 'NodeData', name);
                    contextMenu = PredefinedColumnContextMenu(node, name, obj);
                    contextMenu.assignTo(node);
                end
            end
        
            % categorical parameters
            columnNamesCategorical = obj.tableStoreHandle.getPredefinedColumnNamesByCondition('iscategorical');
            if ~isempty(columnNamesCategorical)
                categoricalNode = uitreenode(obj.treeHandle,'Text','categorical','Tag','catTreenode');
                for i = 1:length(columnNamesCategorical)
                    name = columnNamesCategorical{i};
                    node = uitreenode(categoricalNode,'Text',name, 'NodeData',name);
                    contextMenu = PredefinedColumnContextMenu(node, name, obj);
                    contextMenu.assignTo(node);
                end
            end
        
            % cell parameters
            columnNamesCell = obj.tableStoreHandle.getPredefinedColumnNamesByCondition('iscell');
            if ~isempty(columnNamesCell)
                cellNode = uitreenode(obj.treeHandle,'Text','cell');
                for i = 1:length(columnNamesCell)
                    name = columnNamesCell{i};
                    node = uitreenode(cellNode,'Text', name, 'NodeData', name);
                    contextMenu = PredefinedColumnContextMenu(node, name, obj);
                    contextMenu.assignTo(node);
                end
            end

            % user defined parameters
            columnNamesUserDefined = obj.tableStoreHandle.getUserDefinedColumnNames();
            columnNamesEditable = obj.tableStoreHandle.getEditableColumnNames();
            if ~isempty(columnNamesUserDefined)
                userDefinedNode = uitreenode(obj.treeHandle,'Text','user-defined');
                for i = 1:length(columnNamesUserDefined)
                    name = columnNamesUserDefined{i};
                    node = uitreenode(userDefinedNode,'Text', name, 'NodeData', name);
                    contextMenu = UserDefinedColumnContextMenu(node, name, obj);
                    contextMenu.assignTo(node);
                    if ismember(name, columnNamesEditable)
                        node.Tag = 'editable';
                    end
                end
            end

            % check nodes in obj.activeColumns
            expand(obj.treeHandle,'all')

            obj.checkNodesByNodeData(obj.treeHandle, obj.activeColumns);
        end


        function checkNodesByNodeData(~, tree, nodeNames)
            checkedNodes = cell(1, length(nodeNames));
            nodeCount = 0;
            for i = 1:length(nodeNames)
                % Find the node with the specific name
                nodeName = nodeNames{i};
                node = findobj(tree.Children, 'NodeData', nodeName);
                % get(node)
                
                if ~isempty(node)
                    nodeCount = nodeCount + 1;
                    checkedNodes{nodeCount} = node;
                else
                    % warning('Node with name "%s" not found.', nodeName);
                    fprintf('Node with name "%s" not found.', nodeName);
                end
            end
            tree.CheckedNodes = [checkedNodes{1:nodeCount}];
        end


        function removeColumn(obj, columnName)
            % remove the column from the raw data

            obj.tableStoreHandle.removeColumn(columnName);

            % remove the column from the tree
            % if ~isempty(node)
            %     delete(node);
            % end
            % NOT NECESSARY - will be reloaded completely

            % remove the column from the active columns
            obj.activeColumns = obj.activeColumns(~strcmp(obj.activeColumns, columnName));
        end


        function renameColumn(obj, oldName, newName)
            % rename the column in the raw data
            obj.tableStoreHandle.renameColumn(oldName, newName);

            % % rename the column in the tree
            % if ~isempty(node)
            %     node.Text = newName;
            %     node.NodeData = newName;
            % end
                % NOT NECESSARY - will be reloaded completely

            % remove old name from active columns if it exists
            obj.activeColumns = obj.activeColumns(~strcmp(obj.activeColumns, oldName));
        end

        function editColumnDefinition(obj, columnName)
            
            userColumnDefinition = obj.tableStoreHandle.getUserColumnDefinition(columnName);
            definitionType = userColumnDefinition.getDefinitionType();

            switch definitionType
                case 'categorization'
                    % open the dialog to edit the categorization
                    data = obj.tableStoreHandle.getTableData();
                    % [newName, conditions] = categorizationDefinitionWindow(data, 1, CategorizationStorage(), userColumnDefinition);
                    [newName, conditions] = CategorizationColumnDefinitionDialog.showExisting(data, userColumnDefinition);

                    if isequal(newName, columnName)
                        userColumnDefinition.replaceRules(conditions);
                        newColumnData = userColumnDefinition.generateColumn(data);
                        obj.tableStoreHandle.updateUserDefinedColumn(columnName, newColumnData, userColumnDefinition);
                    else
                        % extract the categorization and store it
                        newCategorization = Categorization(newName, conditions);
                        % apply it to the table
                        newColumnData = newCategorization.generateColumn(data);
                        obj.tableStoreHandle.addUserDefinedColumn(newName, newColumnData, newCategorization); 
                    end

                case 'formula'

                    existingColumnName = userColumnDefinition.getColumnName();
                    existingFormula = userColumnDefinition.getRules();
                    [columnName, formulaString] = FormulaColumnDefinitionDialog.showExisting(existingColumnName, existingFormula);

                    if ~isempty(columnName) && ~isempty(formulaString)
                        data = obj.tableStoreHandle.getTableData();
                        if isequal(existingColumnName, columnName)
                            userColumnDefinition.replaceRules(formulaString);
                            newColumnData = userColumnDefinition.generateColumn(data);
                            obj.tableStoreHandle.updateUserDefinedColumn(columnName, newColumnData, userColumnDefinition);
                        else
                            % create the column definition object
                            columnDefinitionObject = FormulaColumnDefinition(columnName, formulaString);
                            % apply the formula to the table
                            newColumnData = columnDefinitionObject.generateColumn(data);
                            obj.tableStoreHandle.addUserDefinedColumn(columnName, newColumnData, columnDefinitionObject); % add the new column to the table store
                        end
                    end

                case 'merged'

                    categoricalOrNumericColumnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});
                    
                    if ~isempty(categoricalOrNumericColumnNames)  
                        existingColumnName = userColumnDefinition.getColumnName();  
                        [name, formula] = MergedColumnDefinitionDialog.showExisting(categoricalOrNumericColumnNames, existingColumnName);

                        if ~isempty(name) && ~isempty(formula)
                            if isequal(existingColumnName, name)
                                % no name change means that the rules did not change -> do not do anything
                            else
                                % create the column definition object
                                columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                                % apply the formula to the table
                                data = obj.tableStoreHandle.getTableData();
                                newColumnData = columnDefinitionObject.generateColumn(data);
                                obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject); % add the new column to the table store
                            end
                        end
                    end

                case 'manual'

                    existingColumnName = userColumnDefinition.getColumnName();
                    existingGroupNames = userColumnDefinition.getGroupNames();
                    [name, groupNames] = ManualColumnDefinitionDialog.showExisting(existingColumnName, existingGroupNames); 

                    if ~isempty(name) && ~isempty(groupNames)
                        data = obj.tableStoreHandle.getTableData();
                        columnArray = data.(existingColumnName);

                        if isequal(existingColumnName, name)
                            % Determine added, renamed, and removed group names
                            addedGroups = groupNames(length(existingGroupNames) + 1:end);
                            columnArray = addcats(columnArray, addedGroups);
                            
                            removedGroupsIdx = find(cellfun('isempty', groupNames));
                            removedGroupsIdx = removedGroupsIdx(removedGroupsIdx <= length(existingGroupNames));
                            removedGroups = existingGroupNames(removedGroupsIdx);
                            columnArray = removecats(columnArray, removedGroups);

                            renamedGroupsIdx = find(~cellfun('isempty', groupNames) & ~strcmp(existingGroupNames, groupNames));
                            % Keep only renamedGroupsIdx with value max length of existingGroupNames
                            renamedGroupsIdx = renamedGroupsIdx(renamedGroupsIdx <= length(existingGroupNames));
                            oldGroupNames = existingGroupNames(renamedGroupsIdx);
                            newGroupNames = groupNames(renamedGroupsIdx);
                            columnArray = renamecats(columnArray, oldGroupNames, newGroupNames);

                            userColumnDefinition.replaceRules(groupNames);
                            obj.tableStoreHandle.updateUserDefinedColumn(columnName, columnArray, userColumnDefinition);
                        else
                            % create the column definition object
                            groupNames = groupNames(~cellfun('isempty', groupNames));
                            columnDefinitionObject = ManualColumnDefinition(name, groupNames);
                            newColumnData = columnDefinitionObject.generateColumn(data);
                            obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject);
                            obj.tableStoreHandle.makeColumnEditable(name);
                        end
                    end
            end   
        end


        function duplicateColumnDefinition(obj, columnName)
            userColumnDefinition = obj.tableStoreHandle.getUserColumnDefinition(columnName);

            existingNames = obj.tableStoreHandle.getUserDefinedColumnNames();
            newName = FullTableComponentHelper.getUnusedNameCopy(columnName, existingNames);

            rules = userColumnDefinition.getRules();
            definitionType = userColumnDefinition.getDefinitionType();

            switch definitionType   % TO OPTIMIZE - this should be extracted, we depend on specifics here
                % doing this is required because doing a deep copy of the object is not possible
                case 'categorization'
                    newColumnDefinition = Categorization(newName, rules);
                case 'formula'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                case 'merged'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                    newColumnDefinition.setDefinitionType('merged');
                case 'manual'
                    newColumnDefinition = ManualColumnDefinition(newName, rules);
            end

            newColumnData = userColumnDefinition.generateColumn(obj.tableStoreHandle.getTableData());
            obj.tableStoreHandle.addUserDefinedColumn(newName, newColumnData, newColumnDefinition);
            if strcmp(definitionType, 'manual')
                obj.tableStoreHandle.makeColumnEditable(newName);
            end
        end


        function storeDefinitionAsTemplate(obj, columnName)
            % store the column definition as a template
            userColumnDefinition = obj.tableStoreHandle.getUserColumnDefinition(columnName);
            definitionType = userColumnDefinition.getDefinitionType();

            existingNames = obj.templateNames;
            newName = FullTableComponentHelper.getUnusedNameCopy(columnName, existingNames);

            rules = userColumnDefinition.getRules();
            switch definitionType   % TO OPTIMIZE - this should be extracted, we depend on specifics here
                case 'categorization'
                    newColumnDefinition = Categorization(newName, rules);
                case 'formula'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                case 'merged'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                    newColumnDefinition.setDefinitionType('merged');
                case 'manual'
                    newColumnDefinition = ManualColumnDefinition(newName, rules);
            end

            obj.templateNames{end + 1} = newName;   % this should be subsequently displayed in the GUI 
                % TO IMPLEMENT - check, which templates are usable
            obj.templates{end + 1} = newColumnDefinition;

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
            notify(obj, 'templatesChanged'); % will notify the GUI about the change
        end


        function addTemplate(obj, type)
            switch type
                case 'Add categorization'
                    % display user interface to create a new column
                    data = obj.tableStoreHandle.getTableData();
                    n = obj.tableStoreHandle.getNumDefinitionsOfType('categorization');

                    [name, conditions] = CategorizationColumnDefinitionDialog.show(data, n); % open the dialog to define the new column
        
                    % extract the categorization and store it
                    newCategorization = Categorization(name, conditions);

                    % apply it to the table
                    newColumnData = newCategorization.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, newCategorization);                   

            case 'Add formula'
                % display user interface to create a new column
                data = obj.tableStoreHandle.getTableData();
                [name, formula] = FormulaColumnDefinitionDialog.show(); % open the dialog to define the new column
                
                if ~isempty(name) && ~isempty(formula)
                    columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                    % apply the formula to the table
                    newColumnData = columnDefinitionObject.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject); % add the new column to the table store
                end

            case 'Add merged'

                categoricalOrNumericColumnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});

                if ~isempty(categoricalOrNumericColumnNames)    
                    [name, formula] = MergedColumnDefinitionDialog.show(categoricalOrNumericColumnNames);

                    if ~isempty(name) && ~isempty(formula)
                        % create the column definition object
                        columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                        % apply the formula to the table
                        data = obj.tableStoreHandle.getTableData();
                        newColumnData = columnDefinitionObject.generateColumn(data);
                        obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject); % add the new column to the table store
                    end
                end

            case 'Add manual'

                [name, groupNames] = ManualColumnDefinitionDialog.show(); 

                if ~isempty(name) && ~isempty(groupNames)
                    % create the column definition object
                    columnDefinitionObject = ManualColumnDefinition(name, groupNames);
                    % apply the formula to the table
                    data = obj.tableStoreHandle.getTableData();
                    newColumnData = columnDefinitionObject.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject);
                    obj.tableStoreHandle.makeColumnEditable(name);
                end
            end

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
                % TO OPTIMIZE - saving all templates anew with every change might not be very efficient
            notify(obj, 'templatesChanged')
        end


        function removeTemplate(obj, templateName)
            % remove the template from the list of templates
            idx = find(strcmp(obj.templateNames, templateName), 1);
            if isempty(idx)
                disp(['template "', templateName, '" not found.']);
                return
            end

            obj.templateNames(idx) = [];
            obj.templates(idx) = [];

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
            notify(obj, 'templatesChanged')
        end


        function useTemplate(obj, templateName)
            % use the template to create a new column
            idx = find(strcmp(obj.templateNames, templateName), 1);
            if isempty(idx)
                disp(['template "', templateName, '" not found.']);
                return
            end
            userColumnDefinition = obj.templates{idx};
            columnName = userColumnDefinition.getColumnName();
            existingNames = obj.tableStoreHandle.getUserDefinedColumnNames();
            newName = FullTableComponentHelper.getUnusedNameCopy(columnName, existingNames);

            rules = userColumnDefinition.getRules();
            switch userColumnDefinition.getDefinitionType()   % TO OPTIMIZE - this should be extracted, we depend on specifics here
                case 'categorization'
                    newColumnDefinition = Categorization(newName, rules);
                case 'formula'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                case 'merged'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                    newColumnDefinition.setDefinitionType('merged');
                case 'manual'
                    newColumnDefinition = ManualColumnDefinition(newName, rules);
            end

            newColumnData = userColumnDefinition.generateColumn(obj.tableStoreHandle.getTableData());
            obj.tableStoreHandle.addUserDefinedColumn(newName, newColumnData, newColumnDefinition);
            if strcmp(userColumnDefinition.getDefinitionType(), 'manual')
                obj.tableStoreHandle.makeColumnEditable(newName);
            end
        end


        function editTemplate(obj, templateName)
            % Edit an existing template
            idx = find(strcmp(obj.templateNames, templateName), 1);
            if isempty(idx)
                disp('Template not found.');
                return;
            end

            userColumnDefinition = obj.templates{idx};
            definitionType = userColumnDefinition.getDefinitionType();

            switch definitionType
                case 'categorization'
                    % open the dialog to edit the categorization
                    data = obj.tableStoreHandle.getTableData();
                    % [newName, conditions] = categorizationDefinitionWindow(data, 1, CategorizationStorage(), userColumnDefinition);
                    [newName, conditions] = CategorizationColumnDefinitionDialog.showExisting(data, userColumnDefinition);

                    if isequal(newName, templateName)
                        userColumnDefinition.replaceRules(conditions);
                        obj.templates{idx} = userColumnDefinition; % This is not necessary, because for now, the userColumnDefinition is handle - it is changed automatically
                    else
                        % extract the categorization and store it
                        newCategorization = Categorization(newName, conditions);
                        obj.templates{idx} = newCategorization; % this way, we do not preserve the original settings with the original name (different for editing columns)
                        obj.templateNames{idx} = char(newName);
                    end

                case 'formula'

                    existingColumnName = userColumnDefinition.getColumnName();
                    existingFormula = userColumnDefinition.getRules();
                    [columnName, formulaString] = FormulaColumnDefinitionDialog.showExisting(existingColumnName, existingFormula);

                    if ~isempty(columnName) && ~isempty(formulaString)
                        if isequal(existingColumnName, columnName)
                            userColumnDefinition.replaceRules(formulaString);
                            obj.templates{idx} = userColumnDefinition; % This is not necessary, because for now, the userColumnDefinition is handle - it is changed automatically
                        else
                            % create the column definition object
                            columnDefinitionObject = FormulaColumnDefinition(columnName, formulaString);
                            obj.templates{idx} = columnDefinitionObject;
                            obj.templateNames{idx} = char(columnName);
                        end
                    end

                case 'merged'

                    categoricalOrNumericColumnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});
                    
                    if ~isempty(categoricalOrNumericColumnNames)  
                        existingColumnName = userColumnDefinition.getColumnName();  
                        [name, formula] = MergedColumnDefinitionDialog.showExisting(categoricalOrNumericColumnNames, existingColumnName);

                        if ~isempty(name) && ~isempty(formula)
                            if isequal(existingColumnName, name)
                                % no name change means that the rules did not change -> do not do anything
                            else
                                % create the column definition object
                                columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                                obj.templates{idx} = columnDefinitionObject;
                                obj.templateNames{idx} = char(name);
                            end
                        end
                    end

                case 'manual'

                    existingColumnName = userColumnDefinition.getColumnName();
                    existingGroupNames = userColumnDefinition.getGroupNames();
                    [name, groupNames] = ManualColumnDefinitionDialog.showExisting(existingColumnName, existingGroupNames); 

                    if ~isempty(name) && ~isempty(groupNames)
                        if isequal(existingColumnName, name)
                            userColumnDefinition.replaceRules(groupNames);
                            obj.templates{idx} = userColumnDefinition; % This is not necessary, because for now, the userColumnDefinition is handle - it is changed automatically
                        else
                            % create the column definition object
                            groupNames = groupNames(~cellfun('isempty', groupNames));
                            columnDefinitionObject = ManualColumnDefinition(name, groupNames);
                            obj.templates{idx} = columnDefinitionObject;
                            obj.templateNames{idx} = char(name);
                        end
                    end
            end

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
            notify(obj, 'templatesChanged')
        end


        function duplicateTemplate(obj, templateName)
            % Duplicate an existing template
            idx = find(strcmp(obj.templateNames, templateName), 1);
            if isempty(idx)
                disp('Template not found.');
                return;
            end

            userColumnDefinition = obj.templates{idx};
            existingNames = obj.templateNames;
            newName = FullTableComponentHelper.getUnusedNameCopy(templateName, existingNames);

            rules = userColumnDefinition.getRules();
            definitionType = userColumnDefinition.getDefinitionType();

            switch definitionType
                case 'categorization'
                    newColumnDefinition = Categorization(newName, rules);
                case 'formula'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                case 'merged'
                    newColumnDefinition = FormulaColumnDefinition(newName, rules);
                    newColumnDefinition.setDefinitionType('merged');
                case 'manual'
                    newColumnDefinition = ManualColumnDefinition(newName, rules);
            end

            obj.templateNames{end + 1} = newName;
            obj.templates{end + 1} = newColumnDefinition;
            disp(['Template "', templateName, '" duplicated as "', newName, '".']);

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
            notify(obj, 'templatesChanged')
        end


        function exportTemplates(obj)
            % Default directory for save dialog
            if ispc
                % Windows
                defaultDir = fullfile(getenv('USERPROFILE'), 'Documents');
            else
                % macOS/Linux
                defaultDir = fullfile(getenv('HOME'), 'Documents');
            end
            defaultFileName = 'IrbisApp_columnDefinitionTemplates.mat';
        
            % Open a save dialog to let the user choose the location
            [file, path] = uiputfile('*.mat', 'Save templates as', fullfile(defaultDir, defaultFileName));
            
            % Check if the user canceled the dialog
            if isequal(file, 0)
                disp('User canceled the save operation.');
                return;
            end
            
            % Construct the full file path from user selection
            settingsFileName = fullfile(path, file);
            
            % Save the data to the specified location
            templatesToStore = obj.templates;
            templateType = 'full';
            save(settingsFileName, 'templatesToStore', 'templateType');
            disp(['Templates saved to: ', settingsFileName]);
        end


        function importTemplates(obj)
            % Default directory for open dialog
            if ispc
                % Windows
                defaultDir = fullfile(getenv('USERPROFILE'), 'Documents');
            else
                % macOS/Linux
                defaultDir = fullfile(getenv('HOME'), 'Documents');
            end
            
            % Open a file selection dialog to let the user choose the file
            [file, path] = uigetfile('*.mat', 'Select templates file to import', defaultDir);
            
            % Check if the user canceled the dialog
            if isequal(file, 0)
                disp('User canceled the import operation.');
                return;
            end
            
            % Construct the full file path from user selection
            settingsFileName = fullfile(path, file);

            % Load the data from the specified file
            loadedData = load(settingsFileName, 'templatesToStore', 'templateType');

            if ~strcmp(loadedData.templateType, 'full')
                disp('The selected file does not contain the correct template type.');
                return;
            end
            
            if isfield(loadedData, 'templatesToStore')
                importedTemplates = loadedData.templatesToStore;
                for i = 1:length(importedTemplates)
                    template = importedTemplates{i};
                    templateName = template.getColumnName();
                    
                    % Ensure unique template names
                    existingNames = obj.templateNames;
                    uniqueName = FullTableComponentHelper.getUnusedNameCopy(templateName, existingNames);
                    
                    obj.templateNames{end + 1} = uniqueName;
                    template.setColumnName(uniqueName); % Update the name in the template
                    obj.templates{end + 1} = template;
                end
                disp('Templates imported successfully.');
            else
                disp('No templates found in the selected file.');
            end

            fig = ancestor(obj.componentHandle, 'figure');
            saveToSettingsFolder(obj.templates, obj.templateFileName, fig);    % atm, I will make a separate folder for each table type
            notify(obj, 'templatesChanged')
        end


        function templateNames = getTemplateNames(obj)
            templateNames = obj.templateNames
        end


        function setActiveColumns(obj, activeColumns)
            % set the active columns in the tree
            obj.activeColumns = activeColumns;
        end


        function replaceData(obj)
            obj.dataStoreHandle = obj.stateManagerHandle.getActiveDataStore();
            obj.loadData();
        end


        function loadData(obj)
            obj.tableStoreHandle = obj.dataStoreHandle.getTableStore();

            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end

            obj.activeColumns = intersect(obj.activeColumns, obj.tableStoreHandle.getColumnNames());
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~,~)calculateTreeData(obj));

            obj.calculateTreeData();
        end


        function loadInternallyStoredTemplates(obj)
            [primaryFolder, fallbackFolder] = getSettingsFolder;

            % By default, settings should now be saved in Users\user\AppData\Roaming
                % if it is not there, look into the Public folder
            settingsExist = 0;
            if exist(primaryFolder, 'dir')
                filename = fullfile(primaryFolder, obj.templateFileName);
                if isfile(filename)
                    settingsExist = 1;
                end
            end
            if ~settingsExist && exist(fallbackFolder, 'dir')
                filename = fullfile(fallbackFolder, obj.templateFileName);
                if isfile(filename)
                    settingsExist = 1;
                end
            end

            if settingsExist
                % fileContent = importdata(filename);
                % assignin("base", "fileContent", fileContent); % for debugging purposes
                % fileContent = fileContent.data;  % The saveToSettingsFolder function saves the data in a struct with the field 'data'
                % if isfield(fileContent, 'templates')
                    % obj.templates = fileContent.templates;
                    obj.templates = importdata(filename);
                    obj.templateNames = cellfun(@(template) template.getColumnName(), obj.templates, 'UniformOutput', false);
                % else
                %     disp('No templates found in the internal settings file.');
                % end
            else
                disp('No internal settings file found. Templates will not be loaded.');
            end
            
        end


        function createUserDefinedColumn(obj, type)
            switch type
                case 'Add categorization'
                    % display user interface to create a new column
                    data = obj.tableStoreHandle.getTableData();
                    n = obj.tableStoreHandle.getNumDefinitionsOfType('categorization');

                    [name, conditions] = CategorizationColumnDefinitionDialog.show(data, n); % open the dialog to define the new column
        
                    % extract the categorization and store it
                    newCategorization = Categorization(name, conditions);

                    % apply it to the table
                    newColumnData = newCategorization.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, newCategorization);                   

            case 'Add formula'
                % display user interface to create a new column
                data = obj.tableStoreHandle.getTableData();
                [name, formula] = FormulaColumnDefinitionDialog.show(); % open the dialog to define the new column
                
                if ~isempty(name) && ~isempty(formula)
                    columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                    % apply the formula to the table
                    newColumnData = columnDefinitionObject.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject); % add the new column to the table store
                end

            case 'Add merged'

                categoricalOrNumericColumnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric'});

                if ~isempty(categoricalOrNumericColumnNames)    
                    [name, formula] = MergedColumnDefinitionDialog.show(categoricalOrNumericColumnNames);

                    if ~isempty(name) && ~isempty(formula)
                        % create the column definition object
                        columnDefinitionObject = FormulaColumnDefinition(name, formula); % create the column definition object
                        % apply the formula to the table
                        data = obj.tableStoreHandle.getTableData();
                        newColumnData = columnDefinitionObject.generateColumn(data);
                        obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject); % add the new column to the table store
                    end
                end

            case 'Add manual'

                [name, groupNames] = ManualColumnDefinitionDialog.show(); 

                if ~isempty(name) && ~isempty(groupNames)
                    % create the column definition object
                    columnDefinitionObject = ManualColumnDefinition(name, groupNames);
                    % apply the formula to the table
                    data = obj.tableStoreHandle.getTableData();
                    newColumnData = columnDefinitionObject.generateColumn(data);
                    obj.tableStoreHandle.addUserDefinedColumn(name, newColumnData, columnDefinitionObject);
                    obj.tableStoreHandle.makeColumnEditable(name);
                end
            end
        end

        function editManualColumnValue(obj, columnName, rowName, newValue)
            % edit the values in the manual column
            obj.tableStoreHandle.editManualColumnValue(columnName, rowName, newValue);
        end
    end


    methods (Static, Access = private)
        function newName = getUnusedNameCopy(columnName, existingNames)

            % Check if the columnName is not used at all
            if ~any(strcmp(existingNames, columnName))
                newName = columnName;
                return;
            end

            % Initialize a set to track used numbers
            usedNumbers = false(1, 1000); % Assuming a reasonable upper limit for numbers

            % Generate a regular expression pattern to find versions of the name
            pattern = strcat('^', regexptranslate('escape', columnName), '_(\d+)$');
            
            % Loop through the list and find all names that match the pattern
            for i = 1:length(existingNames)
                currentName = existingNames{i};
                
                % Check for columnName_num format
                tokens = regexp(currentName, pattern, 'tokens');
                if ~isempty(tokens)
                    number = str2double(tokens{1}{1});
                    if number > 0
                    usedNumbers(number) = true; % Mark the number as used
                    end
                end
            end
            
            % Find the lowest unused number
            origNum = find(~usedNumbers, 1);
            
            % Assign the new name with the lowest possible number
            newName = sprintf('%s_%d', columnName, origNum);
        end
    end
end