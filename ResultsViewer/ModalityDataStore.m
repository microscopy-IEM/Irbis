classdef (Sealed) ModalityDataStore < handle
    % ModalityDataStore stores modality data and forwards column definition change events.

    properties (Access = private)
        dataCollection = struct();
    end

    properties (Access = private, Transient)
        userColumnDefinitionChangeListeners = struct('pathKey', {}, 'listener', {});
    end

    events
        userColumnDefinitionChanged
    end

    %% Lifecycle

    methods
        function obj = ModalityDataStore()
            % Create an empty modality data store.
        end



        function delete(obj)
            % Delete runtime listeners owned by the modality data store.
            obj.deleteListeners();
        end



        %% Data access

        function setModalityData(obj, modalityPath, modalityData)
            % Store modality data at the requested path and refresh listeners for that path.
            if isempty(modalityPath)
                obj.dataCollection = modalityData;
            else
                obj.dataCollection = setfield(obj.dataCollection, modalityPath{:}, modalityData);
            end

            obj.deleteUserColumnDefinitionChangeListeners(modalityPath);
            obj.addUserColumnDefinitionChangeListener(modalityPath, modalityData);
        end



        function modalityData = getModalityData(obj, modalityPath)
            % Return modality data from the requested path.
            if isempty(modalityPath)
                modalityData = obj.dataCollection;
            else
                if ModalityDataStore.hasNestedField(obj.dataCollection, modalityPath)
                    modalityData = getfield(obj.dataCollection, modalityPath{:});
                else
                    ME = MException('ModalityDataStore:InvalidModalityPath', 'The specified modality path does not exist in the data store: %s', strjoin(modalityPath, '.'));
                    throw(ME);
                end
            end
        end



        function paths = getAvailableModalityPaths(obj)
            % Return a cell array of all available modality paths in the data collection.
            paths = {};
            fields = fieldnames(obj.dataCollection);
            for i = 1:length(fields)
                if isstruct(obj.dataCollection.(fields{i}))
                    subfields = fieldnames(obj.dataCollection.(fields{i}));
                    for j = 1:length(subfields)
                        paths{end + 1} = {fields{i}, subfields{j}};
                    end
                else
                    paths{end + 1} = fields(i);
                end
            end
        end



        %% Listener lifecycle

        function addUserColumnDefinitionChangeListener(obj, modalityPath, modalityData)
            % Add listeners that forward user column definition changes from all leaf data stores under the requested path.
            obj.traverseAndAddListener(modalityPath, modalityData);
        end



        function deleteListeners(obj)
            % Delete all runtime listeners owned by this store and by nested data stores before serialization.
            obj.deleteUserColumnDefinitionChangeListeners({});

            paths = obj.getAvailableModalityPaths();
            for i = 1:length(paths)
                currentDataStore = obj.getModalityData(paths{i});
                if isa(currentDataStore, 'DataStore') && isvalid(currentDataStore)
                    currentDataStore.deleteListeners();
                end
            end
        end



        function regenerateListeners(obj)
            % Regenerate all runtime listeners after loading the modality data store from file.
            obj.deleteUserColumnDefinitionChangeListeners({});

            paths = obj.getAvailableModalityPaths();
            for i = 1:length(paths)
                currentDataStore = obj.getModalityData(paths{i});
                if isa(currentDataStore, 'DataStore') && isvalid(currentDataStore)
                    currentDataStore.regenerateListeners();
                    obj.addUserColumnDefinitionChangeListener(paths{i}, currentDataStore);
                end
            end
        end



        %% Event forwarding

        function notifyUserColumnDefinitionChange(obj, modalityPath, ~, event)
            % Add modality context to a column definition event and forward it from the modality data store.
            event.setModalityPath(modalityPath);
            notify(obj, 'userColumnDefinitionChanged', event);
        end
    end



    methods (Access = ?matlab.unittest.TestCase)
        function traverseAndAddListener(obj, currentPath, data)
            % Traverse stored data and add listeners to leaf data stores.
            if isstruct(data)
                fields = fieldnames(data);
                for i = 1:length(fields)
                    obj.traverseAndAddListener([currentPath, {fields{i}}], data.(fields{i}));
                end
            else
                listener = addlistener(data, 'userColumnDefinitionChanged', @(src, event) obj.notifyUserColumnDefinitionChange(currentPath, src, event));
                obj.userColumnDefinitionChangeListeners(end + 1).pathKey = ModalityDataStore.pathToKey(currentPath);
                obj.userColumnDefinitionChangeListeners(end).listener = listener;
            end
        end



        function deleteUserColumnDefinitionChangeListeners(obj, modalityPath)
            % Delete stored leaf listeners under the requested modality path.
            if isempty(obj.userColumnDefinitionChangeListeners)
                return
            end

            pathKey = ModalityDataStore.pathToKey(modalityPath);
            listenerPathKeys = string({obj.userColumnDefinitionChangeListeners.pathKey});
            if pathKey == ""
                isListenerUnderPath = true(size(listenerPathKeys));
            else
                isListenerUnderPath = listenerPathKeys == pathKey | startsWith(listenerPathKeys, pathKey + ModalityDataStore.pathDelimiter());
            end

            listenersToDelete = obj.userColumnDefinitionChangeListeners(isListenerUnderPath);
            for i = 1:numel(listenersToDelete)
                listener = listenersToDelete(i).listener;
                if ~isempty(listener) && isvalid(listener)
                    delete(listener);
                end
            end

            obj.userColumnDefinitionChangeListeners(isListenerUnderPath) = [];
        end
    end



    methods (Static, Access = ?matlab.unittest.TestCase)
        function tf = hasNestedField(s, path)
            % Check if a nested field exists in a structure for the requested path.
            tf = true;

            for i = 1:numel(path)
                field = path{i};

                if isstruct(s) && isfield(s, field)
                    s = s.(field);
                else
                    tf = false;
                    return
                end
            end
        end



        function key = pathToKey(path)
            % Convert a modality path to a stable string key used for listener ownership.
            if isempty(path)
                key = "";
                return
            end

            key = strjoin(string(path), ModalityDataStore.pathDelimiter());
        end



        function delimiter = pathDelimiter()
            % Return the delimiter used in internal modality path keys.
            delimiter = "/";
        end
    end
end
