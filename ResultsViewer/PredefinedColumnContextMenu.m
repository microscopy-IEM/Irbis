classdef PredefinedColumnContextMenu 
    % Context menu creation for predefined columns for the Full table - affects directly the raw data

    properties
        nodeHandle
        menuHandle
        columnName
        componentHelperHandle
    end

    methods
        function obj = PredefinedColumnContextMenu(node, columnName, componentHelperHandle)
            obj.nodeHandle = node;
            obj.componentHelperHandle = componentHelperHandle;
            obj.columnName = columnName;
            figureHandle = ancestor(node, 'figure');
            obj.menuHandle = uicontextmenu(figureHandle);
            
            % Add menu items
            uimenu(obj.menuHandle, 'Text', 'Delete', 'MenuSelectedFcn', @(~,~)deleteNode(obj));
            uimenu(obj.menuHandle, 'Text', 'Rename', 'MenuSelectedFcn', @(~,~)renameNode(obj));
        end

        function assignTo(obj, node)
            node.ContextMenu = obj.menuHandle;
        end
        
        function deleteNode(obj)
            % Delete the node from the raw data
            obj.componentHelperHandle.removeColumn(obj.columnName);
        end
        
        function renameNode(obj)
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
    end
end