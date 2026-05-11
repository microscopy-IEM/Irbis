function [approvedMerges, usedGizmos] = reviewMatchEventsUI(tableArray, matchEvents)

if isempty(matchEvents)
    uialert(uifigure, 'No match events found.', 'Info');
    approvedMerges = emptyApprovedMergeStruct();
    usedGizmos = ManualEditing.initializeTable();
    return
end

currentIndex = 1;
reviewState = strings(numel(matchEvents),1);
reviewState(:) = "unreviewed";
proposalCache = cell(numel(matchEvents), 1);
approvedMerges = emptyApprovedMergeStruct();
usedGizmos = ManualEditing.initializeTable();
displayMode = "Both";
activeGizmos = {};
activeGizmoProposalIndexes = [];
activeGizmoMatchIndex = [];
activeDisplayOffset = [0 0 0];
activePlanePatchHandles = gobjects(0);
activeDisplayProposals = emptyProposalStruct();
activePlaneIndex = 1;
isUpdatingPlaneDropdown = false;
planeFlatteningFactor = 0.001;
currentAxesLimit = 1;
orbitTool = [];

fig = uifigure( ...
    'Name', 'Match review', ...
    'Position', [100 100 1200 800], ...
    'CloseRequestFcn', @cancelCallback);

gl = uigridlayout(fig, [4 1]);
gl.RowHeight = {54, '1x', 30, 38};
gl.Padding = [6 6 6 6];
gl.RowSpacing = 2;

topGrid = uigridlayout(gl, [2 2]);
topGrid.RowHeight = {26, 26};
topGrid.ColumnWidth = {'1x', 220};
topGrid.Padding = [0 0 0 0];
topGrid.RowSpacing = 0;
topGrid.ColumnSpacing = 8;

infoLabel = uilabel(topGrid);
infoLabel.Layout.Row = 1;
infoLabel.Layout.Column = [1 2];
infoLabel.HorizontalAlignment = 'center';

statusLabel = uilabel(topGrid, 'Text', '');
statusLabel.Layout.Row = 2;
statusLabel.Layout.Column = 1;

displayDropdown = uidropdown( ...
    topGrid, ...
    'Items', {'Both', 'Merged', 'Separated'}, ...
    'Value', char(displayMode), ...
    'ValueChangedFcn', @displayModeChanged);
displayDropdown.Layout.Row = 2;
displayDropdown.Layout.Column = 2;

axesPanel = uipanel(gl, ...
    'BorderType', 'none', ...
    'AutoResizeChildren', 'off', ...
    'Units', 'pixels');

ax = uiaxes(axesPanel, ...
    'Units', 'pixels', ...
    'Position', [0 0 1 1]);
axesPanel.SizeChangedFcn = @resizeAxesToPanel;
view(ax, 3);
grid(ax, 'on');
hold(ax, 'on');
if isprop(ax, 'Clipping')
    ax.Clipping = 'off';
end
configureAxesForGizmo(ax);
resizeAxesToPanel();
orbitTool = OrbitToolClass(ax, {'3D'});
orbitTool.setResettableAxes(ax);

decisionGrid = uigridlayout(gl, [1 3]);
decisionGrid.ColumnWidth = {'1x', '1x', 190};
decisionGrid.Padding = [0 0 0 0];
decisionGrid.ColumnSpacing = 6;
decisionGrid.Layout.Row = 4;
decisionGrid.Layout.Column = 1;

uibutton(decisionGrid, ...
    'Text', 'Reject selected cut', ...
    'ButtonPushedFcn', @rejectCallback);
uibutton(decisionGrid, ...
    'Text', 'Approve selected cut', ...
    'ButtonPushedFcn', @approveCallback);
planeDropdown = uidropdown( ...
    decisionGrid, ...
    'Items', {'Plane 1'}, ...
    'Value', 'Plane 1', ...
    'ValueChangedFcn', @planeSelectionChanged);

navigationGrid = uigridlayout(gl, [1 3]);
navigationGrid.ColumnWidth = {'1x', '1x', '1x'};
navigationGrid.Padding = [0 0 0 0];
navigationGrid.ColumnSpacing = 6;
navigationGrid.Layout.Row = 3;
navigationGrid.Layout.Column = 1;

uibutton(navigationGrid, ...
    'Text', 'Previous merge', ...
    'ButtonPushedFcn', @previousCallback);
uibutton(navigationGrid, ...
    'Text', 'Next merge', ...
    'ButtonPushedFcn', @nextCallback);
uibutton(navigationGrid, ...
    'Text', 'Finish review', ...
    'ButtonPushedFcn', @finishCallback);

showCurrentMatch();
uiwait(fig);

if isvalid(fig)
    delete(fig);
