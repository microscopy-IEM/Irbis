% super important finding - the order of vertexIds in faces determines the orientation of the face
% based on the right-hand rule

function [vertices, faces] = createCylinderObject(nSides,nLayers,radius,height,numberingType)

% generating a cylinder with nSides and nLayers

% number of faces 
nFaces = 2*nSides + 2*nSides*(nLayers-1);
nVertices = nLayers*nSides + 2;

% generating list of faces
faces = zeros(nFaces,3);

faceN = 1;

idCenterUp = 1;
idCenterBottom = nVertices;

% upper cap
for i = 1:(nSides-1)
    faces(faceN,:) = [idCenterUp idCenterUp+i+1 idCenterUp+i];
    faceN = faceN + 1;
end

faces(faceN,:) = [idCenterUp idCenterUp+1 idCenterUp+nSides];
faceN = faceN + 1;

% sides 
for l = 1:(nLayers-1)
    idUp = (l-1)*nSides + idCenterUp;
    idBottom = l*nSides + idCenterUp;
    for i = 1:(nSides-1)
        % if rem(i,2)
            faces(faceN,:) = [idUp+i idUp+i+1 idBottom+i+1];
            faceN = faceN + 1;
            faces(faceN,:) = [idUp+i idBottom+i+1 idBottom+i];
            faceN = faceN + 1;
        % else 
        %     faces(faceN,:) = [idUp+i idUp+i+1 idBottom+i];
        %     faceN = faceN + 1;
        %     faces(faceN,:) = [idUp+i+1 idBottom+i idBottom+i+1];
        %     faceN = faceN + 1;
        % end
    end
    % if rem(nSides,2)
        faces(faceN,:) = [idUp+nSides idUp+1 idBottom+1];
        faceN = faceN + 1;
        faces(faceN,:) = [idUp+nSides idBottom+1 idBottom+nSides];
        faceN = faceN + 1;
    % else
    %     faces(faceN,:) = [idUp+nSides idUp+1 idBottom+nSides];
    %     faceN = faceN + 1;
    %     faces(faceN,:) = [idUp+1 idBottom+nSides idBottom+1];
    %     faceN = faceN + 1;
    % end

end

% bottom cap
for i = 1:(nSides-1)
    faces(faceN,:) = [idCenterBottom idCenterBottom-i-1 idCenterBottom-i];
    faceN = faceN + 1;
end

faces(faceN,:) = [idCenterBottom idCenterBottom-1 idCenterBottom-nSides];

if isequal(numberingType,0)
    faces = faces - 1;
end

% vertices

% Define the angular positions for the circular base
theta = linspace(0, 2*pi, nSides+1);
x = radius * cos(theta(1:end-1));  % X-coordinates of the circle (excluding duplicate)
y = radius * sin(theta(1:end-1));  % Y-coordinates of the circle (excluding duplicate)

% Z-coordinates for each layer (evenly spaced along the height)
zLayers = linspace(0, height, nLayers);

% Create the vertices for all layers (circular slices along the height)
vertices = [];
for i = 1:nLayers
    z = zLayers(i);  % Z-coordinate for this layer
    vertices = [vertices; x', y', z * ones(nSides, 1)];
end
 
% Center points for the bottom and top faces for triangulation
centerBottom = [0, 0, 0];  % Center of the bottom face
centerTop = [0, 0, height];  % Center of the top face

% Append the center points to the vertices list
vertices = [centerBottom; vertices; centerTop];

vertices(:,3) = vertices(:,3) - height/2;
vertices(:,[1 2 3]) = vertices(:,[1 3 2]);
vertices(:,2) = -vertices(:,2);

% objectStruct = struct('vertices',vertices,'faces',faces);
% objectStruct.scalePointVectors = {[1 0 1], [0 1 0]};
% objectStruct.scalePointPositions = {[radius/1.41 0 radius/1.41], [0 height/2 0]};

end
