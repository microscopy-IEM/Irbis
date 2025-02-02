function responses = ResultsViewerSettingsDialog(questions)
    % Create a dialog window
    d = dialog('Position', [300, 300, 300, 100 + numel(questions) * 50], ...
                'Name', 'User Input');

    % Store user responses
    responses = struct();

    % Create UI components dynamically
    uiElements = cell(size(questions));
    
    for i = 1:numel(questions)
        % Determine the type of question
        qType = questions{i}.Type;
        qLabel = questions{i}.Label;
        
        % Create text label
        uicontrol('Parent', d, ...
                    'Style', 'text', ...
                    'String', qLabel, ...
                    'Position', [20, 100 + (numel(questions) - i) * 40, 200, 25], ...
                    'HorizontalAlignment', 'left');

        switch qType
            case 'checkbox'
                % Create a checkbox
                uiElements{i} = uicontrol('Parent', d, ...
                                            'Style', 'checkbox', ...
                                            'Position', [230, 100 + (numel(questions) - i) * 40, 20, 20], ...
                                            'Value', questions{i}.Default);
            case 'edit'
                if isnumeric(questions{i}.Default)
                    % Create an input text box
                    uiElements{i} = uicontrol('Parent', d, ...
                                                'Style', 'edit', ...
                                                'Position', [230, 100 + (numel(questions) - i) * 40, 20, 25], ...
                                                'String', questions{i}.Default);
                else
                    % Create an input text box
                    uiElements{i} = uicontrol('Parent', d, ...
                                                'Style', 'edit', ...
                                                'Position', [150, 100 + (numel(questions) - i) * 40, 100, 25], ...
                                                'String', questions{i}.Default);
                end
        end
    end

    % OK Button
    uicontrol('Parent', d, ...
                'Position', [100, 20, 100, 30], ...
                'String', 'OK', ...
                'Callback', @(btn, event) closeDialog());

    % Wait for user input
    uiwait(d);

    % Retrieve responses before closing
    function closeDialog()
        for i = 1:numel(questions)
            switch questions{i}.Type
                case 'checkbox'
                    responses.(questions{i}.ID) = uiElements{i}.Value;
                case 'edit'
                    % TO OPTIMIZE - at the moment, I want to fill in only numbers
                    % deal also with text options
                    responses.(questions{i}.ID) = str2double(uiElements{i}.String);
            end
        end
        uiresume(d);
        delete(d);
    end
end
    
