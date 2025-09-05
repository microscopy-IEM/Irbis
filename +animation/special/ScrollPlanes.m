classdef ScrollPlanes < animation.SpecialEffect
    methods
        function obj = ScrollPlanes(effectDuration)
            % Constructor for ScrollPlanes effect
            obj.effectDuration = effectDuration;
        end


        function apply(obj, renderer)
            % Apply scrolling effect to the keyframe
            renderer.renderScrollPlanes(obj.effectDuration);
        end
    end
end