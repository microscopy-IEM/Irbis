classdef ExpandSpines < animation.SpecialEffect
    methods
        function obj = ExpandSpines(effectDuration)
            % Constructor for ExpandSpines effect
            obj.effectDuration = effectDuration;
        end


        function apply(obj, renderer)
            % Apply expanding spines effect to the keyframe
            renderer.renderSpineExpansion(obj.effectDuration);
        end
    end
end