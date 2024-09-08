function [patchVertices,patchFaces] = delete_gizmo_cuboid(ax,fig,originalCallbacks)
    % clear old components
    patchObject = findobj(ax,'Tag','3dPlane');
    patchVertices = patchObject.Vertices;
    patchFaces = patchObject.Faces;

    delete(findobj(ax,'Tag','cBallPoint'))
    delete(findobj(ax,'Tag','xBallPoint'))
    delete(findobj(ax,'Tag','yBallPoint'))
    delete(findobj(ax,'Tag','zBallPoint'))

    delete(findobj(ax,'Tag','xlineLink'))

    delete(findobj(ax,'Tag','xzRotLine'))
    delete(findobj(ax,'Tag','xyRotLine'))
    delete(findobj(ax,'Tag','normBallPoint'))
    delete(findobj(ax,'Tag','3dPlane'))
    delete(findobj(ax,'Tag','normLink'))

    % reset callbacks
    fig.WindowButtonMotionFcn = originalCallbacks{1};
    fig.WindowButtonUpFcn = originalCallbacks{2};
    fig.WindowScrollWheelFcn = originalCallbacks{3};
end