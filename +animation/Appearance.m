classdef Appearance
    properties
        visibility
    end

    methods
        function obj = Appearance(visibility)
            arguments
                visibility struct
            end
            obj.visibility = visibility;
        end

        function applyState(obj, renderer)
            renderer.renderAppearance(obj);
        end
    end
end