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
        function gettingStartedScreenshots(testCase)
            testCase.captureWindowSnapshot(testCase.App.IrbisMainFig, ...
                "irbis-gui.png");
        end

        function modelScreenshots(testCase)
            testCase.openModelSpines();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "model-spines-panel.png");

            testCase.openSpinesObjectList();
            testCase.captureSnapshot(testCase.App.objectListComponent_spines, ...
                "spines-objects-panel.png");
        end

        function cropPlanesScreenshots(testCase)
            testCase.openPlanesTab();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "planes-panel.png");
            testCase.captureUiwaitWindowSnapshot(@() testCase.press(testCase.App.CropButton), ...
                "crop-planes-window.png", 2);   % the test will error because we resume the app without necessary info
        end

        function segmentSpinesTutorialScreenshots(testCase)
            testCase.openFilesTab();
            testCase.captureSnapshot(testCase.App.FilesTab, ...
                "tutorial-segment-spines-load-data.png");

            testCase.openPlanesTab();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "tutorial-segment-spines-view-planes.png");

            testCase.openModelTab();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "tutorial-segment-spines-create-model.png");

            testCase.captureModelSubtabOrPlaceholder( ...
                "fullVolumeTab", ...
                "tutorial-segment-spines-full-volume-tab.png", ...
                "Full Volume tab", ...
                "Open Model > Go to Model tab and Full subtab.");

            testCase.captureSnapshot(testCase.App.surfaceReconstructionComp_fullVolume, ...
            "tutorial-segment-spines-reconstruction-panel.png");

            testCase.checkModelCheckboxes("fullVolume");
            testCase.captureSnapshot(testCase.App.RightPanel, ...
                "tutorial-segment-spines-full-volume-visualization.png");

            testCase.captureModelSubtabOrPlaceholder( ...
                "shaftTab", ...
                "tutorial-segment-spines-shaft-tab.png", ...
                "Shaft tab", ...
                "Open Model > Go to Model tab and Dendrites subtab.");

            testCase.openMainAppPanel("DendritetracingSectionButton")
            testCase.capturePanelSnapshotWithHeader(testCase.App.dendriteTracingPanel, ...
                "tutorial-segment-spines-dendrite-tracing-panel.png");

            testCase.openMainAppPanel("ShaftgenerationandadjustmentSectionButton")
            testCase.capturePanelSnapshotWithHeader(testCase.App.shaftGenerationPanel, ...
                "tutorial-segment-spines-shaft-generation-panel.png");

            testCase.checkModelCheckboxes(["fullVolume", "shaft"]);
            testCase.captureSnapshot(testCase.App.RightPanel, ...
                "tutorial-segment-spines-shaft-visualization.png");

            testCase.captureModelSubtabOrPlaceholder( ...
                "spinesTab", ...
                "tutorial-segment-spines-spines-tab.png", ...
                "Spines tab", ...
                "Open Model > Go to Model tab and Spines subtab.");

            testCase.openModelSpines();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "tutorial-segment-spines-separate-spines.png");

            testCase.checkModelCheckboxes(["spines", "dendrite"]);
            testCase.captureSnapshot(testCase.App.RightPanel, ...
                "tutorial-segment-spines-spines-visualization.png");

            testCase.openModelSpines();
            testCase.captureSnapshot(testCase.App.LeftPanel, ...
                "tutorial-segment-spines-calculate-features.png");

            testCase.openFilesTab();
            testCase.captureSnapshot(testCase.App.FilesTab, ...
                "tutorial-segment-spines-save-irbis.png");
        end

        function compareResultsViewerDatasetsTutorialScreenshots(testCase)
            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-batch-load.png", ...
                "Batch load", ...
                "Press Batch load and select each folder of .irbis datasets.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-select-model-spines.png", ...
                "Select model spines", ...
                "Set Modality to model and Object type to spines.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-add-categorization.png", ...
                "Add categorization", ...
                "Open the parameter menu and define the condition categories.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-filter-groupid.png", ...
                "Filter groupId", ...
                "Open Filtering, select groupId, untick 0, and press Filter.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-merged-identifier.png", ...
                "Create merged ID", ...
                "Use add merged to combine fileId and groupId.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-pivoted-development.png", ...
                "Pivoted development plot", ...
                "Switch to Pivoted, set rows and columns, then plot line: averaged.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-summarized-by-condition.png", ...
                "Summarized by condition", ...
                "Show summarized and use group or condition as categorical labels.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-export-plot.png", ...
                "Export plot", ...
                "Use the plot export control and save the image.");

            testCase.captureResultsViewerPlaceholder( ...
                "compare-rv-save-dataset.png", ...
                "Save combined dataset", ...
                "Press Save .irbisRes and choose the output file.");
        end
    end

    methods (Access = private)
        function openFilesTab(testCase)
            testCase.choose(testCase.App.FilesTab);
            testCase.waitForUi();
        end

        function openPlanesTab(testCase)
            testCase.choose(testCase.App.PlanesTab);
            testCase.waitForUi();
        end

        function openModelTab(testCase)
            testCase.choose(testCase.App.ModelTab);
            testCase.waitForUi();
        end

        function openModelSpines(testCase)
            testCase.choose(testCase.App.ModelTab);
            testCase.choose(testCase.App.spinesTab);
            testCase.waitForUi();
        end

        function openSpinesObjectList(testCase)
            spinesObjectPanel = testCase.App.objectListComponent_spines;
            testCase.press(spinesObjectPanel.ObjectlistButton);
            testCase.waitForUi();
        end

        function openMainAppPanel(testCase, buttonName)
            testCase.choose(testCase.App.(buttonName), true);
            testCase.waitForUi();
        end

        function captureSnapshot(testCase, componentHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            testCase.exportPanelSnapshot(componentHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end

        function capturePanelSnapshotWithHeader(testCase, componentHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            testCase.exportPanelSnapshotWithHeader(componentHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end


        function captureWindowSnapshot(testCase, windowHandle, fileName)
            outputFile = fullfile(testCase.OutputDir, fileName);

            exportapp(windowHandle, outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end
        

        function captureNewWindowSnapshot(testCase, interactionFcn, fileName, waitSeconds)
            if nargin < 4
                waitSeconds = 0.5;
            end

            outputFile = fullfile(testCase.OutputDir, fileName);
            existingFigures = findall(groot, "Type", "figure");

            interactionFcn();
            testCase.waitForUi(waitSeconds);

            currentFigures = findall(groot, "Type", "figure");
            newFigures = currentFigures(~ismember(currentFigures, existingFigures));

            testCase.assertNumElements(newFigures, 1, ...
                "Expected exactly one new window after the interaction.");

            exportapp(newFigures(1), outputFile);
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);
        end

        function captureUiwaitWindowSnapshot(testCase, interactionFcn, fileName, waitSeconds, releaseFcn)
            if nargin < 4 || isempty(waitSeconds)
                waitSeconds = 0.5;
            end
            if nargin < 5 || isempty(releaseFcn)
                releaseFcn = @uiresume;
            end

            outputFile = fullfile(testCase.OutputDir, fileName);
            existingFigures = findall(groot, "Type", "figure");
            captureError = [];

            captureTimer = timer( ...
                "ExecutionMode", "singleShot", ...
                "StartDelay", waitSeconds, ...
                "TimerFcn", @captureAndReleaseNewWindow);
            cleanup = onCleanup(@() delete(captureTimer));

            start(captureTimer);
            interactionFcn();

            if ~isempty(captureError)
                rethrow(captureError);
            end
            testCase.verifyTrue(isfile(outputFile), ...
                "Missing screenshot: " + outputFile);

            clear cleanup

            function captureAndReleaseNewWindow(~, ~)
                try
                    drawnow
                    currentFigures = findall(groot, "Type", "figure");
                    newFigures = currentFigures(~ismember(currentFigures, existingFigures));

                    if numel(newFigures) ~= 1
                        captureError = MException( ...
                            "docgen:GenerateScreenshotsTest:UnexpectedNewWindowCount", ...
                            "Expected exactly one new window after the interaction, but found %d.", ...
                            numel(newFigures));
                        releaseWaitCandidates(newFigures);
                        return
                    end

                    exportapp(newFigures(1), outputFile);
                    releaseFcn(newFigures(1));
                catch err
                    captureError = err;
                    currentFigures = findall(groot, "Type", "figure");
                    newFigures = currentFigures(~ismember(currentFigures, existingFigures));
                    releaseWaitCandidates(newFigures);
                end
            end

            function releaseWaitCandidates(newFigures)
                for idx = 1:numel(newFigures)
                    uiresume(newFigures(idx));
                end
                try
                    if isvalid(testCase.App.IrbisMainFig)
                        uiresume(testCase.App.IrbisMainFig);
                    end
                catch
                end
            end
        end

        function checkModelCheckboxes(testCase, namesToCheck)
            % Normalize names
            testCase.choose(testCase.App.ColorMixerButton, true);
            allBranches = ["fullVolume", "shaft", "dendrite", "spines", "synapses"];
            desired = string(namesToCheck);


            for idx = 1:numel(allBranches)
                prop = allBranches(idx);
                propName = [char(prop) 'CheckBox'];
                if endsWith(propName, 'CheckBox', 'IgnoreCase', true) && isprop(testCase.App, propName)
                    comp = testCase.App.(propName);
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
                testCase.captureSnapshot(testCase.App.LeftPanel, fileName);
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

                if isprop(testCase.App, componentPropertyName)
                    component = testCase.App.(componentPropertyName);
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

            exportapp(testCase.App.IrbisMainFig, tmpFile);

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

            exportapp(testCase.App.IrbisMainFig, tmpFile);

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
            figurePosition = getpixelposition(testCase.App.IrbisMainFig);

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
