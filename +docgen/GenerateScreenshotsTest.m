classdef GenerateScreenshotsTest < matlab.uitest.TestCase

    properties
        App
        OutputDir
    end

    methods (TestMethodSetup)
        function createApp(testCase)
            testCase.App = IrbisApp;
            testCase.addTeardown(@delete, testCase.App);

            testCase.App.loadDemonstrationData();

            testCase.OutputDir = fullfile("docs", "assets");
            if ~isfolder(testCase.OutputDir)
                mkdir(testCase.OutputDir);
            end

            drawnow
        end
    end

    methods (Test)
        function testGenerateScreenshots(testCase)
            filesPanelFile = fullfile(testCase.OutputDir, "files-panel.png");
            visualizationPanelFile = fullfile(testCase.OutputDir, "visualization-panel.png");
            modelSpinesPanelFile = fullfile(testCase.OutputDir, "model-spines-panel.png");

            testCase.choose(testCase.App.FilesTab);
            drawnow
            pause(0.2)

            testCase.exportPanelSnapshot(testCase.App.FilesTab, ...
                filesPanelFile);
            testCase.verifyTrue(isfile(filesPanelFile));

            testCase.exportPanelSnapshot(testCase.App.RightPanel, ...
                visualizationPanelFile);
            testCase.verifyTrue(isfile(visualizationPanelFile));

            testCase.choose(testCase.App.ModelTab);
            testCase.choose(testCase.App.spinesTab);

            testCase.exportPanelSnapshot(testCase.App.LeftPanel, ...
                modelSpinesPanelFile);
            testCase.verifyTrue(isfile(modelSpinesPanelFile));

            spinesObjectPanel = testCase.App.objectListComponent_spines;
            testCase.press(spinesObjectPanel.ObjectlistButton);

            testCase.exportPanelSnapshot(spinesObjectPanel, ...
                fullfile(testCase.OutputDir, "spines-objects-panel.png"));
        end
    end

    methods (Access = private)
        function exportPanelSnapshot(testCase, panelHandle, outputFile)
            tmpFile = tempname + ".png";
            cleanup = onCleanup(@() testCase.deleteTempFile(tmpFile));

            exportapp(testCase.App.IrbisMainFig, tmpFile);

            img = imread(tmpFile);
            pos = panelHandle.Position;
            h = size(img, 1);

            [xParentPix, yParentPix] = testCase.calculateContainerOrigin(panelHandle);

            x = round(pos(1) + xParentPix);
            y = round(h - pos(2) - pos(4) + 1 + yParentPix);
            w = round(pos(3));
            hh = round(pos(4));

            yMin = max(1, y);
            yMax = min(size(img, 1), y + hh - 1);
            xMin = max(1, x);
            xMax = min(size(img, 2), x + w - 1);

            cropped = img(yMin:yMax, xMin:xMax, :);
            imwrite(cropped, outputFile);

            clear cleanup
        end

        function [xParentPix, yParentPix] = calculateContainerOrigin(~, containerHandle)
            xParentPix = 0;
            yParentPix = 0;

            currentObject = containerHandle.Parent;

            while ~isa(currentObject, 'matlab.ui.Figure')
                pos = currentObject.Position;
                xParentPix = xParentPix + pos(1);
                yParentPix = yParentPix + pos(2);
                currentObject = currentObject.Parent;
            end
        end

        function deleteTempFile(~, tmpFile)
            if isfile(tmpFile)
                delete(tmpFile);
            end
        end
    end
end