% function create an interactive tool to measure distance between twou user selected points in axes,
% typically on image.


function measureDistToolFcn(fig,ax,z)

    % store original figure callbacks
    WindowButtonDownFcnOrig = fig.WindowButtonDownFcn;
    WindowButtonMotionFcnOrig = fig.WindowButtonMotionFcn;
    WindowButtonUpFcnOrig = fig.WindowButtonUpFcn;
    WindowKeyReleaseFcnOrig = fig.WindowKeyReleaseFcn;
    WindowScrollWheelFcnOrig = fig.WindowScrollWheelFcn;

       
    fig.WindowButtonUpFcn = [];
    fig.WindowButtonMotionFcn = [];
    fig.WindowButtonDownFcn = @(src,evt)startDistLine(src,evt,ax);

    fig.Pointer = 'crosshair';

    % function create distLine and text objects and activate motion
    % callbeck to draw the initial distance line tool
    function startDistLine(fig,~,ax)
    
        if ~isequal(fig.SelectionType,'normal')
            return;
        end

        nDig = 2;
        txtZoffset = 0.2;
        lineZOffset = 0.1;
        xyTxtOffset = 0.0;

        txtCol = [0.96 0.96 0.96];

        % z = ax.CurrentPoint(1,3)
    
        x = ax.CurrentPoint(1,1);
        y = ax.CurrentPoint(1,2);
        % z = ax.CurrentPoint(1,3) + 0;
        % z = 0.1;
        z = z + lineZOffset;
        lineCol = [0.6 0.6 0.8];
    
        distLineObj = patch(ax,[x x],[y y],[z z],lineCol,'Tag','DistLineP2','FaceLighting',...
                                    'none','BackFaceLighting','unlit');
        distLineObj.Marker = "o";
        distLineObj.EdgeColor = lineCol;
        distLineObj.FaceColor = lineCol;
        distLineObj.LineWidth = 2;
        
        % calculate distance between origin and end point of the distLine
        dist = pdist([distLineObj.XData,distLineObj.YData],'euclidean');
        
        % calculate centre positon of the line to place text object
        centrePos = mean([distLineObj.XData,distLineObj.YData,distLineObj.ZData]);            
        
        % create text object
        textObj = text(ax,centrePos(1),centrePos(2),z + txtZoffset,'','FontSize',11,'Color',txtCol,'Interpreter','tex');
        
        
        % update text
        textObj.String = [num2str(round(dist,nDig)) ' um'];
        textObj.BackgroundColor = [0.1 0.1 0.4];
        
        % assignt text object as user data of the distLine object to propagete
        distLineObj.UserData = textObj;

        % textObj.ButtonDownFcn = @(src,evt)moveTool(src,evt);
    
        % associate for start drawing and end of drawing
        fig.WindowButtonMotionFcn = @(src,evt)distLineInitDrawFcn(src,evt,ax,distLineObj);
        fig.WindowButtonUpFcn = @(src,evt)initDrawEndFcn(src,evt);
             
        cm = uicontextmenu(fig);               

        uimenu(cm,'Text','Delete measure tool','MenuSelectedFcn',@(src,evt)deleteDistLine(src,evt,distLineObj));
        distLineObj.ContextMenu = cm;
        textObj.ContextMenu = cm;

        Idx = 1; 

        % Function perform the initial drawing. First point is always the
        % static point and the second point being updated
        function distLineInitDrawFcn(~,~,ax,distLine)
         
            distLinePoints = ax.CurrentPoint;
       
            distLine.XData(Idx) = distLinePoints(1,1);
            distLine.YData(Idx) = distLinePoints(1,2);
    
            % update text position
            dist = pdist([distLine.XData,distLine.YData],'euclidean');
            centrePos = mean([distLine.XData,distLine.YData,distLine.ZData + txtZoffset]);            
            distLine.UserData.Position = centrePos;
    
            if dist >= 1
                distLine.UserData.String = [num2str(round(dist,nDig)) ' um'];
            else
                distLine.UserData.String = [num2str(round(dist*1000,0)) ' nm'];
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

            distLineObj.ButtonDownFcn = @(src,evt)distLinePointDragFcn(src,evt,fig,ax);
            % assign callback to textObject (stored in UserDara of distLine)
            distLineObj.UserData.ButtonDownFcn = @(src,evt)moveTool(src,evt);

            fig.Pointer = 'arrow';
               
        end

            
        function deleteDistLine(~,~,distLine)
        
                delete(distLine.UserData) % delete text object
                delete(distLine) % delete patch object
     
        end

    
        function distLinePointDragFcn(distLine,evt,fig,ax)
    
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            ax.View = [0 89.9];
            
            distLinePoints = distLine.Vertices;
            
            pointerPos = evt.IntersectionPoint;
                      
            % identify from each points the mouse click comes by chosing
            % the nearest one
            Idx = knnsearch(distLinePoints,pointerPos);
                        
            fig.WindowButtonMotionFcn = @(src,evt)motionFcn(src,evt,distLine);
            fig.WindowButtonUpFcn = @(src,evt)motionEndFcn(src,evt);
        
            
            function motionFcn(~,~,distLine)
                    
                currentPoint = ax.CurrentPoint;
           
                distLine.XData(Idx) = currentPoint(1,1);
                distLine.YData(Idx) = currentPoint(1,2);
        
                % update text position
                dist = pdist([distLine.XData,distLine.YData],'euclidean');
                
                centrePos = mean([distLine.XData + xyTxtOffset,distLine.YData + xyTxtOffset,distLine.ZData + txtZoffset]);         
                distLine.UserData.Position = centrePos;
        
                % update text string
                if dist >= 1
                    distLine.UserData.String = [num2str(round(dist,nDig)) ' um'];
                else
                    distLine.UserData.String = [num2str(round(dist*1000,0)) ' nm'];
                end
            
            end
        
        
            function motionEndFcn(fig,~)
                    
                fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
                fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;
                   
            end
 
        end


        % function perform moving of the whole measure tool when draged by
        % text object
        function moveTool(txtObj,evt)

            
            if ~isequal(fig.SelectionType,'normal')
                return;
            end

            ax.View = [0 89.9];
            
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

                distLineObj.UserData.Position(1:2) = txtObjInitPos(1:2) + d(1:2);


                distLineObj.XData = initDistLineXData + d(1);
                distLineObj.YData = initDistLineYData + d(2);
  

            end

            function moveToolEndFcn(fig,~)
                    
                fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
                fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;
                   
            end

        end
    
    end

end






