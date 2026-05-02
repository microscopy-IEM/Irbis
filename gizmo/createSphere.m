function [vertices, faces] = createSphere(radius, nDivisions, numberingType)

    % Generate a triangulated sphere centred at [0 0 0].
    %
    % Inputs:
    %   radius       - sphere radius
    %   nDivisions   - mesh density (sphere uses nDivisions+1 grid points per axis)
    %   numberingType - face numbering convention:
    %                   1 -> MATLAB style (1-based)
    %                   0 -> Python style (0-based)
    %
    % Outputs:
    %   vertices - Nx3 array of vertex coordinates
    %   faces    - Mx3 array of triangle vertex indices

    if nargin < 1 || isempty(radius)
        radius = 0.5;
    end
    if nargin < 2 || isempty(nDivisions)
        nDivisions = 20;
    end
    if nargin < 3 || isempty(numberingType)
        numberingType = 1;
    end

    % Base unit sphere grid
    [X, Y, Z] = sphere(nDivisions);

    % Scale to required radius
    X = radius * X;
    Y = radius * Y;
    Z = radius * Z;

    % Convert parametric grid to triangulated mesh
    meshStruct = surf2patch(X, Y, Z, 'triangles');
    vertices = meshStruct.vertices;
    faces = meshStruct.faces;

    % Numbering convention
    if isequal(numberingType, 0)
        faces = faces - 1;
    end

end
