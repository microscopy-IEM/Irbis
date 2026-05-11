classdef SpineCutting 

    methods (Static)
        function [tableArray, editingTableFull, assignmentTableFull, objectsToRemoveFull] = runUserGuided(tableArray, fig)

            assignin("base", "tableArray", tableArray)

            wb = uiprogressdlg(fig, 'Title', 'Semiautomatic spine cutting','Message',...
                 'Finding merge events...', 'Cancelable', 'off', 'Indeterminate', 'on');

            mergeEvents = detectMergeEvents(tableArray)

            close(wb)

            assignin("base", "mergeEvents", mergeEvents)

            [~, editingTable] = reviewMatchEventsUI(tableArray, mergeEvents)

            assignin("base", "editingTable", editingTable)

            wb = uiprogressdlg(fig, 'Title', 'Semiautomatic spine cutting','Message',...
                 'Finding merge events...', 'Cancelable', 'off', 'Indeterminate', 'on');
            wb.Message = "Processing edits...";

            nTimePoints = numel(unique(editingTable.timePoint));
            allAssignmentTables = cell(nTimePoints, 1);
            allObjectsToRemove = cell(nTimePoints, 1);

            for tp = unique(editingTable.timePoint)'
                disp(tp)
                editingRows = editingTable.timePoint == tp;
                usedGizmos = editingTable(editingRows, :)

                if isempty(usedGizmos)
                    continue
                end
                
                [objectMesh, gizmoMesh, ~] = combineReferencedObjectsAndGizmos(tableArray, usedGizmos);

                mesh_array = cell(1, 2);
                mesh_array{1} = PythonMeshHelper.meshToPyStruct(objectMesh);
                mesh_array{2} = PythonMeshHelper.meshToPyStruct(gizmoMesh);

                separatedMeshes = PythonMeshHelper.subtractAndSeparate(mesh_array);

                [tableArray, editingTable, assignmentTable, objectsToRemove] = ...
                    assignSeparatedMeshes(tableArray, editingTable, separatedMeshes, tp)

                allAssignmentTables{tp} = assignmentTable;
                allObjectsToRemove{tp} = objectsToRemove;
            end

            editingTableFull = editingTable;
            assignmentTableFull = vertcat(allAssignmentTables{:});
            objectsToRemoveFull = vertcat(allObjectsToRemove{:});

            close(wb)
        end
    end
end