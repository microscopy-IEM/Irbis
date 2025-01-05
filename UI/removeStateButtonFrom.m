function removeStateButtonFrom(panel, buttonName)

    % Find the button with the specified name
    buttonToRemove = findobj(panel.Children, 'Text', buttonName);
    
    if isempty(buttonToRemove)
        warning('Button with name "%s" not found.', buttonName);
        return;
    end
    
    % Delete the button
    delete(buttonToRemove);

    % Get the remaining buttons
    existingButtons = findobj(panel.Children);

    if isempty(existingButtons)
        return
    end
    
    % Sort buttons by their xPosition
    positions = reshape([existingButtons.Position], 4, [])';  % Get positions for each button
    [~, idx] = sort(positions(:, 1), 'ascend');  % Sort by the first column (xPosition)
    existingButtons = existingButtons(idx);  % Sort the buttons in the correct order

    % Reposition the remaining buttons
    xPosition = 1;
    for i = 1:length(existingButtons)
        button = existingButtons(i);
        buttonWidth = button.Position(3);  % Keep the existing width
        button.Position = [xPosition, 1, buttonWidth, 20];  % Shift to the left
        xPosition = xPosition + buttonWidth + 1;  % Adjust for the next button
    end
end