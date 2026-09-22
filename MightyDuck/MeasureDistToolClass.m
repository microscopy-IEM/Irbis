classdef MeasureDistToolClass < handle
    % Interactive tool to measure distance between two points.
    % Can synchronize across multiple axes for image comparison.
    
    properties
        fig                 % Parent figure
        ctrlObjs            % Array of control objects (e.g., imshow, surface handles)
        ax                  % Array of parent axes
        imDouble            % Cell array of image data (converted to double)
        pixelSize           % Pixel size
        z                   % Base Z level
        
        % Config parameters
        nDig = 2;           % Number of digits for showed numeric information
        txtZoffset = 0.2;
        lineZOffset = 0.1;
        xyTxtOffset = 0.0;
        maxHist
        minHist
        listenersHandle
        smallUnits = ' nm';
        largeUnits = ' \mum';
        
        % State flags
        showProfile = 0;
        detectPeaks = 0;
        exportPeaks = 0;
        dist = 0;
        
        % Colors
        distTxtCol = [0.96 0.96 0.96];
        lineCol = [0.6 0.6 0.8];
        markerCol = [0.7 0.7 0.9];
        markerHighligthCol = [1 0.7 0.9];
        
        % Graphics object arrays (one per axis)
        distLineObj
        distPoint1Obj
        distPoint2Obj
        textObj
        profileObj
        widthLineObj
        widthTxtObj
        
        % Export window handles
        exportFigObj
        exportAx
        exportPlot
        exportWidth
        exportWidthText
        
        % Original Figure Callbacks Store
        WindowButtonMotionFcnOrig
        WindowButtonUpFcnOrig
        WindowScrollWheelFcnOrig
    end
    
    methods
        function obj = MeasureDistToolClass(fig, ctrlObjs, z, imageCell, pixelSize)
            obj.fig = fig;
            obj.ctrlObjs = ctrlObjs;
            obj.z = z;
            obj.pixelSize = pixelSize;
            
            if isequal(pixelSize,'none')
                obj.pixelSize = 1;
                obj.smallUnits = ' pixels';
                obj.largeUnits = ' pixels';
                disp('pixel units')
            else
                obj.pixelSize = pixelSize;
                disp('real world units')
            end
                       
            % If imageData (imageCell) is empty or not provided, extract CData from ctrlObjs
            if nargin < 4 || isempty(imageCell)
                imageCell = cell(1, length(ctrlObjs));
                for i = 1:length(ctrlObjs)
                    if isprop(ctrlObjs(i), 'CData')
                        imageCell{i} = ctrlObjs(i).CData;
                    else
                        warning('Control object %d does not have a CData property. Using empty array.', i);
                        imageCell{i} = [];
                    end
                end
            elseif ~iscell(imageCell)
                % Ensure image input is a cell array to handle 1 or multiple
                imageCell = {imageCell};
            end
            
            % Pre-convert images to double for interpolation later
            obj.imDouble = cell(size(imageCell));
            for i = 1:length(imageCell)
                if ~isempty(imageCell{i})
                    obj.imDouble{i} = double(imageCell{i});
                else
                    obj.imDouble{i} = [];
                end
            end
            
            obj.maxHist = 10 * obj.pixelSize;
            obj.minHist = 2 * obj.pixelSize;
            
            % Store original callbacks
            obj.WindowButtonMotionFcnOrig = fig.WindowButtonMotionFcn;
            obj.WindowButtonUpFcnOrig = fig.WindowButtonUpFcn;
            obj.WindowScrollWheelFcnOrig = fig.WindowScrollWheelFcn;
            
            fig.WindowButtonUpFcn = [];
            fig.WindowButtonMotionFcn = [];
            fig.WindowScrollWheelFcn = [];
            
            % Setup controls and axes
            numAxes = length(ctrlObjs);
            obj.ax = gobjects(1, numAxes);
            for i = 1:numAxes
                obj.ax(i) = ctrlObjs(i).Parent;
                % Pass the index so we know which axis initiated the draw
                ctrlObjs(i).ButtonDownFcn = @(src, evt) obj.startDistLine(src, evt, i);
            end
            
            fig.Pointer = 'crosshair';


            %%
            for i = 1:numAxes
                obj.listenersHandle = addlistener(ctrlObjs(i), 'CData', 'PostSet', @obj.dataChangedCallback);
                % obj.listenersHandle = addlistener(ctrlObjs(2), 'CData', 'PostSet', @obj.dataChangedCallback);
            end

            % obj.listenersHandle = addlistener(ctrlObjs(1), 'UserData', 'PostSet', @obj.cdataChangedCallback);
            % obj.listenersHandle = addlistener(ctrlObjs(2), 'UserData', 'PostSet', @obj.cdataChangedCallback);
            %%

        end
        
        function startDistLine(obj, ~, evt, activeIdx)
            % Start drawing when left click is used, otherwise cancel
            if evt.Button ~= 1
                for i = 1:length(obj.ctrlObjs)
                    obj.ctrlObjs(i).ButtonDownFcn = '';
                end
                obj.fig.Pointer = 'arrow';
                return
            end
            
            x = obj.ax(activeIdx).CurrentPoint(1,1);
            y = obj.ax(activeIdx).CurrentPoint(1,2);
            drawZ = obj.z + obj.lineZOffset;
            
            numAxes = length(obj.ax);
            
            % Pre-allocate object arrays
            obj.distLineObj = gobjects(1, numAxes);
            obj.distPoint1Obj = gobjects(1, numAxes);
            obj.distPoint2Obj = gobjects(1, numAxes);
            obj.textObj = gobjects(1, numAxes);
            obj.profileObj = gobjects(1, numAxes);
            obj.widthLineObj = gobjects(1, numAxes);
            obj.widthTxtObj = gobjects(1, numAxes);
            
            % Create context menu (only need one shared menu)
            cm = uicontextmenu(obj.fig);
            uimenu(cm, 'Text', 'Delete measure tool', 'MenuSelectedFcn', @(src,evt) obj.deleteDistLine());
            uimenu(cm, 'Text', 'Show profile', 'MenuSelectedFcn', @(src,evt) obj.showProfileFcn(src), 'Checked', obj.showProfile);
            uimenu(cm, 'Text', 'Detect peaks', 'MenuSelectedFcn', @(src,evt) obj.detectPeaksFcn(src), 'Checked', obj.detectPeaks);
            uimenu(cm, 'Text', 'Export', 'MenuSelectedFcn', @(src,evt) obj.exportPeakFcn(src), 'Checked', obj.detectPeaks);
            
            % Instantiate objects for each axis
            for i = 1:numAxes
                curAx = obj.ax(i);
                
                obj.distLineObj(i) = patch(curAx, [x x], [y y], [drawZ drawZ], obj.lineCol, ...
                    'Tag', 'DistLine', 'FaceLighting', 'none', 'LineWidth', 2, ...
                    'BackFaceLighting', 'unlit', 'Marker', 'none', 'EdgeColor', obj.lineCol);
                
                obj.distPoint1Obj(i) = patch(curAx, x, y, drawZ, obj.lineCol, ...
                    'Tag', 'DistLineP1', 'FaceLighting', 'none', 'LineWidth', 2, 'MarkerSize', 6, ...
                    'BackFaceLighting', 'unlit', 'Marker', 'o', 'EdgeColor', obj.lineCol, 'MarkerFaceColor', obj.markerCol);
                
                obj.distPoint2Obj(i) = patch(curAx, x, y, drawZ, obj.lineCol, ...
                    'Tag', 'DistLineP2', 'FaceLighting', 'none', 'LineWidth', 2, 'MarkerSize', 6, ...
                    'BackFaceLighting', 'unlit', 'Marker', 'o', 'EdgeColor', obj.lineCol, 'MarkerFaceColor', obj.markerCol);
                
                obj.textObj(i) = text(curAx, x, y, drawZ + obj.txtZoffset, '0 \mum', ...
                    'FontSize', 11, 'Color', obj.distTxtCol, 'Interpreter', 'tex', ...
                    'BackgroundColor', [0.1 0.1 0.4]);
                
                obj.profileObj(i) = line(curAx, 0, 0, drawZ, 'Tag', 'HistLineP2', 'Color', 'm', 'Visible', 'Off');
                
                obj.widthLineObj(i) = line(curAx, [x x], [y y], [drawZ drawZ], ...
                    'Tag', 'widthLine', 'Color', [0.5 0.5 1], 'LineWidth', 2, 'Visible', 'Off');
                
                obj.widthTxtObj(i) = text(curAx, 0, 0, drawZ, '', 'Tag', 'widthLineTxt', ...
                    'FontSize', 11, 'Color', [0.9 0.9 0.9], 'Visible', 'Off', ...
                    'HorizontalAlignment', 'center', 'BackgroundColor', [0.1 0.1 0.2]);
                
                % Assign Context Menu
                obj.distLineObj(i).ContextMenu = cm;
                obj.textObj(i).ContextMenu = cm;
            end
            
            % Set drawing callbacks
            obj.fig.WindowButtonMotionFcn = @(src, evt) obj.distLineInitDrawFcn(activeIdx);
            obj.fig.WindowButtonUpFcn = @(src, evt) obj.initDrawEndFcn();
            
            iptPointerManager(obj.fig, 'enable');
        end
        
        function distLineInitDrawFcn(obj, activeIdx)
            curAx = obj.ax(activeIdx);
            curAx.View = [0 90];
            camorbit(curAx, 0.01, 0.01);
            camorbit(curAx, -0.01, -0.01);
            
            distLinePoints = curAx.CurrentPoint;
            newX = distLinePoints(1,1);
            newY = distLinePoints(1,2);
            
            % Update all synced axes
            for i = 1:length(obj.ax)
                obj.distLineObj(i).XData(2) = newX;
                obj.distLineObj(i).YData(2) = newY;
                
                obj.distPoint2Obj(i).XData = newX;
                obj.distPoint2Obj(i).YData = newY;
                
                % Calculate distance & update text
                obj.dist = pdist([obj.distLineObj(i).XData, obj.distLineObj(i).YData], 'euclidean');
                centrePos = mean([obj.distLineObj(i).XData, obj.distLineObj(i).YData, obj.distLineObj(i).ZData + obj.txtZoffset]);
                
                obj.textObj(i).Position = centrePos;
                if obj.dist >= 1
                    obj.textObj(i).String = [num2str(round(obj.dist, obj.nDig)) obj.largeUnits];
                else
                    obj.textObj(i).String = [num2str(round(obj.dist*1000, 0)) obj.smallUnits];
                end
            end
        end
        
        function initDrawEndFcn(obj)
            % Restore original figure callbacks
            obj.fig.WindowButtonMotionFcn = obj.WindowButtonMotionFcnOrig;
            obj.fig.WindowButtonUpFcn = obj.WindowButtonUpFcnOrig;
            obj.fig.WindowScrollWheelFcn = obj.WindowScrollWheelFcnOrig;
            
            % Remove button down from control objects
            for i = 1:length(obj.ctrlObjs)
                obj.ctrlObjs(i).ButtonDownFcn = '';
            end
            
            % Setup Pointer Behaviors for all interactive objects across axes
            TextBehavior.enterFcn = @(hfig, cpp) obj.textObjIn(hfig);
            TextBehavior.traverseFcn = [];
            TextBehavior.exitFcn = @(hfig, cpp) obj.textObjOut(hfig);
            
            for i = 1:length(obj.ax)
                DistP1Behavior.enterFcn = @(hfig, cpp) obj.dragPointIn(obj.distPoint1Obj(i));
                DistP1Behavior.traverseFcn = [];
                DistP1Behavior.exitFcn = @(hfig, cpp) obj.dragPointOut(obj.distPoint1Obj(i));
                
                DistP2Behavior.enterFcn = @(hfig, cpp) obj.dragPointIn(obj.distPoint2Obj(i));
                DistP2Behavior.traverseFcn = [];
                DistP2Behavior.exitFcn = @(hfig, cpp) obj.dragPointOut(obj.distPoint2Obj(i));
                
                iptSetPointerBehavior(obj.distPoint1Obj(i), DistP1Behavior);
                iptSetPointerBehavior(obj.distPoint2Obj(i), DistP2Behavior);
                iptSetPointerBehavior(obj.textObj(i), TextBehavior);
                
                % Clear behaviors on delete
                obj.textObj(i).DeleteFcn = @(src, ~) iptSetPointerBehavior(src, []);
                obj.distPoint1Obj(i).DeleteFcn = @(src, ~) iptSetPointerBehavior(src, []);
                obj.distPoint2Obj(i).DeleteFcn = @(src, ~) iptSetPointerBehavior(src, []);
            end
            
            obj.fig.Pointer = 'arrow';
            
            % Destroy if distance is near zero (accidental click)
            if obj.dist < 0.001
                obj.deleteDistLine();
            end
            
            drawnow;
            for i = 1:length(obj.ax)
                enableDefaultInteractivity(obj.ax(i));
            end
        end
        
        function textObjIn(obj, hfig)
            if all(isvalid(obj.textObj))
                for i = 1:length(obj.textObj)
                    obj.textObj(i).ButtonDownFcn = @(src, evt) obj.moveTool(src, evt);
                end
                set(hfig, 'WindowScrollWheelFcn', @(src, evt) obj.zoomHist(evt));
            end
        end
        
        function textObjOut(obj, hfig)
            if all(isvalid(obj.textObj))
                for i = 1:length(obj.textObj)
                    set(obj.textObj(i), 'ButtonDownFcn', '');
                end
                set(hfig, 'WindowScrollWheelFcn', obj.WindowScrollWheelFcnOrig);
                drawnow;
                for i = 1:length(obj.ax)
                    enableDefaultInteractivity(obj.ax(i));
                end
            end
        end
        
        function dragPointIn(obj, hObj)
            if isvalid(hObj)
                set(hObj, 'MarkerSize', 8, 'MarkerFaceColor', obj.markerHighligthCol, ...
                    'ButtonDownFcn', @(src, evt) obj.distLinePointDragFcn(src, evt));
            end
        end
        
        function dragPointOut(obj, hObj)
            if isvalid(hObj)
                set(hObj, 'ButtonDownFcn', '', 'MarkerSize', 6, 'MarkerFaceColor', obj.markerCol);
                drawnow;
                enableDefaultInteractivity(hObj.Parent);
            end
        end
        
        function zoomHist(obj, evt)
            obj.maxHist = obj.maxHist - evt.VerticalScrollCount * obj.pixelSize;
            if obj.maxHist < 0
                obj.maxHist = 0;
            end
            if obj.maxHist > 100 * obj.pixelSize
                obj.maxHist = 100 * obj.pixelSize;
            end
            obj.updateProfilePlot();
        end
        
        function deleteDistLine(obj)
            delete(obj.exportFigObj);
            delete(obj.distPoint1Obj);
            delete(obj.distPoint2Obj);
            delete(obj.profileObj);
            set(obj.fig, 'WindowScrollWheelFcn', obj.WindowScrollWheelFcnOrig);
            delete(obj.textObj);
            delete(obj.distLineObj);
            delete(obj.widthLineObj);
            delete(obj.widthTxtObj);            
            delete(obj.listenersHandle)
            
            drawnow;
            for i = 1:length(obj.ax)
                if isvalid(obj.ax(i))
                    enableDefaultInteractivity(obj.ax(i));
                end
            end
        end
        
        function distLinePointDragFcn(obj, src, evt)
            if ~isequal(obj.fig.SelectionType, 'normal')
                return;
            end
            iptPointerManager(obj.fig, 'disable');
            
            activeAx = src.Parent;
            activeAx.View = [0 90];
            camorbit(activeAx, 0.01, 0.01);
            camorbit(activeAx, -0.01, -0.01);
            
            % Identify which point was clicked (1 or 2)
            pointerPos = evt.IntersectionPoint(1:2);
            distLinePoints = [obj.distLineObj(1).XData, obj.distLineObj(1).YData];
            Idx = knnsearch(distLinePoints, pointerPos);
            
            obj.fig.WindowButtonMotionFcn = @(s, e) motionFcn(s, e);
            obj.fig.WindowButtonUpFcn = @(s, e) motionEndFcn(s, e);
            
            function motionFcn(~, ~)
                currentPoint = activeAx.CurrentPoint;
                
                for i = 1:length(obj.ax)
                    obj.distLineObj(i).XData(Idx) = currentPoint(1,1);
                    obj.distLineObj(i).YData(Idx) = currentPoint(1,2);
                    
                    obj.distPoint1Obj(i).XData = obj.distLineObj(i).XData(2);
                    obj.distPoint1Obj(i).YData = obj.distLineObj(i).YData(2);
                    
                    obj.distPoint2Obj(i).XData = obj.distLineObj(i).XData(1);
                    obj.distPoint2Obj(i).YData = obj.distLineObj(i).YData(1);
                    
                    obj.dist = pdist([obj.distLineObj(i).XData, obj.distLineObj(i).YData], 'euclidean');
                    centrePos = mean([obj.distLineObj(i).XData + obj.xyTxtOffset, ...
                        obj.distLineObj(i).YData + obj.xyTxtOffset, ...
                        obj.distLineObj(i).ZData + obj.txtZoffset]);
                    
                    obj.textObj(i).Position = centrePos;
                    if obj.dist >= 1
                        obj.textObj(i).String = [num2str(round(obj.dist, obj.nDig)) obj.largeUnits];
                    else
                        obj.textObj(i).String = [num2str(round(obj.dist*1000, 0)) obj.smallUnits];
                    end
                end
                obj.updateProfilePlot();
            end
            
            function motionEndFcn(~, ~)
                obj.fig.WindowButtonMotionFcn = obj.WindowButtonMotionFcnOrig;
                obj.fig.WindowButtonUpFcn = obj.WindowButtonUpFcnOrig;
                iptPointerManager(obj.fig, 'enable');
                obj.updateProfilePlot();
                drawnow;
                for i = 1:length(obj.ax)
                    enableDefaultInteractivity(obj.ax(i));
                end
            end
        end
        
        function moveTool(obj, txtObj, evt)
            if evt.Button ~= 1
                return
            end
            
            activeAx = txtObj.Parent;
            activeAx.View = [0 90];
            camorbit(activeAx, 0.01, 0.01);
            camorbit(activeAx, -0.01, -0.01);
            
            pointerPos = evt.IntersectionPoint;
            txtObjInitPos = txtObj.Position;
            initOffset = (pointerPos - txtObjInitPos);
            
            initDistLineXData = obj.distLineObj(1).XData;
            initDistLineYData = obj.distLineObj(1).YData;
            
            obj.fig.WindowButtonMotionFcn = @toolMotionFcn;
            obj.fig.WindowButtonUpFcn = @moveToolEndFcn;
            
            function toolMotionFcn(~, ~)
                currentPos = activeAx.CurrentPoint(1,:);
                dragDist = (currentPos - txtObjInitPos) - initOffset;
                
                for i = 1:length(obj.ax)
                    obj.textObj(i).Position(1:2) = txtObjInitPos(1:2) + dragDist(1:2);
                    
                    obj.distLineObj(i).XData = initDistLineXData + dragDist(1);
                    obj.distLineObj(i).YData = initDistLineYData + dragDist(2);
                    
                    obj.distPoint1Obj(i).XData = obj.distLineObj(i).XData(2);
                    obj.distPoint1Obj(i).YData = obj.distLineObj(i).YData(2);
                    
                    obj.distPoint2Obj(i).XData = obj.distLineObj(i).XData(1);
                    obj.distPoint2Obj(i).YData = obj.distLineObj(i).YData(1);
                end
                obj.updateProfilePlot();
            end
            
            function moveToolEndFcn(~, ~)
                obj.fig.WindowButtonMotionFcn = obj.WindowButtonMotionFcnOrig;
                obj.fig.WindowButtonUpFcn = obj.WindowButtonUpFcnOrig;
                obj.updateProfilePlot();
            end
        end
        
        function updateProfilePlot(obj)
            if ~obj.showProfile
                return
            end
            
            % Line geometry is perfectly synced, so we can calculate the core math once
            x1 = obj.distPoint1Obj(1).XData;
            x2 = obj.distPoint2Obj(1).XData;
            y1 = obj.distPoint1Obj(1).YData;
            y2 = obj.distPoint2Obj(1).YData;
            
            intPoints = round(obj.dist / obj.pixelSize * 2);
            
            if x2 < x1
                x0 = x2; y0 = y2;
                xq = linspace(x2, x1, intPoints)';
                yq = linspace(y2, y1, intPoints)';
            else
                x0 = x1; y0 = y1;
                xq = linspace(x1, x2, intPoints)';
                yq = linspace(y1, y2, intPoints)';
            end
            
            slope = -(y2-y1)./(x2-x1);
            angle = atan(slope);
            R = [cos(angle) -sin(angle); sin(angle) cos(angle)];
            x = linspace(0, obj.dist, intPoints)';
            
            % Calculate and apply the profile independently for EACH axis
            for i = 1:length(obj.ax)
                if isempty(obj.imDouble{i})
                    continue; % Skip if no image data could be found
                end
                
                Vq = interp2(obj.imDouble{i}, xq./obj.pixelSize, yq./obj.pixelSize, 'cubic');
                Vq = normalize(Vq, 1, "range", [0 obj.maxHist]);
                Vq = obj.maxHist - Vq - obj.maxHist - obj.minHist;
                
                points = [x, Vq];
                pointsRot = points * R;
                
                obj.profileObj(i).XData = pointsRot(:,1) + x0;
                obj.profileObj(i).ZData = ones(size(obj.profileObj(i).XData)) .* (obj.z + obj.lineZOffset);
                obj.profileObj(i).YData = pointsRot(:,2) + y0;
                
                if obj.detectPeaks
                    xVect = x - x(1);
                    % [pks, lcs, w, p, wxPk] = findpeaksSK(-Vq, xVect, 'MinPeakProminence', 0.1, 'Annotate', 'extents');
                    [pks, lcs, w, p] = findpeaks(-Vq, xVect, 'MinPeakProminence', 0.1, 'Annotate', 'extents');

                    % clc
                    % pks
                    % lcs
                    % w
                    % wxPk
                    % p

                    % -Vq>p
                    
                    % wxPk
                    
                    if ~isempty(pks)
                        if size(pks,1) > 1
                            [~, peakInd] = max(pks);
                            pks = pks(peakInd);
                            lcs = lcs(peakInd);
                            w = w(peakInd);
                            p = p(peakInd);
                            % wxPk = wxPk(peakInd,:);
                            
                        end

                        wxPk(1) = lcs-w/2;
                        wxPk(2) = lcs+w/2;
                        % wxPk


                        peak_idx = find(xVect == lcs,1);
                        

                        Y_half_prom = -Vq(peak_idx) - (pks / 2);

                        % 2. Find all indices where the signal is above the threshold
                        above_threshold_indices = find(-Vq >= Y_half_prom);
                        
                        % 3. Get the first and last indices
                        idx_first = above_threshold_indices(1)+1;
                        idx_last  = above_threshold_indices(end)-1;

                        wxPk(1) = xVect(idx_first);
                        wxPk(2) = xVect(idx_last);
                        
                        % 4. Extract the values
                        % global_first_value = Yin(idx_first);
                        % global_last_value  = Yin(idx_last);

                        
                        peakWidth = w;
                        ypos = -(pks - p/2);
                        hwpmPoints = [wxPk(1), ypos; wxPk(2), ypos];
                        hwpmPointsRot = hwpmPoints * R;
                        
                        obj.widthLineObj(i).XData = hwpmPointsRot(:,1) + x0;
                        obj.widthLineObj(i).YData = hwpmPointsRot(:,2) + y0;
                        obj.widthLineObj(i).ZData = [obj.z + obj.lineZOffset, obj.z + obj.lineZOffset];
                        
                        if peakWidth >= 1
                            obj.widthTxtObj(i).String = [num2str(round(peakWidth, obj.nDig)) obj.largeUnits];
                        else
                            obj.widthTxtObj(i).String = [num2str(round(peakWidth*1000, 0)) obj.smallUnits];
                        end
                        
                        centrePoint = mean(hwpmPointsRot);
                        obj.widthTxtObj(i).Position = [centrePoint(1)+x0, centrePoint(2)+y0, obj.z + obj.lineZOffset + obj.txtZoffset];
                        
                        obj.widthLineObj(i).Visible = 'on';
                        obj.widthTxtObj(i).Visible = 'on';
                    else
                        obj.widthLineObj(i).Visible = 'off';
                        obj.widthTxtObj(i).Visible = 'off';
                    end
                else
                    obj.widthLineObj(i).Visible = 'off';
                    obj.widthTxtObj(i).Visible = 'off';
                end
                
                % Update Export Plot if active
                if obj.exportPeaks && obj.detectPeaks && isvalid(obj.exportFigObj)
                    obj.exportPlot(i).XData = x;
                    obj.exportPlot(i).YData = -Vq;
                    
                    if ~isempty(pks)
                        obj.exportWidth(i).XData = hwpmPoints(:,1);
                        obj.exportWidth(i).YData = -hwpmPoints(:,2);
                        
                        obj.exportWidthText(i).Position = [hwpmPoints(1,1)+w/2, -(hwpmPoints(1,2)+0.05), 0];
                        if peakWidth >= 1
                            obj.exportWidthText(i).String = [num2str(round(peakWidth, 3)) obj.largeUnits];
                        else
                            obj.exportWidthText(i).String = [num2str(round(peakWidth*1000, 0)) obj.smallUnits];
                        end
                    else
                        obj.exportWidth(i).XData = [];
                        obj.exportWidth(i).YData = [];
                    end
                end
            end
            
            % Close leftover orphan peak windows if disabled
            if ~obj.detectPeaks
                h = findobj('Name', 'Peaks detection');
                if ~isempty(h)
                    close(h)
                end
            end
            
            drawnow;
        end
        
        function showProfileFcn(obj, src)
            if src.Checked
                src.Checked = 0;
                obj.showProfile = 0;
                set(obj.profileObj, 'Visible', 'off');
                set(obj.widthLineObj, 'Visible', 'off');
                set(obj.widthTxtObj, 'Visible', 'off');
                
                % Uncheck Detect peaks if Profile is closed
                cm = obj.distLineObj(1).ContextMenu;
                h = findobj(cm.Children, 'Text', 'Detect peaks');
                if ~isempty(h), h.Checked = 0; end
            else
                src.Checked = 1;
                obj.showProfile = 1;
                obj.updateProfilePlot();
                
                % Only make histObj visible if we actually have image data to plot
                for i = 1:length(obj.ax)
                    if ~isempty(obj.imDouble{i})
                        obj.profileObj(i).Visible = 'on';
                    end
                end
            end
        end
        
        function detectPeaksFcn(obj, src)
            if src.Checked
                src.Checked = 0;
                obj.detectPeaks = 0;
                set(obj.widthLineObj, 'Visible', 'off');
                set(obj.widthTxtObj, 'Visible', 'off');
            else
                src.Checked = 1;
                obj.detectPeaks = 1;
                obj.updateProfilePlot();
                % They become visible inside updateProfilePlot if peaks found
            end
        end
        
        function exportPeakFcn(obj, src)
            if ~obj.detectPeaks
                return
            end
            
            if src.Checked
                src.Checked = 0;
                obj.exportPeaks = 0;
                h = findobj('Name', 'Peaks detection');
                if ~isempty(h), close(h); end
                if isvalid(obj.exportFigObj), close(obj.exportFigObj); end
            else
                src.Checked = 1;
                obj.exportPeaks = 1;
                
                obj.exportFigObj = uifigure("Name", 'Peaks detection', 'WindowStyle', 'alwaysontop', 'Tag', 'distMeasureFig');
                obj.exportFigObj.Position = [100, 100, 600, 400];
                obj.exportFigObj.CloseRequestFcn = @(s, e) obj.exportFigCloseReq();
                
                pos = obj.exportFigObj.Position;
                offset = 100;
                obj.exportAx = uiaxes('Parent', obj.exportFigObj, 'Position', [50, 50, pos(3)-offset, pos(4)-offset]);
                
                % Create plot lines for however many axes we are analyzing
                colors = lines(length(obj.ax));
                obj.exportAx.NextPlot = 'add';
                obj.exportPlot = gobjects(1, length(obj.ax));
                obj.exportWidth = gobjects(1, length(obj.ax));
                obj.exportWidthText = gobjects(1, length(obj.ax));
                
                for i = 1:length(obj.ax)
                    obj.exportPlot(i) = plot(obj.exportAx, [0 0], 'Color', colors(i,:));
                    obj.exportWidth(i) = line(obj.exportAx, [0 0], [0 0], 'Tag', 'widthLineB', 'Color', colors(i,:), 'LineWidth', 2, 'Visible', 'On');
                    obj.exportWidthText(i) = text(obj.exportAx, 0, 0, 0, '', 'Tag', 'widthLineTxt', 'FontSize', 11, 'Color', [0.9 0.9 0.9], 'Visible', 'On', 'HorizontalAlignment', 'center');
                end
                
                obj.updateProfilePlot();
            end
        end

        function dataChangedCallback(obj, src, event)
            % src is the property being listened to
            % event contains information about the change
            
            % disp('Data change detected.');
            
            % You can access the new image data through event.AffectedObject
            % newImage = event.AffectedObject.CData;

            for i = 1:2
                % obj.imageCell{i} = ctrlObjs(i).CData;
                obj.imDouble{i} = double(obj.ctrlObjs(i).CData);
            end
            
            obj.updateProfilePlot
        end
        
        function exportFigCloseReq(obj)
            obj.exportPeaks = 0;
            cm = obj.distLineObj(1).ContextMenu;
            h = findobj(cm.Children, 'Text', 'Export');
            
            if ~isempty(h)
                h.Checked = 0; 
            end

            delete(obj.exportFigObj);
        end
    end
end