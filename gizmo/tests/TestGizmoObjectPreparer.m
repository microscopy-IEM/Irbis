classdef TestGizmoObjectPreparer < matlab.unittest.TestCase

    properties
        Figure
        Axes
    end


    methods (TestMethodTeardown)
        function closeFigure(testCase)
            if ~isempty(testCase.Figure) && isvalid(testCase.Figure)
                close(testCase.Figure);
            end
        end
    end


    methods (Test)
        function preparesFromGeometryStruct(testCase)
            vertices = [
                -1 -1 -1;
                 1 -1 -1;
                 0  1 -1;
                 0  0  1
            ];
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];
            objectStruct = struct('vertices', vertices, 'faces', faces);

            prepared = GizmoObjectPreparer.prepare(objectStruct, 'ScaleAxes', {'x', 'yz'});

            testCase.verifyTrue(isstruct(prepared));
            testCase.verifyTrue(isfield(prepared, 'objectForGizmo'));
            testCase.verifyTrue(isfield(prepared, 'gizmoCenter'));
            testCase.verifyTrue(isfield(prepared, 'scalePointVectors'));
            testCase.verifyTrue(isfield(prepared, 'scalePointPositions'));

            testCase.verifySize(prepared.gizmoCenter, [1 3]);
            testCase.verifyEqual(numel(prepared.scalePointVectors), 2);
            testCase.verifyEqual(numel(prepared.scalePointPositions), 2);
            testCase.verifyEqual(prepared.scalePointVectors{1}, [1 0 0]);
            testCase.verifyEqual(prepared.scalePointVectors{2}, [0 1 1]);
        end


        function preparesFromScatterHandle(testCase)
            testCase.Figure = figure('Visible', 'off');
            testCase.Axes = axes(testCase.Figure);

            points = [0 0 0; 2 0 0; 0 2 0; 0 0 2];
            scatterHandle = scatter3(testCase.Axes, points(:,1), points(:,2), points(:,3));

            prepared = GizmoObjectPreparer.prepare(scatterHandle, 'ScaleAxes', {'xyz'});

            testCase.verifyEqual(prepared.objectForGizmo, scatterHandle);
            testCase.verifySize(prepared.gizmoCenter, [1 3]);
            testCase.verifyEqual(numel(prepared.scalePointPositions), 1);
        end


        function preparesPredefinedSphere(testCase)
            prepared = GizmoObjectPreparer.preparePredefined("sphere");

            testCase.verifyTrue(isstruct(prepared.objectForGizmo));
            testCase.verifyTrue(isfield(prepared.objectForGizmo, 'vertices'));
            testCase.verifyTrue(isfield(prepared.objectForGizmo, 'faces'));
            testCase.verifyGreaterThan(size(prepared.objectForGizmo.vertices,1), 0);
            testCase.verifyGreaterThan(size(prepared.objectForGizmo.faces,1), 0);
            testCase.verifyEqual(prepared.scalePointVectors{1}, [1 1 1]);
        end


        function errorsOnScalePointCountMismatch(testCase)
            vertices = [
                -1 -1 -1;
                 1 -1 -1;
                 0  1 -1;
                 0  0  1
            ];
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];
            objectStruct = struct('vertices', vertices, 'faces', faces);

            call = @() GizmoObjectPreparer.prepare(objectStruct, ...
                'ScaleAxes', {'x', 'y'}, ...
                'ScalePointPositions', {[0 0 0]});

            testCase.verifyError(call, 'GizmoObjectPreparer:ScalePointCountMismatch');
        end
    end
end
