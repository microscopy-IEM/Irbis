classdef SelectionSyncData < event.EventData
    properties
        branch      % String representing branch name
        selectedIds     % Numeric array of selected IDs
        currentTimePoint    % Double representing time point
    end
    
    methods
        function obj = SelectionSyncData(branch, selectedIds, currentTimePoint)
            % Constructor for EventData class
            if nargin > 0
                obj.branch = branch;
                obj.selectedIds = selectedIds;
                obj.currentTimePoint = currentTimePoint;
            end
        end
    end
end