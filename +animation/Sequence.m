classdef Sequence < animation.Views
    properties
        durations double
        specialEffects cell % Cell array of SpecialEffect objects/empty cells
    end


    methods
        function addKeyframe(obj, keyframe, duration, specialEffect, effectName)
            arguments
                obj
                keyframe animation.Keyframe
                duration double {mustBePositive}
                specialEffect = []
                effectName = ''
            end
            addKeyframe@animation.Views(obj, keyframe);
            obj.durations(end+1) = duration;
            obj.specialEffects{end+1} = specialEffect;
            labelNum = obj.usedLabelNumbers(end);
            if isempty(effectName)
                label = ['Keyframe ' num2str(labelNum)];
            else
                label = ['Keyframe ' num2str(labelNum) ': ' effectName];
            end
            obj.labels{end} = label;
        end



        function removeKeyframe(obj, frameIndex)
            removeKeyframe@animation.Views(obj, frameIndex);
            obj.durations(frameIndex) = [];
        end



        function [keyframes, durations, specialEffects] = getSelectedKeyframes(obj, selectedFrames)
            keyframes = getSelectedKeyframes@animation.Views(obj, selectedFrames);
            durations = obj.durations(selectedFrames);
            specialEffects = obj.specialEffects(selectedFrames);
        end



        function changeKeyframeDuration(obj, frameIndex, newDuration)
            obj.durations(frameIndex) = newDuration;
        end



        function durations = getKeyframeDurations(obj)
            durations = obj.durations;
        end



        function changeOrder(obj, keyframeOrder)
            changeOrder@animation.Views(obj, keyframeOrder);
            obj.durations = obj.durations(keyframeOrder);
        end
    end
end