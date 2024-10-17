

function scaleBarFcn(fig,ax,pixelSize,zPos)

    % WindowButtonDownFcnOrig = fig.WindowButtonDownFcn;
    WindowButtonMotionFcnOrig = fig.WindowButtonMotionFcn;
    WindowButtonUpFcnOrig = fig.WindowButtonUpFcn;
    
    delete(findobj(ax,'Tag','scaleBar'))
    delete(findobj(ax,'Tag','scaleBarText'))
    
    % varargin
    if nargin == 2
        pixelSize = 1;
        zPos = 1;
    end
    
    initLength = round(ax.XLim(2)/10,0);
    % initLength = 5;
    % barLength = initLength*pixelSize
    barLength = initLength;
    barWidth = barLength/10;
    
    yTextOffset = 1.5*barWidth;
    

    xPos = 0.95*ax.XLim(2) - 5*pixelSize - barLength;
    yPos = 0.95*ax.YLim(2) - 5*pixelSize - 5*barWidth;


    x = [xPos xPos+barLength xPos+barLength xPos];
    y = [yPos yPos yPos+barWidth yPos+barWidth];
    z = [zPos zPos zPos zPos];
    
    scaleBarObj = fill3(ax,x,y,z,[1 1 1],'Tag','scaleBar','EdgeColor','none','LineWidth',1);
    scaleBarObj.ButtonDownFcn = @(src,evt)scaleBarFcn(src,evt);
    
    textObj = text(ax,xPos,yPos+yTextOffset,zPos,[num2str(initLength) ' \mum'],'Color',[0.9,0.9,0.9],'Tag','scaleBarText');
    textObj.VerticalAlignment = "cap";
    textObj.ButtonDownFcn = @(src,evt)scaleBarFcn(src,evt);
    
      
    % context menu
    cm = uicontextmenu(fig);
    
    uimenu(cm,'Text','Delete scale bar','MenuSelectedFcn',@(src,evt)deleteScaleBar(src,evt));
    cmLength = uimenu(cm,'Text','Set length');
    uimenu(cmLength,'Text','0.1 um','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',0.1);
    uimenu(cmLength,'Text','0.5 um','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',0.5);
    uimenu(cmLength,'Text','1 um','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',1);
    uimenu(cmLength,'Text','5 um','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',5);
    uimenu(cmLength,'Text','10 um','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',10);
    uimenu(cmLength,'Text','Custom length','MenuSelectedFcn',@(src,evt)lengthScaleBar(src,evt),'UserData',[]);

    uimenu(cm,'Text','Set width','MenuSelectedFcn',@(src,evt)widthScaleBar(src,evt),'UserData',[]);

    uimenu(cm,'Text','Scale bar color','MenuSelectedFcn',@(src,evt)scaleBarColor(src,evt),'UserData',[]);
    uimenu(cm,'Text','Text color','MenuSelectedFcn',@(src,evt)scaleBarColor(src,evt),'UserData',[]);
    uimenu(cm,'Text','Font size','MenuSelectedFcn',@(src,evt)textSizeFcn(src,evt),'UserData',[]);
    
    scaleBarObj.ContextMenu = cm;
    textObj.ContextMenu = cm;
    
    % hover behavior
    
    % BarBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'scaleBar'), 'EdgeColor','r');
    % BarBehavior.traverseFcn = [];
    % BarBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'scaleBar'), 'EdgeColor','none');
    
    % textBehavior.enterFcn =@(hfig, cpp)set(findobj(hfig, 'Tag', 'scaleBar'), 'EdgeColor','r');
    % textBehavior.traverseFcn = [];
    % textBehavior.exitFcn = @(hfig, cpp)set(findobj(hfig, 'Tag', 'scaleBar'), 'EdgeColor','none');
    
    BarBehavior.enterFcn =@(hfig, cpp)set(hfig,'Pointer','Fleur');
    BarBehavior.traverseFcn = [];
    BarBehavior.exitFcn = @(hfig, cpp)set(hfig,'Pointer','Arrow');
    
    textBehavior.enterFcn =@(hfig, cpp)set(hfig,'Pointer','Fleur');
    textBehavior.traverseFcn = [];
    textBehavior.exitFcn = @(hfig, cpp)set(hfig,'Pointer','Arrow');
    
    
    iptSetPointerBehavior(scaleBarObj , BarBehavior);
    iptSetPointerBehavior(textObj , textBehavior);
    
    iptPointerManager(fig, 'enable');
    
        function scaleBarFcn(~,evt)

            if ~isequal(fig.SelectionType,'normal')
                return;
            end
    
            InitPos = [xPos, yPos, zPos];
    
            pointerPos = evt.IntersectionPoint;
            
            initOffset = (pointerPos - InitPos);
      
            fig.WindowButtonMotionFcn = @moveFcn;
            fig.WindowButtonUpFcn = @moveEndFcn;
    
            function moveFcn(~,evt)
    
                xPos = evt.IntersectionPoint(1);
                yPos = evt.IntersectionPoint(2);  
        
                currentPos = ax.CurrentPoint(1,:);
                d = (currentPos - InitPos) - initOffset;
    
    
                xPos = InitPos(1) + d(1);
                yPos = InitPos(2) + d(2);
        
                updatePosition
    
            end
        
        end
    
        
    
        function updatePosition
    
            scaleBarObj.XData = [xPos xPos+barLength xPos+barLength xPos];
            scaleBarObj.YData = [yPos yPos yPos+barWidth yPos+barWidth];
    
            yTextOffset = 1.5*barWidth;
            textObj.Position = [xPos; yPos+yTextOffset;zPos];
    
        end
    
        function moveEndFcn(~,~)
    
            fig.WindowButtonMotionFcn = WindowButtonMotionFcnOrig;
            fig.WindowButtonUpFcn = WindowButtonUpFcnOrig;
    
        end
    
        function textSizeFcn(~,~)
    
            currentSize = textObj.FontSize;
    
            prompt = {'Enter text size'};
            dlgtitle = 'Length (\mum)';
            fieldsize = [1 35];
            definput = {num2str(currentSize)};
            opts.Interpreter = 'tex';
            answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);
    
            sz = str2double(answer{1});
            
            if isnan(sz)
                % uialert(fig,'Enter numeric value','Unknown input')
                disp('Enter numeric value')
                return
            else
    
                textObj.FontSize = sz;
    
            end
    
        end
    
        function lengthScaleBar(src,~)
    
    
                if isempty(src.UserData)
                    prompt = {'Enter length of scale bar in \mum'};
                    dlgtitle = 'Length (\mum)';
                    fieldsize = [1 35];
                    definput = {num2str(barLength)};
                    opts.Interpreter = 'tex';
                    answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);
    
                                        
                    if isempty(answer)
                        % uialert(fig,'Enter numeric value','Unknown input')
                        disp('enter numeric value')
                        return
                    end

                    L = str2double(answer{1});

                    if isnan(L)
                        return
                    end
                        
                    if isnumeric(L)

                        if L >(ax.XLim(2) - ax.XLim(1))
                            return
                        end
                        barLength = L;
                    else
                        
                        return
                    end
    
                                
                else
                    barLength = src.UserData;
                end
        
                textObj.String = [num2str(barLength) ' \mum'];
    
                updatePosition
    
        end

        function widthScaleBar(src,~)
    
    
                if isempty(src.UserData)
                    prompt = {'Enter width of scale bar in \mum'};
                    dlgtitle = 'Width (\mum)';
                    fieldsize = [1 35];
                    definput = {'1'};
                    opts.Interpreter = 'tex';
                    answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);
    
                    if isempty(answer)
                        % uialert(fig,'Enter numeric value','Unknown input')
                        disp('enter numeric value')
                        return
                    end

                    W = str2double(answer{1});
                    
                    if isnan(W)
                        % uialert(fig,'Enter numeric value','Unknown input')
                        disp('enter numeric value')
                        return
                    end
    
                    if isnumeric(W)
                        barWidth = W;
                    else
                        
                        return
                    end
    
                                
                else
                    barWidth = src.UserData;
                end
        
                updatePosition
    
        end
    
        function scaleBarColor(src,~)
    
            c = uisetcolor;
    
            if c == 0
                return
            end
          
            switch src.Text
    
                case 'Text color'
                    textObj.Color = c;
                case 'Scale bar color'
                    scaleBarObj.FaceColor = c;
            end
    
    
        end
    
        function deleteScaleBar(~,~)
    
            delete(textObj)
            delete(scaleBarObj)
    
        end


end