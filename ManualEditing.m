classdef ManualEditing
    methods (Static)
        function editingTable = initializeTable()

            varMeta = [
                "timestamp",        "datetime",      "",      "Timestamp of when the object was created";
                "timePoint",        "double",        "",      "Time point associated with the edited object";
                "helperType",       "categorical",   "",      "Type of object used for the editing - specifies also the editing type (e.g. cutting/redefinition, ...)";
                "helperMesh",       "cell",          "",      "Cell array containing the mesh of the editing object (e.g. cutting cuboid, ...)";
                "helperParameters", "cell",          "",      "Cell array containing the parameters describing the editing object";
                "branch",           "string",        "",      "What is the type of the object being edited (e.g. spine/shaft/fullVolume, ...). We assume that both input and output objects are of the same type.";
                "inputId",          "double",        "",      "objectId of the object being edited - we assume that only one object is edited at a time";
                "outputIds",        "cell",         "",      "objectIds of the objects resulting from the editing - can be multiple values (e.g. cutting an object into two results in two outputIds)";
            ];

            % having timePoint as double does not match with how we keep timePoint in List

            varNames = varMeta(:,1)';
            varTypes = varMeta(:,2)';
            nRows = 0; % Start with an empty table
            sz = [nRows numel(varNames)];
            editingTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
            % Assign metadata
            editingTable.Properties.VariableUnits = varMeta(:,3)';
            editingTable.Properties.VariableDescriptions = varMeta(:,4)';
        end


        function T = addRow(T, timePoint, helperType, helperMesh, helperPosition, helperRotation, branch, inputId, outputIds)
            newRowIdx = height(T) + 1;
            % T(newRowIdx, :) = [];
            T{newRowIdx, 'timestamp'} = datetime('now');
            T{newRowIdx, 'timePoint'} = timePoint;
            T{newRowIdx, 'helperType'} = helperType;
            T{newRowIdx, 'helperMesh'} = {helperMesh};
            T{newRowIdx, 'helperParameters'} = {struct('rotation', helperRotation, 'position', helperPosition)};
            T{newRowIdx, 'branch'} = string(branch);
            T{newRowIdx, 'inputId'} = inputId;
            T{newRowIdx, 'outputIds'} = {outputIds};
        end
    end
end