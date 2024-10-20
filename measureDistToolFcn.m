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

        histObj = line(ax,0,0,z,'Tag','HistLineP2','Color','m');

           
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
            DistP1Behavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'DistLineP1'), 'MarkerSize',8,'MarkerFaceColor',markerHighligthCol);
            DistP1Behavior.traverseFcn = [];
            DistP1Behavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'DistLineP1'), 'MarkerSize',6,'MarkerFaceColor',markerCol); 

            DistP2Behavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'DistLineP2'), 'MarkerSize',8,'MarkerFaceColor',markerHighligthCol);
            DistP2Behavior.traverseFcn = [];
            DistP2Behavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'DistLineP2'), 'MarkerSize',6,'MarkerFaceColor',markerCol);

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

            maxHist = maxHist + evt.VerticalScrollCount*pixelSize;
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

            % size(V)

                       
            Vq = interp2(V,xq./pixelSize,yq./pixelSize,'cubic');
            % Vq = interp2(V,xq./pixelSize,yq./pixelSize,'linear');

            % Vq = Vq./20;
            % Vq = Vq - min(Vq);
            % Vq = -Vq;
            % maxHist

            Vq = normalize(Vq,1,"range",[0 maxHist]);
            Vq = maxHist-Vq - maxHist - minHist;
            
            x = linspace(0,d,intPoints)';
            
            points = [x Vq];
            
            pointsRot = points*R;

            histObj.XData = pointsRot(:,1)+x0;
            histObj.ZData = ones(size(histObj.XData)).*z;
            histObj.YData = pointsRot(:,2)+y0;

            drawnow

        end
    
    end

    

end






