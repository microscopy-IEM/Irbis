classdef (Sealed) BoundsChecker
    methods (Static)
        function isIn = isInInterval(frameRange, timeIntervalArray)
            % timeIntervalArray has two columns: start and end times
            arguments
                frameRange (1, 2) double
                timeIntervalArray (2, :) double % two rows: start and end times
            end

            startTime = timeIntervalArray(1, :);
            endTime = timeIntervalArray(2, :);
            isBefore = frameRange(2) < startTime;
            isAfter = frameRange(1) > endTime;
            isIn = ~isBefore & ~isAfter;
        end


        function isIn = isInVolume(volumeMins, volumeMaxs, boundingBoxMins, boundingBoxMaxs)
            % volumeMins and volumeMaxs should be 1 x 1 x 3 vectors
            % boundingBoxMins and boundingBoxMaxs should be 1 x n x 3, where n is the number of objects
            arguments
                volumeMins (1, 1, 3) double
                volumeMaxs (1, 1, 3) double
                boundingBoxMins (1, :, 3) double
                boundingBoxMaxs (1, :, 3) double
            end
            isAbove = any(boundingBoxMins > volumeMaxs, 3);
            isBelow = any(boundingBoxMaxs < volumeMins, 3);

            isIn = ~isAbove & ~isBelow; % the object is inside if it is neither above nor below boundaries
        end
    end
end