classdef PivotedTableComponentHelper < handle

    properties
        dataStoreHandle
        tableStoreHandle
        stateManagerHandle

        componentHandle

        groupedDataParameter
        columnParameter
        rowParameter

        tableStoreListener
        stateManagerListener
    end

    methods
        function obj = PivotedTableComponentHelper()
        end



        function setHandles(obj, stateManagerHandle, dataStoreHandle, componentHandle)
            % set the handles for the tree and other components
            obj.stateManagerHandle = stateManagerHandle;
            obj.stateManagerListener = addlistener(obj.stateManagerHandle, 'newModalityLoaded', @(~,~)replaceData(obj));

            obj.componentHandle = componentHandle;

            obj.dataStoreHandle = dataStoreHandle;
            obj.loadData();
        end



        function delete(obj)
            % delete the listeners
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            if ~isempty(obj.stateManagerListener) && isvalid(obj.stateManagerListener)
                delete(obj.stateManagerListener);
            end
        end



        function setState(obj, processorState)
            % store the selected parameters in this object and update the GUI component dropdowns¨
            % this will not be called if TableProcessor finds out that not all parameters are in the table
            if ~isempty(processorState)
                % the calls to the component only update the dropdown without any propagation side effects
                obj.groupedDataParameter = processorState.groupedDataParameter;
                obj.componentHandle.setDataParameterSelection(obj.groupedDataParameter);

                obj.columnParameter = processorState.columnParameter;
                obj.componentHandle.setColumnParameterSelection(obj.columnParameter);

                obj.rowParameter = processorState.rowParameter;
                obj.componentHandle.setRowParameterSelection(obj.rowParameter);

                % Update the transformation controls based on the saved state
                % The update of the tableStore is left to the processor, because that one is run before table update
                if isfield(processorState, 'transformation')
                    doTransformation = processorState.transformation.do;
                    transformationName = processorState.transformation.name;
                    parameterValue = processorState.transformation.parameterValue;

                    obj.componentHandle.setTransformationSpecs(doTransformation, transformationName, parameterValue);
                else
                    obj.componentHandle.setTransformationSpecs(false, 'none', []);
                end
            end
        end



        function updateTableControls(obj)
            columnNames = obj.tableStoreHandle.getColumnNamesByCondition({'iscategorical', 'isnumeric', 'isstring', 'ischar'});
            obj.componentHandle.setParameterList(columnNames);

            if isempty(columnNames)
                return;
            end

            if ~isempty(obj.columnParameter) && ismember(obj.columnParameter, columnNames)
                obj.componentHandle.setColumnParameter(obj.columnParameter);
                columnNames(strcmp(columnNames, obj.columnParameter)) = [];
            elseif ismember('timePoint', columnNames)
                obj.componentHandle.setColumnParameter('timePoint');
                columnNames(strcmp(columnNames, 'timePoint')) = [];
            else
                obj.componentHandle.setColumnParameter(columnNames{1});
                columnNames(1) = [];
            end

            % handle the situation when there are no columns left
            if isempty(columnNames)
                obj.componentHandle.setRowParameter(obj.columnParameter);
                obj.componentHandle.setDataParameter(obj.columnParameter);
                return;
            end

            if ~isempty(obj.rowParameter) && ismember(obj.rowParameter, columnNames)
                obj.componentHandle.setRowParameter(obj.rowParameter);
                columnNames(strcmp(columnNames, obj.rowParameter)) = [];
            else
                % Prefer the combined file/group identifier when present. It is
                % more specific across merged datasets, while groupId remains the
                % backward-compatible fallback for older data.
                preferredRowParameter = selectPreferredColumnName(columnNames, {'fileId_groupId', 'groupId'});
                obj.componentHandle.setRowParameter(preferredRowParameter);
                columnNames(strcmp(columnNames, preferredRowParameter)) = [];
            end

            % handle the situation when there are no columns left
            if isempty(columnNames)
                obj.componentHandle.setDataParameter(obj.rowParameter);
                return;
            end

            if ~isempty(obj.groupedDataParameter) && ismember(obj.groupedDataParameter, columnNames)
                obj.componentHandle.setDataParameter(obj.groupedDataParameter);
            elseif ismember('volume', columnNames)
                obj.componentHandle.setDataParameter('volume');
            else 
                obj.componentHandle.setDataParameter(columnNames{1});
            end

            % set the transformation status in the component based on the table store
            [doTransformation, transformationName, parameterValue] = obj.tableStoreHandle.getPivotedTransformationSpecs();
            obj.componentHandle.setTransformationSpecs(doTransformation, transformationName, parameterValue);
        end



        function setGroupedDataParameter(obj, parameter)
            obj.groupedDataParameter = parameter;
        end



        function setColumnParameter(obj, parameter)
            obj.columnParameter = parameter;
        end



        function setRowParameter(obj, parameter)
            obj.rowParameter = parameter;
        end



        function setTransformationStatus(obj, doTransform, transformationName, parameterValue)
            % should be called from the component when the user changes the transformation option in the GUI
            arguments
                obj
                doTransform (1,1) logical
                transformationName
                parameterValue = []  % Optional parameter for transformations that require it
            end
            
            obj.tableStoreHandle.setPivotedTransformationStatus(doTransform, transformationName, parameterValue);
        end



        function setTransformationParameter(obj, parameterValue)
            % should be called in case the transformation requires a user-specified parameter (such as reference time point)
            obj.tableStoreHandle.setPivotedTransformationParameter(parameterValue);
        end



        function setRowParameterAndLoadData(obj, parameter)
            obj.rowParameter = parameter;
            obj.loadData();
        end



        function replaceData(obj)
            obj.dataStoreHandle = obj.stateManagerHandle.getActiveDataStore();
            obj.loadData();
        end



        function loadData(obj)
            obj.tableStoreHandle = obj.dataStoreHandle.getTableStore();
            if ~isempty(obj.tableStoreListener) && isvalid(obj.tableStoreListener)
                delete(obj.tableStoreListener);
            end
            obj.tableStoreListener = addlistener(obj.tableStoreHandle, 'tableDataChanged', @(~,~)updateTableControls(obj));

            obj.updateTableControls();
        end
    end
end
