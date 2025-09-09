classdef ResetSpineExpansion < animation.SpecialEffect
    methods
        function obj = ResetSpineExpansion(effectDuration)
            % Constructor for ResetSpineExpansion effect
            obj.effectDuration = effectDuration;
        end

        function apply(~, renderer)
            % Apply reset spine expansion effect to the keyframe
            renderer.resetSpineExpansion();
        end
    end
end