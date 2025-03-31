% filepath: c:\Users\sveco\Documents\Irbis\testGraphicsObjectGroup.m
% Test script for GraphicsObjectGroup class

% Create figure and axes
fig = figure('Name', 'GraphicsObjectGroup Test');
ax = axes('Parent', fig);
view(ax, 3);
grid(ax, 'on');
lighting gouraud;
camlight;

% Create sample data (two cubes)
cube1Vertices = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
cube1Faces = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];

cube2Vertices = cube1Vertices + 2; % Shifted cube

% Package data for group
vertices = {cube1Vertices, cube2Vertices};
faces = {cube1Faces, cube1Faces};
ids = {'cube1', 'cube2'};

% Create callback function
function objectClicked(src, ~)
    disp(['Clicked object: ' src.UserData]);
end

% Initialize group with multiple colors
colors = {[1 0 0], [0 1 0], [0 0 1]}; % Red, Green, Blue
group = GraphicsObjectGroup(ax, 'test_group', 'gouraud', 0.8, colors);
group.initializeGroup(vertices, faces, ids, @objectClicked);

% Test color changes
disp('Testing color changes...');
pause(1);
group.setColor({[1 1 0], [0 1 1]}); % Change to yellow and cyan
pause(1);
group.setColor([1 0 1]); % Change all to magenta
pause(1);

% Test visibility
disp('Testing visibility (should see objects disappear/reappear)...');
pause(1);
group.setVisibility('off');
pause(1);
group.setVisibility('on');

% Test transparency
disp('Testing transparency...');
pause(1);
group.setTransparency(0.3);
pause(1);
group.setTransparency(0.8);

% Test lighting method
disp('Testing lighting method...');
pause(1);
group.setLightingMethod('flat');
pause(1);
group.setLightingMethod('gouraud');

% Test exclusion
disp('Testing object exclusion...');
pause(1);
group.setExcluded([true false]); % Exclude first cube
pause(1);
group.setExcluded([false false]); % Show both

% Test adding new objects
disp('Testing adding new objects...');
% Create a third cube shifted up
cube3Vertices = cube1Vertices + [0 0 2]; % Cube shifted up
newVertices = {cube3Vertices};
newFaces = {cube1Faces};
newIds = {'cube3'};

% Add new objects to existing group
group.addGraphicsObjects(newVertices, newFaces, newIds, {[0.3 0.3 0.3]}); % Gray color
pause(1);

% Verify all objects are visible
group.setExcluded([false false false]);
pause(1);

% Test adding object with duplicate ID
disp('Testing adding object with duplicate ID...');
duplicateCubeVertices = cube1Vertices + [0 3 0]; % Cube shifted in Y
duplicateVertices = {duplicateCubeVertices};
duplicateFaces = {cube1Faces};
duplicateIds = {'cube1'}; % Same ID as first cube

try
    group.addGraphicsObjects(duplicateVertices, duplicateFaces, duplicateIds);
    % error('Expected error for duplicate ID was not thrown');
catch ME
    disp(['Caught expected error: ' ME.message]);
end
pause(1);

% % Test cleanup
% disp('Testing graphics deletion...');
% pause(1);
% group.deleteGraphics();

disp('Test complete!');