classdef TestGizmoTool < matlab.unittest.TestCase

    properties
        Figure
        Axes
    end


    methods (TestMethodSetup)
        function createFigure(testCase)
            testCase.Figure = figure('Visible', 'off');
            testCase.Axes = axes(testCase.Figure);

            testCase.Axes.Units = 'pixels';
            testCase.Axes.XLim = [-10 10];
            testCase.Axes.YLim = [-10 10];
            testCase.Axes.ZLim = [-10 10];
            testCase.Axes.DataAspectRatio = [1 1 1];
            testCase.Axes.PlotBoxAspectRatio = [1 1 1];
            testCase.Axes.NextPlot = 'add';
        end
    end


    methods (TestMethodTeardown)
        function closeFigure(testCase)
            if ~isempty(testCase.Figure) && isvalid(testCase.Figure)
                close(testCase.Figure);
            end
        end
    end


    methods (Test)
        function constructsWithoutObjectAndReturnsPose(testCase)
            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [1 2 3], [0 1 0], struct());

            pos = gizmo.getCentrePositionUM();
            rot = gizmo.getRotationVector();

            testCase.verifyLessThan(norm(pos - [1 2 3]), 1e-9);
            testCase.verifyLessThan(norm(rot - [0 1 0]), 1e-6);

            delete(gizmo);
        end


        function rotateToNoOpForInvalidTargetVector(testCase)
            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], struct());

            rotBefore = gizmo.getRotationVector();

            gizmo.rotateTo([0 0 0]);
            rotAfterZero = gizmo.getRotationVector();

            gizmo.rotateTo([NaN 0 0]);
            rotAfterNaN = gizmo.getRotationVector();

            testCase.verifyLessThan(norm(rotAfterZero - rotBefore), 1e-9);
            testCase.verifyLessThan(norm(rotAfterNaN - rotBefore), 1e-9);

            delete(gizmo);
        end


        function rotateToHandlesAntiparallelDirection(testCase)
            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], struct());

            gizmo.rotateTo([-1 0 0]);
            rot = gizmo.getRotationVector();

            testCase.verifyLessThan(norm(rot - [-1 0 0]), 1e-6);

            delete(gizmo);
        end


        function getRotationVectorThrowsWhenNormalHandleMissing(testCase)
            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], struct());

            normalHandle = findobj(gizmo.getGizmoHandle(), 'Tag', 'normBallPoint');
            delete(normalHandle);

            call = @() gizmo.getRotationVector();
            testCase.verifyError(call, 'GizmoTool:MissingNormalPoint');

            delete(gizmo);
        end


        function setStickyPointsTogglesCentreInteractivity(testCase)
            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], struct());

            centreHandle = findobj(gizmo.getGizmoHandle(), 'Tag', 'cBallPoint');

            testCase.verifyEmpty(get(centreHandle, 'ButtonDownFcn'));
            testCase.verifyEqual(string(get(centreHandle, 'PickableParts')), "none");

            stickyPoints = [0 0 0; 1 0 0];
            stickyNormals = [0 0 1; 0 0 1];
            gizmo.setStickyPoints(stickyPoints, stickyNormals);

            testCase.verifyNotEmpty(get(centreHandle, 'ButtonDownFcn'));
            testCase.verifyEqual(string(get(centreHandle, 'PickableParts')), "visible");

            gizmo.setStickyPoints(zeros(0,3), zeros(0,3));

            testCase.verifyEmpty(get(centreHandle, 'ButtonDownFcn'));
            testCase.verifyEqual(string(get(centreHandle, 'PickableParts')), "none");

            delete(gizmo);
        end


        function deleteRestoresOriginalFigureCallbacks(testCase)
            originalMotion = @(~,~)disp('originalMotionCallback');
            originalUp = @(~,~)disp('originalButtonUpCallback');
            originalScroll = @(~,~)disp('originalScrollCallback');

            testCase.Figure.WindowButtonMotionFcn = originalMotion;
            testCase.Figure.WindowButtonUpFcn = originalUp;
            testCase.Figure.WindowScrollWheelFcn = originalScroll;

            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], struct());

            testCase.Figure.WindowButtonMotionFcn = @(~,~)disp('temporaryMotion');
            testCase.Figure.WindowButtonUpFcn = @(~,~)disp('temporaryUp');
            testCase.Figure.WindowScrollWheelFcn = @(~,~)disp('temporaryScroll');

            delete(gizmo);

            testCase.verifyEqual(func2str(testCase.Figure.WindowButtonMotionFcn), func2str(originalMotion));
            testCase.verifyEqual(func2str(testCase.Figure.WindowButtonUpFcn), func2str(originalUp));
            testCase.verifyEqual(func2str(testCase.Figure.WindowScrollWheelFcn), func2str(originalScroll));
        end


        function constructorThrowsForInvalidObjectReference(testCase)
            objectStruct = struct();
            objectStruct.objectForGizmo = 42;
            objectStruct.scalePointVectors = {};
            objectStruct.scalePointPositions = {};

            call = @() GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], objectStruct);
            testCase.verifyError(call, 'GizmoTool:InvalidObjectReference');
        end


        function preservesExistingObjectHandleAfterDelete(testCase)
            vertices = [
                -1 -1 -1;
                 1 -1 -1;
                 0  1 -1;
                 0  0  1
            ];
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];

            existingHandle = patch(testCase.Axes, 'Vertices', vertices, 'Faces', faces);

            objectStruct = struct();
            objectStruct.objectForGizmo = existingHandle;
            objectStruct.scalePointVectors = {};
            objectStruct.scalePointPositions = {};

            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], objectStruct);
            delete(gizmo);

            testCase.verifyTrue(isvalid(existingHandle));
        end


        function deletesTemporaryCreatedPatchWithGizmo(testCase)
            vertices = [
                -1 -1 -1;
                 1 -1 -1;
                 0  1 -1;
                 0  0  1
            ];
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];

            objectStruct = struct();
            objectStruct.objectForGizmo = struct('vertices', vertices, 'faces', faces);
            objectStruct.scalePointVectors = {};
            objectStruct.scalePointPositions = {};

            gizmo = GizmoTool(testCase.Axes, testCase.Figure, [0 0 0], [1 0 0], objectStruct);
            tempHandle = gizmo.getObjectHandle();
            testCase.verifyFalse(isempty(tempHandle));

            delete(gizmo);

            testCase.verifyFalse(isvalid(tempHandle));
        end


        function acceptsPreparedStructFromPreparer(testCase)
            prepared = GizmoObjectPreparer.preparePredefined("cylinder");

            gizmo = GizmoTool(testCase.Axes, testCase.Figure, prepared.gizmoCenter, [1 0 0], prepared);
            objectHandles = gizmo.getObjectHandle();

            testCase.verifyFalse(isempty(objectHandles));
            testCase.verifyTrue(all(isvalid(objectHandles)));

            delete(gizmo);
        end
    end
end
