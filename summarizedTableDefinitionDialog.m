function [selectedCategory, selectedCheckboxes] = summarizedTableDefinitionDialog(categoricalParameterNames, numericalParameterNames)
    % Determine dialog size based on number of checkboxes
    checkboxHeight = 25;
    maxDialogHeight = 700; % Maximum height allowed for the dialog
    panelHeight = numel(numericalParameterNames) * checkboxHeight;
    dialogHeight = min(maxDialogHeight, 200 + panelHeight);
    
    % Ensure the dialog remains fully visible on the screen
    screenSize = get(0, 'ScreenSize');
    dialogY = max(50, screenSize(4) - dialogHeight - 100); % Move it down if too high
    
    % Create the dialog figure
    dlg = figure('Name', 'Define the table', 'NumberTitle', 'off', ...
                 'Position', [500, dialogY, 300, dialogHeight], 'MenuBar', 'none', ...
                 'ToolBar', 'none', 'Resize', 'on', 'WindowStyle', 'modal', ...
                 'CloseRequestFcn', @closeCallback);
    
    % Dropdown label
    uicontrol('Parent', dlg, 'Style', 'text', 'String', 'Categorical parameter:', ...
              'Position', [20, dialogHeight - 50, 260, 20], 'HorizontalAlignment', 'left');
    
    % Dropdown menu
    dropdown = uicontrol('Parent', dlg, 'Style', 'popupmenu', 'String', categoricalParameterNames, ...
                         'Position', [20, dialogHeight - 80, 260, 30]);
    
    % Checkbox label
    uicontrol('Parent', dlg, 'Style', 'text', 'String', 'Parameters to calculate statistics for:', ...
              'Position', [20, dialogHeight - 110, 260, 20], 'HorizontalAlignment', 'left');
    
    % Checkbox list
    checkboxHandles = gobjects(numel(numericalParameterNames), 1);
    for i = 1:numel(numericalParameterNames)
        checkboxHandles(i) = uicontrol('Parent', dlg, 'Style', 'checkbox', 'String', numericalParameterNames{i}, ...
                                       'Position', [20, dialogHeight - 140 - (i - 1) * checkboxHeight, 260, checkboxHeight], ...
                                       'HorizontalAlignment', 'left', 'Value', 1); % Set all checkboxes to checked
    end
    
    % OK button
    okButton = uicontrol('Parent', dlg, 'Style', 'pushbutton', 'String', 'OK', ...
                          'Position', [100, 20, 100, 40], 'Callback', @okCallback);
    
    % Initialize output variables
    selectedCategory = '';
    selectedCheckboxes = {};
    
    % Wait for user input
    uiwait(dlg);
    
    % Nested callback function
    function okCallback(~, ~)
        % Get selected dropdown value
        selectedIndex = get(dropdown, 'Value');
        selectedCategory = categoricalParameterNames{selectedIndex};
        
        % Get selected checkboxes
        selectedCheckboxes = numericalParameterNames([checkboxHandles.Value] == 1);
        
        % Close dialog
        delete(dlg);
    end
    
    % Close request callback
    function closeCallback(~, ~)
        % Ensure outputs are empty if the user closes the window manually
        selectedCategory = '';
        selectedCheckboxes = {};
        delete(dlg);
    end
end
