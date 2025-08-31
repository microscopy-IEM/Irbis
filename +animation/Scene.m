classdef Scene 
    properties
        sceneState struct
    end

    methods
        function obj = Scene(state)
            obj.sceneState = state;
        end

        function applyStaticProperties(obj, ax)
            % Apply the scene state to the given axes
            disp('Applying static scene properties:');
            disp(obj.sceneState.CameraTarget)
            disp(obj.sceneState.CameraPosition)
            ax.CameraTarget = obj.sceneState.CameraTarget;
            ax.CameraUpVector = obj.sceneState.CameraUpVector;
        end

        function applyState(obj, ax)
            disp('Applying scene state:');
            disp(obj.sceneState);
            % Apply the full scene state to the given axes
            ax.CameraPosition = obj.sceneState.CameraPosition;
            ax.CameraTarget = obj.sceneState.CameraTarget;
            ax.CameraViewAngle = obj.sceneState.CameraViewAngle;
            ax.CameraUpVector = obj.sceneState.CameraUpVector;
        end
    end
end