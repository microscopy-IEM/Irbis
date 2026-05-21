classdef (Sealed) FormulaColumnDefinitionDialog 

    methods (Static)
        function [columnName, formulaString] = show()
            % Create a dialog window for formula input
            prompt = {'New column name:', 'Formula:'};
            dlgTitle = 'Define new column';
            numLines = 1;
            % defaultAns = {'', ''};
            defaultAns = {'Dlog', 'customLog10(MSD5)'}; % temporal
            input = inputdlg(prompt, dlgTitle, numLines, defaultAns);

            % Check if the user pressed cancel
            if isempty(input)
                columnName = '';
                formulaString = [];                
                return;
            end

            % Extract the user input
            columnName = input{1};
            formulaString = input{2};
        end

        function [columnName, formulaString] = showExisting(existingColumnName, existingFormula)
            % Create a dialog window for formula input with existing column name
            prompt = {'New column name:', 'Formula:'};
            dlgTitle = 'Define new column';
            numLines = 1;
            defaultAns = {existingColumnName, existingFormula};
            input = inputdlg(prompt, dlgTitle, numLines, defaultAns);

            % Check if the user pressed cancel
            if isempty(input)
                columnName = '';
                return
            end

            % Extract the user input
            columnName = input{1};
            formulaString = input{2};
        end
    end
end