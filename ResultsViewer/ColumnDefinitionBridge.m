classdef ColumnDefinitionBridge < handle
    % TO OPTIMIZE - it might not be necessary to have this as handle

    % Needs access to the ModalityDataStore and to the main app
    properties (Access = ?matlab.unittest.TestCase)
        modalityDataStore  % Reference to the ModalityDataStore
        irbisApp    % Reference to the main irbis app
    end


    methods
        function obj = ColumnDefinitionBridge(modalityDataStore, irbisApp)
            % Constructor for ColumnDefinitionBridge
            % Inputs:
            %   modalityDataStore - Reference to the ModalityDataStore
            %   irbisApp - Reference to the main irbis app
            
            obj.modalityDataStore = modalityDataStore;
            obj.irbisApp = irbisApp;

            % Add listener
            addlistener(obj.modalityDataStore, 'userColumnDefinitionChanged', @(src, event) obj.columnDefinitionChangedInResultsViewer(src, event));
        end
    end


    methods (Access = ?matlab.unittest.TestCase)
        function columnDefinitionChangedInResultsViewer(obj, ~, event)

            modalityPath = event.modalityPath;  % Get the modality path from the event
            storedCategorizations = obj.irbisApp.getStoredCategorizations(modalityPath);

            columnName = event.name;
            typeOfChange = event.typeOfChange;
            switch typeOfChange
                case 'add'
                    % Handle addition of a new column
                    if ~isempty(storedCategorizations)
                        storedCategorizations.addCategorization(event.userDefinitionObject);
                    end
                    obj.irbisApp.columnDefinitionUpdatedInResultsViewer(modalityPath, columnName);
                case 'remove'
                    % Handle removal of a column
                    if ~isempty(storedCategorizations)
                        storedCategorizations.deleteCategorization(columnName);
                    end
                    obj.irbisApp.columnDefinitionDeletedInResultsViewer(modalityPath, columnName);
                case 'update'
                    % Handle update of a column
                    if ~isempty(storedCategorizations)
                        storedCategorizations.replaceCategorization(event.userDefinitionObject);
                    end
                    obj.irbisApp.columnDefinitionUpdatedInResultsViewer(modalityPath, columnName);
                case 'rename'
                    % Handle renaming of a column
                    oldName = event.oldName;
                    if ~isempty(storedCategorizations)
                        storedCategorizations.renameCategorization(oldName, columnName);
                        % this should not be necessary, as the columnDefinition is the same and therefore already updated
                    end
                    obj.irbisApp.columnRenamedInResultsViewer(modalityPath, oldName, columnName);
                otherwise
                    error('Unknown type of change: %s', typeOfChange);
            end
        end
    end

end