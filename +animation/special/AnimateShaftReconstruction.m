classdef AnimateShaftReconstruction < animation.SpecialEffect
    methods
        function obj = AnimateShaftReconstruction(effectDuration)
            % Constructor for AnimateShaftReconstruction effect
            obj.effectDuration = effectDuration;
        end

        function apply(~, renderer)
            % Apply animate shaft reconstruction effect to the keyframe
            renderer.renderShaftReconstruction();
        end
    end
end