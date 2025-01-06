function switchStateButtonStatus(button)
    % Change color of the button based on its activation
    % greyed out if inactive, blue if active
    if button.Value
        button.FontColor = 'k';
        button.BackgroundColor = [0.7, 0.9, 1];        
    else
        button.FontColor = [0.3 0.3 0.3];
        button.BackgroundColor = [0.7 0.7 0.7];
    end
end