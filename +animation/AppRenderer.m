classdef AppRenderer 
    % interface between app and animation/view classes

    properties
        app 
    end

    methods
        function obj = AppRenderer(app)
            obj.app = app;
        end


        function renderAppearance(obj, appearance)
            % Render the given appearance in the app
            obj.app.setObjectAppearance(appearance);
        end
    end
end