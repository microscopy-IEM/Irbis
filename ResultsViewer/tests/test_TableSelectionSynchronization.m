classdef test_TableSelectionSynchronization < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end



    methods (Test)
        function synchronizerMapsRowsByDisplayRowName(testCase)
            sourceTable = array2table([1; 2], ...
                'VariableNames', {'Value'}, ...
                'RowNames', {'A'; 'C'});
            targetTable = array2table([10; 20], ...
                'VariableNames', {'Summary'}, ...
                'RowNames', {'C'; 'B'});

            sourceProcessor = LocalSelectionSyncProcessor(sourceTable);
            targetProcessor = LocalSelectionSyncProcessor(targetTable);
            synchronizer = MultitableSynchronizer('Category', sourceProcessor, targetProcessor);

            % Source row 2 is category C, but C is row 1 in the target table.
            % The synchronized selection should follow the row name/category,
            % not the incidental row index from the source display.
            sourceProcessor.selectedTableCellsList = [2, 1];
            synchronizer.changeSelectionInOtherTable(1);

            testCase.verifyEqual(targetProcessor.receivedRows, 1);

            delete(synchronizer);
        end



        function processorsClipOutOfBoundsProgrammaticRows(testCase)
            pivotedProcessor = PivotedTableProcessor();
            pivotedProcessor.pivotedTable = array2table([1; 2], ...
                'VariableNames', {'T1'}, ...
                'RowNames', {'A'; 'B'});

            summarizedProcessor = SummarizedTableProcessor();
            summarizedProcessor.filteredTable = array2table([10; 20], ...
                'VariableNames', {'Mean'}, ...
                'RowNames', {'A'; 'B'});

            % Row 3 existed in the old source table in the bug report, but it
            % does not exist in these target displays. The processors should
            % silently keep row 1 and drop row 3 before the UI sees the selection.
            pivotedProcessor.programmaticallySetRowSelection([1; 3]);
            summarizedProcessor.programmaticallySetRowSelection([1; 3]);

            testCase.verifyEqual(pivotedProcessor.selectedTableCellsList, [1, 1]);
            testCase.verifyEqual(summarizedProcessor.selectedTableCellsList, [1, 1]);
        end



        function staleSynchronizerIgnoresDeletedProcessor(testCase)
            sourceTable = array2table([1; 2], ...
                'VariableNames', {'Value'}, ...
                'RowNames', {'A'; 'B'});
            targetTable = array2table([10; 20], ...
                'VariableNames', {'Summary'}, ...
                'RowNames', {'A'; 'B'});

            sourceProcessor = LocalSelectionSyncProcessor(sourceTable);
            targetProcessor = LocalSelectionSyncProcessor(targetTable);
            synchronizer = MultitableSynchronizer('Category', sourceProcessor, targetProcessor);

            % Stored-view restore can replace a table processor while an older
            % synchronizer callback is still reachable from a listener. The
            % callback should detect the deleted target and quietly ignore the
            % stale filter-sync request.
            delete(targetProcessor);

            testCase.verifyWarningFree(@() synchronizer.applyFiltersToOtherTable(1));

            delete(synchronizer);
        end
    end
end
