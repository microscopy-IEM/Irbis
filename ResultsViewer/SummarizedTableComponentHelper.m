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

        function replaceData(obj)
            % replace the data in the data store
            obj.dataStoreHandle = obj.tableStateManagerHandle.getActiveDataStore();
            obj.loadData();
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
end