function restoreOriginalCallbacks(fig, originalCallbacks)
    % reset callbacks
    fig.WindowButtonMotionFcn = originalCallbacks{1};
    fig.WindowButtonUpFcn = originalCallbacks{2};
    fig.WindowScrollWheelFcn = originalCallbacks{3};

    iptPointerManager(fig, 'disable');
end