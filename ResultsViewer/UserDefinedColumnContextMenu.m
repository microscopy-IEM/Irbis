classdef UserDefinedColumnContextMenu 

    properties
        nodeHandle
        menuHandle
        columnName
        componentHelperHandle
    end

    methods
        function obj = UserDefinedColumnContextMenu(node, columnName, componentHelperHandle)
            obj.nodeHandle = node;
            obj.componentHelperHandle = componentHelperHandle;
            obj.columnName = columnName;
            figureHandle = ancestor(node, 'figure');
            obj.menuHandle = uicontextmenu(figureHandle);

            uimenu(obj.menuHandle, 'Text', 'Delete', 'MenuSelectedFcn', @(~,~)deleteColumn(obj));
            uimenu(obj.menuHandle, 'Text', 'Rename', 'MenuSelectedFcn', @(~,~)renameColumn(obj));
            uimenu(obj.menuHandle, 'Text', 'Edit', 'MenuSelectedFcn', @(~,~)editColumnDefinition(obj));
            uimenu(obj.menuHandle, 'Text', 'Duplicate', 'MenuSelectedFcn', @(~,~)duplicateColumnDefinition(obj));
            uimenu(obj.menuHandle, 'Text', 'Store as template', 'MenuSelectedFcn', @(~,~)storeDefinitionAsTemplate(obj));
        end

        function assignTo(obj, node)
            node.ContextMenu = obj.menuHandle;
        end
        
        function deleteColumn(obj)
            % Delete the node from the raw data
            obj.componentHelperHandle.removeColumn(obj.columnName);
        end
        
        function renameColumn(obj)
            % dialog window for entering the new column name
            prompt = {'Enter the new name:'};
            dlgtitle = 'Rename column';
            fieldsize = [1 40];
            definput = {obj.columnName};
            newNameCell = inputdlg(prompt,dlgtitle,fieldsize,definput);

            if ~isempty(newNameCell)
                % propagate the new name to the raw data
                oldName = obj.columnName;
                newName = newNameCell{1};

                obj.componentHelperHandle.renameColumn(oldName, newName);
            else
                % do not do anything, if the user pressed cancel
            end
        end

        function editColumnDefinition(obj)
            obj.componentHelperHandle.editColumnDefinition(obj.columnName);
        end

        function duplicateColumnDefinition(obj)
            obj.componentHelperHandle.duplicateColumnDefinition(obj.columnName);
        end

        function storeDefinitionAsTemplate(obj)
            obj.componentHelperHandle.storeDefinitionAsTemplate(obj.columnName);
        end
    end
end