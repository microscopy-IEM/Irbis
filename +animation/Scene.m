classdef Scene 
    properties
        sceneState struct
    end

    methods
        function obj = Scene(state)
            obj.sceneState = state;
        end

        function applyStaticProperties(obj, ax, renderer)
            % Apply the scene state to the given axes
            disp('Applying static scene properties:');
            disp(obj.sceneState.CameraTarget)
            disp(obj.sceneState.CameraPosition)
            ax.CameraTarget = obj.sceneState.CameraTarget;
            ax.CameraUpVector = obj.sceneState.CameraUpVector;
            % renderer.updateAxesOrigin(obj.sceneState.relativeAxOrigin);
            renderer.updateAxesPosition(obj.sceneState.relativeCentre, obj.sceneState.axToPanelRatio);
        end

        function applyState(obj, ax, renderer)
            disp('Applying scene state:');
            disp(obj.sceneState);
            % Apply the full scene state to the given axes
            ax.CameraPosition = obj.sceneState.CameraPosition;
            ax.CameraTarget = obj.sceneState.CameraTarget;
            ax.CameraViewAngle = obj.sceneState.CameraViewAngle;
            ax.CameraUpVector = obj.sceneState.CameraUpVector;
            % renderer.updateAxesOrigin(obj.sceneState.relativeAxOrigin);
            renderer.updateAxesPosition(obj.sceneState.relativeCentre, obj.sceneState.axToPanelRatio);
        end
    end
end