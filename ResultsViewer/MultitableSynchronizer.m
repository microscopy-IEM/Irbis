classdef (Sealed) MultitableSynchronizer < handle

    % To deal with:
    % - if one table is filtered, the other table gets the same filters
    % - if one table is sorted, the other table gets the same sort order
    % - sync row selection

    properties (Access = ?matlab.unittest.TestCase)
        topTableProcessorHandle
        bottomTableProcessorHandle

        rowParameter

        % Listeners need to be deleted when the synchronizer is deleted.
        topSyncRequestListener
        bottomSyncRequestListener
        topRowParameterListener
        bottomRowParameterListener
        bottomFiltersListener
    end

    %% Lifecycle

    methods
        function obj = MultitableSynchronizer(rowParameter, topTableProcessorHandle, bottomTableProcessorHandle)
            % Store processor handles and register synchronization listeners.
            obj.rowParameter = rowParameter;
            obj.topTableProcessorHandle = topTableProcessorHandle;
            obj.bottomTableProcessorHandle = bottomTableProcessorHandle;

            obj.changeRowParameterInOtherTable(1);

            obj.registerListeners();
            obj.applyFiltersToOtherTable(2);
        end



        function registerListeners(obj)
            % Register listeners that keep selection, row parameters and summarized filtering synchronized.
            obj.deleteExistingListeners();

            sourceTableId = 1;
            obj.topSyncRequestListener = addlistener(obj.topTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            obj.topRowParameterListener = addlistener(obj.topTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));

            sourceTableId = 2;
            obj.bottomSyncRequestListener = addlistener(obj.bottomTableProcessorHandle, 'tableSelectionSyncRequired', @(~, ~) obj.changeSelectionInOtherTable(sourceTableId));
            obj.bottomRowParameterListener = addlistener(obj.bottomTableProcessorHandle, 'rowParameterChanged', @(~, ~) obj.changeRowParameterInOtherTable(sourceTableId));
            obj.bottomFiltersListener = addlistener(obj.bottomTableProcessorHandle, 'newFiltersApplied', @(~, ~) obj.applyFiltersToOtherTable(sourceTableId));
        end



        function delete(obj)
            % Clear row synchronization and delete listeners owned by this synchronizer.
            obj.clearSynchronizedFiltering();
            obj.deleteExistingListeners();
        end



        function deleteExistingListeners(obj)
            % Delete all active listeners owned by this synchronizer.
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
        %% Row selection synchronization

        function changeSelectionInOtherTable(obj, sourceTableId)
            % Copy selected row indices from the source processor to the target processor.
            [sourceProcessor, targetProcessor] = obj.getProcessorsForSourceTable(sourceTableId);

            selectedList = sourceProcessor.getSelectedTableCellsList();
            selectedRowsList = selectedList(:, 1);
            targetProcessor.programmaticallySetRowSelection(selectedRowsList);
        end



        %% Row parameter synchronization

        function changeRowParameterInOtherTable(obj, sourceTableId)
            % Keep the summarized row parameter aligned with the pivoted row parameter.
            [sourceProcessor, targetProcessor] = obj.getProcessorsForSourceTable(sourceTableId);

            [parameterName, parameterType] = sourceProcessor.getRowParameterNameAndType();

            if isequal(parameterType, 'categorical')
                obj.rowParameter = parameterName;
                targetProcessor.programmaticallySetRowParameter(parameterName);
            else
                previousRowParameter = obj.rowParameter;
                sourceProcessor.programmaticallySetRowParameter(previousRowParameter);
            end
        end



        %% Row filter synchronization

        function applyFiltersToOtherTable(obj, sourceTableId)
            % Apply the currently displayed summarized row names as a persistent row filter on the pivoted table.
            [sourceProcessor, targetProcessor] = obj.getProcessorsForSourceTable(sourceTableId);

            if ~ismethod(sourceProcessor, 'getKeptRowNames') || ~ismethod(targetProcessor, 'setRowSynchronizedFilteringStorage')
                return
            end

            if ismethod(sourceProcessor, 'getTableForDisplay')
                sourceTableForDisplay = sourceProcessor.getTableForDisplay();
                if height(sourceTableForDisplay) == 0 && width(sourceTableForDisplay) == 0
                    if ismethod(targetProcessor, 'clearRowSynchronizedFilteringStorage')
                        targetProcessor.clearRowSynchronizedFilteringStorage();
                    end
                    return
                end
            end

            keptRowNames = sourceProcessor.getKeptRowNames();
            targetProcessor.setRowSynchronizedFilteringStorage(obj.rowParameter, keptRowNames);
        end



        function clearSynchronizedFiltering(obj)
            % Clear row-synchronized filtering from processors that support it.
            if obj.isValidProcessor(obj.topTableProcessorHandle) && ismethod(obj.topTableProcessorHandle, 'clearRowSynchronizedFilteringStorage')
                obj.topTableProcessorHandle.clearRowSynchronizedFilteringStorage();
            end

            if obj.isValidProcessor(obj.bottomTableProcessorHandle) && ismethod(obj.bottomTableProcessorHandle, 'clearRowSynchronizedFilteringStorage')
                obj.bottomTableProcessorHandle.clearRowSynchronizedFilteringStorage();
            end
        end



        %% Shared helpers

        function [sourceProcessor, targetProcessor] = getProcessorsForSourceTable(obj, sourceTableId)
            % Return source and target processors for a synchronization event.
            if isequal(sourceTableId, 1)
                sourceProcessor = obj.topTableProcessorHandle;
                targetProcessor = obj.bottomTableProcessorHandle;
            elseif isequal(sourceTableId, 2)
                sourceProcessor = obj.bottomTableProcessorHandle;
                targetProcessor = obj.topTableProcessorHandle;
            else
                error('MultitableSynchronizer:InvalidSourceTableId', 'Source table id must be 1 or 2.');
            end
        end



        function tf = isValidProcessor(~, processorHandle)
            % Return true when a processor handle can still be used.
            tf = isa(processorHandle, 'handle') && isvalid(processorHandle);
        end
    end
end
