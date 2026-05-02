function [vertices, faces] = createThinCuboidObject(scalingFactor,flattenedAxis,flatteningFactor,numberingType)

% default size is 1x1x1 with the centre in 0

vertices = [
    -0.5, -0.5, -0.5;  % Vertex 0
     0.5, -0.5, -0.5;  % Vertex 1
    -0.5,  0.5, -0.5;  % Vertex 2
     0.5,  0.5, -0.5;  % Vertex 3
    -0.5, -0.5,  0.5;  % Vertex 4
     0.5, -0.5,  0.5;  % Vertex 5
    -0.5,  0.5,  0.5;  % Vertex 6
     0.5,  0.5,  0.5   % Vertex 7
];

faces = [
    2, 1, 0;
    1, 2, 3;
    4, 2, 0;
    2, 4, 6;
    1, 4, 0;
    4, 1, 5;
    6, 5, 7;
    5, 6, 4;
    3, 6, 7;
    6, 3, 2;
    5, 3, 7;
    3, 5, 1
];

% scaling factor - makes the cuboid smaller or larger - can be either scalar or 1x3 vector
vertices = vertices.*scalingFactor;

% flattenedAxis - 1/2/3 corresponding to x/y/z
% flatteningFactor will flatten one of the dimensions
vertices(:,flattenedAxis) = vertices(:,flattenedAxis)*flatteningFactor;

% numbering type - whether numbering starts with 1 (Matlab style) or 0 (Python style)
if isequal(numberingType,1)
    faces = faces + 1;
end

% % create an object structure that will be passed to gizmo tool
% objectStruct = struct('vertices',vertices,'faces',faces);
% objectStruct.scalePointVectors = {[0 1 1]};
% objectStruct.scalePointPositions = cell(1, numel(objectStruct.scalePointVectors));
% for scalePointNum = 1:numel(objectStruct.scalePointVectors)
%     scalePointVector = objectStruct.scalePointVectors{scalePointNum};
%     objectStruct.scalePointPositions{scalePointNum} = scalePointVector .* scalingFactor/2;
% end

% % Create a new figure
% figure;
% 
% % Create a patch object for the thin cuboid
% patch('Vertices', vertices, 'Faces', faces, ...
%       'FaceColor', 'cyan', 'EdgeColor', 'black');
% 
% % Set axes properties
% xlabel('X-axis');
% ylabel('Y-axis');
% zlabel('Z-axis');
% grid on;
% axis equal;
% view(3);  % 3D view

end