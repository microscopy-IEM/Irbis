function performDendriteTracking()

    % visuals control
    planeh = findobj(app.UIAxes.Children,'Tag','planePlot');
    planeh.ButtonDownFcn = [];

    currentTimePoint = timePoints(1);

    startPointPix = app.TrackdendriteButton.UserData.startPoint;
    endPointPix = app.TrackdendriteButton.UserData.endPoint;

    % app.trackDendrite(currentTimePoint,start_point,end_point);

    % if app.AlltimepointsCheckBox_shaft.Value

    wb = uiprogressdlg(app.IrbisMainFig,'Title',['Tracking dendrite for time point ' num2str(1)],'Message','Generating...','Cancelable','off');

    for i=timePoints

        
        try
            wb.Value = (i-(timePoints(1)-1))/length(timePoints);
        catch
            wb.Value = 0.5;
        end
        wb.Message = sprintf(['Tracking dendrite for time point ' num2str(i)]);

        app.trackDendrite(currentTimePoint,startPointPix,endPointPix);

        if i < timePoints(end)

            branch = 'shaft';
            modelId = app.timeline.currentIndex.model.(branch)(currentTimePoint);

            nextTimePoint = currentTimePoint + 1;
            app.TimePointSlider.Value = nextTimePoint;
            app.TimePointSliderValueChanged;

            workingRowNum = app.appData.workingRowNum;
            currentDrift = app.model.timeDrift(nextTimePoint,:) - app.model.timeDrift(currentTimePoint,:);  % timeDrift is defined for all tps - this is ok
            currentLine = app.model.(branch).List{modelId}.CentreLine{workingRowNum};
            
            startPointUm = currentLine(1,:)-currentDrift;
            endPointUm = currentLine(end,:)-currentDrift;

            startPointPix(1:2) = startPointUm(1:2)/app.planes.pixel_size;
            startPointPix(3) = startPointUm(3)/app.planes.z_spacing;

            endPointPix(1:2) = round(endPointUm(1:2)/app.planes.pixel_size);
            endPointPix(3) = round(endPointUm(3)/app.planes.z_spacing);

            delete(findobj(app.UIAxes,'Tag','startPoint'))
            plot3(app.UIAxes,startPointUm(1),startPointUm(2),startPointUm(3),'Tag','startPoint','Color','m','Marker','+','MarkerSize',10,'LineWidth',2)
            drawnow     

            delete(findobj(app.UIAxes,'Tag','endPoint'))
            plot3(app.UIAxes,endPointUm(1),endPointUm(2),endPointUm(3),'Tag','endPoint','Color','g','Marker','+','MarkerSize',10,'LineWidth',2)
            drawnow

            currentTimePoint = nextTimePoint;
        end
    end
    app.model.selectableBranches = {branch};
    app.objectSelectabilityChanged;    

    % cancel selection of the parent
        % it was highlighted during plotting, because the selectedObjectBranch was set to fullVolume
    app.appData.selectedObjectBranch = [];


    % hide the rois
    app.ShowprohibitedareasCheckBox.Value = 0;
    app.ShowprohibitedareasCheckBoxValueChanged;

    % % perform object registration in time, so that it does not need to be clicked manually
    % if app.AlltimepointsCheckBox_shaft.Value
    %     evt.Source.Tag = branch;
    %     evt.NewValue = 2;   % make the registration threshold a bit more permissive (=higher) so that the registration goes through
    %     app.objectListComponentrunTimeRegistration(evt);
    % end

    close('all')

    close(wb)
end


function setObjectIdToNextTimePointModel()
    % code for determining parent id for the next time points
    modelIdParent = app.timeline.currentIndex.model.(parentBranch)(currentTimePoint);
    currentList = app.model.(parentBranch).List{modelIdParent};
    currentId = app.appData.selectedObjectId;
    groupId = currentList{num2str(currentId),'groupId'};

    modelIdParentNext = app.timeline.currentIndex.model.(parentBranch)(currentTimePoint+1);
    nextList = app.model.(parentBranch).List{modelIdParentNext};
    nextRow = find(nextList{:,'groupId'} == groupId);
    app.appData.selectedObjectId = str2double(nextList.Properties.RowNames{nextRow});
end