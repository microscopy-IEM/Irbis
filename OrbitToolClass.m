classdef OrbitToolClass < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        hAx     % currently active axes
        hFig    % figure containing the axes
        startXonFig = [];   % x position of the mouse when the action begins, 2D, in pixels
        startYonFig = [];   % y position of the mouse when the action begins, 2D, in pixels
        axPosStart = [];   % starting position of the axes
        axZoom = [];   % zoom level of the axes
        angleStep = 5;   % step size for rotating the view
        cameraTarget = [];
        cameraPosition = [];
        inActiveArea = false;  % whether the mouse is in the active area of any of the axes
        mode = [];  % '2D' or '3D' - mode of the active axes
        existingAxes = [];
        startXonAxes = [];
        xMin2D = 0;
        xMax2D = Inf;
        marginFraction2D = 0.05; % when fitting the selection ROI in a 2D histogram axes, empty area on the sides is added
            % the length of the area corresponds to limit range times the margin
        orbitOn = 1;
        origCallbacks = [];
        keypressExtension = [];
        keyreleaseExtension = [];

        timerActive = false;
        timerFcn = [];
        timerHandle = [];
        timerDelay = 0.2;
        releaseFcnTriggered = false;

        resettableAxes = [];  % axes that can be reset to the original position using resetView
        
    end

    methods

        function obj = OrbitToolClass(varargin)

            axes = varargin{1};
            if nargin == 2
                modes = varargin{2};
            else
                modes(1:numel(axes)) = {'3D'};
            end

            % make the first axes active
            activeId = 1;
            obj.hAx = axes(activeId); 
            obj.hFig = ancestor(obj.hAx, 'figure');
            obj.mode = modes{activeId};
            obj.axZoom = obj.hAx.CameraViewAngle;
            obj.hAx.CameraViewAngleMode = 'manual'; % manual only for 3D
            
            % obj.inActiveArea = false

            % Create and activate a pointer manager for the figure:
            iptPointerManager(obj.hFig, 'enable');

            for i = 1:numel(axes)

                cax = axes(i);
                obj.setHoveringBehavior(cax);

                % cax.Units = "pixels";

                obj.existingAxes{i}.handle = cax;               
                obj.existingAxes{i}.mode = modes{i};                 
            end

            obj.cameraTarget = camtarget(obj.hAx);
            obj.cameraPosition = campos(obj.hAx);
                 
            obj.setCentreOfRotation(obj.cameraTarget); 

            obj.saveOrigCallbacks;
            obj.setCallbacks;   

            obj.setActiveAxes(obj.hAx, false);


        end


        function setResettableAxes(obj, axes)
            % axes should be either empty array or an array of axes handles accessible with ()
            obj.resettableAxes = axes;
        end


        function setHoveringBehavior(obj, ax)

            % set the pointer behavior for hovering over the axes - activates the axes under cursor
            behavior.enterFcn = @(~, ~)obj.setActiveAxes(ax, true);
            behavior.exitFcn = @(~, ~)obj.setActiveAxes(ax, false);
            behavior.traverseFcn = [];

            % behavior can be assigned to any graphical object (axes or uipanel...)
            iptSetPointerBehavior(ax, behavior);
        end


        function utilizeTimer(obj, timerFcn, timerDelay)

            % at the moment intended only for 3D plot
            % TO OPTIMIZE: enable individual timer settings for each axes
            obj.timerActive = true;
            if nargin > 2
                obj.timerDelay = timerDelay;
            end
            obj.timerFcn = timerFcn;

            % singleShot means that it will be executed only once
            obj.timerHandle = timer( ...
                'ExecutionMode','singleShot', ...
                'StartDelay',timerDelay, ...             % debounce window (tune 0.15–0.35 s)
                'TimerFcn', obj.timerFcn);
        end


        function deactivateTimer(obj)
            obj.timerActive = false;
        end


        function activateTimer(obj)
            obj.timerActive = true;
        end


        function delete(obj)
            if obj.timerActive && isvalid(obj.timerHandle)
                stop(obj.timerHandle);
                delete(obj.timerHandle);
            end
        end


        function setCallbacks(obj)

            obj.hFig.WindowButtonDownFcn = @(src, ~) obj.actionBegins(src);
            obj.hFig.WindowButtonUpFcn = @(~, ~) obj.actionEnds();
            obj.hFig.WindowScrollWheelFcn = @(~, evt) obj.zoom(evt);  
            obj.hFig.WindowKeyPressFcn = @(~, evt) obj.keyPressed(evt);
            obj.hFig.WindowKeyReleaseFcn = @(~, evt) obj.keyReleased(evt);
            obj.hFig.WindowButtonMotionFcn = obj.origCallbacks.WindowButtonMotionFcn;
            obj.hFig.KeyPressFcn = obj.origCallbacks.KeyPressFcn;
            obj.hFig.KeyReleaseFcn = obj.origCallbacks.KeyReleaseFcn;

        end


        function removeCallbacks(obj)

            obj.hFig.WindowButtonDownFcn = [];
            obj.hFig.WindowButtonUpFcn = [];
            obj.hFig.WindowScrollWheelFcn = [];        
            obj.hFig.WindowKeyPressFcn = [];
            obj.hFig.WindowKeyReleaseFcn = [];
            obj.hFig.WindowButtonMotionFcn = [];
            obj.hFig.KeyPressFcn = [];
            obj.hFig.KeyReleaseFcn = [];

        end


        function saveOrigCallbacks(obj)

            obj.origCallbacks.WindowButtonDownFcn   = obj.hFig.WindowButtonDownFcn;
            obj.origCallbacks.WindowButtonUpFcn     = obj.hFig.WindowButtonUpFcn;
            obj.origCallbacks.WindowScrollWheelFcn  = obj.hFig.WindowScrollWheelFcn;
            obj.origCallbacks.WindowKeyPressFcn     = obj.hFig.WindowKeyPressFcn;
            obj.origCallbacks.WindowKeyReleaseFcn   = obj.hFig.WindowKeyReleaseFcn;
            obj.origCallbacks.WindowButtonMotionFcn = obj.hFig.WindowButtonMotionFcn;
            obj.origCallbacks.KeyPressFcn           = obj.hFig.KeyPressFcn;
            obj.origCallbacks.KeyReleaseFcn         = obj.hFig.KeyReleaseFcn;      

        end


        function resetOrigCallbacks(obj)

            obj.hFig.WindowButtonDownFcn    = obj.origCallbacks.WindowButtonDownFcn;
            obj.hFig.WindowButtonUpFcn      = obj.origCallbacks.WindowButtonUpFcn;
            obj.hFig.WindowScrollWheelFcn   = obj.origCallbacks.WindowScrollWheelFcn;
            obj.hFig.WindowKeyPressFcn      = obj.origCallbacks.WindowKeyPressFcn;
            obj.hFig.WindowKeyReleaseFcn    = obj.origCallbacks.WindowKeyReleaseFcn;
            obj.hFig.WindowButtonMotionFcn  = obj.origCallbacks.WindowButtonMotionFcn;
            obj.hFig.KeyPressFcn            = obj.origCallbacks.KeyPressFcn;
            obj.hFig.KeyReleaseFcn          = obj.origCallbacks.KeyReleaseFcn;      

        end


        function resetButtonDownCallback(obj)

            % reset the button down callback to the original one
            obj.hFig.WindowButtonDownFcn = @(src, ~) obj.actionBegins(src);

        end


        function resetButtonUpCallback(obj)

            % reset the button up callback to the original one
            obj.hFig.WindowButtonUpFcn = @(~, ~) obj.actionEnds();
        end


        function extendWindowKeyPressCallback(obj, keyPressCallback)

            % extend the key press callback to handle other keys
            obj.keypressExtension = keyPressCallback;

            % TO OPTIMIZE - handling src and evt might not be correct if needed

        end


        function extendWindowKeyReleaseCallback(obj, keyReleaseCallback)

            % extend the key release callback to handle other keys
            obj.keyreleaseExtension = keyReleaseCallback;

            % TO OPTIMIZE - handling src and evt might not be correct if needed

        end


        function overrideWindowKeyReleaseCallback(obj, keyReleaseCallback)

            obj.hFig.WindowKeyReleaseFcn = keyReleaseCallback;

        end


        function resetWindowKeyReleaseCallback(obj)

            % reset the key release callback to the original one added by orbitTool
            obj.hFig.WindowKeyReleaseFcn = @(~, evt) obj.keyReleased(evt);

        end


        function overrideWindowKeyPressCallback(obj, keyPressCallback)

            obj.hFig.WindowKeyPressFcn = keyPressCallback;
        end


        function resetWindowKeyPressCallback(obj)

            % reset the key press callback to the original one added by orbitTool
            obj.hFig.WindowKeyPressFcn = @(~, evt) obj.keyPressed(evt);

        end


        function overrideScrollWheelCallback(obj, scrollWheelCallback)

            obj.hFig.WindowScrollWheelFcn = scrollWheelCallback;

        end


        function resetScrollWheelCallback(obj)

            % reset the scroll wheel callback to the original one added by orbitTool
            obj.hFig.WindowScrollWheelFcn = @(~, evt) obj.zoom(evt);

        end


        function overrideButtonDownCallback(obj, buttonDownCallback)

            obj.hFig.WindowButtonDownFcn = buttonDownCallback;

        end


        function resetButtonMotionCallback(obj)

            % reset the button motion callback to the original one read from the main app
            obj.hFig.WindowButtonMotionFcn = obj.origCallbacks.WindowButtonMotionFcn;

        end



        function switchOrbitOff(obj)

            obj.orbitOn = false;
            % obj.removeCallbacks;
            obj.resetOrigCallbacks;
            
        end


        function switchOrbitOn(obj)

            obj.orbitOn = true;
            obj.setCallbacks;

        end


        function set2DAxesLimits(obj, limits)
            obj.xMin2D = limits(1);
            obj.xMax2D = limits(2);
        end


        function marginFraction2D = getMarginFractionFor2DAxes(obj)
            % the number represents returned the fraction of the axes ranges that should be added to each end
            % used for fitting the selection ROI in a 2D histogram axes
            marginFraction2D = obj.marginFraction2D;
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
                obj.setCentreOfRotation(newCentreOfRotation)         
             
            end

        end


        function actionBegins(obj, src)

            if ~obj.inActiveArea
                return
            end

            switch obj.mode
                case '2D'
                    obj.actionBegins2D(src)
                case '3D'
                    obj.actionBegins3D(src)
            end

        end

        function actionBegins2D(obj,src)

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

       
        function actionBegins3D(obj,src)

            crd = get(obj.hFig, 'CurrentPoint');
            obj.startXonFig = crd(1);
            obj.startYonFig = crd(2);

            obj.axPosStart = obj.hAx.Position;
        
            clickType = get(src, 'SelectionType');
                
            switch clickType
                % https://www.mathworks.com/help/matlab/ref/matlab.ui.figure.html - selectionType triggered in different ways
                case 'normal'
            
                    % resetCentreOfRotation(obj)     
                    return               
                                    
                case 'open'

                    % obj.resetView()
                    return
                    
                case 'alt'
                    obj.releaseFcnTriggered = true;     % added so that the redraw fcn (same as for timer) is activated upon release
                    src.Pointer = 'cross';
                    % determine the rotation direction that I should use
                    centrePos = MicroMToPixelPosition(obj.hAx.CameraTarget, obj.hAx);   % calculate position of rotation centre in pixels
                    deltaY = centrePos(2) - obj.startYonFig;  % calculate the signed y distance of the rotation centre from the mouse position in pixels
                    rotationSign = sign(deltaY*obj.hAx.View(2));  % sign depends on relative position and rotation of the axes
                    % rotationSign supplied here, so that the rotation direction is preserved and jaggered movement is avoided
                    src.WindowButtonMotionFcn = @(~, ~) obj.dragRotate3D(rotationSign); 
                                    
                case 'extend'
                    obj.releaseFcnTriggered = true;
                    src.Pointer = 'hand';
                    src.WindowButtonMotionFcn = @(~, ~) obj.dragPan3D;              
                    
            end

            if obj.timerActive && isvalid(obj.timerHandle)
                % if a timer is utilized, stop it if it is running
                % this will renew the delay period before execution
                if strcmp(obj.timerHandle.Running, 'on')
                    stop(obj.timerHandle);
                end
            end
        end

        function actionEnds(obj)

            obj.resetButtonMotionCallback();
            obj.hFig.Pointer = 'arrow';

            % if obj.releaseFcnTriggered
            %     % TO OPTIMIZE: in some cases, we might want to have different function for timer and release
            %     obj.releaseFcnTriggered = false;
            %     obj.timerFcn();
            % end

            if obj.timerActive && isvalid(obj.timerHandle)
                % if a timer is utilized, stop it if it is running and start again
                % this will renew the delay period before execution
                if strcmp(obj.timerHandle.Running, 'on')
                    stop(obj.timerHandle);
                end
                start(obj.timerHandle);
            end
        end

    
        function dragRotate3D(obj, rotationSign)

            crd = get(obj.hFig, 'CurrentPoint');
            x = crd(1);
            y = crd(2);           
          
            % track the mouse drag distance
            dx = obj.startXonFig - x;
            dy = obj.startYonFig - y;     
    
            obj.startXonFig = x;
            obj.startYonFig = y;

            % TO OPTIMIZE - this requires determination of where is the drag point relative to the rotation centre

            % disp(obj.hAx.CameraPosition)
            % disp(obj.hAx.CameraTarget)
            % disp(obj.hAx.CameraUpVector)
            % check whether the plot is upside down - if so, x rotates in the opposite direction
            % disp(obj.hAx.CameraPosition)
            % if obj.hAx.CameraUpVector(3) < 0
            %     upSign = -1
            % else
            %     upSign = 1
            % end
            % upSign = 1;
            % disp(obj.hAx.View)

            % v = obj.hAx.CameraTarget - obj.hAx.CameraPosition
            % disp('')

            % pos = MicroMToPixelPosition(obj.hAx.CameraTarget, obj.hAx);
            % delta = pos(2) - y

            % upSign = sign(delta*obj.hAx.View(2))

            camorbit(obj.hAx,rotationSign*dx/obj.angleStep,dy/obj.angleStep)

        end


        function dragPan3D(obj)
    
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


        function zoom(obj,evt)

            % obj.xMax2D = 65535;

            if ~obj.inActiveArea
                return
            end

            switch obj.mode
                case '2D'
                    zoom2D(obj,evt)
                case '3D'
                    zoom3D(obj,evt)
            end

        end


        function zoom2D(obj,evt)

            dir = evt.VerticalScrollCount;
    
            % obj.xMax = 40;            
            crd = get(obj.hAx, 'CurrentPoint');
            focusPoint = crd(1);               
                       
            xLim = obj.hAx.XLim;

            dL = focusPoint - xLim(1);
            dR = xLim(2) - focusPoint;            
            
            % k = 0.1;
            % newXLim = [xlim(1) - dir*dL*k, xlim(2) + dir*dR*k];

            if dir < 0  % scrolling up, away from me
                mag = 1.1;
            elseif dir > 0  % scrolling down, towards me
                mag = 0.9;
            else    % this should not happen, dir should be always either 1 or -1
                mag = 1;
            end

            lowerLim = focusPoint - dL/mag;
            upperLim = focusPoint + dR/mag;
            newXLim = [lowerLim, upperLim];

            newXLim(newXLim < obj.xMin2D) = obj.xMin2D;
            newXLim(newXLim > obj.xMax2D) = obj.xMax2D;
            
            obj.hAx.XLim = newXLim;
        end


        function zoom3D(obj,evt)

            % tightPos = obj.hAx.tightPosition;
            % widthRatio = obj.hAx.InnerPosition(3)/tightPos(3);
            % ax = obj.hAx;
            % [azimuth, ~, ~] = SceneGeometry.calculateRotation(ax);
            % widthUM = ax.XLim(2) * abs(cosd(azimuth)) + ax.YLim(2) * abs(sind(azimuth));

            % realWidthUM = widthUM * widthRatio;

            % v = (obj.hAx.CameraPosition - obj.hAx.CameraTarget)./ax.DataAspectRatio;
            % sightVectorLen = norm(v);
            % alpha = atand(realWidthUM/(2*sightVectorLen));
            % zoomAngle = 2*atand(ax.InnerPosition(4)*sind(alpha)/(ax.InnerPosition(3)))
            % realZoomAngle = obj.hAx.CameraViewAngle



            crd = get(obj.hAx, 'CurrentPoint');
        
            cameraTarget_orig = obj.cameraTarget;
            % disp(obj.hAx.CameraTarget)
            % disp(obj.hAx.CameraPosition)
    
            xct = crd(2,1);
            yct = crd(2,2);
            zct = crd(2,3);
    
            obj.setCentreOfRotation([xct,yct,zct]) 
            
            obj.axZoom = obj.axZoom + evt.VerticalScrollCount*0.1*obj.axZoom;
            obj.hAx.CameraViewAngle = obj.axZoom;   
            obj.setCentreOfRotation(cameraTarget_orig) 

            if obj.timerActive && isvalid(obj.timerHandle)
                % if a timer is utilized, stop it if it is running and start again
                % this will renew the delay period before execution
                if strcmp(obj.timerHandle.Running, 'on')
                    stop(obj.timerHandle);
                end
                start(obj.timerHandle);
            end

        end


        function setCentreOfRotation(obj, newCentreOfRotation)
        
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

            obj.setCentreOfRotation([xct,yct,zct]);
       
        end


        function resetView(obj)

            % disp('Resetting view...')

            for ax = obj.resettableAxes
                % we need to make sure that we don't accidentally apply this to the 2D axes
                
                % save information if the axes were active before resetting and recover the status after the resetting
                inActiveAreaStatus = obj.inActiveArea;

                obj.setActiveAxes(ax, true);    % to make sure that the centre of rotation is reset for the correct axes

                obj.resetCentreOfRotation()
                ax.View = [0,90];

                % widthRatio = 1;
                % cameraViewAngle = SceneGeometry.calculateCameraViewAngleFor(ax, widthRatio)

                % reset zoom
                obj.axZoom = 10;
                ax.CameraViewAngle = obj.axZoom;   
                % ax.CameraViewAngle = cameraViewAngle;
                
                % ax.View = [0,89.9];
                % 89

                % needed for not know reason to correcty zoom after reset view
                % IS 250813: I have the same observation -_o_-
                    % I guess it is probably related to setting the View directly
                camorbit(ax,0.01,0.01)
                camorbit(ax,-0.01,-0.01)
                

                hPan = ancestor(ax, 'uipanel');
                % hPan.Position
                
                % reset position

                % preserving the ratio seems to be important for proper manual calculation of the CameraViewAngle

                % adjust camera position to the camera angle
                % sceneWidth = ax.XLim(2)-ax.XLim(1);
                sceneHeight = ax.YLim(2)-ax.YLim(1);        
                % longestSceneEdge = max([sceneWidth,sceneHeight]);
                % observationDist = longestSceneEdge/2/tand(obj.axZoom/2);
                observationDist = sceneHeight/2/tand(obj.axZoom/2);
                xct = obj.cameraTarget(1);
                yct = obj.cameraTarget(2);
                campos(ax,[xct,yct,observationDist])

                adjustRatio = true; % ajust to have width and height the same
                SceneGeometry.fitAxesToPanel(hPan, ax, adjustRatio);    % this will preserve the width/height ratio

                % recover inActiveArea status
                obj.inActiveArea = inActiveAreaStatus;

                % disp(ax.CameraPosition)
                % disp(ax.CameraTarget)
            end
        end


        function setActiveAxes(obj, ax, status)
                      
            if ~obj.orbitOn
                return
            end
            
            obj.inActiveArea = status;
                      
            if status
                obj.hAx = ax;
                obj.axZoom = obj.hAx.CameraViewAngle;  
      
                for i = 1:numel(obj.existingAxes)
                    if isequal(obj.existingAxes{i}.handle,ax)
                        obj.mode = obj.existingAxes{i}.mode;
                    end
                end    
            end

        end


        function keyPressed(obj, evt)
            if ~obj.inActiveArea
                if isa(obj.keypressExtension, 'function_handle')
                    % just call the keypress function supplied
                    obj.keypressExtension(evt);
                end
                return
            end

            switch obj.mode
                case '2D'
                    obj.keyPressCallback2D(obj.hFig, evt);
                case '3D'
                    obj.keyPressCallback3D(evt);
            end
        end


        function keyReleased(obj, evt)
            if isa(obj.keyreleaseExtension, 'function_handle')
                % just call the keyrelease function supplied
                obj.keyreleaseExtension(evt);
            end
        end


        function keyPressCallback3D(obj, evt)      
            
            % dx = 0.05;
            translationStep = 10;
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

            % TO OPTIMIZE - the modifiers cannot work, as we use them for scrolling -> override keypress

            switch evt.Key
            
                case 'leftarrow'
                    if ctrlPressed
                        % camdolly(obj.hAx,dx,0,0)  % this was causing unwanted side view rotation
                        pos = obj.hAx.Position;
                        obj.hAx.Position = [pos(1)-translationStep,pos(2),pos(3),pos(4)];
                    else
                        camorbit(obj.hAx,obj.angleStep,0)
                    end
                case 'rightarrow'
                    if ctrlPressed
                        % camdolly(obj.hAx,-dx,0,0)
                        pos = obj.hAx.Position;
                        obj.hAx.Position = [pos(1)+translationStep,pos(2),pos(3),pos(4)];
                    else
                        camorbit(obj.hAx,-obj.angleStep,0)
                    end
                case 'uparrow'
                    if ctrlPressed
                        % camdolly(obj.hAx,0,-dx,0)
                        pos = obj.hAx.Position;
                        obj.hAx.Position = [pos(1),pos(2)+translationStep,pos(3),pos(4)];
                    elseif shiftPressed
                        obj.axZoom = obj.axZoom - zoomStep*obj.axZoom;
                        obj.hAx.CameraViewAngle = obj.axZoom; 
                    else
                        camorbit(obj.hAx,0,-obj.angleStep)
                    end
                case 'downarrow'
                    if ctrlPressed
                        % camdolly(obj.hAx,0,dx,0)
                        pos = obj.hAx.Position;
                        obj.hAx.Position = [pos(1),pos(2)-translationStep,pos(3),pos(4)];
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

                otherwise
                    if ~isempty(obj.keypressExtension) && isa(obj.keypressExtension, 'function_handle')
                        % just call the keypress function supplied
                        obj.keypressExtension(evt);
                    end
                    return  % do not reset centre of rotation
            end

            if ctrlPressed
                % TO OPTIMIZE move this to keyRelease callback later
                obj.setCentreOfRotation(camera_target_old)
            end
            
           
        end

        function keyPressCallback2D(obj, evt) 
            if ~isempty(obj.keypressExtension) && isa(obj.keypressExtension, 'function_handle')
                % just call the keypress function supplied
                obj.keypressExtension(evt);
            end
        end
    end
end