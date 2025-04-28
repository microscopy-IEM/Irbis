classdef (Sealed) SummarizedTableProcessor < handle

    properties (Access = private)

        rowParameter = ''   % decides which summarized table is going to be used
        
        filteredTable
        activeColumns = {}

        selectedTableCellsList (:,2) = [] % List of selected table cells nx2 array

        isKeptBooleanList = []

        dataStoreHandle
        stateManagerHandle
        tableStoreHandle
        summarizedTableStoreHandle

        summarizedFilteringStorageHandle

        summarizedTableListener
        stateManagerListener
        summarizedFilteringStorageListener
    end

    events
        tableForDisplayChanged
        tableSelectionChanged
        tableSelectionSetProgrammatically
        rowParameterSetProgrammatically
        tableSelectionSyncRequired  % not the prettiest, but added to do table syncing before plotting data starts listening
        rowParameterChanged
        newFiltersApplied
    end

    methods
        function obj = SummarizedTableProcessor()
        end

        function delete(obj)
            % Destructor - clean up listeners
            if ~isempty(obj.summarizedTableListener) && isvalid(obj.summarizedTableListener)
                delete(obj.summarizedTableListener);
            end

            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end

            if ~isempty(obj.summarizedFilteringStorageListener) && isvalid(obj.summarizedFilteringStorageListener)
                delete(obj.summarizedFilteringStorageListener);
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

        function setState(obj, processorState)

            % Set the state of the processor
            if isfield(processorState, 'activeColumns')
                obj.activeColumns = processorState.activeColumns;
            end

            if isfield(processorState, 'selectedTableCellsList')
                obj.selectedTableCellsList = processorState.selectedTableCellsList;
            end

            notify(obj, 'tableForDisplayChanged');
            notify(obj, 'tableSelectionChanged');
        end 
    end

    methods
        function processData(obj)
            % Process data

            % Processing data includes taking the raw data  
            %   aggegate them into rows (for example by having each row for one category)
            % doing statistics on the columns across another variable
                % broader version: allow different column aggregation (timepoint, ...)
                % narrower version: only one column aggregation (timepoint)

            % TO IMPLEMENT - filtering

            if isempty(obj.summarizedTableStoreHandle)
                obj.loadDataForGrouping();
                return;
            end

            if ~isempty(obj.activeColumns)
                % I need to get a table containing both the filtered columns and the active columns
                columnsForFiltering = obj.summarizedFilteringStorageHandle.returnGroupingNames();
                columnsToGet = [columnsForFiltering(:); obj.activeColumns(:)];
                tableForFiltering = obj.summarizedTableStoreHandle.getTableSubsetByName(columnsToGet);

                % Filter the table and keep only the active columns
                isKept = obj.summarizedFilteringStorageHandle.filter(tableForFiltering);
                obj.isKeptBooleanList = isKept;
                if ~isempty(isKept)
                    obj.filteredTable = tableForFiltering(isKept, obj.activeColumns);
                else
                    obj.filteredTable = tableForFiltering(:, obj.activeColumns);
                end
            else
                obj.filteredTable = table();
            end

            notify(obj, 'tableForDisplayChanged');
        end


        function filterData(obj)
            obj.processData();
            notify(obj, 'newFiltersApplied')
        end


        function isKept = getKeptBooleanList(obj)
            isKept = obj.isKeptBooleanList;
        end


        function setActiveColumns(obj, columnNames)
            obj.activeColumns = columnNames;
            obj.processData();
        end


        function setRowParameter(obj, rowParameter)
            % Set the row parameter for the summarized table
            obj.rowParameter = rowParameter;
            obj.loadDataForGrouping();
            notify(obj, 'rowParameterChanged');
        end


        function rowParameter = getRowParameter(obj)
            rowParameter = obj.rowParameter;
        end


        function [name, type] = getRowParameterNameAndType(obj)
            % Returns the name and type of the row parameter
            if isempty(obj.rowParameter)
                name = '';
                type = '';
            else
                name = obj.rowParameter;
                % type = obj.tableStoreHandle.getClassOfColumn(name);
                type = 'categorical';   % TO FIX - I was getting errors for some reason
            end
        end


        function tableForDisplay = getTableForDisplay(obj)
            % Get table for display
            tableForDisplay = obj.filteredTable;
        end


        function replaceData(obj)
            obj.dataStoreHandle = obj.stateManagerHandle.getActiveDataStore();
            obj.loadData();
        end


        function loadData(obj)
            obj.loadDataForGrouping();
        end
        

        function loadDataForGrouping(obj)
            if isempty(obj.rowParameter)
                return
            end
            obj.summarizedTableStoreHandle = obj.dataStoreHandle.getSummarizedTableStore(obj.rowParameter);
            if ~isempty(obj.summarizedTableListener) && isvalid(obj.summarizedTableListener)
                delete(obj.summarizedTableListener);
            end
            obj.summarizedTableListener = addlistener(obj.summarizedTableStoreHandle, 'tableDataChanged', @(~,~)processData(obj));

            obj.summarizedFilteringStorageHandle = obj.dataStoreHandle.getSummarizedFilteringStorage(obj.rowParameter);

            if ~isempty(obj.summarizedFilteringStorageListener) && isvalid(obj.summarizedFilteringStorageListener)
                delete(obj.summarizedFilteringStorageListener);
            end
            obj.summarizedFilteringStorageListener = addlistener(obj.summarizedFilteringStorageHandle, 'filtersChanged', @(~,~)filterData(obj));

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
            numCols = width(obj.filteredTable);
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


        function selectedList = getSelectedTableCellsList(obj)
            selectedList = obj.selectedTableCellsList;
        end


        function setSelectedColumns(obj, columnNames)
            obj.activeColumns = columnNames;
            notify(obj, 'tableForDisplayChanged');
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
            processorState.rowParameter = obj.rowParameter;
            processorState.activeColumns = obj.activeColumns;
            processorState.selectedTableCellsList = obj.selectedTableCellsList;
        end


        function programmaticallySetRowParameter(obj, rowParameter)
            % Set the row parameter programmatically
            obj.rowParameter = rowParameter;

            notify(obj, 'rowParameterSetProgrammatically')

            obj.loadDataForGrouping();
            obj.processData();
        end
    end
end