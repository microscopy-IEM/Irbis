function [selectedItems, unselectedItems] = selectNamesToRecalculate(namesList)
% selectNamesToRecalculate Creates a modal dialog with a checklist
%   [selectedItems, unselectedItems] = selectNamesToRecalculate(namesList) displays a checklist with
%   items from namesList and returns the selected items and unselected items.
%
%   Input:
%       namesList - Cell array of strings with item names
%
%   Output:
%       selectedItems - Cell array of strings containing the selected items
%       unselectedItems - Cell array of strings containing the unselected items

    % Create a figure that blocks all other windows
    fig = uifigure('Name', 'Conflicting column definitions', 'Position', [300 300 400 500]);
    fig.WindowStyle = 'modal';  % Make it blocking
    fig.CloseRequestFcn = @(~, ~) cancelCallback();  % Handle window close
    figure(fig);  % Bring to front
    
    % Add a title label
    uilabel(fig, 'Position', [20 320 360 150], ...
                'Text', ['The following columns are defined differently in different files.' newline, ...
                'Select columns for which you want to keep one of the definitions. ' newline, ...
                'For the other columns, only data will be kept and all the definitions will be discarded.'], ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'WordWrap', 'on', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top');
    
    % Create a panel for the checkboxes
    panel = uipanel(fig, 'Position', [20 70 360 260]);
    
    % Create checkboxes for each item
    numItems = length(namesList);
    checkboxes = cell(numItems, 1);
    
    for columnIdx = 1:numItems
        % Calculate position based on index (from top to bottom)
        yPos = 260 - (columnIdx * 30);
        checkboxes{columnIdx} = uicheckbox(panel, ...
            'Position', [10 yPos 340 20], ...
            'Text', namesList{columnIdx}, ...
            'Value', false);  % Unchecked by default
    end
    
    % Create OK and Cancel buttons
    uibutton(fig, 'Position', [230 20 70 30], ...
                'Text', 'OK', ...
                'ButtonPushedFcn', @(~, ~) okCallback());

    uibutton(fig, 'Position', [310 20 70 30], ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @(~, ~) cancelCallback());

    % Initialize output
    selectedItems = {};
    unselectedItems = {};
    
    % Wait for user interaction (will be unblocked by callbacks)
    uiwait(fig);
    
    % Callbacks
    function okCallback()
        % Collect selected items
        selectedItems = {};
        for i = 1:numItems
            if checkboxes{i}.Value
                selectedItems{end+1} = namesList{i}; %#ok<AGROW>
            else
                unselectedItems{end+1} = namesList{i}; %#ok<AGROW>
            end
        end
        
        % Close the figure
        delete(fig);
    end
    
    function cancelCallback()
        % Return empty selection
        selectedItems = {};
        unselectedItems = namesList;
        
        % Close the figure
        delete(fig);
    end
end