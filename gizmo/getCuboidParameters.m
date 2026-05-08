function parameterStruct = getCuboidParameters(cuboidMesh, positionVector, rotationVector)
    positionVector = reshape(positionVector, 1, []);
    rotationVector = reshape(rotationVector, 1, []);

    if numel(positionVector) ~= 3 || numel(rotationVector) ~= 3
        error('positionVector and rotationVector must be 3-element vectors.');
    end

    % rotationVector encodes orientation (direction), not angles.
    % The cuboid's original orientation is along local +X = [1 0 0].
    % First rotate to be perpendicular to Z-axis, then rotate around Z-axis to align with X-axis.
    dir = rotationVector / norm(rotationVector);
    if any(~isfinite(dir))
        error('rotationVector must be a non-zero finite orientation vector.');
    end

    zAxis = [0 0 1];
    
    % Step 1: Rotate to align direction with Z-axis
    c1 = dot(dir, zAxis);  % cos(angle to Z)
    
    if abs(c1) > 1 - 1e-12
        % Direction is already aligned with Z-axis
        R1 = eye(3);
        if c1 < 0
            R1 = diag([1, 1, -1]);  % Flip to point up
        end
    else
        % Rotate around axis perpendicular to both dir and Z-axis
        v1 = cross(dir, zAxis);
        v1 = v1 / norm(v1);
        s1 = sqrt(1 - c1^2);  % sin(angle)
        vx1 = [0 -v1(3) v1(2); v1(3) 0 -v1(1); -v1(2) v1(1) 0];
        % Rodrigues formula
        R1 = eye(3) + s1 * vx1 + (1 - c1) * vx1 * vx1;
    end
    
    % Step 2: Rotate around Z-axis to orient in X direction
    % Project original direction onto XY plane
    dirXY = [dir(1), dir(2), 0];
    dirXY_norm = norm(dirXY);
    
    if dirXY_norm < 1e-12
        % Direction is purely along Z-axis, no rotation needed around Z
        R2 = eye(3);
    else
        % Rotate around Z-axis to align projected direction with X-axis
        dirXY_normalized = dirXY / dirXY_norm;
        theta = atan2(dirXY_normalized(2), dirXY_normalized(1));
        c2 = cos(-theta);
        s2 = sin(-theta);
        R2 = [c2 -s2 0; s2 c2 0; 0 0 1];
    end
    
    % Combined rotation: first align with Z, then rotate around Z
    % Apply R2 then R1 (right-to-left composition order)
    R = (R2 * R1)';  % Transpose for world-to-local transformation

    if isstruct(cuboidMesh) && isfield(cuboidMesh, 'Vertices')
        vertices = cuboidMesh.Vertices;
    else
        vertices = cuboidMesh;
    end

    if size(vertices,2) ~= 3
        error('cuboidMesh must be Nx3 vertices or struct with field Vertices (Nx3).');
    end

    % Remove translation and orientation effects:
    % world = local * R' + position  =>  local = (world - position) * R
    verticesZeroed = (vertices - positionVector) * R

    vertex1Position = verticesZeroed(1, :);
    scalingFactor = abs(vertex1Position(2)) / 0.5
    flatteningFactor = abs(vertex1Position(3) / vertex1Position(2))


    parameterStruct = struct();
    parameterStruct.vertices = verticesZeroed;
end