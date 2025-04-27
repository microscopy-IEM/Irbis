classdef MultitableSynchronizer < handle

    % To deal with: 
    % - if one table is filtered, the other table gets the same filters
    % - if one table is sorted, the other table gets the same sort order
    % - sync row selection

    properties
        topTableProcessorHandle 
        bottomTableProcessorHandle

        rowParameter
    end

    methods
        function obj = MultitableSynchronizer(rowParameter, topTableProcessorHandle, bottomTableProcessorHandle)
            obj.rowParameter = rowParameter;
            obj.topTableProcessorHandle = topTableProcessorHandle;
            sourceTableId = 1;
            addlistener(obj.topTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            addlistener(obj.topTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));
            obj.bottomTableProcessorHandle = bottomTableProcessorHandle;
            sourceTableId = 2;
            addlistener(obj.bottomTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            addlistener(obj.bottomTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));
            addlistener(obj.bottomTableProcessorHandle, 'newFiltersApplied', @(~, ~) obj.applyFiltersToOtherTable(sourceTableId));
                % only the summarized table can be filtered by itself
        end
    end

    methods (Access = private)
        function changeSelectionInOtherTable(obj, sourceTableId)
            if isequal(sourceTableId, 1)
                sourceProcessor = obj.topTableProcessorHandle;
                targetProcessor = obj.bottomTableProcessorHandle;
            elseif isequal(sourceTableId, 2)
                sourceProcessor = obj.bottomTableProcessorHandle;
                targetProcessor = obj.topTableProcessorHandle;
            end

            selectedList = sourceProcessor.getSelectedTableCellsList();
            selectedRowsList = selectedList(:, 1);
            targetProcessor.programmaticallySetRowSelection(selectedRowsList);
        end


        function changeRowParameterInOtherTable(obj, sourceTableId)
            if isequal(sourceTableId, 1)
                sourceProcessor = obj.topTableProcessorHandle;
                targetProcessor = obj.bottomTableProcessorHandle;
            elseif isequal(sourceTableId, 2)
                sourceProcessor = obj.bottomTableProcessorHandle;
                targetProcessor = obj.topTableProcessorHandle;
            end

            [parameterName, parameterType] = sourceProcessor.getRowParameterNameAndType();

            if isequal(parameterType, 'categorical')
                obj.rowParameter = parameterName;
                targetProcessor.programmaticallySetRowParameter(parameterName);
            else
                previousRowParameter = obj.rowParameter;
                sourceProcessor.programmaticallySetRowParameter(previousRowParameter);
                % other than categorical parameters are not used in Summarized
                % therefore, if Pivoted switches to other type, it is reverted
            end

        end


        function applyFiltersToOtherTable(obj, sourceTableId)
            if isequal(sourceTableId, 1)
                sourceProcessor = obj.topTableProcessorHandle;
                targetProcessor = obj.bottomTableProcessorHandle;
            elseif isequal(sourceTableId, 2)
                sourceProcessor = obj.bottomTableProcessorHandle;
                targetProcessor = obj.topTableProcessorHandle;
            end

            isKept = sourceProcessor.getKeptBooleanList();
            targetProcessor.filterWithBooleanList(isKept);
        end
    end
end