end

    function previousCallback(~,~)
        saveActiveGizmoState();
        currentIndex = max(currentIndex - 1, 1);
        showCurrentMatch();
    end

    function nextCallback(~,~)
        saveActiveGizmoState();
        currentIndex = min(currentIndex + 1, numel(matchEvents));
        showCurrentMatch();
    end

    function approveCallback(~,~)
        saveActiveGizmoState();
        reviewState(currentIndex) = "approved";
        moveToNextMatch();
    end

    function rejectCallback(~,~)
        saveActiveGizmoState();
        reviewState(currentIndex) = "rejected";
        moveToNextMatch();
    end

    function displayModeChanged(src,~)
        saveActiveGizmoState();
        displayMode = string(src.Value);
        showCurrentMatch();
    end

    function planeSelectionChanged(src,~)
        if isUpdatingPlaneDropdown
            return
        end

        saveActiveGizmoState();
        activePlaneIndex = parsePlaneDropdownValue(src.Value);
        switchActivePlaneGizmo();
    end

    function resizeAxesToPanel(~,~)
        panelPosition = axesPanel.Position;
        ax.Units = 'pixels';
        ax.Position = [0 0 max(1, panelPosition(3)) max(1, panelPosition(4))];
        configureAxesForGizmo(ax, currentAxesLimit);
    end

    function finishCallback(~,~)
        saveActiveGizmoState();
        approvedMerges = collectApprovedMerges();
        usedGizmos = collectUsedGizmos();

        if ~isempty(orbitTool) && isvalid(orbitTool)
            delete(orbitTool);
        end

        if isvalid(fig)
            uiresume(fig);
        end
    end

    function cancelCallback(~,~)
        saveActiveGizmoState();
        approvedMerges = emptyApprovedMergeStruct();
        usedGizmos = ManualEditing.initializeTable();

        if ~isempty(orbitTool) && isvalid(orbitTool)
            delete(orbitTool);
        end

        if isvalid(fig)
            uiresume(fig);
        end
    end

    function showCurrentMatch()

        deleteActiveGizmos();
        cla(ax);
        hold(ax, 'on');

        event = matchEvents(currentIndex);

        currentTable = tableArray{event.timePoint1};
        nextTable = tableArray{event.timePoint2};

        planeCount = 0;
        proposals = emptyProposalStruct();

        try
            proposals = getCachedProposals(currentIndex);

            planeCount = numel(proposals);
            activePlaneIndex = min(max(activePlaneIndex, 1), max(planeCount, 1));

        catch ME
            warning('Plane proposal failed for match %d: %s', ...
                currentIndex, ME.message);
        end

        displayFrame = computeDisplayFrame( ...
            currentTable, ...
            nextTable, ...
            event, ...
            proposals);

        displayCurrentTable = translateObjectTableMeshes( ...
            currentTable, ...
            displayFrame.offset);

        displayNextTable = translateObjectTableMeshes( ...
            nextTable, ...
            displayFrame.offset);

        displayProposals = translateProposals( ...
            proposals, ...
            displayFrame.offset);

        drawEventMeshes( ...
            ax, ...
            displayCurrentTable, ...
            displayNextTable, ...
            event, ...
            displayProposals, ...
            displayMode);

        updatePlaneDropdown(planeCount);

        currentAxesLimit = displayFrame.axesLimit;
        configureAxesForGizmo(ax, currentAxesLimit);
        resizeAxesToPanel();
        % drawnow;

        activePlanePatchHandles = drawPlaneCuboids( ...
            ax, ...
            displayProposals, ...
            activePlaneIndex, ...
            planeFlatteningFactor);
        activeDisplayProposals = displayProposals;

        [activeGizmos, activeGizmoProposalIndexes] = createPlaneGizmoForSelectedPatch( ...
            ax, ...
            fig, ...
            displayProposals, ...
            activePlanePatchHandles, ...
            planeFlatteningFactor, ...
            activePlaneIndex);
        activeGizmoMatchIndex = currentIndex;
        activeDisplayOffset = displayFrame.offset;

        if ~isempty(displayProposals)
            orientCamera( ...
                ax, ...
                displayProposals(1).planePoint, ...
                displayProposals(1).planeNormal, ...
                displayFrame.axesLimit, ...
                displayFrame.viewCenter, ...
                displayFrame.viewRadius);
        else
            orientCamera( ...
                ax, ...
                displayFrame.viewCenter, ...
                [1 1 1], ...
                displayFrame.axesLimit, ...
                displayFrame.viewCenter, ...
                displayFrame.viewRadius);
        end

        configureOrbitToolForCurrentScene(orbitTool, ax, displayFrame.viewCenter);

        camlight(ax, 'headlight');
        lighting(ax, 'gouraud');

        statusLabel.Text = sprintf('Status: %s', reviewState(currentIndex));

        infoLabel.Text = sprintf([ ...
            'Match %d / %d | %s | TP %d -> %d | ' ...
            'Source IDs: [%s] | Target IDs: [%s] | Planes: %d'], ...
            currentIndex, ...
            numel(matchEvents), ...
            event.type, ...
            event.timePoint1, ...
            event.timePoint2, ...
            num2str(event.sourceObjectIds(:).'), ...
            num2str(event.targetObjectIds(:).'), ...
            planeCount);
    end

    function updatePlaneDropdown(planeCount)
        isUpdatingPlaneDropdown = true;

        if planeCount < 1
            planeDropdown.Items = {'No planes'};
            planeDropdown.Value = 'No planes';
            activePlaneIndex = 1;
        else
            items = arrayfun( ...
                @(idx) sprintf('Plane %d', idx), ...
                1:planeCount, ...
                'UniformOutput', false);

            activePlaneIndex = min(max(activePlaneIndex, 1), planeCount);
            planeDropdown.Items = items;
            planeDropdown.Value = items{activePlaneIndex};
        end

        isUpdatingPlaneDropdown = false;
    end

    function moveToNextMatch()
        if currentIndex < numel(matchEvents)
            currentIndex = currentIndex + 1;
        end

        showCurrentMatch();
    end

    function saveActiveGizmoState()
        if isempty(activeGizmoMatchIndex) || isempty(activeGizmos)
            return
        end

        proposals = proposalCache{activeGizmoMatchIndex};

        if isempty(proposals)
            return
        end

        for gizmoIndex = 1:min(numel(activeGizmos), numel(activeGizmoProposalIndexes))
            gizmo = activeGizmos{gizmoIndex};
            proposalIndex = activeGizmoProposalIndexes(gizmoIndex);

            if isempty(gizmo) || ~isvalid(gizmo) || proposalIndex > numel(proposals)
                continue
            end

            proposals(proposalIndex).planePoint = ...
                gizmo.getCentrePositionUM() - activeDisplayOffset;
            proposals(proposalIndex).planeNormal = gizmo.getRotationVector();

            objectHandle = gizmo.getObjectHandle();
            if ~isempty(objectHandle) && isvalid(objectHandle(1))
                proposals(proposalIndex).adjustedCuboidVertices = ...
                    objectHandle(1).Vertices - activeDisplayOffset;
                proposals(proposalIndex).adjustedCuboidFaces = objectHandle(1).Faces;
                proposals(proposalIndex).planeSize = estimatePlaneSizeFromCuboid( ...
                    objectHandle(1).Vertices - activeDisplayOffset, ...
                    proposals(proposalIndex).planePoint, ...
                    proposals(proposalIndex).planeNormal);
            end

            if activeGizmoMatchIndex == currentIndex && ...
                    proposalIndex <= numel(activeDisplayProposals)
                activeDisplayProposals(proposalIndex).planePoint = ...
                    gizmo.getCentrePositionUM();
                activeDisplayProposals(proposalIndex).planeNormal = ...
                    proposals(proposalIndex).planeNormal;

                if ~isempty(objectHandle) && isvalid(objectHandle(1))
                    activeDisplayProposals(proposalIndex).adjustedCuboidVertices = ...
                        objectHandle(1).Vertices;
                    activeDisplayProposals(proposalIndex).adjustedCuboidFaces = ...
                        objectHandle(1).Faces;
                    activeDisplayProposals(proposalIndex).planeSize = ...
                        proposals(proposalIndex).planeSize;
                end
            end
        end

        proposalCache{activeGizmoMatchIndex} = proposals;
    end

    function deleteActiveGizmos()
        for gizmoIndex = 1:numel(activeGizmos)
            gizmo = activeGizmos{gizmoIndex};

            if ~isempty(gizmo) && isvalid(gizmo)
                delete(gizmo);
            end
        end

        activeGizmos = {};
        activeGizmoProposalIndexes = [];
        activeGizmoMatchIndex = [];
        activeDisplayOffset = [0 0 0];
        activePlanePatchHandles = gobjects(0);
        activeDisplayProposals = emptyProposalStruct();
    end

    function switchActivePlaneGizmo()
        deleteActiveGizmoOnly();

        if isempty(activeDisplayProposals) || ...
                activePlaneIndex < 1 || ...
                activePlaneIndex > numel(activeDisplayProposals)
            return
        end

        setPlanePatchStyles(activePlanePatchHandles, activePlaneIndex);

        [activeGizmos, activeGizmoProposalIndexes] = createPlaneGizmoForSelectedPatch( ...
            ax, ...
            fig, ...
            activeDisplayProposals, ...
            activePlanePatchHandles, ...
            planeFlatteningFactor, ...
            activePlaneIndex);

    end

    function deleteActiveGizmoOnly()
        for gizmoIndex = 1:numel(activeGizmos)
            gizmo = activeGizmos{gizmoIndex};

            if ~isempty(gizmo) && isvalid(gizmo)
                delete(gizmo);
            end
        end

        activeGizmos = {};
        activeGizmoProposalIndexes = [];
    end

    function proposals = getCachedProposals(matchIndex)
        if isempty(proposalCache{matchIndex})
            event = matchEvents(matchIndex);

            currentTable = tableArray{event.timePoint1};
            nextTable = tableArray{event.timePoint2};

            proposalCache{matchIndex} = computePlaneProposalsFromEvent( ...
                currentTable, ...
                nextTable, ...
                event);
        end

        proposals = proposalCache{matchIndex};
    end

    function approved = collectApprovedMerges()
        approved = emptyApprovedMergeStruct();
        approvedIndexes = find(reviewState == "approved");

        for approvedIndex = approvedIndexes(:).'
            event = matchEvents(approvedIndex);

            if ~isMergeLikeEvent(event)
                continue
            end

            try
                proposals = getCachedProposals(approvedIndex);
            catch ME
                warning('Skipping approved match %d because plane proposals failed: %s', ...
                    approvedIndex, ME.message);
                continue
            end

            if isempty(proposals)
                continue
            end

            approved(end+1) = createApprovedMerge( ... %#ok<AGROW>
                approvedIndex, ...
                event, ...
                proposals);
        end
    end

    function editingTable = collectUsedGizmos()
        editingTable = ManualEditing.initializeTable();
        approvedIndexes = find(reviewState == "approved");

        for matchIndex = approvedIndexes(:).'
            event = matchEvents(matchIndex);

            try
                proposals = getCachedProposals(matchIndex);
            catch ME
                warning('Skipping approved match %d because plane proposals failed: %s', ...
                    matchIndex, ME.message);
                continue
            end

            if isempty(proposals)
                continue
            end

            [editingTimePoint, inputId] = mergedObjectFromMatchEvent(event);

            if isnan(inputId)
                continue
            end

            for proposalIndex = 1:numel(proposals)
                helperMesh = createManualEditingHelperMesh(proposals(proposalIndex));
                helperParameters = createPlaneHelperParameters( ...
                    proposals(proposalIndex), ...
                    matchIndex, ...
                    event, ...
                    reviewState(matchIndex), ...
                    proposalIndex);

                editingTable = ManualEditing.addPlaneCutRow( ...
                    editingTable, ...
                    editingTimePoint, ...
                    helperMesh, ...
                    proposals(proposalIndex).planePoint, ...
                    proposals(proposalIndex).planeNormal, ...
                    proposals(proposalIndex).planeSize, ...
                    "", ...
                    inputId, ...
                    [], ...
                    helperParameters);
            end
        end
    end

end



function approved = emptyApprovedMergeStruct()

approved = struct( ...
    'matchIndex', {}, ...
    'type', {}, ...
    'timePoint1', {}, ...
    'timePoint2', {}, ...
    'sourceIndexes', {}, ...
    'targetIndexes', {}, ...
    'sourceObjectIds', {}, ...
    'targetObjectIds', {}, ...
    'proposals', {}, ...
    'labelPairs', {}, ...
    'planePoints', {}, ...
    'planeNormals', {}, ...
    'planeSizes', {}, ...
    'adjustedCuboidVertices', {}, ...
    'adjustedCuboidFaces', {});

end



function states = emptyGizmoStateStruct()

states = struct( ...
    'matchIndex', {}, ...
    'reviewState', {}, ...
    'type', {}, ...
    'timePoint1', {}, ...
    'timePoint2', {}, ...
    'sourceIndexes', {}, ...
    'targetIndexes', {}, ...
    'sourceObjectIds', {}, ...
    'targetObjectIds', {}, ...
    'editingTimePoint', {}, ...
    'inputId', {}, ...
    'proposalIndex', {}, ...
    'planeIndex', {}, ...
    'labelPair', {}, ...
    'helperType', {}, ...
    'helperMesh', {}, ...
    'helperParameters', {}, ...
    'planePoint', {}, ...
    'planeNormal', {}, ...
    'planeSize', {}, ...
    'adjustedCuboidVertices', {}, ...
    'adjustedCuboidFaces', {});

end



function state = createGizmoState( ...
    matchIndex, ...
    event, ...
    reviewState, ...
    proposalIndex, ...
    proposal)

state = struct();
state.matchIndex = matchIndex;
state.reviewState = reviewState;
state.type = event.type;
state.timePoint1 = event.timePoint1;
state.timePoint2 = event.timePoint2;
state.sourceIndexes = event.sourceIndexes;
state.targetIndexes = event.targetIndexes;
state.sourceObjectIds = event.sourceObjectIds;
state.targetObjectIds = event.targetObjectIds;
[state.editingTimePoint, state.inputId] = editedObjectFromMatchEvent(event);
state.proposalIndex = proposalIndex;
state.planeIndex = proposal.planeIndex;
state.labelPair = proposal.labelPair;
state.helperType = categorical("cuttingCuboid");
state.helperMesh = createHelperMeshFromProposal(proposal);
state.helperParameters = createPlaneHelperParameters( ...
    proposal, ...
    matchIndex, ...
    event, ...
    reviewState, ...
    proposalIndex);
state.planePoint = proposal.planePoint;
state.planeNormal = proposal.planeNormal;
state.planeSize = proposal.planeSize;
state.adjustedCuboidVertices = proposal.adjustedCuboidVertices;
state.adjustedCuboidFaces = proposal.adjustedCuboidFaces;

end



function [timePoint, inputId] = editedObjectFromMatchEvent(event)

[timePoint, inputId] = mergedObjectFromMatchEvent(event);

end



function [timePoint, inputId] = mergedObjectFromMatchEvent(event)

eventType = string(event.type);

if eventType == "merge"
    timePoint = event.timePoint2;
    inputId = firstValue(event.targetObjectIds);
elseif eventType == "split"
    timePoint = event.timePoint1;
    inputId = firstValue(event.sourceObjectIds);
elseif numel(event.targetObjectIds) == 1 && numel(event.sourceObjectIds) > 1
    timePoint = event.timePoint2;
    inputId = firstValue(event.targetObjectIds);
elseif numel(event.sourceObjectIds) == 1 && numel(event.targetObjectIds) > 1
    timePoint = event.timePoint1;
    inputId = firstValue(event.sourceObjectIds);
else
    timePoint = NaN;
    inputId = NaN;
end

    function value = firstValue(values)
        if isempty(values)
            value = NaN;
        else
            value = values(1);
        end
    end

end



function helperMesh = createHelperMeshFromProposal(proposal)

helperMesh = struct( ...
    'Vertices', proposal.adjustedCuboidVertices, ...
    'Faces', proposal.adjustedCuboidFaces);

end



function helperMesh = createManualEditingHelperMesh(proposal)

if ~isempty(proposal.adjustedCuboidVertices) && ...
        ~isempty(proposal.adjustedCuboidFaces)
    helperMesh = surfaceMesh(proposal.adjustedCuboidVertices, proposal.adjustedCuboidFaces);
    return
end

[cuboidObject, ~] = createPlaneCuboidObject(proposal, 0.025);
helperMesh = surfaceMesh(cuboidObject.vertices, cuboidObject.faces);

end



function helperParameters = createPlaneHelperParameters( ...
    proposal, ...
    matchIndex, ...
    event, ...
    reviewState, ...
    proposalIndex)

planeNormal = proposal.planeNormal;

if ~isempty(planeNormal) && all(isfinite(planeNormal)) && norm(planeNormal) > eps
    planeNormal = planeNormal ./ norm(planeNormal);
end

helperParameters = struct();
helperParameters.planePosition = proposal.planePoint;
helperParameters.planePoint = proposal.planePoint;
helperParameters.position = proposal.planePoint;
helperParameters.planeNormal = planeNormal;
helperParameters.normal = planeNormal;
helperParameters.planeSize = proposal.planeSize;
helperParameters.size = proposal.planeSize;
helperParameters.matchIndex = matchIndex;
helperParameters.reviewState = reviewState;
helperParameters.eventType = string(event.type);
helperParameters.proposalIndex = proposalIndex;
helperParameters.planeIndex = proposal.planeIndex;
helperParameters.labelPair = proposal.labelPair;
helperParameters.sourceObjectIds = event.sourceObjectIds;
helperParameters.targetObjectIds = event.targetObjectIds;

end



function tf = isMergeLikeEvent(event)

tf = numel(event.targetIndexes) == 1 && numel(event.sourceIndexes) >= 2;

end



function approved = createApprovedMerge(matchIndex, event, proposals)

approved = struct();

approved.matchIndex = matchIndex;
approved.type = event.type;
approved.timePoint1 = event.timePoint1;
approved.timePoint2 = event.timePoint2;
approved.sourceIndexes = event.sourceIndexes;
approved.targetIndexes = event.targetIndexes;
approved.sourceObjectIds = event.sourceObjectIds;
approved.targetObjectIds = event.targetObjectIds;
approved.proposals = proposals;
approved.labelPairs = vertcat(proposals.labelPair);
approved.planePoints = vertcat(proposals.planePoint);
approved.planeNormals = vertcat(proposals.planeNormal);
approved.planeSizes = vertcat(proposals.planeSize);
approved.adjustedCuboidVertices = {proposals.adjustedCuboidVertices};
approved.adjustedCuboidFaces = {proposals.adjustedCuboidFaces};

end



function configureAxesForGizmo(ax, axesLimit)

if nargin < 2 || isempty(axesLimit)
    axesLimit = 1;
end

ax.Units = 'pixels';
ax.DataAspectRatio = [1 1 1];
ax.PlotBoxAspectRatio = [1 1 1];
ax.NextPlot = 'add';
ax.XLim = [0 axesLimit];
ax.YLim = [0 axesLimit];
ax.ZLim = [0 axesLimit];
ax.XLimMode = 'manual';
ax.YLimMode = 'manual';
ax.ZLimMode = 'manual';
axis(ax, 'manual');
axis(ax, 'vis3d');

if isprop(ax, 'Clipping')
    ax.Clipping = 'off';
end

try
    disableDefaultInteractivity(ax);
catch
end

if isprop(ax, 'Interactions')
    ax.Interactions = [];
end

if isprop(ax, 'Toolbar') && ~isempty(ax.Toolbar)
    ax.Toolbar.Visible = 'off';
end

end



function displayFrame = computeDisplayFrame( ...
    currentTable, ...
    nextTable, ...
    event, ...
    proposals)

meshVertices = collectEventVertices(currentTable, nextTable, event);

if isempty(meshVertices)
    displayFrame.offset = [0 0 0];
    displayFrame.axesLimit = 1;
    displayFrame.viewCenter = [0.5 0.5 0.5];
    displayFrame.viewRadius = 0.5;
    return
end

minCorner = min(meshVertices, [], 1);
displayFrame.offset = -minCorner;

displayVertices = meshVertices + displayFrame.offset;

if ~isempty(proposals)
    planePoints = vertcat(proposals.planePoint) + displayFrame.offset;
    planeSizes = vertcat(proposals.planeSize);

    displayVertices = [ ...
        displayVertices
        planePoints - planeSizes
        planePoints + planeSizes]; %#ok<AGROW>
end

maxCorner = max(displayVertices, [], 1);
span = max(maxCorner);

if isempty(span) || ~isfinite(span) || span <= 0
    span = 1;
end

displayFrame.axesLimit = span;
displayFrame.viewCenter = 0.5 * (min(displayVertices, [], 1) + maxCorner);
displayFrame.viewRadius = 0.5 * norm(max(displayVertices, [], 1) - min(displayVertices, [], 1));

if isempty(displayFrame.viewRadius) || ...
        ~isfinite(displayFrame.viewRadius) || ...
        displayFrame.viewRadius <= 0
    displayFrame.viewRadius = 0.5 * span;
end

end



function vertices = collectEventVertices(currentTable, nextTable, event)

vertices = zeros(0, 3);

for k = 1:numel(event.sourceIndexes)
    mesh = currentTable.Mesh{event.sourceIndexes(k)};
    vertices = [vertices; mesh.Vertices]; %#ok<AGROW>
end

for k = 1:numel(event.targetIndexes)
    mesh = nextTable.Mesh{event.targetIndexes(k)};
    vertices = [vertices; mesh.Vertices]; %#ok<AGROW>
end

end



function objectTable = translateObjectTableMeshes(objectTable, offset)

for rowIndex = 1:height(objectTable)
    mesh = objectTable.Mesh{rowIndex};

    if isempty(mesh)
        continue
    end

    if isstruct(mesh) && isfield(mesh, 'Vertices')
        mesh.Vertices = mesh.Vertices + offset;
    elseif isobject(mesh) && isprop(mesh, 'Vertices')
        mesh = recreateMeshWithTranslatedVertices(mesh, offset);
    else
        continue
    end

    objectTable.Mesh{rowIndex} = mesh;
end

end



function translatedMesh = recreateMeshWithTranslatedVertices(mesh, offset)

translatedVertices = mesh.Vertices + offset;
faces = mesh.Faces;

try
    translatedMesh = feval(class(mesh), translatedVertices, faces);
catch
    try
        translatedMesh = surfaceMesh(translatedVertices, faces);
    catch
        translatedMesh = struct( ...
            'Vertices', translatedVertices, ...
            'Faces', faces);
    end
end

end



function proposals = translateProposals(proposals, offset)

for proposalIndex = 1:numel(proposals)
    proposals(proposalIndex).planePoint = ...
        proposals(proposalIndex).planePoint + offset;

    if ~isempty(proposals(proposalIndex).adjustedCuboidVertices)
        proposals(proposalIndex).adjustedCuboidVertices = ...
            proposals(proposalIndex).adjustedCuboidVertices + offset;
    end
end

end



function index = parsePlaneDropdownValue(value)

tokens = regexp(char(value), '^Plane\s+(\d+)$', 'tokens', 'once');

if isempty(tokens)
    index = 1;
else
    index = str2double(tokens{1});
end

if isempty(index) || ~isfinite(index) || index < 1
    index = 1;
end

index = round(index);

end



function configureOrbitToolForCurrentScene(orbitTool, ax, centreOfRotation)

if isempty(orbitTool) || ~isvalid(orbitTool)
    return
end

if nargin < 3 || isempty(centreOfRotation)
    axesLimit = max([ax.XLim(2), ax.YLim(2), ax.ZLim(2), 1]);
    centreOfRotation = 0.5 * axesLimit * [1 1 1];
end

orbitTool.setActiveAxes(ax, true);
orbitTool.cameraTarget = camtarget(ax);
orbitTool.cameraPosition = campos(ax);

if norm(orbitTool.cameraTarget - centreOfRotation) > 1e-9
    orbitTool.setCentreOfRotation(centreOfRotation);
else
    orbitTool.cameraTarget = centreOfRotation;
end

orbitTool.axZoom = ax.CameraViewAngle;

end



function planePatchHandles = drawPlaneCuboids( ...
    ax, ...
    proposals, ...
    activePlaneIndex, ...
    flatteningFactor)

planePatchHandles = gobjects(1, numel(proposals));

for proposalIndex = 1:numel(proposals)
    [cuboidObject, planeColor] = createPlaneCuboidObject( ...
        proposals(proposalIndex), ...
        flatteningFactor);

    planePatchHandles(proposalIndex) = patch(ax, ...
        'Vertices', cuboidObject.vertices, ...
        'Faces', cuboidObject.faces, ...
        'FaceColor', planeColor, ...
        'FaceAlpha', 0.18, ...
        'EdgeColor', planeColor * 0.75, ...
        'LineWidth', 0.8, ...
        'Clipping', 'off', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end

setPlanePatchStyles(planePatchHandles, activePlaneIndex);

end



function setPlanePatchStyles(planePatchHandles, activePlaneIndex)

for planeIndex = 1:numel(planePatchHandles)
    if ~isgraphics(planePatchHandles(planeIndex))
        continue
    end

    if planeIndex == activePlaneIndex
        set(planePatchHandles(planeIndex), ...
            'FaceAlpha', 0.28, ...
            'LineWidth', 1.5, ...
            'HitTest', 'on', ...
            'PickableParts', 'visible');
    else
        set(planePatchHandles(planeIndex), ...
            'FaceAlpha', 0.12, ...
            'LineWidth', 0.8, ...
            'HitTest', 'off', ...
            'PickableParts', 'none');
    end
end

end



function [gizmos, proposalIndexes] = createPlaneGizmoForSelectedPatch( ...
    ax, ...
    fig, ...
    proposals, ...
    planePatchHandles, ...
    flatteningFactor, ...
    activePlaneIndex)

gizmos = {};
proposalIndexes = [];

if isempty(proposals) || activePlaneIndex < 1 || ...
        activePlaneIndex > numel(proposals) || ...
        activePlaneIndex > numel(planePatchHandles) || ...
        ~isgraphics(planePatchHandles(activePlaneIndex))
    return
end

ensureGizmoPath();

try
    gizmos{1} = createPlaneGizmoForPatch( ...
        ax, ...
        fig, ...
        proposals(activePlaneIndex), ...
        planePatchHandles(activePlaneIndex), ...
        flatteningFactor);
    proposalIndexes = activePlaneIndex;
catch ME
    warning('Could not create gizmo for plane %d: %s', ...
        activePlaneIndex, ME.message);
end

end



function gizmo = createPlaneGizmoForPatch( ...
    ax, ...
    fig, ...
    proposal, ...
    planePatchHandle, ...
    flatteningFactor)

planeSize = proposal.planeSize;

if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
    planeSize = estimatePlaneSizeFromCuboid( ...
        planePatchHandle.Vertices, ...
        proposal.planePoint, ...
        proposal.planeNormal);
end

[localCuboidObject, ~] = createLocalPlaneCuboidObject( ...
    proposal, ...
    flatteningFactor);
planePatchHandle.Vertices = localCuboidObject.vertices + proposal.planePoint;
planePatchHandle.Faces = localCuboidObject.faces;

scalePointDistance = planeSize * 1.15;
prepared = GizmoObjectPreparer.prepare( ...
    planePatchHandle, ...
    'ScaleAxes', {'yz', 'x'}, ...
    'ScalePointPositions', { ...
        [0 scalePointDistance scalePointDistance], ...
        [scalePointDistance * flatteningFactor 0 0]}, ...
    'GizmoCenter', proposal.planePoint);

gizmo = GizmoTool( ...
    ax, ...
    fig, ...
    proposal.planePoint, ...
    proposal.planeNormal, ...
    prepared);

objectHandle = gizmo.getObjectHandle();
if ~isempty(objectHandle)
    set(objectHandle, ...
        'FaceColor', [1 0 0], ...
        'FaceAlpha', 0.24, ...
        'EdgeColor', [0.8 0 0], ...
        'LineWidth', 1.5, ...
        'Clipping', 'off');
end

gizmoGroup = gizmo.getGizmoHandle();
disableClipping(gizmoGroup);

end



function [cuboidObject, planeSize] = createLocalPlaneCuboidObject( ...
    proposal, ...
    flatteningFactor)

planeSize = proposal.planeSize;

if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
    planeSize = 1;
end

scalingVector = 2 * planeSize * [1 1 1];
flattenedAxis = 1;
numberingType = 1;

[vertices, faces] = createThinCuboidObject( ...
    scalingVector, ...
    flattenedAxis, ...
    flatteningFactor, ...
    numberingType);

cuboidObject = struct( ...
    'vertices', vertices, ...
    'faces', faces);

end



function [cuboidObject, planeColor, planeSize] = createPlaneCuboidObject( ...
    proposal, ...
    flatteningFactor)

planeColor = [1 0 0];

if ~isempty(proposal.adjustedCuboidVertices) && ...
        ~isempty(proposal.adjustedCuboidFaces)

    cuboidObject = struct( ...
        'vertices', proposal.adjustedCuboidVertices, ...
        'faces', proposal.adjustedCuboidFaces);

    planeSize = proposal.planeSize;

    if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
        planeSize = estimatePlaneSizeFromCuboid( ...
            cuboidObject.vertices, ...
            proposal.planePoint, ...
            proposal.planeNormal);
    end

    return
end

planeSize = proposal.planeSize;

if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
    planeSize = 1;
end

scalingVector = 2 * planeSize * [1 1 1];
flattenedAxis = 1;
numberingType = 1;

[vertices, faces] = createThinCuboidObject( ...
    scalingVector, ...
    flattenedAxis, ...
    flatteningFactor, ...
    numberingType);

vertices = orientLocalCuboidToPlane( ...
    vertices, ...
    proposal.planePoint, ...
    proposal.planeNormal);

cuboidObject = struct( ...
    'vertices', vertices, ...
    'faces', faces);

end



function vertices = orientLocalCuboidToPlane(vertices, planePoint, planeNormal)

planeNormal = planeNormal ./ norm(planeNormal);
sourceNormal = [1 0 0];

rotationAxis = cross(sourceNormal, planeNormal);
axisNorm = norm(rotationAxis);

if axisNorm <= eps
    if dot(sourceNormal, planeNormal) < 0
        R = axisAngleRotation([0 0 1], pi);
    else
        R = eye(3);
    end
else
    rotationAxis = rotationAxis ./ axisNorm;
    rotationAngle = atan2(axisNorm, dot(sourceNormal, planeNormal));
    R = axisAngleRotation(rotationAxis, rotationAngle);
end

vertices = (R * vertices.').';
vertices = vertices + planePoint;

end



function R = axisAngleRotation(axisVector, angleRadians)

axisVector = axisVector ./ norm(axisVector);
x = axisVector(1);
y = axisVector(2);
z = axisVector(3);
c = cos(angleRadians);
s = sin(angleRadians);
C = 1 - c;

R = [
    c + x*x*C,     x*y*C - z*s, x*z*C + y*s
    y*x*C + z*s,   c + y*y*C,   y*z*C - x*s
    z*x*C - y*s,   z*y*C + x*s, c + z*z*C
];

end



function ensureGizmoPath()

gizmoPath = fullfile(fileparts(mfilename('fullpath')), 'gizmo');

if exist(gizmoPath, 'dir') && ~contains(path, gizmoPath)
    addpath(gizmoPath);
end

end



function disableClipping(graphicsRoot)

if isempty(graphicsRoot) || ~isgraphics(graphicsRoot)
    return
end

graphicsObjects = findobj(graphicsRoot);

for objectIndex = 1:numel(graphicsObjects)
    if isprop(graphicsObjects(objectIndex), 'Clipping')
        graphicsObjects(objectIndex).Clipping = 'off';
    end
end

end



function planeSize = estimatePlaneSizeFromCuboid(vertices, planePoint, planeNormal)

planeNormal = planeNormal ./ norm(planeNormal);
U = null(planeNormal(:).');
projectedVertices = (vertices - planePoint) * U;
planeSize = max(vecnorm(projectedVertices, 2, 2));

if isempty(planeSize) || ~isfinite(planeSize) || planeSize <= 0
    planeSize = 1;
end

end



function drawEventMeshes( ...
    ax, ...
    currentTable, ...
    nextTable, ...
    event, ...
    proposals, ...
    displayMode)

sourceIndexes = event.sourceIndexes(:);
targetIndexes = event.targetIndexes(:);

drawSourceAsMerged = numel(sourceIndexes) == 1 && numel(targetIndexes) >= 2;
drawTargetAsMerged = numel(targetIndexes) == 1 && numel(sourceIndexes) >= 2;
showMerged = displayMode == "Merged" || displayMode == "Both";
showSeparated = displayMode == "Separated" || displayMode == "Both";

splitResult = [];

if ~isempty(proposals)
    splitResult = proposals(1).splitResult;
end

if showSeparated && ~drawSourceAsMerged
    sourceColors = referenceColors(numel(sourceIndexes));

    for k = 1:numel(sourceIndexes)
        drawContextMesh(ax, currentTable.Mesh{sourceIndexes(k)}, sourceColors(k,:));
    end
end

if showSeparated && ~drawTargetAsMerged
    targetColors = referenceColors(numel(targetIndexes));

    for k = 1:numel(targetIndexes)
        drawContextMesh(ax, nextTable.Mesh{targetIndexes(k)}, targetColors(k,:));
    end
end

if showMerged && drawSourceAsMerged
    drawMergedMesh(ax, currentTable.Mesh{sourceIndexes(1)}, splitResult);
end

if showMerged && drawTargetAsMerged
    drawMergedMesh(ax, nextTable.Mesh{targetIndexes(1)}, splitResult);
end

end



function colors = referenceColors(nColors)

colors = lines(max(nColors, 1));

end



function drawContextMesh(ax, mesh, color)

    % disp(mean(mesh.Vertices, 1));

patch(ax, ...
    'Vertices', mesh.Vertices, ...
    'Faces', mesh.Faces, ...
    'FaceColor', color, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.18, ...
    'Clipping', 'off', ...
    'HitTest', 'off', ...
    'PickableParts', 'none');

end



function drawMergedMesh(ax, mesh, splitResult)

if ~isempty(splitResult) && isfield(splitResult, 'labels') && ...
        numel(splitResult.labels) == size(mesh.Vertices, 1)

    colors = referenceColors(max(splitResult.labels));
    faceColor = colors(splitResult.labels,:);

    patch(ax, ...
        'Vertices', mesh.Vertices, ...
        'Faces', mesh.Faces, ...
        'FaceVertexCData', faceColor, ...
        'FaceColor', 'interp', ...
        'EdgeColor', [0.18 0.18 0.18], ...
        'LineWidth', 0.2, ...
        'FaceAlpha', 0.88, ...
        'EdgeAlpha', 0.12, ...
        'Clipping', 'off', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');

    return
end

patch(ax, ...
    'Vertices', mesh.Vertices, ...
    'Faces', mesh.Faces, ...
    'FaceColor', [0.72 0.72 0.72], ...
    'EdgeColor', [0.18 0.18 0.18], ...
    'LineWidth', 0.2, ...
    'FaceAlpha', 0.88, ...
    'EdgeAlpha', 0.12, ...
    'Clipping', 'off', ...
    'HitTest', 'off', ...
    'PickableParts', 'none');

end



function proposals = computePlaneProposalsFromEvent( ...
    currentTable, ...
    nextTable, ...
    event)

switch string(event.type)

    case "merge"

        proposals = computeMergePlaneProposals( ...
            currentTable, ...
            nextTable, ...
            event);

    case "split"

        proposals = computeSplitPlaneProposals( ...
            currentTable, ...
            nextTable, ...
            event);

    otherwise

        proposals = computeComplexPlaneProposals( ...
            currentTable, ...
            nextTable, ...
            event);

end

end



function proposals = computeMergePlaneProposals( ...
    currentTable, ...
    nextTable, ...
    event)

sourceIndexes = event.sourceIndexes(:);
targetIndexes = event.targetIndexes(:);

if numel(targetIndexes) ~= 1
    error('Merge event must have exactly one target object.');
end

merged = nextTable.Mesh{targetIndexes(1)};

proposals = emptyProposalStruct();
sourceMeshes = meshesFromTable(currentTable, sourceIndexes);

result = proposeCutPlanesFromReferences( ...
    sourceMeshes, ...
    merged, ...
    Visualize = false);

proposal = createProposal( ...
    sourceIndexes, ...
    targetIndexes(1), ...
    result);

proposals = appendProposals(proposals, proposal);

end



function proposals = computeSplitPlaneProposals( ...
    currentTable, ...
    nextTable, ...
    event)

sourceIndexes = event.sourceIndexes(:);
targetIndexes = event.targetIndexes(:);

if numel(sourceIndexes) ~= 1
    error('Split event must have exactly one source object.');
end

merged = currentTable.Mesh{sourceIndexes(1)};

proposals = emptyProposalStruct();
targetMeshes = meshesFromTable(nextTable, targetIndexes);

result = proposeCutPlanesFromReferences( ...
    targetMeshes, ...
    merged, ...
    Visualize = false);

proposal = createProposal( ...
    sourceIndexes(1), ...
    targetIndexes, ...
    result);

proposals = appendProposals(proposals, proposal);

end



function proposals = computeComplexPlaneProposals( ...
    currentTable, ...
    nextTable, ...
    event)

if numel(event.targetIndexes) == 1 && ...
        numel(event.sourceIndexes) >= 2

    proposals = computeMergePlaneProposals( ...
        currentTable, ...
        nextTable, ...
        event);

elseif numel(event.sourceIndexes) == 1 && ...
        numel(event.targetIndexes) >= 2

    proposals = computeSplitPlaneProposals( ...
        currentTable, ...
        nextTable, ...
        event);

else

    proposals = emptyProposalStruct();

end

end



function proposals = emptyProposalStruct()

proposals = struct( ...
    'sourcePairIndexes', {}, ...
    'targetIndex', {}, ...
    'planeIndex', {}, ...
    'labelPair', {}, ...
    'planePoint', {}, ...
    'planeNormal', {}, ...
    'planeSize', {}, ...
    'adjustedCuboidVertices', {}, ...
    'adjustedCuboidFaces', {}, ...
    'splitResult', {});

end



function meshes = meshesFromTable(objectTable, objectIndexes)

objectIndexes = objectIndexes(:);
meshes = cell(1, numel(objectIndexes));

for k = 1:numel(objectIndexes)
    meshes{k} = objectTable.Mesh{objectIndexes(k)};
end

end



function proposal = createProposal( ...
    sourcePairIndexes, ...
    targetIndex, ...
    result)

proposal = struct( ...
    'sourcePairIndexes', sourcePairIndexes, ...
    'targetIndex', targetIndex, ...
    'planeIndex', 1, ...
    'labelPair', [], ...
    'planePoint', [], ...
    'planeNormal', [], ...
    'planeSize', [], ...
    'adjustedCuboidVertices', [], ...
    'adjustedCuboidFaces', [], ...
    'splitResult', result);

if isfield(result, 'planes') && ~isempty(result.planes)
    nPlanes = numel(result.planes);
    proposal = repmat(proposal, 1, nPlanes);

    for planeIndex = 1:nPlanes
        proposal(planeIndex).planeIndex = planeIndex;
        proposal(planeIndex).labelPair = result.planes(planeIndex).labelPair;
        proposal(planeIndex).planePoint = result.planes(planeIndex).point;
        proposal(planeIndex).planeNormal = result.planes(planeIndex).normal;
        proposal(planeIndex).planeSize = result.planes(planeIndex).size;
        proposal(planeIndex).adjustedCuboidVertices = [];
        proposal(planeIndex).adjustedCuboidFaces = [];
        proposal(planeIndex).splitResult = result;
    end

    return
end

proposal.planePoint = result.planePoint;
proposal.planeNormal = result.planeNormal;
proposal.planeSize = result.planeSize;

proposal.splitResult = result;

end



function proposals = appendProposals(proposals, newProposals)

if isempty(newProposals)
    return
end

if isempty(proposals)
    proposals = newProposals;
else
    proposals(end+1:end+numel(newProposals)) = newProposals;
end

end



function drawPlaneOnAxes( ...
    ax, ...
    point, ...
    normal, ...
    planeSize, ...
    planeNumber)

normal = normal ./ norm(normal);

tmp = [1 0 0];

if abs(dot(tmp, normal)) > 0.9
    tmp = [0 1 0];
end

u = cross(normal, tmp);
u = u ./ norm(u);

v = cross(normal, u);
v = v ./ norm(v);

scale = planeSize;

corners = [
    point + scale * (-u - v)
    point + scale * ( u - v)
    point + scale * ( u + v)
    point + scale * (-u + v)
];

patch(ax, ...
    'Vertices', corners, ...
    'Faces', [1 2 3 4], ...
    'FaceColor', [1 0 0], ...
    'FaceAlpha', 0.22, ...
    'EdgeColor', 'r', ...
    'LineWidth', 2);

quiver3(ax, ...
    point(1), point(2), point(3), ...
    normal(1)*scale, ...
    normal(2)*scale, ...
    normal(3)*scale, ...
    'Color', 'r', ...
    'LineWidth', 2);

text(ax, ...
    point(1), ...
    point(2), ...
    point(3), ...
    sprintf('Plane %d', planeNumber), ...
    'Color', 'r', ...
    'FontWeight', 'bold');

end



function orientCamera(ax, point, normal, axesLimit, targetPoint, viewRadius)

if nargin < 4 || isempty(axesLimit)
    axesLimit = max([ax.XLim(2), ax.YLim(2), ax.ZLim(2), 1]);
end

if nargin < 5 || isempty(targetPoint)
    targetPoint = point;
end

if nargin < 6 || isempty(viewRadius) || ...
        ~isfinite(viewRadius) || viewRadius <= 0
    viewRadius = 0.5 * axesLimit;
end

if isempty(normal) || any(~isfinite(normal)) || norm(normal) < eps
    normal = [1 1 1];
end

normal = normal ./ norm(normal);
cameraViewAngle = 14;
cameraDistance = max( ...
    viewRadius / sind(0.5 * cameraViewAngle), ...
    0.25 * axesLimit);

camtarget(ax, targetPoint);

campos(ax, targetPoint + normal * cameraDistance);

camup(ax, [0 0 1]);

ax.CameraViewAngleMode = 'manual';
ax.CameraViewAngle = cameraViewAngle;

end
