classdef TableStateManager < handle
    properties (Access = private)
        dataStoreHandle
        appStateManagerHandle
        appHandle

        tableType

        tableProcessorHandle
        tableComponentHelperHandle
        tableComponentHandle

        gridRowNum

        stateManagerListener
    end

    events
        newModalityLoaded
    end

    methods
        function obj = TableStateManager(appStateManagerHandle, appHandle, dataStoreHandle, tableType, gridRowNum)
            obj.appStateManagerHandle = appStateManagerHandle;
            obj.appHandle = appHandle;
            obj.dataStoreHandle = dataStoreHandle;
            obj.tableType = tableType;
            obj.gridRowNum = gridRowNum;

            % add listener to the app state manager
            obj.stateManagerListener = addlistener(appStateManagerHandle, 'newModalityLoaded', @(~,~)loadNewDataStore(obj));

            % generate the table processor and component helper
            obj.createNewComponentPlusHelpers();
        end

        function delete(obj)
            if ~isempty(obj.tableProcessorHandle)
                delete(obj.tableProcessorHandle);
                obj.tableProcessorHandle = [];
            end

            if ~isempty(obj.tableComponentHelperHandle)
                delete(obj.tableComponentHelperHandle);
                obj.tableComponentHelperHandle = [];
            end

            if ~isempty(obj.tableComponentHandle)
                delete(obj.tableComponentHandle);
                obj.tableComponentHandle = [];
            end

            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
                obj.stateManagerListener = [];
            end
        end

        function changeTableType(obj, newTableType)
            obj.tableType = newTableType;

            obj.createNewComponentPlusHelpers();

        end

        function createNewComponentPlusHelpers(obj)
            obj.generateTableProcessor();
            obj.generateTableComponentHelper();
            obj.generateTableComponent();

            obj.setHandles();
        end

        function loadNewDataStore(obj)
            obj.dataStoreHandle = obj.appStateManagerHandle.getActiveDataStore();
            notify(obj, 'newModalityLoaded');
        end

        function generateTableProcessor(obj)

            if ~isempty(obj.tableProcessorHandle)
                delete(obj.tableProcessorHandle);
            end
            obj.tableProcessorHandle = TableProcessorFactory.createProcessor(obj.tableType);

        end

        function generateTableComponentHelper(obj)

            if ~isempty(obj.tableComponentHelperHandle)
                delete(obj.tableComponentHelperHandle);
            end
            obj.tableComponentHelperHandle = TableComponentHelperFactory.create(obj.tableType);

        end

        function generateTableComponent(obj)

            if ~isempty(obj.tableComponentHandle)
                delete(obj.tableComponentHandle);
            end

            container = obj.appHandle.getTableComponentGridLayout();
            obj.tableComponentHandle = TableComponentFactory.createComponent(obj.tableType, container);

            % set the position within the grid layout
            obj.tableComponentHandle.Layout.Row = obj.gridRowNum;
            obj.tableComponentHandle.Layout.Column = 1;
        end

        function setHandles(obj)
            % disp('TableStateManager:setHandles');
            % disp(obj.tableProcessorHandle);

            obj.tableComponentHandle.setHandles(obj.tableProcessorHandle, obj.tableComponentHelperHandle);  % needs to be first, because helper already calls something with handles in the component
            obj.tableProcessorHandle.setHandles(obj, obj.dataStoreHandle);
            obj.tableComponentHelperHandle.setHandles(obj, obj.dataStoreHandle, obj.tableComponentHandle);
        end

        function tableProcessorHandle = getTableProcessorHandle(obj)
            tableProcessorHandle = obj.tableProcessorHandle;
        end

        function tableType = getTableType(obj)
            tableType = obj.tableType;
        end

        function dataStoreHandle = getActiveDataStore(obj)
            dataStoreHandle = obj.dataStoreHandle;
        end

        function setState(obj, processorState)
            % propagating the state setting to the table processor
            obj.tableProcessorHandle.setState(processorState);
            obj.tableComponentHelperHandle.setState(processorState);
        end
    end
end