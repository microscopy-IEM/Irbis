function [selectedType, selectedBranch] = generateNewConnectionEditingWindow(branches)
    % Create a dialog to select relationship type and branch
    %   [selectedType, selectedBranch] = generateNewConnectionEditingWindow(branches)
    %   
    %   Inputs:
    %       branches - cell array of branch names
    %
    %   Outputs:
    %       selectedType   - 'parent' or 'children' (empty if cancelled)
    %       selectedBranch - selected branch name (empty if cancelled)
    
    selectedType = '';
    selectedBranch = '';
    
    % Create figure
    fig = uifigure('Name', 'Define new connection to relatives', 'Position', [100 100 400 200]);
    
    % Create main grid layout
    mainGrid = uigridlayout(fig, [3 2]);
    mainGrid.RowHeight = {50, 50, 50};
    mainGrid.ColumnWidth = {100, '1x'};
    
    % Type dropdown
    uilabel(mainGrid, 'Text', 'What kind or relative:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(mainGrid, 'Items', {'children', 'parent'});
    typeDropdown.Layout.Row = 1;
    typeDropdown.Layout.Column = 2;
    
    % Branch dropdown
    uilabel(mainGrid, 'Text', 'Branch:', 'HorizontalAlignment', 'right');
    branchDropdown = uidropdown(mainGrid, 'Items', branches);
    branchDropdown.Layout.Row = 2;
    branchDropdown.Layout.Column = 2;
    
    % Buttons
    OKbutton = uibutton(mainGrid, 'Text', 'OK', 'ButtonPushedFcn', @okCallback);
    OKbutton.Layout.Row = 3;
    OKbutton.Layout.Column = 1;
    
    Cancelbutton = uibutton(mainGrid, 'Text', 'Cancel', 'ButtonPushedFcn', @cancelCallback);
    Cancelbutton.Layout.Row = 3;
    Cancelbutton.Layout.Column = 2;
    
    uiwait(fig);
    
    function okCallback(~, ~)
        selectedType = lower(typeDropdown.Value);
        selectedBranch = branchDropdown.Value;
        uiresume(fig);
        close(fig);
    end
    
    function cancelCallback(~, ~)
        selectedType = '';
        selectedBranch = '';
        uiresume(fig);
        close(fig);
    end
end
