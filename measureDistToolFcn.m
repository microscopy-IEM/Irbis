% function create an interactive tool to measure distance between twou user selected points in axes,
% typically on image.

function measureDistToolFcn(fig,ax,z,im,pixelSize)

    % store original figure callbacks
    WindowButtonDownFcnOrig = fig.WindowButtonDownFcn;
    WindowButtonMotionFcnOrig = fig.WindowButtonMotionFcn;
    WindowButtonUpFcnOrig = fig.WindowButtonUpFcn;
    WindowKeyReleaseFcnOrig = fig.WindowKeyReleaseFcn;
    WindowScrollWheelFcnOrig = fig.WindowScrollWheelFcn;
       
    fig.WindowButtonUpFcn = [];
    fig.WindowButtonMotionFcn = [];
    fig.WindowButtonDownFcn = @(src,evt)startDistLine(src,evt);

    fig.Pointer = 'crosshair';

    % function create distLine and text objects and activate motion
    % callbeck to draw the initial distance line tool
    function startDistLine(fig,~)
    
        if ~isequal(fig.SelectionType,'normal')
            return;
        end
      
        nDig = 2; % number of digits to round distance values
        txtZoffset = 0.2;
        lineZOffset = 0.1;
        xyTxtOffset = 0.0;

        % hiostogram attributes
        maxHist = 10*pixelSize;
        minHist = 2*pixelSize;
 
        % in default only measure distance, profile function are set to off
        showHist = 0;
        detectPeaks = 0;
        exportPeaks = 0;       

        distTxtCol = [0.96 0.96 0.96];
           
        x = ax.CurrentPoint(1,1);
        y = ax.CurrentPoint(1,2);
        % z = ax.CurrentPoint(1,3) + 0;
        % z = 0.1;
        z = z + lineZOffset;
        lineCol = [0.6 0.6 0.8];
        markerCol = [0.7 0.7 0.9];
        markerHighligthCol = [1 0.7 0.9];
    
        % create graphical objects of the measureDist tool
        distLineObj = patch(ax,[x x],[y y],[z z],lineCol,'Tag','DistLine','FaceLighting','none','LineWidth',2,...
                                    'BackFaceLighting','unlit','Marker','none','EdgeColor',lineCol);

        distPoint1Obj = patch(ax,x,y,z,lineCol,'Tag','DistLineP1','FaceLighting','none','LineWidth',2,'MarkerSize',6,...
                                    'BackFaceLighting','unlit','Marker','o','EdgeColor',lineCol,'MarkerFaceColor',markerCol);
     
        distPoint2Obj = patch(ax,x,y,z,lineCol,'Tag','DistLineP2','FaceLighting','none','LineWidth',2,'MarkerSize',6,...
                                    'BackFaceLighting','unlit','Marker','o','EdgeColor',lineCol,'MarkerFaceColor',markerCol);

        textObj = text(ax,0,0,z,'','FontSize',11,'Color',distTxtCol,'Interpreter','tex');
 
        histObj = line(ax,0,0,z,'Tag','HistLineP2','Color','m','Visible','Off');

        widthLineObj = line(ax,[x x],[y y],[z z],'Tag','widthLine','Color',[0.5 0.5 1],'LineWidth',2,'Visible','Off');
        widthTxtObj = text(ax,0,0,z,'','Tag','widthLineTxt','FontSize',11,'Color',[0.9 0.9 0.9],'Visible','Off');

        % pre-define variable to handle peak export figure
        exportFigObj = [];
        exportAx = [];
        exportPlot = [];
        exportWidth = [];
           
        % define main variable t o keep distance between origin and end point of the distLine
        dist = 0;
        
        % calculate centre positon of the line to place text object
        centrePos = [x,y,z];    
        
        % update text object text and position        
        textObj.Position = [centrePos(1),centrePos(2),z + txtZoffset];
        textObj.String = '0 \mum';
        textObj.BackgroundColor = [0.1 0.1 0.4];
             
        % associate for start drawing and end of drawing
        fig.WindowButtonMotionFcn = @(src,evt)distLineInitDrawFcn(src,evt);
        fig.WindowButtonUpFcn = @(src,evt)initDrawEndFcn(src,evt);
        
        % define context menu
        cm = uicontextmenu(fig);               

        uimenu(cm,'Text','Delete measure tool','MenuSelectedFcn',@(src,evt)deleteDistLine(src,evt));
        uimenu(cm,'Text','Show profile','MenuSelectedFcn',@(src,evt)showProfileFcn(src,evt),'Checked',showHist);
        uimenu(cm,'Text','Detect peaks','MenuSelectedFcn',@(src,evt)detectPeaksFcn(src,evt),'Checked',detectPeaks);
        uimenu(cm,'Text','Export','MenuSelectedFcn',@(src,evt)exportPeakFcn(src,evt),'Checked',detectPeaks);
        
        % assign menu to graphical components
        distLineObj.ContextMenu = cm;
        textObj.ContextMenu = cm;
       
        % Ensure to enable hover function in figure
        iptPointerManager(fig, 'enable');

        Idx = 1; 

        % Function perform the initial drawing. First point is always the
        % static point and the second point being updated
        % function called when the initial drawing starts (mouse button pressed)
        function distLineInitDrawFcn(~,~)
         
            ax.View = [0 90];
            distLinePoints = ax.CurrentPoint;
       
            distLineObj.XData(Idx) = distLinePoints(1,1);
            distLineObj.YData(Idx) = distLinePoints(1,2);

            distPoint2Obj.XData = distLinePoints(1,1);
            distPoint2Obj.YData = distLinePoints(1,2);
    
            % update text position during initial drawing
            dist = pdist([distLineObj.XData,distLineObj.YData],'euclidean');
            centrePos = mean([distLineObj.XData,distLineObj.YData,distLineObj.ZData + txtZoffset]);            
            textObj.Position = centrePos;
    
            % show um for longer distances and nm for short
            if dist >= 1
                textObj.String = [num2str(round(dist,nDig)) ' \mum'];
            else
                textObj.String = [num2str(round(dist*1000,0)) ' nm'];
            end
            
        end
    
        % function called when the initial drawing ends (mouse button released)
        function initDrawEndFcn(fig,~)
                
            % assign back all original figure callbacks
            fig.WindowButtonDownFcn = WindowButtonDownFcnOrig;
            fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
            fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;
            % fig.WindowKeyPressFcn = [];
            fig.WindowKeyReleaseFcn = WindowKeyReleaseFcnOrig;
            fig.WindowScrollWheelFcn = WindowScrollWheelFcnOrig;

            % assign callbacks to distLine objects that execute draging by selected edn points
            distLineObj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);            
            distPoint1Obj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);
            distPoint2Obj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);

            % assign callback that execute draging the alle objects together
            textObj.ButtonDownFcn = @(src,evt)moveTool(src,evt);
           
            % set pointer hover over graphical objects behavior
            DistP1Behavior.enterFcn =@(hfig, cpp)set(distPoint1Obj, 'MarkerSize',8,'MarkerFaceColor',markerHighligthCol);
            DistP1Behavior.traverseFcn = [];
            DistP1Behavior.exitFcn = @(hfig, cpp)set(distPoint1Obj, 'MarkerSize',6,'MarkerFaceColor',markerCol); 

            DistP2Behavior.enterFcn =@(hfig, cpp)set(distPoint2Obj, 'MarkerSize',8,'MarkerFaceColor',markerHighligthCol);
            DistP2Behavior.traverseFcn = [];
            DistP2Behavior.exitFcn = @(hfig, cpp)set(distPoint2Obj, 'MarkerSize',6,'MarkerFaceColor',markerCol);

            TextBehavior.enterFcn = @(hfig, cpp)set(hfig, 'WindowScrollWheelFcn',@(src,evt)zoomHist(src,evt));
            TextBehavior.traverseFcn = [];
            TextBehavior.exitFcn = @(hfig, cpp)set(hfig, 'WindowScrollWheelFcn',WindowScrollWheelFcnOrig);
         
            iptSetPointerBehavior(distPoint1Obj , DistP1Behavior);
            iptSetPointerBehavior(distPoint2Obj , DistP2Behavior);
            iptSetPointerBehavior(textObj , TextBehavior);

            % set pointer back to arrow
            fig.Pointer = 'arrow';

            % if no distance was set by mouse during initial drag (accidental single click), delete the tool.
            if dist < 0.001
                deleteDistLine
            end
                           
        end

        % function modify plotted profile amplitude by mouse wheel interaction
        function zoomHist(~,evt)

            maxHist = maxHist - evt.VerticalScrollCount*pixelSize;

            if maxHist < 0
                maxHist = 0;
            end

            if maxHist > 100*pixelSize
                maxHist = 100*pixelSize;
            end

            updateHistPlot

        end
            
        function deleteDistLine(~,~)
        
                delete(distPoint1Obj)
                delete(distPoint2Obj)   
                delete(histObj)
                delete(textObj) % delete text object
                delete(distLineObj) % delete patch object
                delete(widthLineObj)
                delete(widthTxtObj)
                delete(exportFigObj)
     
        end
    
        function distLinePointDragFcn(~,evt)
    
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            ax.View = [0 90];
            
            distLinePoints = distLineObj.Vertices;            
            pointerPos = evt.IntersectionPoint;
                      
            % identify from each points the mouse click comes by chosing the nearest one
            Idx = knnsearch(distLinePoints,pointerPos);
                        
            fig.WindowButtonMotionFcn = @(src,evt)motionFcn(src,evt);
            fig.WindowButtonUpFcn = @(src,evt)motionEndFcn(src,evt);
                    
            function motionFcn(~,~)
                    
                currentPoint = ax.CurrentPoint;
           
                distLineObj.XData(Idx) = currentPoint(1,1);
                distLineObj.YData(Idx) = currentPoint(1,2);

                distPoint1Obj.XData = distLineObj.XData(2);
                distPoint1Obj.YData = distLineObj.YData(2);

                distPoint2Obj.XData = distLineObj.XData(1);
                distPoint2Obj.YData = distLineObj.YData(1);
        
                % update text position
                dist = pdist([distLineObj.XData,distLineObj.YData],'euclidean');                
                centrePos = mean([distLineObj.XData + xyTxtOffset,distLineObj.YData + xyTxtOffset,distLineObj.ZData + txtZoffset]);         
                textObj.Position = centrePos;
        
                % update text string
                if dist >= 1
                    textObj.String = [num2str(round(dist,nDig)) ' \mum'];
                else
                    textObj.String = [num2str(round(dist*1000,0)) ' nm'];
                end

                updateHistPlot                
            
            end        
        
            function motionEndFcn(~,~)
                    
                fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
                fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;

                updateHistPlot
                drawnow
                   
            end
 
        end

        % function perform moving of the whole measure tool when draged by text object
        function moveTool(txtObj,evt)
            
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            ax.View = [0 90];
            
            pointerPos = evt.IntersectionPoint;

            txtObjInitPos = txtObj.Position;
            initOffset = (pointerPos - txtObjInitPos);

            initDistLineXData = distLineObj.XData;
            initDistLineYData = distLineObj.YData;
            
            fig.WindowButtonMotionFcn = @toolMotionFcn;
            fig.WindowButtonUpFcn = @(src,evt)moveToolEndFcn(src,evt);

            function toolMotionFcn(~,~)

                currentPos = ax.CurrentPoint(1,:);

                dragDist = (currentPos - txtObjInitPos) - initOffset;

                textObj.Position(1:2) = txtObjInitPos(1:2) + dragDist(1:2);

                distLineObj.XData = initDistLineXData + dragDist(1);
                distLineObj.YData = initDistLineYData + dragDist(2);

                distPoint1Obj.XData = distLineObj.XData(2);
                distPoint1Obj.YData = distLineObj.YData(2);
    
                distPoint2Obj.XData = distLineObj.XData(1);
                distPoint2Obj.YData = distLineObj.YData(1);

                updateHistPlot                
  
            end

            function moveToolEndFcn(fig,~)
                    
                fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
                fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;

                updateHistPlot
                                  
            end

        end

        function updateHistPlot()
                        
            if ~showHist
                return
            end

            x1 = distPoint1Obj.XData;
            x2 = distPoint2Obj.XData;
            y1 = distPoint1Obj.YData;
            y2 = distPoint2Obj.YData;      
                     
            % n of points on line to interpolate
            intPoints = round(dist/pixelSize*4);
                    
            % distinguish "left" and "right" point
            if x2 < x1
                
                x0 = x2;
                y0 = y2;
                
                xq = linspace(x2,x1,intPoints)';
                yq = linspace(y2,y1,intPoints)';

            else                
                
                x0 = x1;
                y0 = y1;
                
                xq = linspace(x1,x2,intPoints)';
                yq = linspace(y1,y2,intPoints)';
            end

            % get angle from line slope
            slope = -(y2-y1)./(x2-x1);
            angle = atan(slope);

            % assemble rotation matrix
            R = [cos(angle) -sin(angle); sin(angle) cos(angle)];

            V = double(im);
      
            Vq = interp2(V,xq./pixelSize,yq./pixelSize,'cubic');
            % Vq = interp2(V,xq./pixelSize,yq./pixelSize,'linear');

            Vq = normalize(Vq,1,"range",[0 maxHist]);
            Vq = maxHist-Vq - maxHist - minHist;
            
            x = linspace(0,dist,intPoints)';
            
            points = [x Vq];
             
            % rotate points to align with measureDistTool orientation
            pointsRot = points*R;

            histObj.XData = pointsRot(:,1)+x0;
            histObj.ZData = ones(size(histObj.XData)).*z;
            histObj.YData = pointsRot(:,2)+y0;

            if detectPeaks

                xVect = x - x(1);
               
                [pks,~,w,p,wxPk] = findpeaksSK(-Vq,xVect,'MinPeakProminence',0.1,'Annotate','extents','SortStr','descend');

                if ~isempty(pks) 
        
                    peakInd = 1;
                    peakWidth = w(peakInd);
    
                    ypos = -(pks(peakInd) - p(peakInd)/2);
        
                    xpos1 = wxPk(1,1);
                    xpos2 = wxPk(1,2);
                 
                    hwpmPoints = [xpos1,ypos; xpos2,ypos];
    
                    % rotate points
                    hwpmPointsRot = hwpmPoints*R;   
        
                    widthLineObj.XData = (hwpmPointsRot(:,1)+x0);
                    widthLineObj.YData = (hwpmPointsRot(:,2)+y0);
                    widthLineObj.ZData = [z z];    
                   
                    widthTxtObj.String = [num2str(round(peakWidth,3)) ' \mum'];
                    widthTxtObj.Position = [hwpmPointsRot(1,1)+x0,(hwpmPointsRot(1,2)+y0),z + txtZoffset];

                    widthLineObj.Visible = 'on';
                    widthTxtObj.Visible = 'on';

                else
    
                    widthLineObj.Visible = 'off';
                    widthTxtObj.Visible = 'off';
    
                end


            else

                % close('Peaks detection')
                h = findobj('Name','Peaks detection');
                if ~isempty(h)

                    close(h)

                end

            end

            if exportPeaks && detectPeaks
               
                exportPlot.XData = x;
                exportPlot.YData = -Vq;
                
                if ~isempty(pks) 
                    exportWidth.XData = (hwpmPoints(:,1)+0);
                    exportWidth.YData = -(hwpmPoints(:,2)+0);
                else
                    exportWidth.XData = [];
                    exportWidth.YData = [];
                end
               
            end            

            drawnow

        end

        function showProfileFcn(src,~)

            if src.Checked
                src.Checked = 0;
                showHist = 0;
                histObj.Visible = 'off';
                widthLineObj.Visible = 'off';
                widthTxtObj.Visible = 'off';

                h = findobj(distLineObj.ContextMenu.Children,'Text','Detect peaks');
                h.Checked = 0;
            else
                src.Checked = 1;
                showHist = 1;
                updateHistPlot
                histObj.Visible = 'on';                
            end
            
        end

        function detectPeaksFcn(src,~)
            
            if src.Checked
                src.Checked = 0;
                detectPeaks = 0;

                widthLineObj.Visible = 'off';
                widthTxtObj.Visible = 'off';

                
            else
                src.Checked = 1;
                detectPeaks = 1;

                updateHistPlot        
      
                widthLineObj.Visible = 'on';
                widthTxtObj.Visible = 'on';
            end
    
        end
  
        function exportPeakFcn(src,~)

             if ~detectPeaks
                 return
             end   

             if src.Checked
                src.Checked = 0;
                exportPeaks = 0;
            
                 % close('Peaks detection')
                h = findobj('Name','Peaks detection');
                if ~isempty(h)
                
                    close(h)
                
                end

                close(exportFigObj)
                
            else
                src.Checked = 1;
                exportPeaks = 1;
                                                

                exportFigObj = uifigure("Name",'Peaks detection','WindowStyle','alwaysontop','Tag','distMeasureFig');
                exportFigObj.Position = [100,100,600,400];
                exportFigObj.CloseRequestFcn = @exportFigCloseReq;
                pos = exportFigObj.Position;
                offset = 100;
                exportAx = uiaxes('Parent',exportFigObj,'Position',[50,50,pos(3)-offset,pos(4)-offset]);

                exportPlot = plot(exportAx,[0,0]);
                exportAx.NextPlot = 'add';
                exportWidth = line(exportAx,[0 0],[0 0],'Tag','widthLineB','Color',[0.5 0.5 1],'LineWidth',2,'Visible','On');
                updateHistPlot

             end           

        end

        function exportFigCloseReq(~,~)
             
            exportPeaks = 0;
          
            h = findobj(distLineObj.ContextMenu.Children,'Text','Export');
            h.Checked = 0;
            delete(exportFigObj)

        end
    
    end
    
end






