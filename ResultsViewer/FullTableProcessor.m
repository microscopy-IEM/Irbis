classdef (Sealed) FullTableProcessor < handle
    properties (Access = ?matlab.unittest.TestCase)
        filteredTable
        activeColumns = {}
        dataStoreHandle
        filteringStorageHandle
        tableStoreHandle
        stateManagerHandle
        filterListener  % Store the listener handle
        tableStoreListener
        stateManagerListener
        selectedTableCellsList (:,2) = [] % Initialize as empty array

        isColumnSelectionPreserved = true % when there are no cells selected for a given column (for example after filtering), the first row of that column is selected automatically if this is true
    end

    events
        tableForDisplayChanged
        tableSelectionChanged
        tableSelectionSetProgrammatically
        tableSelectionSyncRequired  % not the prettiest, but added to do table syncing before plotting data starts listening
        plotUpdateRequired          % notify that plotting needs to be updated (used instead of tableSelectionChanged to avoid freezing)
    end

        % Take in raw data and spit out a table of type full
            % The processing can include:
                % - Filtering
                % - Selecting only certain columns

    methods (Access = public)
        function obj = FullTableProcessor()

        end

        function delete(obj)
            % Destructor - clean up listeners
            if ~isempty(obj.filterListener) && isvalid(obj.filterListener)
                delete(obj.filterListener);
            end
            
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end

            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
        end

        function setHandles(obj, stateManagerHandle, dataStoreHandle)
            if nargin < 3 || isempty(stateManagerHandle) || isempty(dataStoreHandle)
                error('FullTableProcessor:InvalidInput', 'Valid stateManager and dataStore handles are required');
            end

            obj.stateManagerHandle = stateManagerHandle;
            obj.stateManagerListener = addlistener(obj.stateManagerHandle, 'newModalityLoaded', @(~, ~) replaceData(obj));

            obj.dataStoreHandle = dataStoreHandle;
            obj.loadData();

        end

        function tableForDisplay = getTableForDisplay(obj)
            % Return a subset of the filtered table based on active columns
            if isempty(obj.activeColumns) || isempty(obj.filteredTable)
                tableForDisplay = table();
                return;
            end
            
            try
                tableForDisplay = obj.filteredTable(:, obj.activeColumns);
            catch ME
                warning('FullTableProcessor:ColumnError', 'Error accessing columns: %s', ME.message);
                tableForDisplay = table();
            end
        end

        function columnEditability = getColumnEditability(obj)
            columnEditability = obj.tableStoreHandle.getEditabilityOfColumns(obj.activeColumns);
        end


        function storeSelectedTableCellsList(obj, selectedTableCellsList)
            % Validates and stores the selected table cells
            if ~isempty(selectedTableCellsList) && (~ismatrix(selectedTableCellsList) || size(selectedTableCellsList, 2) ~= 2)
                error('FullTableProcessor:InvalidSelection', 'Selected cells must be an nx2 array');
            end

            obj.selectedTableCellsList = selectedTableCellsList;
            notify(obj, 'tableSelectionChanged'); % TO OPTIMIZE - this again activates the component, which caused this in the first place
        end


        function setSelectedColumns(obj, columnNames)
            if isempty(columnNames)
                % nothing is going to be shown
            end

            previouslyActiveColumns = obj.activeColumns;
            obj.selectedTableCellsList = obj.updateSelectionAfterColumnChange(previouslyActiveColumns, columnNames);

            obj.activeColumns = columnNames;
            notify(obj, 'tableForDisplayChanged');  
        end


        function selectedList = getSelectedTableCellsList(obj, n)
            if nargin < 2
                % If n is not provided, return all selected cells
                selectedList = obj.selectedTableCellsList;
                return;
            end
            
            if isempty(obj.selectedTableCellsList)
                selectedList = [];
                return;
            end
            
            % Get unique column indices
            uniqueCols = unique(obj.selectedTableCellsList(:,2));
            
            % Preallocate selectedList based on maximum possible size
            maxSize = length(uniqueCols) * n;
            selectedList = zeros(maxSize, 2);
            currentIdx = 1;
            
            for col = uniqueCols'
                % Find all rows for this column
                colMask = obj.selectedTableCellsList(:,2) == col;
                rowsForCol = obj.selectedTableCellsList(colMask, 1);
                
                % Take only first n rows for this column
                firstNRows = rowsForCol(1:min(n, length(rowsForCol)));
                numRows = length(firstNRows);
                
                % Fill preallocated array
                selectedList(currentIdx:currentIdx+numRows-1, 1) = firstNRows;
                selectedList(currentIdx:currentIdx+numRows-1, 2) = col;
                currentIdx = currentIdx + numRows;
            end
            
            % Trim to actual size
            selectedList = selectedList(1:currentIdx-1, :);
        end


        function [subtable, isCategorical] = getSelectedColumns(obj)
            if isempty(obj.selectedTableCellsList)
                subtable = table();
                isCategorical = [];
                % warning('FullTableProcessor:NoSelection', 'No cells are selected');
                return;
            end

            selectedColumnNumsInOrder = unique(obj.selectedTableCellsList(:,2), 'stable'); % stable needed to preserve the order of selection

            displayedTable = obj.getTableForDisplay();      % the selection is relative to the displayed table
            subtable = displayedTable(:, selectedColumnNumsInOrder);
            
            isCategorical = varfun(@iscategorical, subtable, 'OutputFormat', 'uniform');
        end

        function [subtable, isCategorical] = getSelectedRows(obj)
            selectedRowNumsInOrder = unique(obj.selectedTableCellsList(:,1), 'stable');

            displayedTable = obj.getTableForDisplay();      % the selection is relative to the displayed table
            subtable = displayedTable(selectedRowNumsInOrder, :);
            
            isCategorical = varfun(@iscategorical, subtable, 'OutputFormat', 'uniform');
        end

        function [subtable, isCategorical] = getSelected(obj)
            selectedRowNumsInOrder = unique(obj.selectedTableCellsList(:,1), 'stable');
            selectedColumnNumsInOrder = unique(obj.selectedTableCellsList(:,2), 'stable'); % stable needed to preserve the order of selection

            displayedTable = obj.getTableForDisplay();      % the selection is relative to the displayed table
            subtable = displayedTable(selectedRowNumsInOrder, selectedColumnNumsInOrder);
            
            isCategorical = varfun(@iscategorical, subtable, 'OutputFormat', 'uniform');
        end


        function processorState = getState(obj)
            % Return the current state of the processor
            processorState = struct();
            processorState.activeColumns = obj.activeColumns;
            processorState.selectedTableCellsList = obj.selectedTableCellsList;
        end


        function setState(obj, processorState)
            % disp('FullTableProcessor:setState');
            % disp(processorState)
            % Set the state of the processor
            if isfield(processorState, 'activeColumns')
                obj.activeColumns = processorState.activeColumns;
            end

            if isfield(processorState, 'selectedTableCellsList')
                obj.selectedTableCellsList = processorState.selectedTableCellsList;
            end

            notify(obj, 'tableForDisplayChanged');

            % disp('FullTableProcessor:setState:notify');
            % notify(obj, 'tableSelectionChanged');

            % call just plotting function instead
            notify(obj, 'plotUpdateRequired');
        end


        function setRowSelection(obj, rowNames)
            % Set row selection based on row names
            % rowNames - cell array of row names to select
            
            % Validate input
            if ~iscell(rowNames)
                error('FullTableProcessor:InvalidInput', 'rowNames must be a cell array');
            end
            
            % Get the current displayed table
            displayedTable = obj.getTableForDisplay();
            
            if isempty(displayedTable) || isempty(rowNames)
                obj.selectedTableCellsList = [];
                notify(obj, 'tableSelectionChanged');
                return;
            end
            
            % Match row names to indices
            allRowNames = displayedTable.Properties.RowNames;
            [~, rowIndices] = ismember(rowNames, allRowNames);
            
            % Filter out any row names that weren't found
            validRows = rowIndices > 0;
            rowIndices = rowIndices(validRows);
            
            if isempty(rowIndices)
                obj.selectedTableCellsList = [];
                notify(obj, 'tableSelectionChanged');
                return;
            end
            
            % Create selection cells list - for each row, select all columns
            numColumns = width(displayedTable);

            % Preallocate the array with the exact size needed
            selectedCells = zeros(numel(rowIndices) * numColumns, 2);

            % Fill the array using linear indexing instead of concatenation
            idx = 1;
            for i = 1:numel(rowIndices)
                rowIdx = rowIndices(i);
                selectedCells(idx:idx+numColumns-1, 1) = rowIdx;
                selectedCells(idx:idx+numColumns-1, 2) = 1:numColumns;
                idx = idx + numColumns;
            end
            
            % Store the selection
            obj.selectedTableCellsList = selectedCells;
            
            % Notify changes
            notify(obj, 'tableForDisplayChanged');  % handles also selection update
            % notify(obj, 'tableSelectionChanged');   % TO OPTIMIZE - use tableSelectionChangedProgrammatically instead?

            % update plotting
            notify(obj, 'plotUpdateRequired');
        end


        function editManualColumnValue(obj, columnName, rowName, newValue)
            % Locate the row and column indices for the specified rowName and columnName
            rowIdx = find(strcmp(obj.filteredTable.Properties.RowNames, rowName));
            colIdx = find(strcmp(obj.filteredTable.Properties.VariableNames, columnName));

            if isempty(rowIdx) || isempty(colIdx)
                error('FullTableProcessor:InvalidInput', 'Specified row or column does not exist in the table');
            end

            % Update the value in the filteredTable
            obj.filteredTable{rowIdx, colIdx} = newValue;

            % Notify listeners that the table has changed
            notify(obj, 'tableForDisplayChanged');
        end
    end

    methods (Access = private)
        % Processes the table data by applying filters and updating the filtered table.
        % This method is triggered when data or filters change and ensures the
        % filtered table reflects the current state of the data and active filters.
        function processData(obj)

            rowNames = {};
            colNames = {};
            if ~isempty(obj.selectedTableCellsList) && ~isempty(obj.filteredTable)
                % Store selected row and column names
                [rowNames, colNames] = obj.getSelectedRowAndColumnNames();
            end

            obj.filteredTable = obj.tableStoreHandle.getTableData();
            % disp('FullTableProcessor:processData:filteredTable');
            % disp(obj.filteredTable);

            isKept = obj.filteringStorageHandle.filter(obj.filteredTable);
            if ~isempty(isKept)
                obj.filteredTable = obj.filteredTable(isKept, :);
            end

            % Restore selection using rowNames and colNames as coordinate pairs
            obj.selectedTableCellsList = obj.getSelectedCellsFromNames(rowNames, colNames);

            notify(obj, 'tableForDisplayChanged');
            % notify(obj, 'tableSelectionChanged');

            % 251001 - updating just plotting instead of calling tableSelectionChanged
            % that was probably causing freezing, as two listeners were trying to manipulate UITable at the same time
            notify(obj, 'plotUpdateRequired');

            % getTableForDisplay handles selecting active columns
        end

        function replaceData(obj)
            % this should be called when the data changes

            obj.dataStoreHandle = obj.stateManagerHandle.getActiveDataStore();
            obj.loadData();
        end

        function loadData(obj)
            obj.tableStoreHandle = obj.dataStoreHandle.getTableStore();

            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~, ~) processData(obj));
            
            obj.filteringStorageHandle = obj.dataStoreHandle.getFilteringStorage();

            if ~isempty(obj.filterListener) && isvalid(obj.filterListener)
                delete(obj.filterListener);
            end
            obj.filterListener = addlistener(obj.filteringStorageHandle, 'filtersChanged', @(~, ~) processData(obj));

            obj.activeColumns = intersect(obj.activeColumns, obj.tableStoreHandle.getColumnNames());

            obj.processData();
        end

        function [rowNamesOut, colNamesOut] = getSelectedRowAndColumnNames(obj)
            % Returns two cell arrays: rowNamesOut and colNamesOut, each corresponding to the selected cells.
            % The n-th element in rowNamesOut and n-th in colNamesOut represent one coordinate within the table.
            % If the table does not have row names, row indices are used for rowNamesOut.

            % TO OPTIMIZE - this causes problem if a column is removed

            if isempty(obj.selectedTableCellsList)
                rowNamesOut = {};
                colNamesOut = {};
                return;
            end

            displayedTable = obj.getTableForDisplay();
            selectedRows = obj.selectedTableCellsList(:,1);
            selectedCols = obj.selectedTableCellsList(:,2);

            % Get row names or indices
            if ~isempty(displayedTable.Properties.RowNames)
                allRowNames = displayedTable.Properties.RowNames;
            else
                allRowNames = {};
            end

            allColNames = displayedTable.Properties.VariableNames;

            nSelected = size(obj.selectedTableCellsList, 1);
            rowNamesOut = cell(nSelected, 1);
            colNamesOut = cell(nSelected, 1);

            for k = 1:nSelected
                rowIdx = selectedRows(k);
                colIdx = selectedCols(k);

                if ~isempty(allRowNames)
                    if rowIdx <= length(allRowNames) && rowIdx > 0
                        % Ensure rowIdx is within bounds of allRowNames
                        rowNamesOut{k} = allRowNames{rowIdx};
                    else
                        % Mark this cell for deletion by setting empty values
                        rowNamesOut{k} = '';
                        % This will prevent processing of this invalid selection
                    end
                else
                    if isnumeric(rowIdx) && isscalar(rowIdx) && rowIdx >= 1 && rowIdx <= height(displayedTable)
                        % Use numeric index if no row names
                        rowNamesOut{k} = num2str(rowIdx);
                    else
                        rowNamesOut{k} = ''; % Mark this cell for deletion
                    end
                end
                if colIdx <= length(allColNames) && colIdx > 0
                    % Ensure colIdx is within bounds of allColNames
                    colNamesOut{k} = allColNames{colIdx};
                else
                    % Mark this cell for deletion by setting empty values
                    colNamesOut{k} = '';
                end
              
                % Remove entries with empty values (invalid selections)
                if isempty(rowNamesOut{k}) || isempty(colNamesOut{k})
                    rowNamesOut{k} = [];
                    colNamesOut{k} = [];
                end
            end
        end

        function selectedCells = getSelectedCellsFromNames(obj, rowNames, colNames)
            % Returns the selected cells based on the provided row and column names.
            % The n-th element in rowNames and n-th in colNames represent one coordinate.
            % If the table does not have row names, it uses row indices instead.

            displayedTable = obj.getTableForDisplay();
            if isempty(displayedTable) || isempty(rowNames) || isempty(colNames)
                selectedCells = [];
                return;
            end

            try     % added because I was getting some comparsion error for ismember - TO OPTIMIZE - find out why
                n = min(numel(rowNames), numel(colNames));
                selectedCells = zeros(n, 2);

                if ~isempty(displayedTable.Properties.RowNames)
                    allRowNames = displayedTable.Properties.RowNames;
                    allColNames = displayedTable.Properties.VariableNames;
                    
                    % Create logical matrices for matching
                    [~, rowFound] = ismember(rowNames, allRowNames);
                    [~, colFound] = ismember(colNames, allColNames);
                    
                    % Find valid matches (both row and column found)
                    validMatches = rowFound > 0 & colFound > 0;
                    
                    % Fill the selectedCells array
                    selectedCells(validMatches, 1) = rowFound(validMatches);
                    selectedCells(validMatches, 2) = colFound(validMatches);
                else
                    allColNames = displayedTable.Properties.VariableNames;
                    
                    % Convert rowNames to numeric if possible
                    rowIdxs = str2double(rowNames);
                    validRows = ~isnan(rowIdxs) & rowIdxs >= 1 & rowIdxs <= height(displayedTable);
                    
                    % Find column indices
                    [~, colIdxs] = ismember(colNames, allColNames);
                    validCols = colIdxs > 0;
                    
                    % Find valid matches (both row and column are valid)
                    validMatches = validRows & validCols;
                    
                    % Fill the selectedCells array
                    selectedCells(validMatches, 1) = rowIdxs(validMatches);
                    selectedCells(validMatches, 2) = colIdxs(validMatches);
                end

                % Remove any rows with zeros (invalid matches)
                selectedCells = selectedCells(all(selectedCells > 0, 2), :);
                
                % If isColumnSelectionPreserved is true, add first row for columns with no valid selection
                % Added 251001 to solve the problem with selection disappearing after filtering (because the selected rows were filtered out)
                if obj.isColumnSelectionPreserved && ~isempty(selectedCells)
                    % Get unique column indices that have valid selections
                    selectedColumns = unique(selectedCells(:, 2));
                    
                    % Get all column indices that were requested
                    [~, requestedColumns] = ismember(colNames, displayedTable.Properties.VariableNames);
                    requestedColumns = requestedColumns(requestedColumns > 0);
                    
                    % Find columns that were requested but have no valid selection
                    missingColumns = setdiff(requestedColumns, selectedColumns);
                    
                    % Add first row for missing columns
                    if ~isempty(missingColumns)
                        firstRowSelections = [ones(length(missingColumns), 1), missingColumns(:)];
                        selectedCells = [selectedCells; firstRowSelections];
                    end
                end

                
            catch
                selectedCells = [];
            end
        end


        function newSelectedCells = updateSelectionAfterColumnChange(obj, previouslyActiveColumns, columnNames)
            % Update selectedTableCellsList based on column changes
            % Added 251001 so that the selection can update accordingly if columns are removed or added

            newSelectedCells = [];
            
            if isempty(obj.selectedTableCellsList) || isempty(previouslyActiveColumns)
                return
            end
            % Get unique column indices from current selection
            selectedColIndices = unique(obj.selectedTableCellsList(:,2));
            
            % Preallocate for worst case (all columns remain)
            maxPossibleCells = size(obj.selectedTableCellsList, 1);
            newSelectedCells = zeros(maxPossibleCells, 2);
            cellCount = 0;
            
            for i = 1:length(selectedColIndices)
                oldColIdx = selectedColIndices(i);
                
                % Get the column name from the old active columns
                if oldColIdx <= length(previouslyActiveColumns)
                columnName = previouslyActiveColumns{oldColIdx};
                
                % Find new index of this column in the new column list
                newColIdx = find(strcmp(columnNames, columnName), 1);
                
                if ~isempty(newColIdx)
                    % Find all rows that had this column selected
                    rowsWithThisCol = obj.selectedTableCellsList(obj.selectedTableCellsList(:,2) == oldColIdx, 1);
                    % Update to new column index
                    numNewCells = length(rowsWithThisCol);
                    newSelectedCells(cellCount+1:cellCount+numNewCells, 1) = rowsWithThisCol;
                    newSelectedCells(cellCount+1:cellCount+numNewCells, 2) = newColIdx;
                    cellCount = cellCount + numNewCells;
                end
                % If column not found in new list, it's discarded
                end
            end
            
            % Trim to actual size
            newSelectedCells = newSelectedCells(1:cellCount, :);
        end
    end
end