function rotationMatrix = calculateRotationMatrix(originalVector, rotatedVector)
    % Normalize vectors
    rotatedVector = rotatedVector / norm(rotatedVector);
    originalVector = originalVector / norm(originalVector);

    if norm(rotatedVector - originalVector) < 1e-12
        % Already aligned
        rotationMatrix = eye(3);
        return

    % Special case check: if rotatedVector is exactly opposite of 'direction'
    elseif norm(rotatedVector + originalVector) < 1e-12
        % 1) Pick any axisCandidate that is not collinear with 'direction'
        axisCandidate = cross(originalVector, [1; 0; 0]);
        if norm(axisCandidate) < 1e-12
            % If direction is parallel to [1;0;0], pick a different fallback:
            axisCandidate = cross(originalVector, [0; 1; 0]);
        end
        
        % 2) Normalize the axis
        axisCandidate = axisCandidate / norm(axisCandidate);
        
        % 3) Construct rotation matrix for 180 deg (pi radians) about 'axisCandidate'
        rotationMatrix = axisAngle2Matrix(axisCandidate, pi);
        
        return;  % done
    end
    
    % Otherwise, use an axis-angle approach
    k = cross(rotatedVector, originalVector);
    k = k / norm(k);          % unit rotation axis
    angle = acos(dot(rotatedVector, originalVector));
    
    rotationMatrix = axisAngle2Matrix(k, angle);
end

function R = axisAngle2Matrix(k, theta)
    % k is a 3x1 *unit* vector
    kx = k(1); ky = k(2); kz = k(3);
    ct = cos(theta);
    st = sin(theta);
    vt = 1 - ct;
    
    R = [ kx*kx*vt + ct,    kx*ky*vt - kz*st,  kx*kz*vt + ky*st;
          ky*kx*vt + kz*st, ky*ky*vt + ct,    ky*kz*vt - kx*st;
          kz*kx*vt - ky*st, kz*ky*vt + kx*st, kz*kz*vt + ct      ];
end