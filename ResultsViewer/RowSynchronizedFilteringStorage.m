classdef (Sealed) RowSynchronizedFilteringStorage < handle
    properties (Access = private)
        baseFilteringStorage
        baseFilteringStorageListener
        rowSyncActive (1,1) logical = false
        rowParameter (1,1) string = ""
        keptRowNames (:,1) string = strings(0, 1)
    end

    events
        filtersChanged
    end

    %% Lifecycle

    methods
        function obj = RowSynchronizedFilteringStorage(baseFilteringStorage)
            % Wrap a base filtering storage object and forward its filter change events.
            if nargin == 0 || isempty(baseFilteringStorage)
                error("RowSynchronizedFilteringStorage:MissingBaseStorage", ...
                    "A base filtering storage object is required.");
            end

            obj.baseFilteringStorage = baseFilteringStorage;
            % I do not want to add this filtering here, because it is included in the filtering from the Summarized table as well 
            % obj.baseFilteringStorageListener = addlistener(obj.baseFilteringStorage, "filtersChanged", @(~, ~) notify(obj, "filtersChanged"));
        end



        function delete(obj)
            % Delete the listener attached to the wrapped filtering storage object.
            if ~isempty(obj.baseFilteringStorageListener) && isvalid(obj.baseFilteringStorageListener)
                delete(obj.baseFilteringStorageListener);
            end
        end



        %% Filtering

        function isKept = filter(obj, rawTable)
            % Apply the base filters and optionally restrict rows to synchronized row values.
            isKept = obj.baseFilteringStorage.filter(rawTable);

            if ~obj.rowSyncActive
                return
            end

            if ~istable(rawTable)
                error("RowSynchronizedFilteringStorage:UnsupportedInput", ...
                    "Row synchronization can only be applied to table input.");
            end

            if isempty(isKept)
                isKept = true(height(rawTable), 1);
            else
                isKept = logical(isKept(:));
            end

            if numel(isKept) ~= height(rawTable)
                error("RowSynchronizedFilteringStorage:InvalidBaseFilterSize", ...
                    "The base filter returned %d rows for a table with %d rows.", numel(isKept), height(rawTable));
            end

            if ~ismember(obj.rowParameter, string(rawTable.Properties.VariableNames))
                error("RowSynchronizedFilteringStorage:MissingRowParameter", ...
                    "The synchronized row parameter '%s' is not present in the filtered table.", ...
                    obj.rowParameter);
            end

            rowValues = string(rawTable.(char(obj.rowParameter)));
            syncKept = ismember(rowValues(:), obj.keptRowNames);
            isKept = isKept & syncKept;
        end



        %% Row synchronization state

        function setRowSync(obj, rowParameter, keptRowNames)
            % Store the row synchronization constraint and notify listeners only when it changes.
            newRowParameter = string(rowParameter);
            newKeptRowNames = string(keptRowNames(:));

            if obj.rowSyncActive && obj.rowParameter == newRowParameter && isequal(obj.keptRowNames, newKeptRowNames)
                return
            end

            obj.rowParameter = newRowParameter;
            obj.keptRowNames = newKeptRowNames;
            obj.rowSyncActive = true;
            notify(obj, "filtersChanged");
        end



        function clearRowSync(obj)
            % Clear the row synchronization constraint and notify listeners only when there was active synchronization.
            if ~obj.rowSyncActive
                return
            end

            obj.rowParameter = "";
            obj.keptRowNames = strings(0, 1);
            obj.rowSyncActive = false;
            notify(obj, "filtersChanged");
        end



        function tf = hasRowSync(obj)
            % Return true when a row synchronization constraint is active.
            tf = obj.rowSyncActive;
        end



        %% Wrapped storage access

        function baseFilteringStorage = getBaseFilteringStorage(obj)
            % Return the wrapped filtering storage object.
            baseFilteringStorage = obj.baseFilteringStorage;
        end
    end
end
