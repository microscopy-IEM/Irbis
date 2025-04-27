function plotFiltering(app, filteredData, fullData, dataType, name)
    histogram(app.UIAxes,fullData,"FaceColor",[0.5 0.5 0.5],"FaceAlpha",0.7,'LineStyle','none')
    hold(app.UIAxes, "on")
    histogram(app.UIAxes,filteredData,"FaceColor",[0 0.4470 0.7410],"FaceAlpha",1)
    if isequal('numeric',dataType)
        app.generateFilteringROI;
    end
    hold(app.UIAxes, "off")
    name = strrep(name, '_', ' ');
    xlabel(app.UIAxes,name)
    ylabel(app.UIAxes, 'Counts')
end












function ROIIsMoving(app,src,~)
    % private function
    % adjust what is going to happen when filtering ROI is moving
    app.FilterSpinnerLow.Value = src.Position(1);
    app.FilterSpinnerHigh.Value = src.Position(3)+src.Position(1);
end



function plotZoomCallback(app,~,~,filteringRoiHandle,listener)
    % private functions
    % recenters the flitering roi in y when the y limits are changed (e.g. by zooming or panning)
    if isvalid(filteringRoiHandle)
        oldPosition = filteringRoiHandle.Position;
        newPosition = [oldPosition(1), app.UIAxes.YLim(1)-0.1, oldPosition(3), app.UIAxes.YLim(2)-app.UIAxes.YLim(1)+0.2];
        filteringRoiHandle.Position = newPosition;
    else
        disp('roi not valid')
        disp(listener)
        % delete(listener)
    end
end



function generateFilteringROI(app)
    % adds the visual filtering element to the histogram plot
    % conditions: plot needs to show histogram

    % I wanted to generate it in the startupfcn and then just change the data when refreshed
        % but the roi object is deleted when axes are refreshed - gives 'invalid or deleted object' error

    % we cannot ask validity of app.appData.YLimChangeListener, because that might just be an empty array (no validity parameter)
    % problem with continuing existence of listeners of deleted rois
    % it is not enough to just unassign it in app.appData.YLimChangeListener - it keeps on existing
    % disp('innn here')
    % isfield(app.appData, 'YLimChangeListener')
    % yLimProp = findprop(metaclass(app.UIAxes),'YLim');
    % listeners = yLimProp.PostSetListenerHandles;
    % disp(listeners)
    if isfield(app.appData, 'YLimChangeListener') && isa(app.appData.YLimChangeListener,'event.listener')
        % disp('in generating - valid')
        % disp(app.appData.YLimChangeListener)
        % isa(app.appData.YLimChangeListener,'event.listener')
        delete(app.appData.YLimChangeListener)
        % delete(app.appData.YLimChangeListener)
        % app.appData.YLimChangeListener = [];
    % else
        % disp('not listener')
    end
    % disp('after if')
    app.appData.YLimChangeListener = [];

    filteredParameterName = app.FilterDropDown.Value;
    modality = app.ModalityDropDown.Value;
    root = app.getRoot(modality);

    % check if the filter is already in use
    if ismember(filteredParameterName,root.storedFilters.returnGroupingNames)
        conds = root.storedFilters.getConditions(filteredParameterName);
        xPos = conds(1);
        width = conds(2)-conds(1);
    else
        xPos = app.UIAxes.XLim(1);
        width = app.UIAxes.XLim(2)-app.UIAxes.XLim(1);
    end

    position = [xPos, app.UIAxes.YLim(1)-0.1, width, app.UIAxes.YLim(2)-app.UIAxes.YLim(1)+0.2];
    filteringROI = drawrectangle(app.UIAxes, 'Position', position,'Color','r','Tag','filteringROI','FaceAlpha',0.1,'ContextMenu',[]);
    addlistener(filteringROI,'MovingROI', @app.ROIIsMoving);
    app.appData.YLimChangeListener = addlistener(app.UIAxes, 'YLim', 'PostSet', @(src,evt)plotZoomCallback(app,src,evt,filteringROI,app.appData.YLimChangeListener));

    app.appData.filteringROI = filteringROI;
    % roiHandle.Position = position;
    % roiHandle.Visible = "on";

    % adjust immediately afterwards
    app.adjustFilteringROI;
end



function adjustFilteringROI(app,varargin)
    filteredParameterName = app.FilterDropDown.Value;
    modality = app.ModalityDropDown.Value;
    root = app.getRoot(modality);

    roiHandle = app.appData.filteringROI;

    % if there is varargin, it corresponds to the manual input
    if nargin == 3
    lowThreshold = varargin{1};
    highThreshold = varargin{2};
    if lowThreshold >= highThreshold
        app.FilterSpinnerLow.Value = highThreshold;
        app.FilterSpinnerHigh.Value = lowThreshold;
        lowThreshold = app.FilterSpinnerLow.Value;
        highThreshold = app.FilterSpinnerHigh.Value;
    end
    xPos = lowThreshold;
    width = highThreshold - lowThreshold;

    % check if the filter is already in use
    elseif ismember(filteredParameterName,root.storedFilters.returnGroupingNames)
        conds = root.storedFilters.getConditions(filteredParameterName);
        xPos = conds(1);
        width = conds(2)-conds(1);
    else
        return
    end

    position = [xPos, app.UIAxes.YLim(1)-0.1, width, app.UIAxes.YLim(2)-app.UIAxes.YLim(1)+0.2];
    roiHandle.Position = position;
    roiHandle.bringToFront
    % get(roiHandle)
    roiHandle.InteractionsAllowed = 'all';
    % disp(roiHandle.PickableParts)
    % bringToFront(roiHandle)
    % roiHandle.Visible = "on";  
end