classdef (Sealed) PivotedTableProcessor < handle
    properties (Access = ?matlab.unittest.TestCase)
        pivotedTable = table();     % initialized already as a table because if it was empty, some downstream components were asking for .Properties and were thus throwing warnings
        groupedDataParameter
        columnParameter
        rowParameter
        aggregationFunction
        filteringStorageHandle
        tableStoreHandle
        stateManagerHandle
        dataStoreHandle

        tableStoreListener
        tableStoreTransformationListener
        filterListener
        stateManagerListener

        selectedTableCellsList (:,2) = [] % Initialize as empty array
        rowSelectionMode (1,1) string = "specific"
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

            if ~isempty(obj.tableStoreTransformationListener) && isvalid(obj.tableStoreTransformationListener)
                delete(obj.tableStoreTransformationListener);
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

            obj.processDataWithoutNotification(); 

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

            if isempty(filteredTable)
                obj.pivotedTable = table(); % Return an empty table if filteredTable is empty
                return;
            end

            obj.pivotedTable = pivotTable(filteredTable, obj.columnParameter, obj.rowParameter, obj.groupedDataParameter);

            % REPLACED WITH GENERAL TRANFORMATIONS, kept here for now for info about NaN handling:
            % apply normalization by dividing each value in the row by the first value in the row, if the setting is on
            % if the first column is 0/NaN, find the first non-zero/non-NaN value and divide by it, if it exists, otherwise keep the row as is (all zeros/NaNs)

            % apply transformation to the pivoted table if the setting is on
            [doTransform, transform] = obj.tableStoreHandle.getPivotedTransformationStatus();
            if doTransform && ~isempty(transform)
                A = table2array(obj.pivotedTable);
                transformedA = transform.dataFcn(A);
                transformedColumnNames = transform.nameFcn(obj.pivotedTable.Properties.VariableNames);
                obj.pivotedTable = array2table(transformedA, 'VariableNames', transformedColumnNames, 'RowNames', obj.pivotedTable.Properties.RowNames);
            end

            if obj.rowSelectionMode == "allVisible"
                obj.selectedTableCellsList = obj.getAllVisibleRowSelection();
            else
                % Loading a different dataset or applying synchronized filters can shrink
                % the pivoted table while a previous specific selection is still stored.
                % Keep only cells that are valid for the current display so the UI table
                % never receives stale row/column indices.
                [obj.selectedTableCellsList, ~] = obj.validateSelection(obj.selectedTableCellsList);
            end
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

            if obj.rowSelectionMode == "allVisible"
                obj.selectedTableCellsList = obj.getAllVisibleRowSelection();
            else
                % Filtering can remove rows from the displayed table. Specific
                % selections must be clipped before listeners forward them to the UI.
                [obj.selectedTableCellsList, ~] = obj.validateSelection(obj.selectedTableCellsList);
            end

            notify(obj, 'tableForDisplayChanged');
        end



        function setRowSynchronizedFilteringStorage(obj, rowParameter, keptRowNames)
            % Activate persistent row synchronization filtering for future pivot table recalculations.
            if ~obj.hasUsableFilteringStorage()
                return
            end

            obj.ensureRowSynchronizedFilteringStorage();

            if ~obj.hasUsableFilteringStorage()
                return
            end

            obj.filteringStorageHandle.setRowSync(rowParameter, keptRowNames);
        end



        function clearRowSynchronizedFilteringStorage(obj)
            % Restore the original filtering storage when row synchronization is no longer needed.
            if ~obj.hasUsableFilteringStorage()
                return
            end

            if ~isa(obj.filteringStorageHandle, 'RowSynchronizedFilteringStorage')
                return
            end

            synchronizedFilteringStorage = obj.filteringStorageHandle;
            obj.filteringStorageHandle = synchronizedFilteringStorage.getBaseFilteringStorage();
            delete(synchronizedFilteringStorage);
            obj.rebuildFilterListener();

            % During stored-view teardown or app shutdown, row-sync cleanup can be
            % called after the table store has already been deleted. In that case
            % the important work is listener/storage cleanup; there is no live UI
            % left that needs a recalculated pivoted table.
            if obj.hasUsableTableStore()
                obj.processData();
            end
        end



        function setAggregationFunction(obj, func)
            obj.aggregationFunction = func;
        end



        function result = getTableForDisplay(obj)
            result = obj.pivotedTable;
             
            % Add names of the row and column parameters to the table, so that they can be ingested during plotting
            % Added here because the getSelected functions is getting the data directly from here, so there is lower risk of lost or outdated info
            if ~isempty(result)
                result.Properties.UserData.rowParameter = obj.rowParameter;
                result.Properties.UserData.columnParameter = obj.columnParameter;
                result.Properties.UserData.groupedDataParameter = obj.groupedDataParameter;
            end
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

            if ~isempty(obj.tableStoreTransformationListener) && isvalid(obj.tableStoreTransformationListener)
                delete(obj.tableStoreTransformationListener);
            end
            obj.tableStoreTransformationListener = addlistener(obj.tableStoreHandle, 'pivotedTransformationChanged', @(~, ~) processData(obj));
            
            obj.filteringStorageHandle = obj.dataStoreHandle.getFilteringStorage();

            obj.rebuildFilterListener();

            obj.processData();
        end



        function storeSelectedTableCellsList(obj, selectedTableCellsList)
            % Validates and stores the selected table cells
            obj.selectedTableCellsList = selectedTableCellsList;
            obj.rowSelectionMode = obj.detectRowSelectionMode(selectedTableCellsList);
            notify(obj, 'tableSelectionSyncRequired'); % added first, because syncing must be before plotting (to be able to combine the data)
            notify(obj, 'tableSelectionChanged'); % this is observed by DataFormatter that processes data for plotting - needs data from both tables, if applicable
        end



        function programmaticallySetRowSelection(obj, selectedRowsList)
            % Convert row indices to selectedTableCellsList after clipping them
            % against the current display. Selection sync can receive indices from
            % a different table shape during dataset changes, and MATLAB rejects
            % out-of-bounds UITable.Selection values.
            displayedTable = obj.getTableForDisplay();
            selectedRowsList = obj.keepValidDisplayedRows(selectedRowsList, displayedTable);

            numRows = numel(selectedRowsList);
            numCols = width(displayedTable);
            processedSelectionList = NaN(numRows * numCols, 2); % Preallocate the array
            index = 1;

            for i = 1:numRows
                row = selectedRowsList(i);
                cols = (1:numCols)';
                processedSelectionList(index:(index + numCols - 1), :) = [repmat(row, numCols, 1), cols];
                index = index + numCols;
            end

            obj.selectedTableCellsList = processedSelectionList;
            obj.rowSelectionMode = obj.detectRowSelectionMode(processedSelectionList);

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
                obj.rowSelectionMode = "specific";
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
                obj.rowSelectionMode = "specific";
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
            obj.rowSelectionMode = obj.detectRowSelectionMode(selectedCells);
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
            processorState.rowSelectionMode = obj.rowSelectionMode;

            % include also information about table transformation
            [doTransformation, transformationName, parameterValue] = obj.tableStoreHandle.getPivotedTransformationSpecs();
            processorState.transformation.do = doTransformation;
            processorState.transformation.name = transformationName;
            processorState.transformation.parameterValue = parameterValue;
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

                if isfield(processorState, 'rowSelectionMode')
                    obj.rowSelectionMode = string(processorState.rowSelectionMode);
                else
                    obj.rowSelectionMode = obj.detectRowSelectionMode(obj.selectedTableCellsList);
                end

                if obj.rowSelectionMode == "allVisible"
                    obj.selectedTableCellsList = obj.getAllVisibleRowSelection();
                end

                % Set the transformation status to the tableStore based on the saved state
                % GUI update is left for the componentHelper, because processor does not have component's handle
                if isfield(processorState, 'transformation')
                    doTransformation = processorState.transformation.do;
                    transformationName = processorState.transformation.name;
                    parameterValue = processorState.transformation.parameterValue;

                    obj.tableStoreHandle.setPivotedTransformationStatus(doTransformation, transformationName, parameterValue);
                else
                    % If the transformation field is not present in the state, reset to default (no transformation)
                    obj.tableStoreHandle.setPivotedTransformationStatus(false, 'none', []);
                end

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



        function rowSelectionMode = detectRowSelectionMode(obj, selectedTableCellsList)
            % Return all-visible mode when every currently displayed row has at least one selected cell.
            displayedTable = obj.getTableForDisplay();

            if isempty(displayedTable) || isempty(selectedTableCellsList)
                rowSelectionMode = "specific";
                return
            end

            selectedRows = unique(selectedTableCellsList(:, 1));
            allDisplayedRows = (1:height(displayedTable))';
            if numel(selectedRows) == height(displayedTable) && all(ismember(allDisplayedRows, selectedRows))
                rowSelectionMode = "allVisible";
            else
                rowSelectionMode = "specific";
            end
        end



        function selectedCells = getAllVisibleRowSelection(obj)
            % Select every cell in the displayed table because the user selected all visible rows before filtering changed.
            displayedTable = obj.getTableForDisplay();

            if isempty(displayedTable) || width(displayedTable) == 0
                selectedCells = [];
                return
            end

            [rowGrid, colGrid] = ndgrid(1:height(displayedTable), 1:width(displayedTable));
            selectedCells = [rowGrid(:), colGrid(:)];
        end



        function validRows = keepValidDisplayedRows(~, selectedRowsList, displayedTable)
            % Return only finite integer row indices that exist in displayedTable.
            % This helper is deliberately close to the UI-facing selection code:
            % the processor is the last reliable place to prevent stale synchronized
            % rows from reaching UITable.Selection.
            validRows = [];

            if isempty(selectedRowsList) || isempty(displayedTable) || width(displayedTable) == 0
                return
            end

            selectedRowsList = selectedRowsList(:);
            isValid = isfinite(selectedRowsList) & ...
                mod(selectedRowsList, 1) == 0 & ...
                selectedRowsList >= 1 & ...
                selectedRowsList <= height(displayedTable);
            validRows = selectedRowsList(isValid);
        end



        function programmaticallySetRowParameter(obj, rowParameter)
            % Set the row parameter programmatically
            obj.rowParameter = rowParameter;

            notify(obj, 'rowParameterSetProgrammatically')

            obj.processData();
        end



        function ensureRowSynchronizedFilteringStorage(obj)
            % Wrap the current filtering storage when row synchronization needs to be applied.
            if ~obj.hasUsableFilteringStorage()
                return
            end

            if isa(obj.filteringStorageHandle, 'RowSynchronizedFilteringStorage')
                return
            end

            obj.filteringStorageHandle = RowSynchronizedFilteringStorage(obj.filteringStorageHandle);
            obj.rebuildFilterListener();
        end



        function rebuildFilterListener(obj)
            % Recreate the filter listener after the filtering storage handle changes.
            if ~isempty(obj.filterListener) && isvalid(obj.filterListener)
                delete(obj.filterListener);
            end

            obj.filterListener = addlistener(obj.filteringStorageHandle, 'filtersChanged', @(~, ~) processData(obj));
        end



        function tf = hasUsableFilteringStorage(obj)
            % Stored-view restore can leave an old processor with a property that
            % still points to a deleted filtering-storage handle. Accessing class
            % information or methods on that handle raises "Invalid or deleted
            % object", so row synchronization must check liveness first.
            try
                tf = ~isempty(obj.filteringStorageHandle) && ...
                    (~isa(obj.filteringStorageHandle, 'handle') || isvalid(obj.filteringStorageHandle));
            catch
                tf = false;
            end
        end



        function tf = hasUsableTableStore(obj)
            % Return true only when the table store can still be queried. Listener
            % cleanup can happen late in UI/app teardown, where handle properties
            % may still exist but point to deleted objects.
            try
                tf = ~isempty(obj.tableStoreHandle) && ...
                    (~isa(obj.tableStoreHandle, 'handle') || isvalid(obj.tableStoreHandle));
            catch
                tf = false;
            end
        end
    end
end
