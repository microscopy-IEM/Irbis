classdef SpineCutting 

    methods (Static)
        function [tableArray, editingTableFull, assignmentTableFull, objectsToRemoveFull] = runUserGuided(tableArray)

            assignin("base", "tableArray", tableArray)

            mergeEvents = detectMergeEvents(tableArray)

            assignin("base", "mergeEvents", mergeEvents)

            [~, editingTable] = reviewMatchEventsUI(tableArray, mergeEvents)

            assignin("base", "editingTable", editingTable)


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
        end
    end
end