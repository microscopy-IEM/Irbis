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

            if ~obj.isValidProcessor(obj.topTableProcessorHandle) || ~obj.isValidProcessor(obj.bottomTableProcessorHandle)
                return
            end

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



        function refreshSynchronizedFiltering(obj)
            % Reapply summarized-to-pivoted row filtering for the current table
            % state. Stored-view restore builds the summarized table before its
            % saved processor state is applied, so the constructor's initial sync
            % can run against an empty/default summarized display. Calling this
            % after restore makes the pivoted row-sync filter reflect the final
            % summarized table.
            sourceTableId = 2;
            obj.applyFiltersToOtherTable(sourceTableId);
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
            % Synchronize selected rows from the source processor to the target
            % processor. Prefer row names over raw row indices because Pivoted and
            % Summarized displays can have different row counts/order while still
            % representing the same category labels. If row names are unavailable,
            % fall back to bounded row-index syncing; each processor clips indices
            % again before updating the UI.
            [sourceProcessor, targetProcessor] = obj.getProcessorsForSourceTable(sourceTableId);

            if ~obj.areProcessorsUsable(sourceProcessor, targetProcessor)
                return
            end

            selectedList = sourceProcessor.getSelectedTableCellsList();
            selectedRowsList = selectedList(:, 1);
            selectedRowsList = obj.mapRowsByDisplayRowNames(sourceProcessor, targetProcessor, selectedRowsList);
            targetProcessor.programmaticallySetRowSelection(selectedRowsList);
        end



        %% Row parameter synchronization

        function changeRowParameterInOtherTable(obj, sourceTableId)
            % Keep the summarized row parameter aligned with the pivoted row parameter.
            [sourceProcessor, targetProcessor] = obj.getProcessorsForSourceTable(sourceTableId);

            if ~obj.areProcessorsUsable(sourceProcessor, targetProcessor)
                return
            end

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

            if ~obj.areProcessorsUsable(sourceProcessor, targetProcessor)
                return
            end

            if ~ismethod(sourceProcessor, 'getKeptRowNames') || ~ismethod(targetProcessor, 'setRowSynchronizedFilteringStorage')
                return
            end

            % Do not use an empty visible summarized table as a reason to clear
            % row sync. During initial open and stored-view restore, the bottom
            % processor may not have active display columns yet, but it can still
            % report the row names kept by its summarized filters.
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
            try
                tf = isa(processorHandle, 'handle') && isvalid(processorHandle);
            catch
                tf = false;
            end
        end



        function tf = areProcessorsUsable(obj, sourceProcessor, targetProcessor)
            % Listener callbacks may run after a stored view has replaced one of
            % the processors. Treat that as a stale sync request and ignore it.
            tf = obj.isValidProcessor(sourceProcessor) && obj.isValidProcessor(targetProcessor);
        end



        function targetRows = mapRowsByDisplayRowNames(~, sourceProcessor, targetProcessor, sourceRows)
            % Convert source display row indices to target display row indices by
            % matching row names. This keeps selection tied to the underlying group
            % label instead of to an incidental table position, which is important
            % after loading a new dataset or switching between groupId and
            % fileId_groupId based summaries.
            targetRows = sourceRows;

            if isempty(sourceRows) || ...
                    ~ismethod(sourceProcessor, 'getTableForDisplay') || ...
                    ~ismethod(targetProcessor, 'getTableForDisplay')
                return
            end

            sourceTable = sourceProcessor.getTableForDisplay();
            targetTable = targetProcessor.getTableForDisplay();

            if isempty(sourceTable) || isempty(targetTable) || ...
                    isempty(sourceTable.Properties.RowNames) || ...
                    isempty(targetTable.Properties.RowNames)
                return
            end

            sourceRows = unique(sourceRows(:), 'stable');
            isSourceRowValid = isfinite(sourceRows) & ...
                mod(sourceRows, 1) == 0 & ...
                sourceRows >= 1 & ...
                sourceRows <= height(sourceTable);
            sourceRows = sourceRows(isSourceRowValid);

            if isempty(sourceRows)
                targetRows = [];
                return
            end

            sourceRowNames = string(sourceTable.Properties.RowNames(sourceRows));
            targetRowNames = string(targetTable.Properties.RowNames);
            [isMatched, matchedRows] = ismember(sourceRowNames, targetRowNames);

            targetRows = matchedRows(isMatched);
        end
    end
end
