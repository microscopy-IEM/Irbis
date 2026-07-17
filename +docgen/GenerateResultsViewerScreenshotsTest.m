classdef GenerateResultsViewerScreenshotsTest < matlab.uitest.TestCase

    properties
        RVApp
        windowHandle
        OutputDir
    end

    methods (TestMethodSetup)
        function createApp(testCase)
            testCase.RVApp = IrbisResultsViewer;
            testCase.windowHandle = testCase.RVApp.IrbisResultsViewerUIFigure;
            testCase.addTeardown(@delete, testCase.RVApp);

            testCase.RVApp.loadDemonstrationData();

            testCase.OutputDir = fullfile("docs", "assets");
            if ~isfolder(testCase.OutputDir)
                mkdir(testCase.OutputDir);
            end

            drawnow
        end
    end

    methods (Test)
        function ResultsViewerIntroScreenshots(testCase)
            testCase.captureWindowSnapshot(testCase.windowHandle, ...
                "rv-intro.png");
        end

        function compareResultsViewerDatasetsTutorialScreenshots(testCase)
            testCase.choose(testCase.RVApp.ViewSelectionDropDown, ...
            'spines-pivoted-volume-comparison');
            testCase.press(testCase.RVApp.UseviewButton);
            testCase.waitForUi(2);
            testCase.captureWindowSnapshot(testCase.windowHandle, ...
                "rv-dataset-comparison.png");
        end
    end

    methods (Access = private)
        function openFilesTab(testCase)
            testCase.choose(testCase.RVApp.FilesTab);
            testCase.waitForUi();
        end

        function openPlanesTab(testCase)
            testCase.choose(testCase.RVApp.PlanesTab);
            testCase.waitForUi();
        end

        function openModelTab(testCase)
            testCase.choose(testCase.RVApp.ModelTab);
            testCase.waitForUi();
        end

        function openModelSpines(testCase)
            testCase.choose(testCase.RVApp.ModelTab);
            testCase.choose(testCase.RVApp.spinesTab);
            testCase.waitForUi();
        end

        function openSpinesObjectList(testCase)
            spinesObjectPanel = testCase.RVApp.objectListComponent_spines;
            testCase.press(spinesObjectPanel.ObjectlistButton);
            testCase.waitForUi();
        end

        function openMainAppPanel(testCase, buttonName)
            testCase.choose(testCase.RVApp.(buttonName), true);
            testCase.waitForUi();
        end

        function captureSnapshot(testCase, componentHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            testCase.exportPanelSnapshot(componentHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end


        function captureWindowSnapshot(testCase, windowHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            exportapp(windowHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end

        function capturePanelSnapshotWithHeader(testCase, componentHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            testCase.exportPanelSnapshotWithHeader(componentHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end

        function checkModelCheckboxes(testCase, namesToCheck)
            % Normalize names
            testCase.choose(testCase.RVApp.ColorMixerButton, true);
            allBranches = ["fullVolume", "shaft", "dendrite", "spines", "synapses"];
            desired = string(namesToCheck);


            for idx = 1:numel(allBranches)
                prop = allBranches(idx);
                propName = [char(prop) 'CheckBox'];
                if endsWith(propName, 'CheckBox', 'IgnoreCase', true) && isprop(testCase.RVApp, propName)
                    comp = testCase.RVApp.(propName);
                    shouldCheck = any(strcmpi(prop, desired));
                    testCase.choose(comp, shouldCheck);
                end
            end

            testCase.waitForUi();
        end

        function captureModelSubtabOrPlaceholder(testCase, tabPropertyNames, ...
                fileName, titleText, detailsText)
            testCase.openModelTab();

            if testCase.chooseFirstAppComponentIfPresent(tabPropertyNames)
                testCase.captureSnapshot(testCase.RVApp.LeftPanel, fileName);
            else
                testCase.capturePlaceholderSnapshot(fileName, ...
                    titleText, detailsText);
            end
        end

        function didChoose = chooseFirstAppComponentIfPresent(testCase, ...
                componentNames)
            didChoose = false;

            for componentName = string(componentNames)
                componentPropertyName = char(componentName);

                if isprop(testCase.RVApp, componentPropertyName)
                    component = testCase.RVApp.(componentPropertyName);
                    testCase.choose(component);
                    testCase.waitForUi();
                    didChoose = true;
                    return
                end
            end
        end

        function captureResultsViewerPlaceholder(testCase, fileName, ...
                titleText, detailsText)
            testCase.capturePlaceholderSnapshot(fileName, ...
                "ResultsViewer: " + titleText, detailsText);
        end

        function capturePlaceholderSnapshot(testCase, fileName, titleText, ...
                detailsText)
            outputFile = fullfile(testCase.OutputDir, fileName);

            fig = figure("Visible", "off", ...
                "Color", [0.96 0.96 0.96], ...
                "Position", [100 100 900 420]);
            cleanup = onCleanup(@() close(fig));

            ax = axes(fig, ...
                "Position", [0 0 1 1], ...
                "Visible", "off", ...
                "XLim", [0 1], ...
                "YLim", [0 1]);

            rectangle(ax, ...
                "Position", [0.025 0.025 0.95 0.95], ...
                "EdgeColor", [0.65 0.65 0.65], ...
                "LineStyle", "--");

            text(ax, 0.06, 0.68, titleText, ...
                "FontSize", 24, ...
                "FontWeight", "bold", ...
                "Color", [0.12 0.12 0.12], ...
                "Interpreter", "none");

            text(ax, 0.06, 0.48, detailsText, ...
                "FontSize", 14, ...
                "Color", [0.25 0.25 0.25], ...
                "Interpreter", "none");

            text(ax, 0.06, 0.22, ...
                "TODO: replace this placeholder with the exact UI sequence.", ...
                "FontSize", 12, ...
                "Color", [0.45 0.45 0.45], ...
                "Interpreter", "none");

            exportgraphics(fig, outputFile, "Resolution", 120);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing placeholder screenshot: " + outputFile);

            clear cleanup
        end

        function exportPanelSnapshot(testCase, panelHandle, outputFile)
            testCase.waitForUi(0.1);

            tmpFile = tempname + ".png";
            cleanup = onCleanup(@() testCase.deleteTempFile(tmpFile));

            exportapp(testCase.RVApp.IrbisMainFig, tmpFile);

            img = imread(tmpFile);
            [x, y, w, hh] = testCase.calculateSnapshotRectangle( ...
                panelHandle, size(img));

            yMin = max(1, y);
            yMax = min(size(img, 1), y + hh - 1);
            xMin = max(1, x);
            xMax = min(size(img, 2), x + w - 1);

            cropped = img(yMin:yMax, xMin:xMax, :);
            imwrite(cropped, outputFile);

            clear cleanup
        end

        function exportPanelSnapshotWithHeader(testCase, panelHandle, outputFile)
            % extracts the panel with the button for toggling the panel
            testCase.waitForUi(0.1);

            tmpFile = tempname + ".png";
            cleanup = onCleanup(@() testCase.deleteTempFile(tmpFile));

            exportapp(testCase.RVApp.IrbisMainFig, tmpFile);

            img = imread(tmpFile);
            [x, y, w, hh] = testCase.calculateSnapshotRectangle( ...
                panelHandle, size(img));
            y = y - 35; % move up to include the header
            hh = hh + 35; % add extra height for the header

            yMin = max(1, y);
            yMax = min(size(img, 1), y + hh - 1);
            xMin = max(1, x);
            xMax = min(size(img, 2), x + w - 1);

            cropped = img(yMin:yMax, xMin:xMax, :);
            imwrite(cropped, outputFile);

            clear cleanup
        end
        function [x, y, w, h] = calculateSnapshotRectangle(testCase, ...
                componentHandle, imageSize)
            componentPosition = getpixelposition(componentHandle, true);
            figurePosition = getpixelposition(testCase.RVApp.IrbisMainFig);

            scaleX = imageSize(2) / figurePosition(3);
            scaleY = imageSize(1) / figurePosition(4);

            x = round(componentPosition(1) * scaleX);
            y = round(imageSize(1) - ...
                (componentPosition(2) + componentPosition(4)) * scaleY + 1);
            w = max(1, round(componentPosition(3) * scaleX));
            h = max(1, round(componentPosition(4) * scaleY));
        end

        function waitForUi(~, seconds)
            if nargin < 2
                seconds = 0.2;
            end

            drawnow
            pause(seconds)
            drawnow
        end

        function deleteTempFile(~, tmpFile)
            if isfile(tmpFile)
                delete(tmpFile);
            end
        end
    end
end
