classdef ObjectInspector < handle
        % ObjectInspector: A MATLAB window for visualizing and interacting with time-varying mesh data.
        % Provides UI controls for time navigation, mesh visualization, parameter table, and temporal plots.
    % --- UI and Data Properties ---
    properties
        playButton                % uibutton: Play/pause button for time navigation
        prevButton                % uibutton: Button to go to previous time point
        nextButton                % uibutton: Button to go to next time point
        timeEdit                  % uieditfield: Numeric edit field for selecting time point
        sliderPanel               % uigridlayout: Panel containing slider and navigation controls
        playTimer                 % timer: Timer object for auto-play functionality
        meshAxesLimits            % double[2x3]: Stores mesh axes limits for restoring view ([min; max])
        fig                       % uifigure: Main UI figure window
        rowArray                  % cell: Cell array of tables, one per time point
        parametersToShow          % cellstr: List of parameter names to display in the parameter table
        meshAxes                  % uiaxes: Axes for mesh visualization
        scaleBarAxes              % uiaxes: Axes for the dynamic scale bar under meshAxes
        paramTable                % uitable: Table UI component for parameter display
        plotAxes                  % uiaxes: Axes for temporal plot of selected variable
        dropdown                  % uidropdown: (Unused) Dropdown for variable selection
        slider                    % uislider: Slider for time navigation
        bottomPanel               % uipanel: Panel for plot and controls
        controlPanel              % uipanel: (Unused) Panel for additional controls
        selectedPlotVar           % char: Stores the currently selected variable for plotting
        meshLightHandle           % graphics handle: Handle to the camlight object for mesh lighting
        meshAxesCameraListener    % event.listener: Handle to the CameraPosition listener for updating lighting
        meshAxesScaleListeners    % event.listener[]: Handles to limit listeners for dynamic scale bar updates
        figSizeListener           % event.listener: Handle to figure SizeChanged updates
        theme = 'dark';                      % char: Theme name ('dark' or 'light')
        rotateButton              % uibutton: Toggle button for rotation
        rotationSpeedSlider       % uislider: Slider for rotation speed
        rotationTimer             % timer: Timer for automatic rotation
        rotationSpeed             % double: Current rotation speed (degrees per tick)
        rotationAxis              % double[1x3]: Precomputed rotation axis
        rotationOrigin            % double[1x3]: Origin for rotation (basePoint)

    end

    methods
        function obj = ObjectInspector(tableList, parametersToShow, theme)
            % Constructor: Initializes the ObjectInspector app
            arguments
                tableList = {[]}
                parametersToShow = {}
                theme = 'dark'
            end
            obj.rowArray = tableList;
            obj.parametersToShow = parametersToShow;
            obj.theme = obj.normalizeTheme(theme);
            obj.createUI();
            obj.refresh();
            obj.updateScaleBar();
        end

        
        
        function setTableList(obj, newTableList)
            % Set a new table list and refresh UI
            obj.rowArray = newTableList;
            obj.refresh();
        end

        
        
        function setParametersToShow(obj, params)
            % Set parameters to show in the parameter table and refresh UI
            obj.parametersToShow = params;
            obj.refresh();
        end

        
        
        function createUI(obj)
            % Create all UI components and layout

            obj.fig = uifigure('Name', 'Object Inspector', 'Position', [100 100 1200 700], 'Theme', obj.theme);
            % obj.fig.Color = obj.getThemeColor();
            gl = uigridlayout(obj.fig, [2 2]);
            gl.RowHeight = {'1x', 200};
            gl.ColumnWidth = {'2x', 'fit'};

            % Mesh container with mesh axes (top) + scale bar (bottom)
            meshContainerLayout = uigridlayout(gl, [2 1]);
            meshContainerLayout.Layout.Row = 1;
            meshContainerLayout.Layout.Column = 1;
            meshContainerLayout.RowHeight = {'1x', 36};
            meshContainerLayout.ColumnWidth = {'1x'};
            meshContainerLayout.Padding = [0 0 0 0];
            meshContainerLayout.RowSpacing = 0;

            % Mesh axes (upper row)
            obj.meshAxes = uiaxes(meshContainerLayout);
            obj.meshAxes.Layout.Row = 1;
            obj.meshAxes.Layout.Column = 1;
            obj.meshAxes.CameraViewAngleMode = 'manual';
            obj.meshAxes.CameraViewAngle = 10; % default view angle

            % get(obj.meshAxes)
            % obj.meshAxes.Color = 'none';      % for some reason, this was opening a new figure window
            obj.meshAxes.Color = obj.fig.Color;
            obj.meshAxes.XColor = 'none';
            obj.meshAxes.YColor = 'none';
            obj.meshAxes.ZColor = 'none';

            % Scale bar axes (bottom row)
            obj.scaleBarAxes = uiaxes(meshContainerLayout);
            obj.scaleBarAxes.Layout.Row = 2;
            obj.scaleBarAxes.Layout.Column = 1;
            obj.scaleBarAxes.XTick = [];
            obj.scaleBarAxes.YTick = [];
            obj.scaleBarAxes.XColor = 'none';
            obj.scaleBarAxes.YColor = 'none';
            obj.scaleBarAxes.Box = 'off';
            obj.scaleBarAxes.Toolbar.Visible = 'off';
            obj.scaleBarAxes.Interactions = [];
            try
                obj.scaleBarAxes.Color = 'none';
            catch
                disp('Warning: Unable to set scale bar axes color to transparent. Setting to figure background color instead.');
                obj.scaleBarAxes.Color = obj.fig.Color;
            end

            % Vectorized global bounding box calculation
            allVerts = [];
            for t = 1:numel(obj.rowArray)
                T = obj.rowArray{t};
                if isempty(T) || ~ismember('Mesh', T.Properties.VariableNames)
                    disp('No mesh data for time point ' + string(t) + '; skipping bounding box calculation.');
                    continue;
                end
                for meshIdx = 1:height(T)
                    mesh = T.Mesh{meshIdx};
                    if isempty(mesh) || ~isprop(mesh, 'Vertices')
                        continue;
                    end
                    verts = mesh.Vertices;
                    allVerts = [allVerts; verts];
                end
            end
            if ~isempty(allVerts)
                minXYZ = min(allVerts, [], 1);
                maxXYZ = max(allVerts, [], 1);
                obj.meshAxes.XLim = [minXYZ(1), maxXYZ(1)];
                obj.meshAxes.YLim = [minXYZ(2), maxXYZ(2)];
                obj.meshAxes.ZLim = [minXYZ(3), maxXYZ(3)];
                obj.meshAxesLimits = [minXYZ; maxXYZ];
            else
                obj.meshAxesLimits = [];
            end
            axis(obj.meshAxes, 'equal');
            view(obj.meshAxes, 3);
            camlight(obj.meshAxes);
            lighting(obj.meshAxes, 'gouraud');
            obj.meshAxes.Clipping = 'off';
            obj.meshAxes.Interactions = [zoomInteraction rotateInteraction];
            enableDefaultInteractivity(obj.meshAxes);
            % disp(obj.meshAxes.Interactions);

            % Add camlight and store handle
            obj.meshLightHandle = camlight(obj.meshAxes, 'headlight');
            obj.meshAxes.Clipping = 'off';
            % Add listener to update camlight after rotation
            obj.meshAxesCameraListener = addlistener(obj.meshAxes, 'View', 'PostSet', @(~,~) obj.updateMeshLight());
            % obj.meshAxesScaleListeners = [ ...
            %     addlistener(obj.meshAxes, 'XLim', 'PostSet', @(~,~) obj.updateScaleBar()), ...
            %     addlistener(obj.meshAxes, 'YLim', 'PostSet', @(~,~) obj.updateScaleBar()), ...
            %     addlistener(obj.meshAxes, 'ZLim', 'PostSet', @(~,~) obj.updateScaleBar()), ...
            % ];
            % I assume that it's enough to just observe one of the axes, as all of them are changing synchronously
            obj.meshAxesScaleListeners = [ ...
                addlistener(obj.meshAxes, 'XLim', 'PostSet', @(~,~) obj.updateScaleBar()), ...
            ];
            obj.figSizeListener = addlistener(obj.fig, 'SizeChanged', @(~,~) obj.updateScaleBar());
            % obj.updateScaleBar(); % will be called later

            % Parameter table
            obj.paramTable = uitable(gl);
            obj.paramTable.Layout.Row = 1;
            obj.paramTable.Layout.Column = 2;
            obj.paramTable.ColumnName = {'Parameter', 'Value', 'Unit'};
            obj.paramTable.CellSelectionCallback = @(src, evt) obj.onTableRowSelected(evt);
            obj.paramTable.FontSize = 12;   % 12 is the default; CHANGE HERE FOR VISUALIZATION!!!

            % Bottom panel (plot + controls)
            obj.bottomPanel = uipanel(gl);
            obj.bottomPanel.Layout.Row = 2;
            obj.bottomPanel.Layout.Column = [1 2];
            bottomGL = uigridlayout(obj.bottomPanel, [2 1]);
            bottomGL.RowHeight = {40, '1x'};
            bottomGL.ColumnWidth = {'1x'};

            % Slider and controls panel (row 1)
            obj.sliderPanel = uigridlayout(bottomGL);
            obj.sliderPanel.Layout.Row = 1;
            obj.sliderPanel.Layout.Column = 1;
            obj.sliderPanel.ColumnWidth = {40, 40, 80, '1x', 40, 70, 120};
            obj.sliderPanel.RowHeight = {35};
            obj.sliderPanel.Padding = [0 0 0 0];

            % Play button
            obj.playButton = uibutton(obj.sliderPanel, 'Text', '▶', 'ButtonPushedFcn', @(src,evt)obj.onPlayPressed());
            obj.playButton.Layout.Row = 1;
            obj.playButton.Layout.Column = 1;

            % Previous button
            obj.prevButton = uibutton(obj.sliderPanel, 'Text', '←', 'ButtonPushedFcn', @(src,evt)obj.onPrevPressed());
            obj.prevButton.Layout.Row = 1;
            obj.prevButton.Layout.Column = 2;

            % Time point edit field
            obj.timeEdit = uieditfield(obj.sliderPanel, 'numeric', 'ValueChangedFcn', @(src,evt)obj.onTimeEditChanged());
            obj.timeEdit.Layout.Row = 1;
            obj.timeEdit.Layout.Column = 3;
            obj.timeEdit.Limits = [1 max(1, numel(obj.rowArray))];
            obj.timeEdit.RoundFractionalValues = true;
            obj.timeEdit.Value = 1;

            % Slider
            nTime = numel(obj.rowArray);
            obj.slider = uislider(obj.sliderPanel, ...
                'Limits', [1 max(1, nTime)], ...
                'Value', 1, ...
                'MajorTicks', 1:nTime, ...
                'MinorTicks', [], ...
                'ValueChangingFcn', @(src, evt) obj.onTimeChanging(evt), ...
                'ValueChangedFcn', @(src, evt) obj.onTimeChanged(round(src.Value)));
            obj.slider.Layout.Row = 1;
            obj.slider.Layout.Column = 4;


            % Next button
            obj.nextButton = uibutton(obj.sliderPanel, 'Text', '→', 'ButtonPushedFcn', @(src,evt)obj.onNextPressed());
            obj.nextButton.Layout.Row = 1;
            obj.nextButton.Layout.Column = 5;

            % Rotate toggle button
            obj.rotateButton = uibutton(obj.sliderPanel, 'Text', 'Rotate', 'ButtonPushedFcn', @(src,evt)obj.onRotatePressed());
            obj.rotateButton.Layout.Row = 1;
            obj.rotateButton.Layout.Column = 6;

            % Rotation speed slider
            obj.rotationSpeedSlider = uislider(obj.sliderPanel, ...
                'Limits', [1 100], ...
                'Value', 20, ...
                'MajorTicks', [1 20 40 60 80 100], ...
                'MinorTicks', [], ...
                'ValueChangedFcn', @(src,evt)obj.onRotationSpeedChanged());
            obj.rotationSpeedSlider.Layout.Row = 1;
            obj.rotationSpeedSlider.Layout.Column = 7;
            obj.rotationSpeed = 20; % default speed

            % Plot axes (row 2)
            obj.plotAxes = uiaxes(bottomGL);
            obj.plotAxes.Layout.Row = 2;
            obj.plotAxes.Layout.Column = 1;
        end


        function onRotatePressed(obj)
            % Toggle rotation on/off
            obj.computeRotationAxis();
            if isempty(obj.rotationTimer) || ~isvalid(obj.rotationTimer)
                obj.rotationTimer = timer('ExecutionMode','fixedRate','Period',0.05,'TimerFcn',@(~,~)obj.rotateView());
            end
            if strcmp(obj.rotateButton.Text, 'Rotate')
                obj.rotateButton.Text = 'Stop';
                start(obj.rotationTimer);
            else
                obj.rotateButton.Text = 'Rotate';
                stop(obj.rotationTimer);
            end
        end



        function onRotationSpeedChanged(obj)
            % Update rotation speed from slider
            obj.rotationSpeed = obj.rotationSpeedSlider.Value;
        end



        % function rotateView(obj)
        %     % Rotate the meshAxes view around a precomputed axis
        %     ax = obj.meshAxes;
        %     if isempty(obj.rotationAxis) || isempty(obj.rotationOrigin)
        %         obj.computeRotationAxis();
        %     end
        %     % Get current camera position and target
        %     campos = ax.CameraPosition;
        %     camtarget = ax.CameraTarget;
        %     % Build rotation matrix
        %     theta = obj.rotationSpeed * 0.05 * pi/180; % convert to radians
        %     u = obj.rotationAxis(:)';
        %     o = obj.rotationOrigin(:)';
        %     R = axang2rotm([u theta]);
        %     % Rotate camera position and target around the axis
        %     campos_rel = campos - o;
        %     camtarget_rel = camtarget - o;
        %     campos_new = (R * campos_rel(:))' + o;
        %     camtarget_new = (R * camtarget_rel(:))' + o;
        %     ax.CameraPosition = campos_new;
        %     ax.CameraTarget = camtarget_new;
        % end


        function rotateView(obj)
            % Rotate the meshAxes view around Z axis
            ax = obj.meshAxes;
            [az, el] = view(ax);
            az = az + obj.rotationSpeed * 0.05; % scale by timer period
            view(ax, [az, el]);
        end


        function computeRotationAxis(obj)
            % Compute the rotation axis from basePoint to furthest 5% of vertices
            idx = 1;
            if ~isempty(obj.slider) && isvalid(obj.slider)
                idx = round(obj.slider.Value);
            end
            if isempty(obj.rowArray) || isempty(obj.rowArray{idx})
                obj.rotationAxis = [0 0 1];
                obj.rotationOrigin = [0 0 0];
                return;
            end
            T = obj.rowArray{idx};
            if ~ismember('Mesh', T.Properties.VariableNames) || isempty(T.Mesh{1})
                obj.rotationAxis = [0 0 1];
                obj.rotationOrigin = [0 0 0];
                return;
            end
            mesh = T.Mesh{1};
            if ~isprop(mesh, 'Vertices') || isempty(mesh.Vertices)
                obj.rotationAxis = [0 0 1];
                obj.rotationOrigin = [0 0 0];
                return;
            end
            verts = mesh.Vertices;
            % Get basePoint
            basePoint = [];
            if ismember('basePoint', T.Properties.VariableNames) && ~isempty(T.basePoint)
                basePoint = T.basePoint;
                if iscell(basePoint)
                    basePoint = basePoint{1};
                end
                if isnumeric(basePoint) && numel(basePoint) >= 3 && all(isfinite(basePoint(1:3)))
                    basePoint = basePoint(1:3);
                else
                    basePoint = [];
                end
            end
            if isempty(basePoint)
                obj.rotationAxis = [0 0 1];
                obj.rotationOrigin = [0 0 0];
                return;
            end
            % Compute distances from basePoint to all vertices
            dists = sqrt(sum((verts - basePoint).^2, 2));
            nFurthest = max(1, round(0.05 * numel(dists)));
            [~, idxs] = maxk(dists, nFurthest);
            furthestVerts = verts(idxs, :);
            % Compute mean of furthest points
            meanFurthest = mean(furthestVerts, 1);
            axisVec = meanFurthest - basePoint;
            if norm(axisVec) < 1e-8
                axisVec = [0 0 1];
            else
                axisVec = axisVec / norm(axisVec);
            end
            obj.rotationAxis = axisVec;
            obj.rotationOrigin = basePoint;
        end
        

        function delete(obj)
            % Destructor: Clean up timers
            if ~isempty(obj.rotationTimer) && isvalid(obj.rotationTimer)
                stop(obj.rotationTimer);
                delete(obj.rotationTimer);
            end
            if ~isempty(obj.playTimer) && isvalid(obj.playTimer)
                stop(obj.playTimer);
                delete(obj.playTimer);
            end
        end
        
        
        function refresh(obj)
            % Refresh UI controls and update all displays
            % Only update slider and edit field if needed
            nTime = numel(obj.rowArray);
            if ~isempty(obj.slider) && isvalid(obj.slider)
                if any(obj.slider.Limits ~= [1 max(1, nTime)])
                    obj.slider.Limits = [1 max(1, nTime)];
                end
                if ~isequal(obj.slider.MajorTicks, 1:nTime)
                    obj.slider.MajorTicks = 1:nTime;
                end
                % Don't reset value unless out of bounds
                if obj.slider.Value < 1 || obj.slider.Value > nTime
                    obj.slider.Value = 1;
                end
            end
            if ~isempty(obj.timeEdit) && isvalid(obj.timeEdit)
                if any(obj.timeEdit.Limits ~= [1 max(1, nTime)])
                    obj.timeEdit.Limits = [1 max(1, nTime)];
                end
                if obj.timeEdit.Value < 1 || obj.timeEdit.Value > nTime
                    obj.timeEdit.Value = 1;
                end
            end

            % Redraw UI after data changes, using first available time point
            availableIdx = find(~cellfun(@isempty, obj.rowArray));
            if isempty(availableIdx)
                % No available time points, clear UI
                if ~isempty(obj.slider) && isvalid(obj.slider)
                    obj.slider.Enable = 'off';
                end
                if ~isempty(obj.timeEdit) && isvalid(obj.timeEdit)
                    obj.timeEdit.Enable = 'off';
                end
                if ~isempty(obj.playButton) && isvalid(obj.playButton)
                    obj.playButton.Enable = 'off';
                end
                if ~isempty(obj.prevButton) && isvalid(obj.prevButton)
                    obj.prevButton.Enable = 'off';
                end
                if ~isempty(obj.nextButton) && isvalid(obj.nextButton)
                    obj.nextButton.Enable = 'off';
                end
                cla(obj.meshAxes);
                cla(obj.plotAxes);
                obj.paramTable.Data = {};
                return;
            end

            % Only one available time point: disable controls
            if numel(availableIdx) == 1
                idx = availableIdx(1);
                % For MATLAB UI controls, Limits must be strictly increasing
                lim = [idx-0.5 idx+0.5];
                if ~isempty(obj.slider) && isvalid(obj.slider)
                    obj.slider.Enable = 'off';
                    obj.slider.Limits = lim;
                    obj.slider.MajorTicks = idx;
                    obj.slider.Value = idx;
                end
                if ~isempty(obj.timeEdit) && isvalid(obj.timeEdit)
                    obj.timeEdit.Enable = 'off';
                    obj.timeEdit.Limits = lim;
                    obj.timeEdit.Value = idx;
                end
                if ~isempty(obj.playButton) && isvalid(obj.playButton)
                    obj.playButton.Enable = 'off';
                end
                if ~isempty(obj.prevButton) && isvalid(obj.prevButton)
                    obj.prevButton.Enable = 'off';
                end
                if ~isempty(obj.nextButton) && isvalid(obj.nextButton)
                    obj.nextButton.Enable = 'off';
                end
                obj.updateMesh(idx);
                obj.updateTable(idx);
                obj.updatePlot();
                return;
            end

            % Multiple available time points: enable controls and set to available
            if ~isempty(obj.slider) && isvalid(obj.slider)
                obj.slider.Enable = 'on';
                obj.slider.Limits = [availableIdx(1) availableIdx(end)];
                obj.slider.MajorTicks = availableIdx;
                if ~ismember(obj.slider.Value, availableIdx)
                    obj.slider.Value = availableIdx(1);
                end
            end
            if ~isempty(obj.timeEdit) && isvalid(obj.timeEdit)
                obj.timeEdit.Enable = 'on';
                obj.timeEdit.Limits = [availableIdx(1) availableIdx(end)];
                if ~ismember(obj.timeEdit.Value, availableIdx)
                    obj.timeEdit.Value = availableIdx(1);
                end
            end
            if ~isempty(obj.playButton) && isvalid(obj.playButton)
                obj.playButton.Enable = 'on';
            end
            if ~isempty(obj.prevButton) && isvalid(obj.prevButton)
                obj.prevButton.Enable = 'on';
            end
            if ~isempty(obj.nextButton) && isvalid(obj.nextButton)
                obj.nextButton.Enable = 'on';
            end

            % Use current value if available, else first available
            idx = availableIdx(1);
            if ~isempty(obj.slider) && isvalid(obj.slider) && ismember(round(obj.slider.Value), availableIdx)
                idx = round(obj.slider.Value);
            end
            obj.updateMesh(idx);
            obj.updateTable(idx);
            obj.updatePlot();
        end


        
        function updateMeshLight(obj)
            % Update camlight position after camera movement
            % Move the existing camlight to follow the camera
            % disp('Updating camlight position to follow camera');
            if ~isempty(obj.meshLightHandle) && isvalid(obj.meshLightHandle)
                camlight(obj.meshLightHandle, 'headlight');
            end
            obj.updateScaleBar();
        end



        function onPlayPressed(obj)
            % Callback for play/pause button
            if isempty(obj.playTimer) || ~isvalid(obj.playTimer)
                obj.playTimer = timer('ExecutionMode','fixedRate','Period',0.5,'TimerFcn',@(~,~)obj.advanceTime());
            end
            if strcmp(obj.playButton.Text, '▶')
                obj.playButton.Text = '⏸';
                start(obj.playTimer);
            else
                obj.playButton.Text = '▶';
                stop(obj.playTimer);
            end
        end

        

        function advanceTime(obj)
            % Advance to the next time point
            nTime = numel(obj.rowArray);
            nextVal = obj.slider.Value + 1;
            if nextVal > nTime
                nextVal = 1;
            end
            obj.slider.Value = nextVal;
            obj.onTimeChanged(nextVal);
        end

        

        function onPrevPressed(obj)
            % Callback for previous button
            val = obj.slider.Value - 1;
            if val < 1
                val = numel(obj.rowArray);
            end
            obj.slider.Value = val;
            obj.onTimeChanged(val);
        end

        
        
        function onNextPressed(obj)
            % Callback for next button
            val = obj.slider.Value + 1;
            if val > numel(obj.rowArray)
                val = 1;
            end
            obj.slider.Value = val;
            obj.onTimeChanged(val);
        end

        

        function onTimeEditChanged(obj)
            % Callback for time edit field value change
            val = obj.timeEdit.Value;
            nTime = numel(obj.rowArray);
            val = max(1, min(nTime, round(val)));
            obj.slider.Value = val;
            obj.onTimeChanged(val);
        end

        

        function onTimeChanging(obj, evt)
            % Callback for slider value changing
            val = round(evt.Value);
            if obj.slider.Value ~= val
                obj.slider.Value = val;
                obj.onTimeChanged(val);
            end
        end

        

        function T = getCurrentTable(obj)
            % Get the current table (first time point)
            if isempty(obj.rowArray) || isempty(obj.rowArray{1})
                T = [];
            else
                T = obj.rowArray{1};
            end
        end

   

        function updateMesh(obj, timeIdx)
            % Plot the mesh for the given time index
            ax = obj.meshAxes;
            % Save current camera properties
            % camPos = get(ax, 'CameraPosition');
            % camTarget = get(ax, 'CameraTarget');
            % camUp = get(ax, 'CameraUpVector');
            % camViewAngle = get(ax, 'CameraViewAngle');
            % camProj = get(ax, 'Projection');

            cla(ax);
            if isempty(obj.rowArray) || isempty(obj.rowArray{timeIdx})
                obj.updateScaleBar();
                return;
            end
            T = obj.rowArray{timeIdx};
            if isempty(T) || ~ismember('Mesh', T.Properties.VariableNames)
                obj.updateScaleBar();
                return;
            end
            mesh = T.Mesh{1};
            if isempty(mesh)
                obj.updateScaleBar();
                return;
            end


            % Prepare per-vertex color: default color for all, color basePatch vertices by group
            nVerts = size(mesh.Vertices,1);
            meshColor = repmat([0.7 0.7 0.8], nVerts, 1);
            if ismember('basePatch', T.Properties.VariableNames) && ~isempty(T.basePatch{1})
                basePatchData = T.basePatch{1};
                nGroups = numel(basePatchData);
                colorList = lines(max(6, nGroups));
                % For each group, color its vertices
                for patchIndex = 1:nGroups
                    patchVerts = basePatchData(patchIndex).vertices;
                    groupColor = colorList(mod(patchIndex-1, size(colorList,1))+1, :);
                    for k = 1:size(patchVerts,1)
                        dists = sqrt(sum((mesh.Vertices - patchVerts(k,:)).^2,2));
                        [minDist, minIdx] = min(dists);
                        if minDist < 1e-6 % tolerance for floating point
                            meshColor(minIdx,:) = groupColor;
                        end
                    end
                end
            end
            % Plot mesh with per-vertex color
            patch(ax, ...
                'Vertices', mesh.Vertices, ...
                'Faces', mesh.Faces, ...
                'FaceVertexCData', meshColor, ...
                'FaceColor', 'interp', ...
                'EdgeColor', 'none', ...
                'FaceAlpha', 1);

            % Plot basePoint if available
            if ismember('basePoint', T.Properties.VariableNames) && ~isempty(T.basePoint)
                basePoint = T.basePoint;
                if iscell(basePoint)
                    basePoint = basePoint{1};
                end
                if isnumeric(basePoint) && numel(basePoint) >= 3 && all(isfinite(basePoint(1:3)))
                    bp = basePoint(1:3);
                    hold(ax, 'on');
                    plot3(ax, bp(1), bp(2), bp(3), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
                    hold(ax, 'off');
                end
            end

            axis(ax, 'equal');
            ax.Clipping = 'off';
            % Restore axes limits if available
            if ~isempty(obj.meshAxesLimits)
                ax.XLim = obj.meshAxesLimits(:,1)';
                ax.YLim = obj.meshAxesLimits(:,2)';
                ax.ZLim = obj.meshAxesLimits(:,3)';
            end
            if isempty(obj.meshLightHandle) || ~isvalid(obj.meshLightHandle)
                obj.meshLightHandle = camlight(ax, 'headlight');
            else
                camlight(obj.meshLightHandle, 'headlight');
            end
            lighting(ax, 'gouraud');
            obj.updateScaleBar();
        end


        function updateScaleBar(obj)
            % disp('Updating scale bar');
            % pause(1); % This does not seem to help
            % Draw a dynamic scale bar from visible world width in meshAxes.
            if isempty(obj.scaleBarAxes) || ~isvalid(obj.scaleBarAxes) || isempty(obj.meshAxes) || ~isvalid(obj.meshAxes)
                disp('Scale bar or mesh axes not available');
                return;
            end

            scaleAx = obj.scaleBarAxes;
            meshAx = obj.meshAxes;

            meshAxesPixelPosition = getpixelposition(meshAx, true);
            meshAxesWidthPx = meshAxesPixelPosition(3);
            meshAxesHeightPx = meshAxesPixelPosition(4);
            if meshAxesWidthPx <= 1 || meshAxesHeightPx <= 1
                % During startup the layout may not be fully resolved yet.
                % drawnow;  % We do not like drawnow
                meshAxesPixelPosition = getpixelposition(meshAx, true);
                meshAxesWidthPx = meshAxesPixelPosition(3);
                meshAxesHeightPx = meshAxesPixelPosition(4);
                if meshAxesWidthPx <= 1 || meshAxesHeightPx <= 1
                    cla(scaleAx);
                    return;
                end
            end

            cameraDistance = norm(meshAx.CameraTarget - meshAx.CameraPosition);
            if ~isfinite(cameraDistance) || cameraDistance <= 0
                cla(scaleAx);
                return;
            end

            visibleHeight = 2 * cameraDistance * tand(meshAx.CameraViewAngle / 2);
            visibleWidth = visibleHeight * (meshAxesWidthPx / meshAxesHeightPx);
            worldPerPixel = visibleWidth / meshAxesWidthPx;
            if ~isfinite(worldPerPixel) || worldPerPixel <= 0
                cla(scaleAx);
                return;
            end

            targetPixelLength = 0.22 * meshAxesWidthPx;
            targetWorldLength = targetPixelLength * worldPerPixel;
            scaleLength = obj.roundToNiceScale(targetWorldLength);

            scaleAxesPixelPosition = getpixelposition(scaleAx, true);
            scaleAxesWidthPx = scaleAxesPixelPosition(3);
            if scaleAxesWidthPx <= 1
                scaleAxesWidthPx = meshAxesWidthPx;
            end
            rightMarginNormalized = 0.04;
            leftMarginNormalized = 0.02;
            minBarWidthNormalized = 0.12;
            maxBarWidthNormalized = 1 - rightMarginNormalized - leftMarginNormalized;

            barPixelLength = scaleLength / worldPerPixel;
            barWidthNormalized = barPixelLength / scaleAxesWidthPx;

            for stepIndex = 1:10
                if barWidthNormalized > maxBarWidthNormalized
                    scaleLength = obj.roundToNiceScale(scaleLength * 0.5);
                elseif barWidthNormalized < minBarWidthNormalized
                    scaleLength = obj.roundToNiceScale(scaleLength * 2);
                else
                    break;
                end
                barPixelLength = scaleLength / worldPerPixel;
                barWidthNormalized = barPixelLength / scaleAxesWidthPx;
            end
            barWidthNormalized = min(maxBarWidthNormalized, max(minBarWidthNormalized, barWidthNormalized));

            barEnd = 1 - rightMarginNormalized;
            barStart = max(leftMarginNormalized, barEnd - barWidthNormalized);
            tickHalfHeight = 0.12;
            barColor = obj.getScaleBarForegroundColor();

            cla(scaleAx);
            hold(scaleAx, 'on');
            plot(scaleAx, [barStart, barEnd], [0.5, 0.5], '-', 'LineWidth', 2, 'Color', barColor);
            plot(scaleAx, [barStart, barStart], [0.5 - tickHalfHeight, 0.5 + tickHalfHeight], '-', 'LineWidth', 2, 'Color', barColor);
            plot(scaleAx, [barEnd, barEnd], [0.5 - tickHalfHeight, 0.5 + tickHalfHeight], '-', 'LineWidth', 2, 'Color', barColor);
            [displayLength, unitLabel] = obj.formatScaleLengthWithUnits(scaleLength);
            scaleBarLabel = sprintf('%g %s', displayLength, unitLabel);
            text(scaleAx, (barStart + barEnd) / 2, 0.82, scaleBarLabel, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 11, 'Color', barColor);
            hold(scaleAx, 'off');

            scaleAx.XLim = [0, 1];
            scaleAx.YLim = [0, 1];
            scaleAx.XTick = [];
            scaleAx.YTick = [];
            scaleAx.XColor = 'none';
            scaleAx.YColor = 'none';
            scaleAx.Box = 'off';
            try
                scaleAx.Color = 'none';
            catch
                scaleAx.Color = obj.fig.Color;
            end
            % disp('reached the end')
        end


        function niceValue = roundToNiceScale(~, rawValue)
            % Round a raw scale bar target length to a readable value.
            if ~isfinite(rawValue) || rawValue <= 0
                niceValue = 1;
                return;
            end

            magnitude = 10^floor(log10(rawValue));
            normalized = rawValue / magnitude;

            if normalized < 1.5
                base = 1;
            elseif normalized < 3
                base = 2;
            elseif normalized < 7
                base = 5;
            else
                base = 10;
            end

            niceValue = base * magnitude;
        end


        function [displayLength, unitLabel] = formatScaleLengthWithUnits(~, scaleLengthUm)
            % Convert um to a readable metric unit level for the scale bar label.
            if ~isfinite(scaleLengthUm) || scaleLengthUm <= 0
                displayLength = 1;
                unitLabel = 'um';
                return;
            end

            if scaleLengthUm >= 1e6
                displayLength = scaleLengthUm / 1e6;
                unitLabel = 'm';
            elseif scaleLengthUm >= 1e3
                displayLength = scaleLengthUm / 1e3;
                unitLabel = 'mm';
            elseif scaleLengthUm >= 1
                displayLength = scaleLengthUm;
                unitLabel = 'um';
            else
                displayLength = scaleLengthUm * 1e3;
                unitLabel = 'nm';
            end
        end


        function barColor = getScaleBarForegroundColor(obj)
            % Choose white for dark backgrounds and black for light backgrounds.
            if strcmp(obj.theme, 'dark')
                barColor = [1 1 1];
            else
                barColor = [0 0 0];
            end
        end


        function theme = normalizeTheme(~, theme)
            % Normalize theme input to either 'dark' or 'light'.
            if isstring(theme)
                theme = char(theme);
            end
            if isempty(theme) || ~ischar(theme)
                theme = 'dark';
                return;
            end

            theme = lower(strtrim(theme));
            if startsWith(theme, 'l')
                theme = 'light';
            else
                theme = 'dark';
            end
        end


        function color = getThemeColor(obj)
            % Return the figure background color for the selected theme.
            if strcmp(obj.theme, 'light')
                color = [0.94 0.94 0.94];
            else
                color = [0.12 0.12 0.12];
            end
        end

        
        
        function updateTable(obj, timeIdx)
            % Update the parameter table for the given time index
            if isempty(obj.rowArray) || isempty(obj.rowArray{timeIdx})
                obj.paramTable.Data = {};
                return;
            end
            T = obj.rowArray{timeIdx};
            if isempty(T)
                obj.paramTable.Data = {};
                return;
            end
            if isempty(obj.parametersToShow)
                varNames = T.Properties.VariableNames;
                meshCol = strcmp(varNames, 'Mesh');
                params = varNames(~meshCol);
            else
                params = intersect(obj.parametersToShow, T.Properties.VariableNames, 'stable');
            end
            units = T.Properties.VariableUnits;
            nVars = numel(params);
            tableData = cell(nVars, 3);
            for i = 1:nVars
                var = params{i};
                val = T.(var)(1);
                if isnumeric(val)
                    valStr = num2str(val);
                elseif iscategorical(val) || isstring(val)
                    valStr = char(val);
                else
                    valStr = '-';
                end
                unitIdx = strcmp(T.Properties.VariableNames, var);
                if ~isempty(units) && any(unitIdx)
                    unitStr = units{unitIdx};
                else
                    unitStr = '';
                end
                tableData{i,1} = var;
                tableData{i,2} = valStr;
                tableData{i,3} = unitStr;
            end
            obj.paramTable.Data = tableData;
        end

        
        
        function updatePlot(obj, selectedVar)
            % Update the temporal plot for the selected variable
            ax = obj.plotAxes;
            cla(ax);
            if nargin < 2 || isempty(selectedVar)
                % Use stored selection if available
                if ~isempty(obj.selectedPlotVar)
                    selectedVar = obj.selectedPlotVar;
                else
                    data = obj.paramTable.Data;
                    if isempty(data)
                        return;
                    end
                    selectedVar = data{1,1};
                end
            end
            obj.selectedPlotVar = selectedVar;
            nTime = numel(obj.rowArray);
            values = nan(1, nTime);
            for t = 1:nTime
                T = obj.rowArray{t};
                if isempty(T) || ~ismember(selectedVar, T.Properties.VariableNames)
                    continue;
                end
                values(t) = T.(selectedVar)(1);
            end
            plot(ax, 1:nTime, values, '-o', 'LineWidth', 1.5);
            hold(ax, 'on');
            % Draw vertical line at current time point, or first available
            currIdx = 1;
            if ~isempty(obj.slider) && isvalid(obj.slider)
                currIdx = round(obj.slider.Value);
            end
            % If current time point is missing, use first available
            if isnan(values(currIdx))
                availIdx = find(~isnan(values), 1, 'first');
                if ~isempty(availIdx)
                    currIdx = availIdx;
                end
            end
            yl = ylim(ax);
            plot(ax, [currIdx currIdx], yl, 'r--', 'LineWidth', 1.5);
            hold(ax, 'off');
            xlabel(ax, 'Time point');
            ylabel(ax, selectedVar);
            title(ax, ['Temporal development: ' selectedVar]);
            grid(ax, 'on');
        end

        

        function onTableRowSelected(obj, evt)
            % Callback for selecting a row in the parameter table
            if isempty(evt.Indices)
                return;
            end
            row = evt.Indices(1);
            data = obj.paramTable.Data;
            if isempty(data) || row > size(data,1)
                return;
            end
            selectedVar = data{row,1};
            obj.selectedPlotVar = selectedVar;
            obj.updatePlot(selectedVar);
        end


        
        function onTimeChanged(obj, timeIdx)
            % Callback for time change (slider or edit field)
            obj.updateMesh(timeIdx);
            obj.updateTable(timeIdx);
            % Always use the stored selected variable for plotting
            if isempty(obj.selectedPlotVar)
                obj.updatePlot();
            else
                obj.updatePlot(obj.selectedPlotVar);
            end
            if ~isempty(obj.timeEdit) && isvalid(obj.timeEdit)
                obj.timeEdit.Value = timeIdx;
            end
            if ~isempty(obj.slider) && isvalid(obj.slider)
                obj.slider.Value = timeIdx;
            end
            obj.computeRotationAxis;
        end
    end
end
