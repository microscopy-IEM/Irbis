classdef SummarizedTableComponentHelper < handle

    properties
        dataStoreHandle
        tableStoreHandle
        summarizedTableStoreHandle
        tableStateManagerHandle

        componentHandle
        treeHandle

        activeColumns

        rowParameter    % decides which summarized table is going to be used

        tableStoreListener
        summarizedTableListener
        stateManagerListener
    end

    events
        tableDataChanged
    end

    methods
        function obj = SummarizedTableComponentHelper()

        end

        function setHandles(obj, tableStateManagerHandle, dataStoreHandle, componentHandle)
            % set the handles for the tree and other components
            obj.tableStateManagerHandle = tableStateManagerHandle;
            obj.stateManagerListener = addlistener(obj.tableStateManagerHandle, 'newModalityLoaded', @(~,~)replaceData(obj));

            obj.componentHandle = componentHandle;
            obj.treeHandle = obj.componentHandle.getTreeHandle();

            obj.dataStoreHandle = dataStoreHandle;
 
            obj.loadData();
        end


        function delete(obj)
            % delete the listeners
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            if ~isempty(obj.summarizedTableListener) && isvalid(obj.summarizedTableListener)
                delete(obj.summarizedTableListener);
            end
            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
        end


        function setState(obj, processorState)
            % set the state of the processor
            if isfield(processorState, 'activeColumns')
                obj.activeColumns = processorState.activeColumns;
            end
            obj.checkNodesByNodeData(obj.treeHandle, obj.activeColumns);
        end


        function calculateTreeData(obj)
            % disp('calculateTreeData')
            delete(obj.treeHandle.Children); % delete all nodes in the tree
            parentNames = obj.summarizedTableStoreHandle.getParentNames();
            if ~isempty(parentNames)
                for i = 1:length(parentNames)
                    name = parentNames{i};
                    parentNode = uitreenode(obj.treeHandle,'Text', name, 'NodeData', name);
                    % contextMenu = PredefinedColumnContextMenu(node, name, obj);
                    % contextMenu.assignTo(node);

                    statisticalColumnNames = obj.summarizedTableStoreHandle.getStatisticalColumnNamesForParent(name);
                    if ~isempty(statisticalColumnNames)
                        for j = 1:length(statisticalColumnNames)
                            columnName = statisticalColumnNames{j};
                            node = uitreenode(parentNode,'Text', columnName, 'NodeData', columnName);
                            % contextMenu = PredefinedColumnContextMenu(node, columnName, obj);
                            % contextMenu.assignTo(node);
                        end
                    else
                        delete(parentNode)
                    end

                end

                obj.checkNodesByNodeData(obj.treeHandle, obj.activeColumns);
            end

            % user defined parameters
            columnNamesUserDefined = obj.summarizedTableStoreHandle.getUserDefinedColumnNames();
            columnNamesEditable = obj.summarizedTableStoreHandle.getEditableColumnNames();
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


        function setRowParameter(obj, rowParameter)
            % Set the row parameter for the summarized table
            obj.rowParameter = rowParameter;

            obj.loadDataForGrouping();
        end


        function setActiveColumns(obj, activeColumns)
            % Set the active columns for the summarized table
            obj.activeColumns = activeColumns;
        end


        function findAndSetRowParameters(obj)
            % disp('findAndSetRowParameters')
            categoricalParameters = obj.tableStoreHandle.getColumnNamesByCondition('iscategorical');

            obj.componentHandle.setParameterList(categoricalParameters);

            if isempty(categoricalParameters)
                return
            end

            if ~isempty(obj.rowParameter) && ismember(obj.rowParameter, categoricalParameters)
                obj.componentHandle.setRowParameter(obj.rowParameter);
            else
                obj.rowParameter = categoricalParameters{1};
                obj.componentHandle.setRowParameter(obj.rowParameter);
            end

            obj.loadDataForGrouping();
        end


        function createUserDefinedColumn(obj, type)
            % create a user defined column

            columnDefinitionObject = UserColumnDefinitionFactory.create(type, obj.summarizedTableStoreHandle);
            if isempty(columnDefinitionObject)
                return  % the user canceled the dialog or something went wrong
            end

            existingColumnNames = obj.summarizedTableStoreHandle.getColumnNames();
            requiredColumnNames = columnDefinitionObject.getRequiredColumnNames(existingColumnNames);

            requiredTableSubset = obj.summarizedTableStoreHandle.getTableSubsetByName(requiredColumnNames);
            newColumnData = columnDefinitionObject.generateColumn(requiredTableSubset);
            columnName = columnDefinitionObject.getColumnName();

            obj.summarizedTableStoreHandle.addUserDefinedColumn(columnName, newColumnData, columnDefinitionObject);
            if isequal(type, 'manual')
                obj.summarizedTableStoreHandle.makeColumnEditable(columnName);
            end
        end


        function removeColumn(obj, columnName)
            % remove a column from the data store
            obj.summarizedTableStoreHandle.removeColumn(columnName);

            obj.activeColumns = obj.activeColumns(~strcmp(obj.activeColumns, columnName));
        end


        function renameColumn(obj, oldName, newName)
            % rename a column in the data store
            obj.summarizedTableStoreHandle.renameColumn(oldName, newName);
            obj.activeColumns = obj.activeColumns(~strcmp(obj.activeColumns, oldName));
        end


        function editColumnDefinition(obj, columnName)

            userColumnDefinition = obj.summarizedTableStoreHandle.getUserColumnDefinition(columnName);
            definitionType = userColumnDefinition.getDefinitionType();

            newColumnDefinitionObject = UserColumnDefinitionFactory.redefine(definitionType, obj.summarizedTableStoreHandle, userColumnDefinition);
            if isempty(newColumnDefinitionObject)
                return
            end

            newName = newColumnDefinitionObject.getColumnName();

            existingColumnNames = obj.summarizedTableStoreHandle.getColumnNames();
            requiredColumnNames = newColumnDefinitionObject.getRequiredColumnNames(existingColumnNames);

            requiredTableSubset = obj.summarizedTableStoreHandle.getTableSubsetByName(requiredColumnNames);
            newColumnData = newColumnDefinitionObject.generateColumn(requiredTableSubset);

            if isequal(newName, columnName)
                if isequal(definitionType, 'manual')
                    % instead of creating the column anew, we need to update the existing manually set values
                    oldGroupNames = userColumnDefinition.getGroupNames();
                    newGroupNames = newColumnDefinitionObject.getGroupNames();

                    oldColumnData = obj.summarizedTableStoreHandle.getTableSubsetByName(columnName);
                    newColumnData = obj.applyGroupNameChanges(oldColumnData, oldGroupNames, newGroupNames);

                    obj.summarizedTableStoreHandle.updateColumnDefinition(columnName, newColumnData, newColumnDefinitionObject);
                    obj.summarizedTableStoreHandle.makeColumnEditable(columnName);
                else
                    obj.summarizedTableStoreHandle.updateColumnDefinition(columnName, newColumnData, newColumnDefinitionObject);
                end
            else
                obj.summarizedTableStoreHandle.addUserDefinedColumn(newName, newColumnData, newColumnDefinitionObject);

                if isequal(definitionType, 'manual')
                    obj.summarizedTableStoreHandle.makeColumnEditable(newName);
                end
            end
        end


        function duplicateColumnDefinition(obj, columnName)
            userColumnDefinition = obj.summarizedTableStoreHandle.getUserColumnDefinition(columnName);

            existingNames = obj.summarizedTableStoreHandle.getUserDefinedColumnNames();
            newName = SummarizedTableComponentHelper.getUnusedNameCopy(columnName, existingNames);

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
                    newColumnDefinition = ManualColumnDefinition(newName, rules, userColumnDefinition.getDefaultGroupName());
            end

            existingColumnNames = obj.summarizedTableStoreHandle.getColumnNames();
            requiredColumnNames = newColumnDefinition.getRequiredColumnNames(existingColumnNames);

            requiredTableSubset = obj.summarizedTableStoreHandle.getTableSubsetByName(requiredColumnNames);
            newColumnData = newColumnDefinition.generateColumn(requiredTableSubset);

            obj.summarizedTableStoreHandle.addUserDefinedColumn(newName, newColumnData, newColumnDefinition);
            if isequal(definitionType, 'manual')
                obj.summarizedTableStoreHandle.makeColumnEditable(newName);
            end
        end


        function storeDefinitionAsTemplate(obj, columnName)
            % do not do anything for now
            % TO IMPLEMENT - decide how to deal with templates in summarized table
        end


        function replaceData(obj)
            % replace the data in the data store
            obj.dataStoreHandle = obj.tableStateManagerHandle.getActiveDataStore();
            obj.loadData();
        end


        function editManualColumnValue(obj, columnName, rowName, newValue)
            % edit the values in the manual column
            obj.summarizedTableStoreHandle.editManualColumnValue(columnName, rowName, newValue);
        end


        function loadData(obj)
            obj.tableStoreHandle = obj.dataStoreHandle.getTableStore();
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~,~)findAndSetRowParameters(obj));

            obj.findAndSetRowParameters();
        end


        function loadDataForGrouping(obj)
            obj.summarizedTableStoreHandle = obj.dataStoreHandle.getSummarizedTableStore(obj.rowParameter);
            if ~isempty(obj.summarizedTableListener) && isvalid(obj.summarizedTableListener)
                delete(obj.summarizedTableListener);
            end
            obj.summarizedTableListener = addlistener(obj.summarizedTableStoreHandle, 'tableDataChanged', @(~,~)calculateTreeData(obj));

            obj.calculateTreeData();
        end
    end


    methods (Access = private)
        function newManualColumn = applyGroupNameChanges(~, manualColumn, oldGroupNames, newGroupNames)
            % Determine added, renamed, and removed group names
            addedGroups = newGroupNames((length(oldGroupNames) + 1):end);
            newManualColumn = addcats(manualColumn, addedGroups);
            
            removedGroupsIdx = find(cellfun('isempty', newGroupNames));
            removedGroupsIdx = removedGroupsIdx(removedGroupsIdx <= length(oldGroupNames)); % we care only about the groups that have a match in oldGroupNames
            removedGroups = oldGroupNames(removedGroupsIdx);
            newManualColumn = removecats(newManualColumn, removedGroups);

            renamedGroupsIdx = find(~cellfun('isempty', newGroupNames) & ~strcmp(oldGroupNames, newGroupNames));
            % Keep only renamedGroupsIdx with value max length of oldGroupNames
            renamedGroupsIdx = renamedGroupsIdx(renamedGroupsIdx <= length(oldGroupNames)); % we care only about the groups that have a match in oldGroupNames
            oldGroupNames = oldGroupNames(renamedGroupsIdx);
            newGroupNames = newGroupNames(renamedGroupsIdx);
            newManualColumn = renamecats(newManualColumn, oldGroupNames, newGroupNames);
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