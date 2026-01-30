function deleteGizmo(ax, gizmoHandle)

    % iptPointerManager(ancestor(ax, 'figure'),'disable');   % attempt to avoid errors stemming from deleted components
    % - on laptop, we are sometimes getting error related to exitFcn on Invalid or deleted object
    % this is not possible - pointer manager is also used by orbitTool to determine whether cursor is within axes

    if nargin > 1 && isvalid(gizmoHandle) && ishandle(gizmoHandle)
        % not having to use findobj should be much faster
        tic
        delete(gizmoHandle);
        disp(['Deleted gizmo using handle in ' num2str(toc) ' s']);
    else
        tic
        directionNames = ['x', 'y', 'z'];
        for directionN = 1:numel(directionNames)
            directionName = directionNames(directionN);
            delete(findobj(ax, 'Tag', [directionName 'BallPoint']));
            delete(findobj(ax, 'Tag', [directionName 'lineLink']));
            delete(findobj(ax, 'Tag', [directionName 'referencePoint']));
            delete(findobj(ax, 'Tag', [directionName 'RotLine']));
        end

        delete(findobj(ax, 'Tag', 'cBallPoint'));
        delete(findobj(ax, 'Tag', 'normLink'));
        delete(findobj(ax, 'Tag', 'normBallPoint'));
        delete(findobj(ax, 'Tag', '3Dobject'));
        delete(findobj(ax, 'Tag', 'scalePoint'));
        disp(['Deleted gizmo using findobj in ' num2str(toc) ' s']);
    end
end