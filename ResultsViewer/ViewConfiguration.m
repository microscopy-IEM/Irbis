classdef (Sealed) ViewConfiguration

    properties (Access = private)
        viewName = '';
        configurationStruct = struct();
    end

    methods (Access = public)     
        function obj = ViewConfiguration(viewName, configurationStruct)
            obj.viewName = viewName;
            obj.configurationStruct = configurationStruct;
        end

        function name = getViewName(obj)
            name = obj.viewName;
        end

        function config = getConfiguration(obj)
            config = obj.configurationStruct;
        end
    end
end