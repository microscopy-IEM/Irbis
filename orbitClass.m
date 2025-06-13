classdef orbitClass < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        hAx
        hFig
        startXonFig = [];
        startYonFig = [];
        azStart = [];
        elStart = [];
        observationDist = [];
        axPosStart = [];
        axZoom = [];
        angleStep = [];
        cameraTarget = []
        cameraPosition = [];
        inActiveArea = [];
        mode = [];
        axesInfo = [];
        startXonAxes = [];
        xMax2D = Inf;
        orbitOn = 1;
        origCallbacks = [];
    end

    methods
        function obj = orbitClass(varargin)

            ax = varargin{1};
            if nargin == 2
                mode = varargin{2};
            else
                mode(1:numel(ax)) = {'3D'};
            end

            % saveOrigCallbacks(obj);
            
            cax = 1;
            obj.hAx = ax(cax); 
            obj.hFig = ancestor(obj.hAx, 'figure');
            obj.mode = mode{cax};
            
            
            % Create and activate a pointer manager for the figure:
            iptPointerManager(obj.hFig, 'enable');

            for i = 1:numel(ax)

                cax = ax(i);
     
                pb.enterFcn = @(hFig,cp)obj.setActiveAxes(hFig,cp,true,cax);
                pb.exitFcn = @(hFig,cp)obj.setActiveAxes(hFig,cp,false,cax);
                pb.traverseFcn = [];
            
                % can be assigned to any graphical object (axes or uipanel...)
                iptSetPointerBehavior(cax,pb)

                cax.Units = "pixels";
                % cax.CameraViewAngleMode = 'manual';

                obj.axesInfo{i}.axh = cax;               
                obj.axesInfo{i}.mode = mode{i};                 
        
            end     

            % hPan = ancestor(obj.hAx, 'uipanel');
            % cax = hPan;
            % pb.enterFcn = @(hFig,cp)obj.setActiveAxes(hFig,cp,true,cax);
            % pb.exitFcn = @(hFig,cp)obj.setActiveAxes(hFig,cp,false,cax);
            % pb.traverseFcn = [];
            % % 
            % % can be assigned to any graphical object (axes or uipanel...)
            iptSetPointerBehavior(cax,pb)



                      
            obj.cameraTarget = camtarget(obj.hAx);
            obj.cameraPosition = campos(obj.hAx);
                 
            
            %% Default constants
            
            obj.angleStep = 5;                          
            obj.hAx.CameraViewAngleMode = 'manual'; % manual only for 3D
            obj.axZoom = obj.hAx.CameraViewAngle;
                        
            setCentreOfRotation(obj,obj.cameraTarget)            

            obj.setCallbacks            

        end

        function setCallbacks(obj)

            % switch obj.mode
            %     case '2D'
            %         obj.setCallbacks2D
            %     case '3D'
            %         obj.setCallbacks3D
            % end

            obj.hFig.WindowButtonDownFcn = @obj.actionBegin;
            obj.hFig.WindowButtonUpFcn = @obj.actionEnds;
            obj.hFig.WindowScrollWheelFcn = @obj.zoom;  
            obj.hFig.WindowKeyPressFcn = @obj.keyPressCallback3D;


        end

        % function setCallbacks3D(obj)
        % 
        %     % obj.hFig.WindowButtonDownFcn = @obj.actionBegin3D;
        %     obj.hFig.WindowButtonDownFcn = @obj.actionBegin;
        %     obj.hFig.WindowButtonUpFcn = @obj.actionEnds;
        %     % obj.hFig.WindowScrollWheelFcn = @obj.zoom3D;
        %     obj.hFig.WindowScrollWheelFcn = @obj.zoom;  
        %     obj.hFig.WindowKeyPressFcn = @obj.keyPressCallback3D;
        % 
        % end
        % 
        % function setCallbacks2D(obj)
        % 
        %     % obj.hFig.WindowButtonDownFcn = @obj.actionBegin2D;
        %     obj.hFig.WindowButtonDownFcn = @obj.actionBegin;
        %     obj.hFig.WindowButtonUpFcn = @obj.actionEnds;
        %     % obj.hFig.WindowScrollWheelFcn = @obj.zoom2D;    
        %     obj.hFig.WindowScrollWheelFcn = @obj.zoom;  
        %     obj.hFig.WindowKeyPressFcn = @obj.keyPressCallback2D;
        % 
        % end

        function removeCallbacks(obj)

            obj.hFig.WindowButtonDownFcn = [];
            obj.hFig.WindowButtonUpFcn = [];
            obj.hFig.WindowScrollWheelFcn = [];        
            obj.hFig.WindowKeyPressFcn = [];
            obj.hFig.WindowButtonMotionFcn = [];

        end

        function saveOrigCallbacks(obj)

            obj.origCallbacks.WindowButtonDownFcn   = obj.hFig.WindowButtonDownFcn;
            obj.origCallbacks.WindowButtonUpFcn     = obj.hFig.WindowButtonUpFcn;
            obj.origCallbacks.WindowScrollWheelFcn  = obj.hFig.WindowScrollWheelFcn;
            obj.origCallbacks.WindowKeyPressFcn     = obj.hFig.WindowKeyPressFcn;
            obj.origCallbacks.WindowButtonMotionFcn = obj.hFig.WindowButtonMotionFcn;           
            % obj.origCallbacks.WindowKeyReleaseFcn   = obj.hFig.WindowKeyReleaseFcn;
            % obj.origCallbacks.CreateFcn             = obj.hFig.CreateFcn;

        end

        function resetOrigCallbacks(obj)

            obj.hFig.WindowButtonDownFcn    = obj.origCallbacks.WindowButtonDownFcn;
            obj.hFig.WindowButtonUpFcn      = obj.origCallbacks.WindowButtonUpFcn;
            obj.hFig.WindowScrollWheelFcn   = obj.origCallbacks.WindowScrollWheelFcn;
            obj.hFig.WindowKeyPressFcn      = obj.origCallbacks.WindowKeyPressFcn;
            obj.hFig.WindowButtonMotionFcn  = obj.origCallbacks.WindowButtonMotionFcn;           
            % obj.hFig.WindowKeyReleaseFcn    = obj.origCallbacks.WindowKeyReleaseFcn;
            % obj.hFig.CreateFcn              = obj.origCallbacks.CreateFcn;


        end

        function switchOrbitOff(obj)

            obj.orbitOn = false;
            obj.removeCallbacks;
            % obj.resetOrigCallbacks;
            
        end

        function switchOrbitOn(obj)

            obj.orbitOn = true;

        end


        function selectObject(obj,src,evt)

            if evt.Button == 1
    
                h = findobj(obj.hAx,'Tag','meshObject');
                set(h,'EdgeColor',[0,0,0])
                set(h,'Selected','off')
        
                src.EdgeColor = [1 0 0];
        
                % new camera traget will be centre of the selected mesh object
                xct = mean(src.XData,'all');
                yct = mean(src.YData,'all');
                zct = mean(src.ZData,'all');
    
                newCentreOfRotation = [xct,yct,zct];
                setCentreOfRotation(obj,newCentreOfRotation)         
             
            end

        end

        function actionBegin(obj,src,~)

            switch obj.mode
                case '2D'
                    actionBegin2D(obj,src,[])
                case '3D'
                    actionBegin3D(obj,src,[])
            end

        end

        function actionBegin2D(obj,src,~)

            if ~obj.inActiveArea
                return
            end

            crd = get(obj.hAx, 'CurrentPoint');
            obj.startXonAxes = crd(1);

            clickType = get(src, 'SelectionType');
                
                switch clickType
                    case 'normal'               
                                                                           
                    case 'open'    
                                           
                    case 'alt'
                                                                       
                    case 'extend'
    
                        src.Pointer = 'left';                        
                        src.WindowButtonMotionFcn = @obj.dragPan2D;
                        
                end

        end

       
        function actionBegin3D(obj,src,~)

            if ~obj.inActiveArea
                return
            end

            crd = get(obj.hFig, 'CurrentPoint');
            obj.startXonFig = crd(1);
            obj.startYonFig = crd(2);
                
            % subtract origin (camera target) to convert cartesian to sherical system origin = camera_position-camera_target
    
            xd = obj.cameraPosition(1)-obj.cameraTarget(1);
            yd = obj.cameraPosition(2)-obj.cameraTarget(2);
            zd = obj.cameraPosition(3)-obj.cameraTarget(3);
            
            [obj.azStart,obj.elStart,obj.observationDist] = cart2sph(xd,yd,zd);        
    
            obj.axPosStart = obj.hAx.Position;
        
            clickType = get(src, 'SelectionType');
                
                switch clickType
                    case 'normal'
               
                        % resetCentreOfRotation(obj)                    
                                       
                    case 'open'
    
                        % obj.resetView()
                      
                    case 'alt'
                                             
                        src.Pointer = 'cross';
                        src.WindowButtonMotionFcn = @obj.dragRotate3D; 
                                      
                    case 'extend'
    
                        src.Pointer = 'hand';
                        src.WindowButtonMotionFcn = @obj.dragPan3D;              
                        
                end
            
        end

        function actionEnds(obj,~,~)
            obj.hFig.WindowButtonMotionFcn = [];
            obj.hFig.Pointer = 'arrow';
            % drawnow
            % 777
            % clc
            % pt = obj.hFig.Pointer
        end
    
        function dragRotate3D(obj,~, ~)

            if ~isequal(obj.mode,'3D')
                return
            end
        
            crd = get(obj.hFig, 'CurrentPoint');
            x = crd(1);
            y = crd(2);           
          
            % track the mouse drag distance
            dx = obj.startXonFig - x;
            dy = obj.startYonFig - y;     
    
            obj.startXonFig = x;
            obj.startYonFig = y;
                                   
            camorbit(obj.hAx,dx/obj.angleStep,dy/obj.angleStep)

            % text(obj.hAx,1,1,num2str(crd))
            % disp(obj.hAx.View)
          % crd
        end

        function dragPan3D(obj,~, ~)
       
            if ~obj.inActiveArea || ~isequal(obj.mode,'3D')
                return
            end
    
            crd = get(obj.hFig, 'CurrentPoint');
            x = crd(1);
            y = crd(2);
    
            % track the mouse drag distance
            dx = obj.startXonFig - x;
            dy = obj.startYonFig - y;
    
            axPosNew = [obj.axPosStart(1) - dx,obj.axPosStart(2) - dy,obj.axPosStart(3),obj.axPosStart(4)];
    
            obj.hAx.Position = axPosNew;

        end

        function dragPan2D(obj,~,~)

            if ~obj.inActiveArea || ~isequal(obj.mode,'2D')
                return
            end

            crd = get(obj.hAx, 'CurrentPoint');
            x = crd(1);
           
            % track the mouse drag distance
            dx = obj.startXonAxes - x;
           
            xlim = obj.hAx.XLim;
            newXLim = obj.hAx.XLim + dx;

            % obj.xMax = 40;
            xrange = xlim(2) - xlim(1);

            if newXLim(1) < 0
              newXLim = [0 xrange];
            end

            if newXLim(2) > obj.xMax2D
              newXLim = [obj.xMax2D-xrange obj.xMax2D];
            end           

            obj.hAx.XLim = newXLim;


        end

        function zoom(obj,src,evt)

            switch obj.mode
                case '2D'
                    zoom2D(obj,src,evt)
                case '3D'
                    zoom3D(obj,src,evt)
            end

        end

        function zoom2D(obj,~,evt)

            dir = evt.VerticalScrollCount;

            if ~obj.inActiveArea
                return
            end
    
            % obj.xMax = 40;            
            crd = get(obj.hAx, 'CurrentPoint');
            x = crd(1);               
                       
            xlim = obj.hAx.XLim;

            dL = x - xlim(1);
            dR = xlim(2) - x;            
            
            k = 0.1;

            newXLim = [xlim(1) - dir*dL*k, xlim(2) + dir*dR*k];

            newXLim(newXLim < 0) = 0;
            newXLim(newXLim > obj.xMax2D) = obj.xMax2D;
           
            obj.hAx.XLim = newXLim;


        end

        function zoom3D(obj,~,evt)
      
            if ~obj.inActiveArea
                return
            end
    
            crd = get(obj.hAx, 'CurrentPoint');
        
            cameraTarget_orig = obj.cameraTarget;
    
            xct = crd(2,1);
            yct = crd(2,2);
            zct = crd(2,3);
    
            obj.setCentreOfRotation([xct,yct,zct]) 
            
            obj.axZoom = obj.axZoom + evt.VerticalScrollCount*0.1*obj.axZoom;
    
            if obj.axZoom < 0.5
                obj.axZoom = 0.5;
            elseif obj.axZoom > 50
                obj.axZoom = 50;
    
            end
    
            obj.hAx.CameraViewAngle = obj.axZoom;   
            obj.setCentreOfRotation(cameraTarget_orig) 

        end

        function setCentreOfRotation(obj,newCentreOfRotation)
        
            axTightPosOld = obj.hAx.tightPosition;
           
            % new and old camera targets:
            camera_target_new = newCentreOfRotation;
            camera_target_old = obj.cameraTarget;              
        
            camera_position_old = campos(obj.hAx);
            
            % shift between old and new camera positions
            camPosShift = camera_target_old - camera_target_new;
    
            % camera must be shifted in parallel with camera target to maintain the view
            camera_position_new = camera_position_old - camPosShift; 
                     
            % save updated camera_position and camera_target and apply it on axes
            obj.cameraTarget = camera_target_new;
            obj.cameraPosition = camera_position_new;
            
            camtarget(obj.hAx,obj.cameraTarget)       
            campos(obj.hAx,camera_position_new)
                     
    
            % camtarget moves axes to centre - needs to be compensated by oposit shift:                
            axPosNew = obj.hAx.Position;
            axTightPosNew = obj.hAx.tightPosition;    
            posDiff = axTightPosNew - axTightPosOld;
        
            % Update axes position
            newAxPos = [axPosNew(1) - posDiff(1),axPosNew(2) - posDiff(2),axPosNew(3),axPosNew(4)];
            set(obj.hAx,'Position',newAxPos);
       
        end

        function resetCentreOfRotation(obj)
           
            % set centre of rotation to centre of axis
            xct = (obj.hAx.XLim(2)-obj.hAx.XLim(1))/2 + obj.hAx.XLim(1);
            yct = (obj.hAx.YLim(2)-obj.hAx.YLim(1))/2 + obj.hAx.YLim(1);
            zct = (obj.hAx.ZLim(2)-obj.hAx.ZLim(1))/2 + obj.hAx.ZLim(1);

            setCentreOfRotation(obj,[xct,yct,zct]);
       
        end

        function resetView(obj)
        
            obj.resetCentreOfRotation()
            % reset zoom
            obj.axZoom = 12;
            obj.hAx.CameraViewAngle = obj.axZoom;        
            obj.hAx.View = [0,90];
            % obj.hAx.View = [0,89.9];
            % 89

            % needed for not know reason to correcty zoom after reset view
            camorbit(obj.hAx,0.01,0.01)
            camorbit(obj.hAx,-0.01,-0.01)
               

            hPan = ancestor(obj.hAx, 'uipanel');
            % hPan.Position
            
            % reset position
            offset = 0;
            % sceneRect = obj.hFig.Position;
            sceneRect = hPan.Position;
            obj.hAx.Position = [offset,offset,sceneRect(3)-offset*2,sceneRect(4)-offset*2];
            
            % adjust camera position to the camera angle
            sceneWidth = obj.hAx.XLim(2)-obj.hAx.XLim(1);
            sceneHeight = obj.hAx.YLim(2)-obj.hAx.YLim(1);        
            longestSceneEdge = max([sceneWidth,sceneHeight]);
            obj.observationDist = longestSceneEdge/2/tand(obj.axZoom/2);
            xct = obj.cameraTarget(1);
            yct = obj.cameraTarget(2);
            campos(obj.hAx,[xct,yct,obj.observationDist])

            


      
        end

        function setActiveAxes(obj,src,cp,status,ax)
                      
            if ~obj.orbitOn
                return
            end
            
            obj.inActiveArea = status;
                      
            if status
    
                obj.hAx = ax;
                obj.axZoom = obj.hAx.CameraViewAngle;  
      
                for i = 1:2
                
                    if isequal(obj.axesInfo{i}.axh,ax)
                                        
                        obj.mode = obj.axesInfo{i}.mode;
    
                    end
                    
                end    
                
                % obj.setCallbacks

            else
                % obj.removeCallbacks
            end

        end

        function keyPressCallback3D(obj,~,evt)      
            
            dx = 0.05;
            zoomStep = 0.1;
            
            ctrlPressed = 0;
            shiftPressed = 0;
           
            if ~isempty(evt.Modifier)
                modifier = evt.Modifier{1};
                switch modifier
                    case 'control'
                        ctrlPressed = 1;
                        camera_target_old = obj.cameraTarget;
                    case 'shift'
                        shiftPressed = 1;
    
                end
            end
            
            % evt.Key                      
            
            switch evt.Key
            
                case 'leftarrow'
                    if ctrlPressed
                        camdolly(obj.hAx,dx,0,0)
                    else
                        camorbit(obj.hAx,obj.angleStep,0)
                    end
                case 'rightarrow'
                    if ctrlPressed
                        camdolly(obj.hAx,-dx,0,0)
                    else
                        camorbit(obj.hAx,-obj.angleStep,0)
                    end
                case 'uparrow'
                    if ctrlPressed
                        camdolly(obj.hAx,0,-dx,0)
                    elseif shiftPressed
                        obj.axZoom = obj.axZoom - zoomStep*obj.axZoom;
                        obj.hAx.CameraViewAngle = obj.axZoom; 
                    else
                        camorbit(obj.hAx,0,-obj.angleStep)
                    end
                case 'downarrow'
                    if ctrlPressed
                        camdolly(obj.hAx,0,dx,0)
                    elseif shiftPressed
                        obj.axZoom = obj.axZoom + zoomStep*obj.axZoom;
                        obj.hAx.CameraViewAngle = obj.axZoom;
                    else
                        camorbit(obj.hAx,0,obj.angleStep)
                    end

                case 'r'
                    if ctrlPressed
                        obj.resetView
                    end

            end

            % disp(obj.hAx.View)
            

            if ctrlPressed
                % TO OPTIMIZE move this to keyRelease callback later
                obj.setCentreOfRotation(camera_target_old)
            end
            
           
        end

        function keyPressCallback2D(obj,src,evt) 



        end
    end
end