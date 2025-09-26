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


        function updateAxesOrigin(obj, originPos)
            obj.app.setAxesOriginPos(originPos);
        end


        function updateAxesPosition(obj, centrePos, axToPanelRatio)
            obj.app.setAxesPosition(centrePos, axToPanelRatio);
        end


        function renderScrollPlanes(obj, effectDuration)
            obj.app.animatePlaneScroll(effectDuration);
        end


        function renderScrollTime(obj, timeScroll)
            obj.app.animateTimeScroll(timeScroll);
        end


        function renderSpineExpansion(obj, effectDuration)
            obj.app.animateSpineExpansion(effectDuration);
        end


        function resetSpineExpansion(obj)
            obj.app.resetSpineExpansion();
        end


        function renderShaftReconstruction(obj, ~)
            obj.app.animateShaftReconstruction();
        end
    end
end