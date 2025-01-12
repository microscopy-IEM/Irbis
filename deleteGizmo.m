function deleteGizmo(ax)
    
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

end