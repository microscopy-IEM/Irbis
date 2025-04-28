classdef TemplateSettingsDialogWindow < handle
    properties (Access = private)
        componentHelperHandle
    end
    
    methods
        function obj = TemplateSettingsDialogWindow(componentHelperHandle)
            % Constructor to create the dialog window
            obj.componentHelperHandle = componentHelperHandle;
        end
        
        function createDialog(obj)
            fig = uifigure('Name', 'Categorization', 'Position', [100 100 400 250]);

            % Common settings
            elementHeight = 25;  % Unified height
            yFirstRow = 200;     % Y position for first row
            ySecondRow = 160;    % Y position for second row
            yThirdRow = 120;     % Y position for third row
            yFourthRow = 70;     % Y position for fourth row
        
        
            %% Second row: Template label and dropdown
            uilabel(fig, 'Text', 'Template', ...
                'Position', [10, ySecondRow, 60, elementHeight], ...
                'HorizontalAlignment', 'left');
        
            existingTemplateNames = obj.componentHelperHandle.getTemplateNames();
            selectedTemplateDropDown = uidropdown(fig, ...
                'Items', existingTemplateNames, ...
                'Position', [80, ySecondRow, 310, elementHeight]);

            %% First row: Add dropdown and Add button - here, because I need to use the selected template name
            addTypeDropdown = uidropdown(fig, ...
                'Items', {'categorization', 'formula', 'merged', 'manual'}, ...
                'Position', [10, yFirstRow, 250, elementHeight]);
        
            uibutton(fig, 'Text', 'Add', ...
                'Position', [270, yFirstRow, 120, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) addTemplateOfSelectedType(addTypeDropdown, selectedTemplateDropDown));
        
            %% Third row: Centered Use, Edit, Duplicate, Delete buttons
            buttonWidth = 80;
            spacing = 15; % Adjusted spacing for four buttons
            totalWidth = 4 * buttonWidth + 3 * spacing;
            startX = (400 - totalWidth) / 2; % 400 is figure width
        
            uibutton(fig, 'Text', 'Use', ...
                'Position', [startX, yThirdRow, buttonWidth, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.useSelectedTemplate(selectedTemplateDropDown));
        
            uibutton(fig, 'Text', 'Edit', ...
                'Position', [startX + buttonWidth + spacing, yThirdRow, buttonWidth, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.editSelectedTemplate(selectedTemplateDropDown));
            
            uibutton(fig, 'Text', 'Duplicate', ...
                'Position', [startX + 2 * (buttonWidth + spacing), yThirdRow, buttonWidth, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.duplicateSelectedTemplate(selectedTemplateDropDown));
        
            uibutton(fig, 'Text', 'Delete', ...
                'Position', [startX + 3 * (buttonWidth + spacing), yThirdRow, buttonWidth, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.deleteSelectedTemplate(selectedTemplateDropDown));
        
            %% Fourth row: Import and Export templates
            uibutton(fig, 'Text', 'Import templates', ...
                'Position', [10, yFourthRow, 180, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.importTemplates(selectedTemplateDropDown));
        
            uibutton(fig, 'Text', 'Export templates', ...
                'Position', [210, yFourthRow, 180, elementHeight], ...
                'ButtonPushedFcn', @(~, ~) obj.exportTemplates());
        end
    end

    methods (Access = private)
        function addTemplateOfSelectedType(obj, columnTypeDropDown, selectedTemplateDropDown)
            % Callback for the Add button
            selectedType = columnTypeDropDown.Value;
            % Handle the addition of the selected type here
            disp(['Adding: ', selectedType]);

            obj.componentHelperHandle.addTemplate(selectedType);
            selectedTemplateDropDown.Items = obj.componentHelperHandle.getTemplateNames();
        end

        function useSelectedTemplate(obj, selectedTemplateDropDown)
            % Callback for the Use button
            % Handle the usage of the selected template here
            disp('Using selected template');

            selectedTemplateName = selectedTemplateDropDown.Value;
            obj.componentHelperHandle.useTemplate(selectedTemplateName);
        end
        
        function editSelectedTemplate(obj, selectedTemplateDropDown)
            % Callback for the Edit button
            % Handle the editing of the selected template here
            disp('Editing selected template');

            selectedTemplateName = selectedTemplateDropDown.Value;
            obj.componentHelperHandle.editTemplate(selectedTemplateName);
            selectedTemplateDropDown.Items = obj.componentHelperHandle.getTemplateNames();
        end

        function duplicateSelectedTemplate(obj, selectedTemplateDropDown)
            % Callback for the Duplicate button
            % Handle the duplication of the selected template here
            disp('Duplicating selected template');

            selectedTemplateName = selectedTemplateDropDown.Value;
            obj.componentHelperHandle.duplicateTemplate(selectedTemplateName);
            selectedTemplateDropDown.Items = obj.componentHelperHandle.getTemplateNames();
        end

        function deleteSelectedTemplate(obj, selectedTemplateDropDown)
            % Callback for the Delete button
            % Handle the deletion of the selected template here
            disp('Deleting selected template');

            selectedTemplateName = selectedTemplateDropDown.Value;
            obj.componentHelperHandle.removeTemplate(selectedTemplateName);
            selectedTemplateDropDown.Items = obj.componentHelperHandle.getTemplateNames();
        end

        function importTemplates(obj, selectedTemplateDropDown)
            % Callback for the Import button
            % Handle the import of templates here
            disp('Importing templates');

            obj.componentHelperHandle.importTemplates();
            selectedTemplateDropDown.Items = obj.componentHelperHandle.getTemplateNames();
        end

        function exportTemplates(obj)
            % Callback for the Export button
            % Handle the export of templates here
            disp('Exporting templates');

            obj.componentHelperHandle.exportTemplates();
        end
    end
end
