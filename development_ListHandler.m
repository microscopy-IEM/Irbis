classdef ListHandler()

    % ListHandler

    properties
        List                % Cell array of tables
        currentTableId 
        timelineHandle
    end

    methods
        function getCurrentTable(obj)
        end

        function getTableForTimepoint(obj, timepoint)
            % Get the table for a specific timepoint

            % Get cellId from the timepoint
            cellId = timelineHandle.getCellIdForTimepoint(timepoint);
        end
    end