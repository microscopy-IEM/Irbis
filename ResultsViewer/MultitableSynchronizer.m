classdef (Sealed) MultitableSynchronizer < handle

    % To deal with: 
    % - if one table is filtered, the other table gets the same filters
    % - if one table is sorted, the other table gets the same sort order
    % - sync row selection

    properties (Access = ?matlab.unittest.TestCase)
        topTableProcessorHandle 
        bottomTableProcessorHandle

        rowParameter

        % listeneres - need to be deleted when the synchronizer is deleted
        topSyncRequestListener
        bottomSyncRequestListener
        topRowParameterListener
        bottomRowParameterListener
        bottomFiltersListener
    end

    methods
        function obj = MultitableSynchronizer(rowParameter, topTableProcessorHandle, bottomTableProcessorHandle)
            obj.rowParameter = rowParameter;
            obj.topTableProcessorHandle = topTableProcessorHandle;
            obj.bottomTableProcessorHandle = bottomTableProcessorHandle;

            obj.registerListeners();
        end


        function registerListeners(obj)
            obj.deleteExistingListeners();  % delete existing listeners to avoid duplicates

            sourceTableId = 1;
            obj.topSyncRequestListener = addlistener(obj.topTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            obj.topRowParameterListener = addlistener(obj.topTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));
            
            sourceTableId = 2;
            obj.bottomSyncRequestListener = addlistener(obj.bottomTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            obj.bottomRowParameterListener = addlistener(obj.bottomTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));
            obj.bottomFiltersListener = addlistener(obj.bottomTableProcessorHandle, 'newFiltersApplied', @(~, ~) obj.applyFiltersToOtherTable(sourceTableId));
                % only the summarized table can be filtered by itself
        end


        function delete(obj)
            % wrapped like this because I don't know if I can call delete() to just delete the listeners and not the whole app
            obj.deleteExistingListeners();
        end


        function deleteExistingListeners(obj)
            if ~isempty(obj.topSyncRequestListener) && isvalid(obj.topSyncRequestListener)
                delete(obj.topSyncRequestListener);
            end

            if ~isempty(obj.bottomSyncRequestListener) && isvalid(obj.bottomSyncRequestListener)
                delete(obj.bottomSyncRequestListener);
            end

            if ~isempty(obj.topRowParameterListener) && isvalid(obj.topRowParameterListener)
                delete(obj.topRowParameterListener);
            end

            if ~isempty(obj.bottomRowParameterListener) && isvalid(obj.bottomRowParameterListener)
                delete(obj.bottomRowParameterListener);
            end

            if ~isempty(obj.bottomFiltersListener) && isvalid(obj.bottomFiltersListener)
                delete(obj.bottomFiltersListener);
            end
        end
    end



    methods (Access = ?matlab.unittest.TestCase)
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