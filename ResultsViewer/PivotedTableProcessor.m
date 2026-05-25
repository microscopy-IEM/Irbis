classdef (Sealed) PivotedTableProcessor < handle
    properties (Access = ?matlab.unittest.TestCase)
        pivotedTable
        groupedDataParameter
        columnParameter
        rowParameter
        aggregationFunction
        filteringStorageHandle
        tableStoreHandle
        stateManagerHandle
        dataStoreHandle

        tableStoreListener
        filterListener
        stateManagerListener

        selectedTableCellsList (:,2) = [] % Initialize as empty array
    end




    events
        tableForDisplayChanged
        tableSelectionChanged
        tableSelectionSetProgrammatically
        rowParameterSetProgrammatically
        tableSelectionSyncRequired  % not the prettiest, but added to do table syncing before plotting data starts listening
        rowParameterChanged
        plotUpdateRequired
    end




    methods
        function obj = PivotedTableProcessor()
        end



        function delete(obj)
            % Destructor - clean up listeners
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end

            if ~isempty(obj.filterListener) && isvalid(obj.filterListener)
                delete(obj.filterListener);
            end

            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
        end



        function setHandles(obj, stateManagerHandle, dataStoreHandle)

            obj.stateManagerHandle = stateManagerHandle;
            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
            obj.stateManagerListener = addlistener(obj.stateManagerHandle, 'newModalityLoaded', @(~, ~) replaceData(obj));

            obj.dataStoreHandle = dataStoreHandle;
            obj.loadData();
        end

        

        function processData(obj)

            rawTable = obj.tableStoreHandle.getTableData();

            isMissingParameters = isempty(obj.groupedDataParameter) || isempty(obj.columnParameter) || isempty(obj.rowParameter);
            if isMissingParameters
                return;
            end

            isMissingData = isempty(rawTable);
            if isMissingData
                return;
            end

            % filter
            isKept = obj.filteringStorageHandle.filter(rawTable);
            if ~isempty(isKept)
                filteredTable = rawTable(isKept, :);
            else
                filteredTable = rawTable;
            end

            obj.pivotedTable = pivotTable(filteredTable, obj.columnParameter, obj.rowParameter, obj.groupedDataParameter);

            % apply normalization by dividing each value in the row by the first value in the row, if the setting is on
            % if the first column is 0/NaN, find the first non-zero/non-NaN value and divide by it, if it exists, otherwise keep the row as is (all zeros/NaNs)
            doNormalizeByFirst = obj.tableStoreHandle.getNormalizationStatus();
            if doNormalizeByFirst
                obj.pivotedTable = normalizeByFirstValueInRow(obj.pivotedTable);
            end
            % disp(obj.pivotedTable)

            notify(obj, 'tableForDisplayChanged');

            % notify the plottling component that the plot needs to be updated
            notify(obj, 'plotUpdateRequired');
        end



        function processDataWithoutNotification(obj)
            % Process data without notifying observers
            rawTable = obj.tableStoreHandle.getTableData();

            isMissingParameters = isempty(obj.groupedDataParameter) || isempty(obj.columnParameter) || isempty(obj.rowParameter);
            if isMissingParameters
                return;
            end

            isMissingData = isempty(rawTable);
            if isMissingData
                return;
            end

            % filter
            isKept = obj.filteringStorageHandle.filter(rawTable);
            if ~isempty(isKept)
                filteredTable = rawTable(isKept, :);
            else
                filteredTable = rawTable;
            end

            obj.pivotedTable = pivotTable(filteredTable, obj.columnParameter, obj.rowParameter, obj.groupedDataParameter);
        end

        

        function filterWithBooleanList(obj, isKept)
            % Filter the data with a boolean list
            if isempty(obj.tableStoreHandle)
                return;
            end

            obj.processDataWithoutNotification(); 
            if ~isempty(isKept)
                obj.pivotedTable = obj.pivotedTable(isKept, :);
            end

            notify(obj, 'tableForDisplayChanged');
        end



        function setAggregationFunction(obj, func)
            obj.aggregationFunction = func;
        end



        function result = getTableForDisplay(obj)
            result = obj.pivotedTable;
        end



        function setGroupedDataParameter(obj, parameter)
            obj.groupedDataParameter = parameter;
            obj.processData();
        end



        function setColumnParameter(obj, parameter)
            obj.columnParameter = parameter;
            obj.processData();
        end



        function setRowParameter(obj, parameter)
            obj.rowParameter = parameter;
            obj.processData();
            notify(obj, 'rowParameterChanged');
        end



        function replaceData(obj)
            % this should be called when the data changes

            obj.dataStoreHandle = obj.stateManagerHandle.getActiveDataStore();
            obj.loadData();
        end



        function [name, type] = getRowParameterNameAndType(obj)
            % Returns the name and type of the row parameter
            if isempty(obj.rowParameter)
                name = '';
                type = '';
            else
                name = obj.rowParameter;
                type = obj.tableStoreHandle.getClassOfColumn(name);
                if iscell(type)
                    type = type{1};
                end
            end
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

            obj.processData();
        end



        function storeSelectedTableCellsList(obj, selectedTableCellsList)
            % Validates and stores the selected table cells
            obj.selectedTableCellsList = selectedTableCellsList;
            notify(obj, 'tableSelectionSyncRequired'); % added first, because syncing must be before plotting (to be able to combine the data)
            notify(obj, 'tableSelectionChanged'); % this is observed by DataFormatter that processes data for plotting - needs data from both tables, if applicable
        end



        function programmaticallySetRowSelection(obj, selectedRowsList)
            % convert row selection to selectedTableCellsList
            numRows = numel(selectedRowsList);
            numCols = width(obj.pivotedTable);
            processedSelectionList = NaN(numRows * numCols, 2); % Preallocate the array
            index = 1;

            for i = 1:numRows
                row = selectedRowsList(i);
                cols = (1:numCols)';
                processedSelectionList(index:(index + numCols - 1), :) = [repmat(row, numCols, 1), cols];
                index = index + numCols;
            end

            obj.selectedTableCellsList = processedSelectionList;

            notify(obj, 'tableSelectionSetProgrammatically')     % notify the component, since we do not have direct link to it
        end



        function setRowSelection(obj, rowNames)
            % Set row selection based on row names
            % rowNames - cell array of row names to select
            % disp("setting row selection in pivoted table processor")
            % Validate input
            if ~iscell(rowNames)
                error('FullTableProcessor:InvalidInput', 'rowNames must be a cell array');
            end
            
            % Get the current displayed table
            displayedTable = obj.getTableForDisplay();
            
            if isempty(displayedTable) || isempty(rowNames)
                disp("No table to select from or empty row names provided. Clearing selection.")
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
            % disp(obj.selectedTableCellsList)
            
            % Notify changes
            notify(obj, 'tableSelectionChanged');
            % update plotting
            % notify(obj, 'plotUpdateRequired');
        end



        function selectedList = getSelectedTableCellsList(obj)
            selectedList = obj.selectedTableCellsList;
        end



        function [subtable, isCategorical] = getSelectedColumns(obj)
            if isempty(obj.selectedTableCellsList)
                subtable = table();
                isCategorical = [];
                warning('FullTableProcessor:NoSelection', 'No cells are selected');
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
            processorState.groupedDataParameter = obj.groupedDataParameter;
            processorState.columnParameter = obj.columnParameter;
            processorState.rowParameter = obj.rowParameter;
            processorState.selectedTableCellsList = obj.selectedTableCellsList;
        end



        function setState(obj, processorState)
            % Set the state of the processor
            if ~isempty(processorState)
                usedColumnNames = {processorState.groupedDataParameter, processorState.columnParameter, processorState.rowParameter};
                [areColumnsValid, invalidColumnNames] = obj.tableStoreHandle.validateColumnsExist(usedColumnNames);
                if ~areColumnsValid
                    % TO FIX - this check should be probably in ComponentHelper rather than here
                    % TO FIX - with the current setup, there are loops in calls - should be cleaned
                    % the dropdowns will be just filled with default values
                    ME = MException('TableProcessor:InvalidState', 'The following columns specified in the state do not exist in the table: %s', strjoin(invalidColumnNames, ', '));
                    throw(ME);
                end
                obj.groupedDataParameter = processorState.groupedDataParameter;
                obj.columnParameter = processorState.columnParameter;
                obj.rowParameter = processorState.rowParameter;
                [validSelection, ~] = obj.validateSelection(processorState.selectedTableCellsList);
                obj.selectedTableCellsList = validSelection;


                notify(obj, 'tableForDisplayChanged')
                notify(obj, 'tableSelectionSetProgrammatically')

                % notify the plottling component that the plot needs to be updated 
                notify(obj, 'plotUpdateRequired');
            end
        end



        function [validSelection, isAllValid] = validateSelection(obj, selection)
            % validates that selection fits within the size of the table
            % used for example when applying view, so that out-of-bounds error is not thrown
            % input: 
            %   - selectionCellsList
            %
            % output: 
            %   - validSelection - list of in-bounds selected cells, same format as selection (selectedTableCellsList)
            %   - isAllValid - boolean value saying whether all cell indices fit within the table
            % 
            validSelection = [];
            isAllValid = true;

            if isempty(selection)
                return
            end

            if ~isnumeric(selection) || size(selection, 2) ~= 2
                isAllValid = false;
                return
            end

            displayedTable = obj.getTableForDisplay();
            if isempty(displayedTable)
                isAllValid = false;
                return
            end

            numRows = height(displayedTable);
            numCols = width(displayedTable);

            rows = selection(:, 1);
            cols = selection(:, 2);

            isFiniteInteger = isfinite(rows) & isfinite(cols) & (mod(rows, 1) == 0) & (mod(cols, 1) == 0);
            isInBounds = rows >= 1 & rows <= numRows & cols >= 1 & cols <= numCols;
            isValid = isFiniteInteger & isInBounds;

            validSelection = selection(isValid, :);
            isAllValid = all(isValid);
        end



        function programmaticallySetRowParameter(obj, rowParameter)
            % Set the row parameter programmatically
            obj.rowParameter = rowParameter;

            notify(obj, 'rowParameterSetProgrammatically')

            obj.processData();
        end
    end
end