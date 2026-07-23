classdef LocalDataFormatterProcessor < handle
    properties
        selectedTable = table()
        selectedRowsTable = table()
        selectedColumnsTable = table()
        selectedIsCategorical = []
    end



    events
        tableSelectionChanged
        plotUpdateRequired
    end



    methods
        function obj = LocalDataFormatterProcessor(selectedTable, selectedIsCategorical)
            if nargin > 0
                obj.selectedTable = selectedTable;
                obj.selectedRowsTable = selectedTable;
                obj.selectedColumnsTable = selectedTable;
            end

            if nargin > 1
                obj.selectedIsCategorical = selectedIsCategorical;
            end
        end



        function [subtable, isCategorical] = getSelected(obj)
            subtable = obj.selectedTable;
            isCategorical = obj.selectedIsCategorical;
        end



        function [subtable, isCategorical] = getSelectedRows(obj)
            subtable = obj.selectedRowsTable;
            isCategorical = obj.selectedIsCategorical;
        end



        function [subtable, isCategorical] = getSelectedColumns(obj)
            subtable = obj.selectedColumnsTable;
            isCategorical = obj.selectedIsCategorical;
        end
    end
end
