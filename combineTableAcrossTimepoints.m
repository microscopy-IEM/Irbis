function combinedTable = combineTableAcrossTimepoints(cellList)
    % private function
    % combines array of tables into one big combinedTable with all time points

    if istable(cellList)
        combinedTable = cellList;
        disp('there is only one time point')
        return
    end

    % create combined table from all time points
    combinedTable = table();

    % Identify all unique columns
    columnNames = {};
    columnClasses = {};
    for tp = 1:numel(cellList)
        currentTable = cellList{tp};
        if istable(currentTable)
            columnNames = [columnNames, currentTable.Properties.VariableNames];
            columnClasses = [columnClasses, varfun(@class, currentTable, 'OutputFormat', 'cell')];
        end
    end

    [allColumns, ia] = unique(columnNames, 'stable');
    allClasses = columnClasses(ia);

    % allColumns = unique(horzcat(app.irbis.tracks.tracksList{:}.Properties.VariableNames), 'stable');
    % 
    % Loop through each time point
    for tp = 1:numel(cellList)
        tempTable = cellList{tp};  % Get the table from the cell array
        % Add missing columns with NaNs
        if istable(tempTable) && ~isempty(tempTable)
            missingCols = setdiff(allColumns, tempTable.Properties.VariableNames);
            for col = missingCols
                colIdx = find(strcmp(allColumns, col));
                colClass = allClasses{colIdx};
        
                switch colClass
                    case 'double'
                        placeholder = NaN(height(tempTable), 1);
                    case 'categorical'
                        placeholder = repmat(categorical(missing), height(tempTable), 1);
                        % placeholder = categorical(missing(height(tempTable), 1));
                    case 'logical'
                        placeholder = false(height(tempTable), 1);
                    case 'datetime'
                        placeholder = NaT(height(tempTable), 1);
                    case 'cell'
                        placeholder = cell(height(tempTable), 1);
                    case 'string'
                        placeholder = strings(height(tempTable), 1);
                    otherwise
                        error('Unhandled data type: %s', colClass);
                end
        
                tempTable.(col{1}) = placeholder;
            end

            if ~isempty(tempTable.Properties.RowNames)
                tempTable.id = tempTable.Properties.RowNames;
                tempTable.Properties.RowNames = strcat(tempTable.Properties.RowNames, '_', num2str(tp));
            end
            if ~ismember('timePoint',tempTable.Properties.VariableNames)
                timePoint = repmat(tp, height(tempTable), 1);  % Create a time point column
            else
                timePoint = tempTable.timePoint;
            end
            tempTable.timePoint = categorical(timePoint);  % Add as a categorical column
            if ismember('groupId',tempTable.Properties.VariableNames)      % TO OPTIMIZE - groupId changed as categorical
                tempTable.groupId = categorical(tempTable.groupId);
            end
            % combinedTable
            % tempTable
            try
                % Reorder columns of T2 to match the order of T1
                if ~isempty(combinedTable.Properties.VariableNames)
                    tempTable = tempTable(:, combinedTable.Properties.VariableNames);
                end
                combinedTable = [combinedTable; tempTable];  % Concatenate vertically
            catch ME
                disp('error catched')
                disp(ME.message)
                combinedTable = [];
            end
        end
    end
end