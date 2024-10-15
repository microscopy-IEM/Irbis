function combinedTable = combineTableAcrossTimepoints(cellList,varargin)
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
    for idx = 1:numel(cellList)
        currentTable = cellList{idx};
        if istable(currentTable)
            columnNames = [columnNames, currentTable.Properties.VariableNames];
            columnClasses = [columnClasses, varfun(@class, currentTable, 'OutputFormat', 'cell')];
        end
    end

    [allColumns, ia] = unique(columnNames, 'stable');
    allClasses = columnClasses(ia);

    % I need to incorporate the fact that the position in the array does not equal the timepoint
    % timePoint is equal to position of the corresponding index number in the currentIndex array
    % example: 
        % model.(branch).List = 1x5 cell
        % currentIndex.model.(branch) = [0 1 2 0 3 4 5]
            % first element in cell corresponds to the 2nd timepoint, second element to 3rd, third element to 5th etc.
    if nargin == 2
        currentIndex = varargin{1};
        correspondingTimePoints = zeros(size(cellList));
        for i = 1:numel(cellList)
            timePoint = currentIndex(i); 

            if ~isequal(timePoint,0)
                correspondingTimePoints(i) = timePoint;
            else
                correspondingTimePoints(i) = NaN;
            end
        end
    else
        correspondingTimePoints = 1:numel(cellList);
    end

    % allColumns = unique(horzcat(app.irbis.tracks.tracksList{:}.Properties.VariableNames), 'stable');
    % 
    % Loop through each time point
    for idx = 1:numel(cellList)
        tempTable = cellList{idx};  % Get the table from the cell array
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
                tempTable.Properties.RowNames = strcat(tempTable.Properties.RowNames, '_', num2str(idx));
            end
            if ~ismember('timePoint',tempTable.Properties.VariableNames)
                tp = correspondingTimePoints(idx);
                timePoint = repmat(tp, height(tempTable), 1);  % Create a time point column
            else
                timePoint = tempTable.timePoint;
            end
            tempTable.timePoint = categorical(timePoint);  % Add as a categorical column
                % we don't want it as categorical anymore
                % but we want to convert it from categorical to numerical 
                    % however, this will cause problems in already created categorizations
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