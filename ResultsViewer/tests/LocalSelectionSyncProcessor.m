classdef LocalSelectionSyncProcessor < handle
    properties
        displayedTable
        selectedTableCellsList (:,2) = []
        rowParameter = 'Category'
        rowType = 'categorical'
        receivedRows = []
        receivedRowSyncParameter = ''
        receivedKeptRowNames = strings(0, 1)
    end



    events
        tableSelectionSyncRequired
        tableSelectionSetProgrammatically
        rowParameterChanged
        newFiltersApplied
    end



    methods
        function obj = LocalSelectionSyncProcessor(displayedTable)
            obj.displayedTable = displayedTable;
        end



        function tableForDisplay = getTableForDisplay(obj)
            tableForDisplay = obj.displayedTable;
        end



        function selectedList = getSelectedTableCellsList(obj)
            selectedList = obj.selectedTableCellsList;
        end



        function programmaticallySetRowSelection(obj, selectedRowsList)
            % Store the exact rows received from the synchronizer so tests can
            % verify row-name mapping without depending on a full UI component.
            obj.receivedRows = selectedRowsList(:);
            obj.selectedTableCellsList = [obj.receivedRows, ones(numel(obj.receivedRows), 1)];
            notify(obj, 'tableSelectionSetProgrammatically');
        end



        function [name, type] = getRowParameterNameAndType(obj)
            name = obj.rowParameter;
            type = obj.rowType;
        end



        function programmaticallySetRowParameter(obj, rowParameter)
            obj.rowParameter = rowParameter;
        end



        function rowNames = getKeptRowNames(obj)
            % Return the displayed row names to mimic SummarizedTableProcessor
            % during row-synchronized filtering tests.
            rowNames = string(obj.displayedTable.Properties.RowNames(:));
        end



        function setRowSynchronizedFilteringStorage(obj, rowParameter, keptRowNames)
            % Store the requested filter sync instead of applying real filters.
            % This keeps synchronizer tests focused on listener/handle behavior.
            obj.receivedRowSyncParameter = rowParameter;
            obj.receivedKeptRowNames = string(keptRowNames(:));
        end
    end
end
