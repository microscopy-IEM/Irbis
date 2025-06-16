classdef ColumnDefinitionEvent < event.EventData
    % ColumnDefinitionEvent is an event class for column definition changes.
    % Column definition changes need to be propagated from TableStore (through DataStore and AppStateManager) to the main app and vice versa
    % It contains the column name, change type, and new object
    % At the moment, if we update/rename a column, the handle object stays the same, it is just updated
    
    properties
        name  % Name of the column
        oldName = '' % Old name of the column, used for renaming
        typeOfChange  % Type of the change (add/remove/update/rename)
            % rename is the same as update, but it does not require recalculation of the column
        userDefinitionObject % The column definition object
        modalityPath = {} % Path to the modality - added in later steps 
    end
    
    methods
        function obj = ColumnDefinitionEvent(name, typeOfChange, userDefinitionObject)
            % Constructor for ColumnDefinitionEvent
            % Inputs:
            %   name - Name of the column
            %   typeOfChange - Type of the change (add/remove/update/rename)
            %   userDefinitionObject - The column definition object
            
            obj.name = name;
            obj.typeOfChange = typeOfChange;
            obj.userDefinitionObject = userDefinitionObject;
        end


        function setOldName(obj, oldName)
            % Set the old name of the column
            % This is useful for renaming columns
            
            if ischar(oldName) || isstring(oldName)
                obj.oldName = oldName;
            else
                error('Old name must be a string or character array.');
            end
        end


        function setModalityPath(obj, modalityPath)
            % Set the modality path for the event
            % This is useful for context when notifying listeners
            
            if iscell(modalityPath)
                obj.modalityPath = modalityPath;
            else
                error('Modality path must be a cell array of strings.');
            end
        end
    end
end