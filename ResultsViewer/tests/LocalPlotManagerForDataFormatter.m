classdef LocalPlotManagerForDataFormatter < handle
    properties
        lastData = []
        wasCleaned (1,1) logical = false
    end



    methods
        function plotData(obj, data)
            % Capture formatter output so tests can inspect labels without
            % depending on PlotManager, axes, or App Designer components.
            obj.lastData = data;
        end



        function cleanPlot(obj)
            obj.wasCleaned = true;
        end
    end
end
