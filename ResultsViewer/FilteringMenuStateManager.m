classdef FilteringMenuStateManager < handle
    properties (Access = private)
        dataStoreHandle
        appStateManagerHandle
        appHandle

        tableType

        tableProcessorHandle
        filteringMenuComponentHandle

        gridRowNum

        stateManagerListener
    end

    events
        newModalityLoaded
    end

    methods
        function obj = FilteringMenuStateManager(appStateManagerHandle, appHandle, dataStoreHandle, tableType, tableProcessorHandle)
            obj.appStateManagerHandle = appStateManagerHandle;
            obj.appHandle = appHandle;
            obj.dataStoreHandle = dataStoreHandle;
            obj.tableType = tableType;
            obj.tableProcessorHandle = tableProcessorHandle;

            % add listener to the app state manager
            obj.stateManagerListener = addlistener(appStateManagerHandle, 'newModalityLoaded', @(~,~)loadNewDataStore(obj));

            % generate the table processor and component helper
            obj.createNewComponent();
        end

        function delete(obj)
            if ~isempty(obj.filteringMenuComponentHandle)
                delete(obj.filteringMenuComponentHandle);
                obj.filteringMenuComponentHandle = [];
            end

            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
                obj.stateManagerListener = [];
            end
        end

        function loadNewDataStore(obj)
            obj.dataStoreHandle = obj.appStateManagerHandle.getActiveDataStore();
            notify(obj, 'newModalityLoaded');
        end

        function createNewComponent(obj)

            % disp('Creating new filtering menu component...');
            obj.generateComponent();
            obj.setHandles();
        end

        function generateComponent(obj)
            if ~isempty(obj.filteringMenuComponentHandle)
                delete(obj.filteringMenuComponentHandle);
            end

            container = obj.appHandle.getFilteringMenuGridLayout();
            % disp(obj.tableType)
            obj.filteringMenuComponentHandle = FilteringMenuComponentFactory.create(obj.tableType, container);

            % set the position within the grid layout
            obj.filteringMenuComponentHandle.Layout.Row = 1;
            obj.filteringMenuComponentHandle.Layout.Column = 1;
        end

        function setHandles(obj)
            obj.filteringMenuComponentHandle.setHandles(obj, obj.dataStoreHandle, obj.tableProcessorHandle);
            % appStateManagerHandle swapped for the filtering component manager - the app one is not needed
        end

        function dataStoreHandle = getActiveDataStore(obj)
            dataStoreHandle = obj.dataStoreHandle;
        end
    end
end

