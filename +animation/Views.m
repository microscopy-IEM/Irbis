classdef Views < handle
    properties
        keyframes cell
        labels cell
        usedLabelNumbers double = []
    end

    methods
        function addKeyframe(obj, keyframe)
            obj.keyframes{end+1} = keyframe;
            labelNum = obj.getNewLabelNumber();
            label = ['View ' num2str(labelNum)];
            obj.labels{end+1} = label;
        end


        function labelNum = getNewLabelNumber(obj)
            if isempty(obj.usedLabelNumbers)
                labelNum = 1;
                obj.usedLabelNumbers = labelNum;
            else
                labelNum = max(obj.usedLabelNumbers) + 1;
                obj.usedLabelNumbers(end+1) = labelNum;
            end
        end


        function removeKeyframe(obj, frameIndex)
            obj.keyframes(frameIndex) = [];
            obj.labels(frameIndex) = [];
            obj.usedLabelNumbers(frameIndex) = [];
        end


        function replaceKeyframe(obj, frameIndex, newKeyframe)
            obj.keyframes{frameIndex} = newKeyframe;
        end


        function renameKeyframe(obj, frameIndex, newLabel)
            obj.labels{frameIndex} = newLabel;
        end


        function keyframes = getSelectedKeyframes(obj, selectedFrames)
            keyframes = obj.keyframes(selectedFrames);
        end


        function labels = getKeyframeLabels(obj)
            labels = obj.labels;
        end


        function labelNumbers = getLabelNumbers(obj)
            labelNumbers = obj.usedLabelNumbers;
        end


        function count = getKeyframeCount(obj)
            count = numel(obj.keyframes);
        end


        function changeOrder(obj, keyframeOrder)
            obj.keyframes = obj.keyframes(keyframeOrder);
            obj.labels = obj.labels(keyframeOrder);
            obj.usedLabelNumbers = obj.usedLabelNumbers(keyframeOrder);
        end
    end
end