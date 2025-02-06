classdef ResultsViewStorage < handle
    properties
        storedViews = {}    % Cell array of resultsView objects
    end
    methods
        function obj = ResultsViewStorage()
            obj.storedViews = {};
        end


        function addView(obj, resultsView)
            obj.storedViews{end+1} = resultsView;
        end


        function deleteView(obj, name)
            idx = obj.getIndexByName(name);
            if idx > 0
                obj.storedViews(idx) = [];
            end
        end


        function viewNamesList = getViewNamesList(obj)
            viewNamesList = cell(1, length(obj.storedViews));
            for i = 1:length(obj.storedViews)
                viewNamesList{i} = obj.storedViews{i}.viewName;
            end
        end


        function resultsView = getViewByName(obj, name)
            idx = obj.getIndexByName(name);
            if idx > 0
                resultsView = obj.storedViews{idx};
            else
                resultsView = [];
            end
        end

        
        function index = getIndexByName(obj, name)
            index = -1;
            for i = 1:length(obj.storedViews)
                if strcmp(obj.storedViews{i}.viewName, name)
                    index = i;
                    break;
                end
            end
        end
    end
end