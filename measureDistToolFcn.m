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

        nDig = 2;
        txtZoffset = 0.2;
        lineZOffset = 0.1;
        xyTxtOffset = 0.0;

        % pixelSize = 0.09678;

        % hiostogram attributes
        maxHist = 10*pixelSize;
        minHist = 2*pixelSize;

        showHist = 0;
        detectPeaks = 0;
        exportPeaks = 0;
       

        txtCol = [0.96 0.96 0.96];
           
        x = ax.CurrentPoint(1,1);
        y = ax.CurrentPoint(1,2);
        % z = ax.CurrentPoint(1,3) + 0;
        % z = 0.1;
        z = z + lineZOffset;
        lineCol = [0.6 0.6 0.8];
        markerCol = [0.7 0.7 0.9];
        markerHighligthCol = [1 0.7 0.9];
    
        distLineObj = patch(ax,[x x],[y y],[z z],lineCol,'Tag','DistLine','FaceLighting','none','LineWidth',2,...
                                    'BackFaceLighting','unlit','Marker','none','EdgeColor',lineCol);

        distPoint1Obj = patch(ax,x,y,z,lineCol,'Tag','DistLineP1','FaceLighting','none','LineWidth',2,'MarkerSize',6,...
                                    'BackFaceLighting','unlit','Marker','o','EdgeColor',lineCol,'MarkerFaceColor',markerCol);
     
        distPoint2Obj = patch(ax,x,y,z,lineCol,'Tag','DistLineP2','FaceLighting','none','LineWidth',2,'MarkerSize',6,...
                                    'BackFaceLighting','unlit','Marker','o','EdgeColor',lineCol,'MarkerFaceColor',markerCol);

        histObj = line(ax,0,0,z,'Tag','HistLineP2','Color','m','Visible','Off');

           
        % calculate distance between origin and end point of the distLine
        dist = pdist([distLineObj.XData,distLineObj.YData],'euclidean');
        
        % calculate centre positon of the line to place text object
        centrePos = mean([distLineObj.XData,distLineObj.YData,distLineObj.ZData]);          
        
        % create text object
        textObj = text(ax,centrePos(1),centrePos(2),z + txtZoffset,'','FontSize',11,'Color',txtCol,'Interpreter','tex');
                
        % update text
        textObj.String = [num2str(round(dist,nDig)) ' \mum'];
        textObj.BackgroundColor = [0.1 0.1 0.4];
             
        % associate for start drawing and end of drawing
        fig.WindowButtonMotionFcn = @(src,evt)distLineInitDrawFcn(src,evt);
        fig.WindowButtonUpFcn = @(src,evt)initDrawEndFcn(src,evt);
             
        cm = uicontextmenu(fig);               

        uimenu(cm,'Text','Delete measure tool','MenuSelectedFcn',@(src,evt)deleteDistLine(src,evt));
        uimenu(cm,'Text','Show profile','MenuSelectedFcn',@(src,evt)showProfileFcn(src,evt),'Checked',showHist);
        uimenu(cm,'Text','Detect peaks','MenuSelectedFcn',@(src,evt)detectPeaksFcn(src,evt),'Checked',detectPeaks);
        uimenu(cm,'Text','Export','MenuSelectedFcn',@(src,evt)exportFcn(src,evt),'Checked',detectPeaks);

        
        % assign menu to graphic components
        distLineObj.ContextMenu = cm;
        textObj.ContextMenu = cm;
       
        iptPointerManager(fig, 'enable');

        Idx = 1; 

        % Function perform the initial drawing. First point is always the
        % static point and the second point being updated
        function distLineInitDrawFcn(~,~)
         
            ax.View = [0 90];
            distLinePoints = ax.CurrentPoint;
       
            distLineObj.XData(Idx) = distLinePoints(1,1);
            distLineObj.YData(Idx) = distLinePoints(1,2);

            distPoint2Obj.XData = distLinePoints(1,1);
            distPoint2Obj.YData = distLinePoints(1,2);
    
            % update text position
            dist = pdist([distLineObj.XData,distLineObj.YData],'euclidean');
            centrePos = mean([distLineObj.XData,distLineObj.YData,distLineObj.ZData + txtZoffset]);            
            textObj.Position = centrePos;
    
            if dist >= 1
                textObj.String = [num2str(round(dist,nDig)) ' \mum'];
            else
                textObj.String = [num2str(round(dist*1000,0)) ' nm'];
            end
            
        end
    
        function initDrawEndFcn(fig,~)
                
            % assign back all original figure callbacks
            fig.WindowButtonDownFcn = WindowButtonDownFcnOrig;
            fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
            fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;
            % fig.WindowKeyPressFcn = [];
            fig.WindowKeyReleaseFcn = WindowKeyReleaseFcnOrig;
            fig.WindowScrollWheelFcn = WindowScrollWheelFcnOrig;

            distLineObj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);
            % assign callback to textObject (stored in UserDara of distLine)
            distPoint1Obj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);
            distPoint2Obj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt);

            textObj.ButtonDownFcn = @(src,evt)moveTool(src,evt);

           
            % hover behavior
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

            fig.Pointer = 'arrow';

            updateHistPlot

               
        end

        function zoomHist(~,evt)

            maxHist = maxHist - evt.VerticalScrollCount*pixelSize;
            % minHist = 2;

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
     
        end

    
        function distLinePointDragFcn(~,evt)
    
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            % ax.View = [0 89.9];
            ax.View = [0 90];
            
            distLinePoints = distLineObj.Vertices;            
            pointerPos = evt.IntersectionPoint;
                      
            % identify from each points the mouse click comes by chosing
            % the nearest one
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


        % function perform moving of the whole measure tool when draged by
        % text object
        function moveTool(txtObj,evt)

            
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            % ax.View = [0 89.9];
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

                d = (currentPos - txtObjInitPos) - initOffset;

                textObj.Position(1:2) = txtObjInitPos(1:2) + d(1:2);


                distLineObj.XData = initDistLineXData + d(1);
                distLineObj.YData = initDistLineYData + d(2);

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
           
            d = pdist([distLineObj.XData,distLineObj.YData],'euclidean');
         
            % nOf points on line to interpolate
            intPoints = round(d/pixelSize*4);
                    
            if x2 < x1
 
                slope = -(y2-y1)./(x2-x1);

                x0 = x2;
                y0 = y2;
                
                xq = linspace(x2,x1,intPoints)';
                yq = linspace(y2,y1,intPoints)';


            else
                
                slope = -(y2-y1)./(x2-x1);

                x0 = x1;
                y0 = y1;
                
                xq = linspace(x1,x2,intPoints)';
                yq = linspace(y1,y2,intPoints)';
            end

            angle = atan(slope);

            R = [cos(angle) -sin(angle); sin(angle) cos(angle)];

            V = double(im);
      
            Vq = interp2(V,xq./pixelSize,yq./pixelSize,'cubic');
            % Vq = interp2(V,xq./pixelSize,yq./pixelSize,'linear');

            Vq = normalize(Vq,1,"range",[0 maxHist]);
            Vq = maxHist-Vq - maxHist - minHist;
            
            x = linspace(0,d,intPoints)';
            clc
            points = [x Vq];
            
            % rotate points to align with measureDistTool orientation
            pointsRot = points*R;

            histObj.XData = pointsRot(:,1)+x0;
            histObj.ZData = ones(size(histObj.XData)).*z;
            histObj.YData = pointsRot(:,2)+y0;

            if detectPeaks

                
                % % if exportPeaks
                % h = findobj('Name','Peaks detection');
                % if isempty(h)
                %      figure('Name','Peaks detection')
                % end
                
                cla
                plot(-Vq)
    
                % xVect = xq - xq(1);
                xVect = x - x(1);
                % xVect = xq;
                findpeaks(-Vq,xVect,'MinPeakProminence',0.1,'Annotate','extents')
    
                
                [pks,locs,w,p] = findpeaks(-Vq,xVect,'MinPeakProminence',0.1,'Annotate','extents');

                if ~isempty(pks)
        

                    peakWidth = w(1);

                    % disp(['Peak half-maxima width = ' num2str(round(peakWidth,3))])
                    
                    ypos = -(pks(1) - p(1)/2);
                    xpos = locs(1) - w(1)/2;
        
                    line([xpos,xpos+w(1)],[ypos,ypos]);
        
                    % hwpmPoints = [xpos,ypos; xpos+w(1),ypos];
                    
                    
                    hwpmPoints = [xpos,ypos; xpos+w(1),ypos];
    
                    hwpmPointsRot = hwpmPoints*R;
    
    
                    % hwpmPoints = [xpos+x0,ypos+y0; xpos+x0+w(1),ypos+y0]
    
    
                    delete(findobj(ax,'Tag','tempWline'))
                    wLine = line(ax,hwpmPointsRot(:,1)+x0,(hwpmPointsRot(:,2)+y0),[z z],'Tag','tempWline','Color','b');


                    delete(findobj(ax,'Tag','tempWlineTxt'))
                    wTxt = text(ax,hwpmPointsRot(1,1)+x0,(hwpmPointsRot(1,2)+y0),z + txtZoffset,'','Tag','tempWlineTxt','FontSize',10,'Color',[0.9 0.9 0.9]);
                    wTxt.String = [num2str(round(peakWidth,3)) ' \mum'];
                else

                    delete(findobj(ax,'Tag','tempWlineTxt'))
                    delete(findobj(ax,'Tag','tempWline'))


                end
            else
                
                % close('Peaks detection')
                h = findobj('Name','Peaks detection');
                if ~isempty(h)
                
                    close(h)
                
                end

            
            end

            

            drawnow

        end


        function showProfileFcn(src,evt)

            if src.Checked
                src.Checked = 0;
                showHist = 0;
                histObj.Visible = 'off';
            else
                src.Checked = 1;
                showHist = 1;
                updateHistPlot
                histObj.Visible = 'on';
            end
            

            % get(src)

        end

        function detectPeaksFcn(src,evt)

            if src.Checked
                src.Checked = 0;
                detectPeaks = 0;
                % histObj.Visible = 'off';
                delete(findobj(ax,'Tag','tempWlineTxt'))
                delete(findobj(ax,'Tag','tempWline'))
                
            else
                src.Checked = 1;
                detectPeaks = 1;
                
                % histObj.Visible = 'on';
                % figure('Name','Peaks detection')
                updateHistPlot
            end
            

            % get(src)

        end

        function exportFcn(src,evt)


             if src.Checked
                src.Checked = 0;
                exportPeaks = 0;
                % histObj.Visible = 'off';
                % delete(findobj(ax,'Tag','tempWlineTxt'))
                % delete(findobj(ax,'Tag','tempWline'))

                 % close('Peaks detection')
                h = findobj('Name','Peaks detection');
                if ~isempty(h)
                
                    close(h)
                
                end
                
            else
                src.Checked = 1;
                exportPeaks = 1;
                
                % histObj.Visible = 'on';
                figure('Name','Peaks detection')
                updateHistPlot
            end

            

        end
    
    end

    

end






