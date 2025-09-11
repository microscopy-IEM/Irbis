classdef AnimateShaftConstruction < animation.SpecialEffect
    methods
        function obj = AnimateShaftConstruction(effectDuration)
            % Constructor for AnimateShaftConstruction effect
            obj.effectDuration = effectDuration;
        end

        function apply(~, renderer)
            % Apply animate shaft reconstruction effect to the keyframe
            renderer.renderShaftReconstruction();
        end
    end
end