function button = addStateButtonTo(panel, newName, varargin)

    if nargin < 2
        error('Not enough input arguments.');
    elseif nargin == 2
        buttonState = true;  % Default state for newly created buttons
    elseif nargin == 3
        buttonState = varargin{1};  % Use the provided state
    elseif nargin > 3
        error('Too many input arguments.');
    end

    % Get the existing buttons' labels
    existingButtons = findobj(panel.Children);

    % Check if a button with the same name already exists
    existingButton = findobj(existingButtons, '-property', 'Text', 'Text', newName);

    if ~isempty(existingButton)
        % If the button exists, activate it
        existingButton.Value = true;
        existingButton.FontColor = 'k';
        existingButton.BackgroundColor = [0.7, 0.9, 1];  % Active color
        return
    end

    % Get the xPosition of the last button (if any)
    if isempty(existingButtons)
        xPosition = 1;  % Start at 1 if no buttons exist
    else
        lastButton = existingButtons(1);  % Get the most recently created button
        lastPosition = lastButton.Position;
        xPosition = lastPosition(1) + lastPosition(3) + 1;  % Position to the right of the last button
    end
    
    yPosition = 1;  % Vertical position for the button
    widthFactor = 7; % Approximate width factor per character

    % Estimate the button width based on text length
    buttonTextLength = length(newName);
    buttonWidth = buttonTextLength * widthFactor;  % Estimate width based on text length

    % Create a new button at the end
    button = uibutton(panel, 'state', ... 
        'Text', newName, ...
        'Tooltip', newName, ...
        'Position', [xPosition, yPosition, buttonWidth, 20]);
    
    % Set the initial activation status
    button.Value = buttonState;
    if button.Value
        button.FontColor = 'k';
        button.BackgroundColor = [0.7, 0.9, 1];  
    else
        button.FontColor = [0.3 0.3 0.3];
        button.BackgroundColor = [0.7 0.7 0.7];
    end
end