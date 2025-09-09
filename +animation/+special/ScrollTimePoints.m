classdef ScrollTimePoints < animation.SpecialEffect
    methods
        function obj = ScrollTimePoints(effectDuration)
            % Constructor for ScrollTimePoints effect
            obj.effectDuration = effectDuration;
        end


        function apply(obj, renderer)
            % Apply scrolling effect to the keyframe
            renderer.renderScrollTime(obj.effectDuration);
        end
    end
end