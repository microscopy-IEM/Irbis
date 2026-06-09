% % tmpFile = tempname + ".png";
% % exportapp(app.UIFigure, tmpFile);

% % img = imread(tmpFile);

% % pos = app.MyPanel.Position;  % [x y width height]

% % % Convert MATLAB coordinates (bottom-left origin)
% % h = size(img,1);

% % x = round(pos(1));
% % y = round(h - pos(2) - pos(4));
% % w = round(pos(3));
% % hh = round(pos(4));

% % cropped = img(y:y+hh-1, x:x+w-1, :);

% % imwrite(cropped, "panel.png");

% function generateScreenshots()

%     import matlab.uitest.TestCase

%     testCase = TestCase.forInteractiveUse;

%     app = IrbisApp;
%     cleanup = onCleanup(@() delete(app));

%     app.loadDemonstrationData();

%     outputDir = fullfile("docs", "assets");
%     if ~exist(outputDir, "dir")
%         mkdir(outputDir);
%     end

%     drawnow

%     % Choose Files tab
%     testCase.choose(app.FilesTab);
%     drawnow
%     pause(0.2)

%     exportPanelSnapshot(app, app.FilesTab, ...
%         fullfile(outputDir, "files-panel.png"));

%     exportPanelSnapshot(app, app.RightPanel, ...
%         fullfile(outputDir, "visualization-panel.png"));

%     testCase.choose(app.ModelTab);
%     testCase.choose(app.spinesTab);

%     exportPanelSnapshot(app, app.LeftPanel, ...
%         fullfile(outputDir, "model-spines-panel.png"));

%     testCase.press(app.objectListComponent_spines.ObjectlistButton);

%         % exportPanelSnapshot(app, app.ModelPanel, ...
%     %     fullfile(outputDir, "model-panel-after-create.png"));

%     % % Press button
%     % testCase.press(app.CreateModelButton);
%     % drawnow
%     % pause(0.5)

%     % exportPanelSnapshot(app, app.ModelPanel, ...
%     %     fullfile(outputDir, "model-panel-after-create.png"));

%     % % Choose another tab
%     % testCase.choose(app.PlanesTab);
%     % drawnow
%     % pause(0.2)

%     % exportPanelSnapshot(app, app.PlanesPanel, ...
%     %     fullfile(outputDir, "planes-panel.png"));

% end


% function exportPanelSnapshot(app, panelHandle, outputFile)

%     tmpFile = tempname + ".png";
%     exportapp(app.IrbisMainFig, tmpFile);

%     img = imread(tmpFile);

%     pos = panelHandle.Position;
%     h = size(img, 1);

%     if isa(panelHandle, 'matlab.ui.container.Panel')
%         [xParentPix, yParentPix] = calculateContainerOrigin(panelHandle)
%     else
%         xParentPix = 0;
%         yParentPix = 0;
%     end

%     x = round(pos(1) + xParentPix);
%     y = round(h - pos(2) - pos(4) + 1 + yParentPix);
%     w = round(pos(3));
%     hh = round(pos(4));

%     yMin = max(1, y);
%     yMax = min(size(img, 1), y + hh - 1);
%     xMin = max(1, x);
%     xMax = min(size(img, 2), x + w - 1);

%     cropped = img(yMin:yMax, xMin:xMax, :);
%     imwrite(cropped, outputFile);

%     delete(tmpFile);

% end


% function [xParentPix, yParentPix] = calculateContainerOrigin(ax)
%     % calculate starting pixel position of the axes container
%     xParentPix = 0;
%     yParentPix = 0;

%     currentObject = ax.Parent;

%     while true
%             if isa(currentObject,'matlab.ui.Figure')
%             break
%         end
%         pos = currentObject.Position;
%         xParentPix = xParentPix + pos(1);
%         yParentPix = yParentPix + pos(2);
%         currentObject = currentObject.Parent;
%     end
% end


function results = generateScreenshots()

results = runtests("docgen.GenerateScreenshotsTest");

end