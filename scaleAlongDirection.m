function T = scaleAlongDirection(center, direction, scaleFactor)

    % Ensure column vectors
    center = center(:);
    direction = direction(:);

    T = eye(4);
    T(1:3,4) = -center;

    

    
    % SCALE_ALONG_DIRECTION creates a 4x4 transform that:
    %   1) Translates center c to the origin
    %   2) Rotates so that direction d lines up with the x-axis
    %   3) Scales along the x-axis by factor s
    %   4) Rotates back
    %   5) Translates back by c
    %
    % INPUTS:
    %   c : [3x1] center of scaling
    %   d : [3x1] direction in which to scale
    %   s : scalar scale factor
    %
    % OUTPUT:
    %   T : [4x4] homogeneous transformation matrix
    
        % Ensure column vectors
        center = center(:);
        direction = direction(:);
        
        % 1) Translate center c to origin
        T_trans1 = eye(4);
        T_trans1(1:3,4) = -center;  % subtract c
        
        % 2) Rotate so direction d lines up with +x axis
        R = rotation_to_x_axis(direction);  % get a 3x3 rotation
        T_R = eye(4);
        T_R(1:3,1:3) = R;
        
        % 3) Scale along x-axis
        T_scale = eye(4);
        T_scale(1,1) = scaleFactor;      % scale in x by s
        % (y and z remain unscaled => 1,1)
        
        % 4) Rotate back (R^-1 = R')
        T_R_inv = eye(4);
        T_R_inv(1:3,1:3) = R';
        
        % 5) Translate back
        T_trans2 = eye(4);
        T_trans2(1:3,4) = center;   % add c
        
        % Compose them: T_trans2 * T_R_inv * T_scale * T_R * T_trans1
        T = T_trans2 * T_R_inv * T_scale * T_R * T_trans1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function R = rotation_to_x_axis(d)
        % Normalize direction
        d = d / norm(d);
        x_axis = [1; 0; 0];
        if norm(d - x_axis) < 1e-12
            % Already aligned
            R = eye(3);
            return
        elseif norm(d + x_axis) < 1e-12
            % d is exactly opposite of x-axis => rotate 180 deg about y-axis
            R = [ ...
                -1,  0,  0; ...
                 0,  1,  0; ...
                 0,  0, -1 ];
            return
        end
        
        % Otherwise, use an axis-angle approach
        k = cross(d, x_axis);
        k = k / norm(k);          % unit rotation axis
        angle = acos(dot(d, x_axis));
        
        R = axisAngle2Matrix(k, angle);
    end
    
    function R = axisAngle2Matrix(k, theta)
        % k is a 3x1 unit vector
        kx = k(1); ky = k(2); kz = k(3);
        ct = cos(theta); st = sin(theta); vt = 1 - ct;
        
        R = [ kx*kx*vt + ct,   kx*ky*vt - kz*st, kx*kz*vt + ky*st;
              ky*kx*vt + kz*st, ky*ky*vt + ct,   ky*kz*vt - kx*st;
              kz*kx*vt - ky*st, kz*ky*vt + kx*st, kz*kz*vt + ct ];
    end
    