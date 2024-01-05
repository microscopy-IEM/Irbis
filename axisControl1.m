
function axisControl1


hFig = figure;
ax = gca;
[X,Y] = meshgrid(-3:.125:3);
Z = peaks(X,Y);
meshc(X,Y,Z);
axis([-3 3 -3 3 -10 10]);
xlabel('x');
ylabel('y');
zlabel('z');

disableDefaultInteractivity(ax)
SetFigureCallbacks3D()

function SetFigureCallbacks3D()
        %SetFigureCallbacks3D set callback-functions for processing figure events in mode 3D
        
        set(hFig, ...
            'WindowButtonDownFcn',      {@WindowButtonDownCallback3D}, ...
            'WindowButtonUpFcn',        {@WindowButtonUpCallback3D}, ...
            'WindowButtonMotionFcn',    {@WindowButtonMotionCallback3D}, ...
            'WindowScrollWheelFcn',     {@WindowScrollWheelFcn3D}, ...
            'WindowKeyPressFcn',        {@WindowKeyPressCallback3D}, ...
            'WindowKeyReleaseFcn',      {@WindowKeyReleaseCallback3D});
end

 function WindowButtonDownCallback3D(src, evnt)    %#ok
        %WindowButtonDownCallback3D
        src
        % if fIsMouseOnLegend, return; end
        
        clickType = get(src, 'SelectionType');
        
        switch clickType
            case 'normal'
                DragMouseBegin3D();
            case 'open'
                ResetAxesToOrigView3D();
            case 'alt'
                RotateMouseBegin3D();
            case 'extend'
                ZoomMouseExtendBegin3D();
        end
 end


end