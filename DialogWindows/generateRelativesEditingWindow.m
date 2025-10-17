function [parents, children] = generateRelativesEditingWindow(parents, children)
    % Create a dialog to edit parent and child relationships
    %   [parents, children] = generateRelativesEditingWindow(parents, children)
    %   
    %   Inputs:
    %       parents  - dictionary with branch names as keys and cell arrays of IDs as values
    %       children - dictionary with branch names as keys and cell arrays of IDs as values
    %
    %   Outputs:
    %       parents  - Updated parents dictionary (empty if cancelled)
    %       children - Updated children dictionary (empty if cancelled)
    
    % Create figure
    fig = uifigure('Name', 'Edit relatives IDs', 'Position', [100 100 500 600]);
    
    % Create main grid layout
    mainGrid = uigridlayout(fig, [3 1]);
    mainGrid.RowHeight = {'fit', 'fit', 30};
    mainGrid.ColumnWidth = {'1x', 100, 100};

    if ~isempty(parents)
        % Get branch names
        parentBranches = keys(parents);

        % Store edit fields for later retrieval
        parentFields = dictionary();

        % Create Parents section
        parentPanel = uipanel(mainGrid, 'Title', 'Parents');
        parentPanel.Layout.Row = 1;
        parentPanel.Layout.Column = [1, 3];
        parentGrid = uigridlayout(parentPanel, [length(parentBranches) 2]);
        parentGrid.ColumnWidth = {150, '1x'};
        
        for i = 1:length(parentBranches)
            branch = parentBranches{i};
            uilabel(parentGrid, 'Text', branch);
            editField = uieditfield(parentGrid, 'text', 'Value', cellArrayToString(parents(branch)));
            parentFields(branch) = editField;
        end
    else
        parentBranches = {};
    end

    if ~isempty(children)
        % Get branch names
        childBranches = keys(children);

        % Store edit fields for later retrieval
        childFields = dictionary();

        % Create Children section
        childPanel = uipanel(mainGrid, 'Title', 'Children');
        childPanel.Layout.Row = 2;
        childPanel.Layout.Column = [1, 3];
        childGrid = uigridlayout(childPanel, [length(childBranches) 2]);
        childGrid.ColumnWidth = {150, '1x'};
        
        for i = 1:length(childBranches)
            branch = childBranches{i};
            uilabel(childGrid, 'Text', branch);
            editField = uieditfield(childGrid, 'text', 'Value', cellArrayToString(children(branch)));
            childFields(branch) = editField;
        end
    else
        childBranches = {};
    end

    % Add buttons
    OKbutton = uibutton(mainGrid, 'Text', 'OK', 'ButtonPushedFcn', @(btn,event) okCallback());
    OKbutton.Layout.Row = 3;
    OKbutton.Layout.Column = 2;
    Cancelbutton = uibutton(mainGrid, 'Text', 'Cancel', 'ButtonPushedFcn', @(btn,event) cancelCallback());
    Cancelbutton.Layout.Row = 3;
    Cancelbutton.Layout.Column = 3;

    fig.Position(4) = mainGrid.Position(4) + 200;

    % Wait for user
    uiwait(fig);
    
    % Nested callback functions
    function okCallback()
        % Update parents dictionary
        for j = 1:length(parentBranches)
            branch = parentBranches{j};
            parents(branch) = stringToCellArray(parentFields(branch).Value);
        end
        
        % Update children dictionary
        for j = 1:length(childBranches)
            branch = childBranches{j};
            children(branch) = stringToCellArray(childFields(branch).Value);
        end
        
        uiresume(fig);
        close(fig);
    end
    
    function cancelCallback()
        parents = dictionary();
        children = dictionary();
        uiresume(fig);
        close(fig);
    end
    
    % Helper function to convert cell array to string
    function str = cellArrayToString(cellArr)
        if isempty(cellArr)
            str = '';
        else
            unpackedArr = cellArr{1};
            if iscell(unpackedArr)
                unpackedArr = cell2mat(unpackedArr);
            end
            unpackedArr = arrayfun(@num2str, unpackedArr, 'UniformOutput', false);
            str = strjoin(unpackedArr, ', ');
        end
    end
    
    % Helper function to convert string to cell array
    function cellArr = stringToCellArray(str)
        if isempty(strtrim(str))
            cellArr = {};
        else
            parts = strsplit(str, ',');
            arr = arrayfun(@(x) str2double(strtrim(x)), parts, 'UniformOutput', false);
            cellArr = {arr};
        end
    end
end