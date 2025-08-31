classdef Keyframe
    properties
        scene
        appearance
        timeStatus
    end

    methods
        function obj = Keyframe(scene, appearance, timeStatus)
            arguments
                scene animation.Scene
                appearance animation.Appearance
                timeStatus
            end
            obj.scene = scene;
            obj.appearance = appearance;
            obj.timeStatus = timeStatus;
        end



        function applyState(obj, ax, renderer)
            disp('Applying keyframe state');
            obj.scene.applyState(ax);
            obj.appearance.applyState(renderer);
        end



        function applyStaticProperties(obj, ax, renderer)
            obj.scene.applyStaticProperties(ax);
            obj.appearance.applyState(renderer);
        end



        function timepoint = getTimePoint(obj)
            timepoint = obj.timeStatus.timePoint;
        end
    end
end