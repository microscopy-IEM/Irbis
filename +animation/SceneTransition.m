classdef SceneTransition

    properties
        % camposIncrement
        horizontalAngleIncrement
        verticalAngleIncrement
        viewAngleIncrement
        dtheta
        dphi
    end

    methods
        function obj = SceneTransition(ax, startScene, endScene, duration, period)

            arguments
                ax matlab.graphics.axis.Axes
                startScene animation.Scene
                endScene animation.Scene
                duration (1,1) double {mustBePositive}
                period (1,1) double {mustBePositive}
            end
            nSteps = duration / period
            % subtracting start and end position leads to 'zoom in' effect in the middle of transition
            % obj.camposIncrement = (endScene.sceneState.CameraPosition - startScene.sceneState.CameraPosition) / nSteps;
            disp('rotation start:')
            disp(startScene.sceneState.CameraPosition)
            disp('rotation end:')
            disp(endScene.sceneState.CameraPosition)
            startVec = startScene.sceneState.CameraPosition - startScene.sceneState.CameraTarget;
            endVec = endScene.sceneState.CameraPosition - endScene.sceneState.CameraTarget;
            [dtheta, dphi] = animation.SceneTransition.camorbitAnglesFromVectors(ax, startVec, endVec)
            obj.horizontalAngleIncrement = wrapTo180(180-dtheta) / nSteps;
            obj.verticalAngleIncrement = wrapTo180(dphi) / nSteps;
            obj.dtheta = dtheta;
            obj.dphi = dphi;
            % obj.horizontalAngleIncrement = wrapTo180(180-dtheta) / nSteps;
            % obj.verticalAngleIncrement = wrapTo180(dphi) / nSteps;
            obj.viewAngleIncrement = (endScene.sceneState.CameraViewAngle - startScene.sceneState.CameraViewAngle) / nSteps;
        end



        function atOnce(obj, ax)
            % ax.CameraPosition = ax.CameraPosition + obj.camposIncrement;
            camorbit(ax, obj.dtheta, obj.dphi, 'data', [0 0 -1]);
            % ax.CameraViewAngle = ax.CameraViewAngle + obj.viewAngleIncrement;
        end


        
        function incrementallyTransition(obj, ax)
            % ax.CameraPosition = ax.CameraPosition + obj.camposIncrement;
            camorbit(ax, obj.horizontalAngleIncrement, obj.verticalAngleIncrement, 'data', [0 0 1]);
            % ax.CameraViewAngle = ax.CameraViewAngle + obj.viewAngleIncrement;
        end
    end


    methods (Static, Access = private)
        function [dtheta, dphi] = camorbitAnglesFromVectors(ax, v1, v2)
        % v1, v2: 1x3 vectors (from the same origin). Units arbitrary.
        % Returns dtheta (horizontal) and dphi (vertical) in degrees for camorbit.

            % Spherical angles in MATLAB: az = angle in the XY plane, el = angle from XY plane.
            [az1, el1, ~] = cart2sph(v1(1), v1(2), v1(3));
            [az2, el2, ~] = cart2sph(v2(1), v2(2), v2(3));

            % Differences (wrap to [-180, 180] so the orbit takes the shorter path).
            dtheta = rad2deg((az2 - az1));   % horizontal
            dphi   = rad2deg((el2 - el1));   % vertical
        end


        % function [dtheta, dphi] = camorbitAnglesFromVectors(ax, v1, v2)
        % % ax : target axes
        % % v1 : (campos - camtarget) in DATA coords
        % % v2 : (desiredPos - camtarget) in DATA coords
        % % Returns dtheta (horizontal) and dphi (vertical) for camorbit in degrees.

        %     % 0) Guard
        %     if any(isnan(v1)) || any(isnan(v2)) || norm(v1)==0 || norm(v2)==0
        %         error('Vectors must be finite and nonzero.');
        %     end

        %     % 1) Apply axis-direction flips so "data" coordinates are consistent
        %     sx = animation.SceneTransition.dirSign(ax.XDir);  % +1 for 'normal', -1 for 'reverse'
        %     sy = animation.SceneTransition.dirSign(ax.YDir);
        %     sz = animation.SceneTransition.dirSign(ax.ZDir);
        %     v1 = [sx, sy, sz] .* v1;
        %     v2 = [sx, sy, sz] .* v2;

        %     % 2) Spherical in math convention (az from +X, CCW; el from XY plane)
        %     [az1, el1] = cart2sph(v1(1), v1(2), v1(3));
        %     [az2, el2] = cart2sph(v2(1), v2(2), v2(3));

        %     % 3) Convert to MATLAB's view convention:
        %     %    az_view = 90° - az_math_deg ; el_view = el_math_deg
        %     az1v = 90 - rad2deg(az1);
        %     az2v = 90 - rad2deg(az2);
        %     el1v =  rad2deg(el1);
        %     el2v =  rad2deg(el2);

        %     % 4) Differences → camorbit deltas (wrapped to shortest path)
        %     dtheta = wrapTo180(az2v - az1v);   % horizontal
        %     dphi   = wrapTo180(el2v - el1v);   % vertical
        % end

        % function s = dirSign(dirStr)
        %     s = 1; 
        %     if strcmp(dirStr,'reverse')
        %         s = -1; 
        %     end
        % end


        % function [dtheta, dphi] = camorbitAnglesFromVectors(ax, v1, v2)
        % % ax : target axes
        % % v1 : (campos - camtarget) in DATA coords
        % % v2 : (desiredPos - camtarget) in DATA coords
        % % Returns dtheta (horizontal) and dphi (vertical) for camorbit in degrees.

        %     % 0) Guard
        %     if any(isnan(v1)) || any(isnan(v2)) || norm(v1)==0 || norm(v2)==0
        %         error('Vectors must be finite and nonzero.');
        %     end

        %     % Projections into XY plane

        %     v1_xy = [v1(1), -v1(2), 0]
        %     v2_xy = [v2(1), -v2(2), 0]

        %     if isequal(v1_xy, [0 0 0]) || isequal(v2_xy, [0 0 0])
        %         dtheta = 0;
        %     else
                    
        %         % Normalize
        %         v1_xy = v1_xy / norm(v1_xy)
        %         v2_xy = v2_xy / norm(v2_xy)

        %         % Azimuth (angle in XY plane)
        %         atan2d(v1_xy(2), v1_xy(1))
        %         atan2d(v2_xy(2), v2_xy(1))
        %         dtheta = atan2d(v1_xy(2), v1_xy(1)) - atan2d(v2_xy(2), v2_xy(1));
        %         % dtheta = rad2deg(atan2(sin(azimuth), cos(azimuth))); % keep in [-180, 180]
        %     end


        %     % Elevation of each vector
        %     elev1 = atan2(v1(3), norm(v1(1:2)));
        %     elev2 = atan2(v2(3), norm(v2(1:2)));

        %     % Difference in elevation
        %     dphi = rad2deg(elev1 - elev2);
        % end

        % function s = dirSign(dirStr)
        %     s = 1; 
        %     if strcmp(dirStr,'reverse')
        %         s = -1; 
        %     end
        % end
    end
end