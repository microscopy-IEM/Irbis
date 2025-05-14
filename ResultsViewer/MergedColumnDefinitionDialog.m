classdef (Sealed) MergedColumnDefinitionDialog 

    methods (Static)
        function [columnName, formulaString] = show(categoricalOrNumericColumnNames)

            if any(ismember(categoricalOrNumericColumnNames, 'fileId')) && any(ismember(categoricalOrNumericColumnNames, 'groupId'))
                [firstColumnName, secondColumnName] = MergedColumnDefinitionDialog.twoDropdownsInputDialog(categoricalOrNumericColumnNames, categoricalOrNumericColumnNames, 'fileId', 'groupId');
            else
                [firstColumnName, secondColumnName] = MergedColumnDefinitionDialog.twoDropdownsInputDialog(categoricalOrNumericColumnNames, categoricalOrNumericColumnNames);
            end

            if isempty(firstColumnName) || isempty(secondColumnName)
                columnName = '';
                formulaString = '';
                return;
            end
            formulaString = sprintf('string(%s) + "_" + string(%s)', firstColumnName, secondColumnName);
            columnName = sprintf('%s_%s', firstColumnName, secondColumnName);
        end

        function [columnName, formulaString] = showExisting(categoricalOrNumericColumnNames, existingColumnName)
            % Extract existing column names from the formula string
            if ~isempty(existingColumnName)
                parts = split(existingColumnName, '_');
                if numel(parts) == 2
                    firstColumnName = parts{1};
                    secondColumnName = parts{2};
                else
                    firstColumnName = '';
                    secondColumnName = '';
                end
            else
                firstColumnName = '';
                secondColumnName = '';
            end
            if ~(isempty(firstColumnName) || isempty(secondColumnName))
                % If the formula string is valid, show the dialog with existing values
                [firstColumnName, secondColumnName] = MergedColumnDefinitionDialog.twoDropdownsInputDialog(categoricalOrNumericColumnNames, categoricalOrNumericColumnNames, firstColumnName, secondColumnName);
            else
                % If the formula string is not valid, show the dialog without pre-filling values
                [firstColumnName, secondColumnName] = MergedColumnDefinitionDialog.twoDropdownsInputDialog(categoricalOrNumericColumnNames, categoricalOrNumericColumnNames);
            end

            if isempty(firstColumnName) || isempty(secondColumnName)
                columnName = '';
                formulaString = '';
                return;
            end
            formulaString = sprintf('string(%s) + "_" + string(%s)', firstColumnName, secondColumnName);
            columnName = sprintf('%s_%s', firstColumnName, secondColumnName);
        end
    end

    methods (Static, Access = private)
        function [value1, value2] = twoDropdownsInputDialog(options1, options2, varargin)
            % Outputs
            value1 = '';
            value2 = '';
        
            % Create modal figure
            d = uifigure('Name', 'Define Column', 'WindowStyle', 'modal', 'Position', [100 100 320 230]);

            % Dropdown 1
            uilabel(d, 'Text', 'Option 1:', 'Position', [20 135 100 22]);
            dd1 = uidropdown(d, 'Items', options1, 'Position', [120 135 170 22]);
            if nargin > 2
                dd1.Value = varargin{1};
            end
        
            % Dropdown 2
            uilabel(d, 'Text', 'Option 2:', 'Position', [20 95 100 22]);
            dd2 = uidropdown(d, 'Items', options2, 'Position', [120 95 170 22]);
            if nargin > 3
                dd2.Value = varargin{2};
            end
        
            % OK button
            uibutton(d, 'Text', 'OK', ...
                'Position', [50 30 100 30], ...
                'ButtonPushedFcn', @(btn,event) onOK());
        
            % Cancel button
            uibutton(d, 'Text', 'Cancel', ...
                'Position', [170 30 100 30], ...
                'ButtonPushedFcn', @(btn,event) onCancel());
        
            % Wait for user
            uiwait(d);
        
            function onOK()
                value1 = char(dd1.Value);
                value2 = char(dd2.Value);
                uiresume(d);
                delete(d);
            end
        
            function onCancel()
                value1 = '';
                value2 = '';
                uiresume(d);
                delete(d);
            end
        end
        
    end
end