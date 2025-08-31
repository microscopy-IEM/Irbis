classdef Sequence < animation.Views
    properties
        durations double
    end


    methods
        function addKeyframe(obj, keyframe, duration)
            addKeyframe@animation.Views(obj, keyframe);
            obj.durations(end+1) = duration;
            labelNum = obj.usedLabelNumbers(end);
            label = ['Keyframe ' num2str(labelNum)];
            obj.labels{end} = label;
        end



        function removeKeyframe(obj, frameIndex)
            removeKeyframe@animation.Views(obj, frameIndex);
            obj.durations(frameIndex) = [];
        end



        function [keyframes, durations] = getSelectedKeyframes(obj, selectedFrames)
            keyframes = getSelectedKeyframes@animation.Views(obj, selectedFrames);
            durations = obj.durations(selectedFrames);
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