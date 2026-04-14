classdef SelectionSyncData < event.EventData
    properties
        branch      % String representing branch name
        selectedIds     % Numeric array of selected IDs
        selectedGroupIds    % Numeric array of selected group IDs
        currentTimePoint    % Double representing time point
    end
    
    methods
        function obj = SelectionSyncData(branch, selectedIds, selectedGroupIds, currentTimePoint)
            % Constructor for EventData class
            if nargin > 0
                obj.branch = branch;
                obj.selectedIds = selectedIds;
                obj.selectedGroupIds = selectedGroupIds; % Store selected group IDs
                obj.currentTimePoint = currentTimePoint;
            end
        end
    end
end