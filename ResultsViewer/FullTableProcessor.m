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
    end

    events
        tableForDisplayChanged
        tableSelectionChanged
        tableSelectionSetProgrammatically
        tableSelectionSyncRequired  % not the prettiest, but added to do table syncing before plotting data starts listening
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

            obj.activeColumns = columnNames;
            notify(obj, 'tableForDisplayChanged');  
        end


        function selectedList = getSelectedTableCellsList(obj)
            selectedList = obj.selectedTableCellsList;
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
            notify(obj, 'tableSelectionChanged');
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
            notify(obj, 'tableSelectionChanged');

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
                    rowNamesOut{k} = allRowNames{rowIdx};
                else
                    rowNamesOut{k} = rowIdx; % Use index if no row names
                end
                colNamesOut{k} = allColNames{colIdx};
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

            n = min(numel(rowNames), numel(colNames));
            selectedCells = zeros(n, 2);

            if ~isempty(displayedTable.Properties.RowNames)
                allRowNames = displayedTable.Properties.RowNames;
                for k = 1:n
                    rowIdx = find(strcmp(allRowNames, rowNames{k}), 1);
                    colIdx = find(strcmp(displayedTable.Properties.VariableNames, colNames{k}), 1);
                    if ~isempty(rowIdx) && ~isempty(colIdx)
                        selectedCells(k, :) = [rowIdx, colIdx];
                    end
                end
            else
                for k = 1:n
                    rowIdx = rowNames{k};
                    colIdx = find(strcmp(displayedTable.Properties.VariableNames, colNames{k}), 1);
                    % Ensure rowIdx is a valid numeric index within the table
                    if isnumeric(rowIdx) && isscalar(rowIdx) && rowIdx >= 1 && rowIdx <= height(displayedTable) && ~isempty(colIdx)
                        selectedCells(k, :) = [rowIdx, colIdx];
                    end
                end
            end

            % Remove any rows with zeros (invalid matches)
            selectedCells = selectedCells(all(selectedCells > 0, 2), :);
        end
    end
end