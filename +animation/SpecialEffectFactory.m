classdef (Sealed) SpecialEffectFactory
    methods (Static)
        function effect = create(effectType, effectDuration)
            switch effectType
                case 'Expand spines'
                    effect = animation.special.ExpandSpines(effectDuration);
                case 'Reset spine expansion'
                    effect = animation.special.ResetSpineExpansion(effectDuration);
                case 'Scroll planes'
                    effect = animation.special.ScrollPlanes(effectDuration);
                case 'Scroll time points'
                    effect = animation.special.ScrollTimePoints(effectDuration);
                case 'Animate shaft construction'
                    effect = animation.special.AnimateShaftConstruction(effectDuration);
                otherwise
                    error('Unknown effect type: %s', effectType);
            end
        end
    end
end
