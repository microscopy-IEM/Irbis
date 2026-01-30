function restoreOriginalCallbacks(fig, originalCallbacks)
    % reset callbacks
    fig.WindowButtonMotionFcn = originalCallbacks{1};
    fig.WindowButtonUpFcn = originalCallbacks{2};
    fig.WindowScrollWheelFcn = originalCallbacks{3};

    % this was probably causing stuck rotation, because active area checking relies on pointer manager
    % iptPointerManager(fig, 'disable');
end