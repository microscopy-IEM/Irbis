        function endsSelectionForTracking(app,~,evt,timePoints)
            % disp('endsSelection')

            % disp('in endsSelectionForTracking')
            branch = 'shaft';
            parentBranch = 'fullVolume';
            % function perform dendrite trackin after manual selection of two points

            cursorPoint = evt.IntersectionPoint;

            % convert um to pixels
            cursorPointum(1:2) = round(cursorPoint(1:2)./app.planes.pixel_size);
            cursorPointum(3) = app.PlaneSpinner.Value;
           
            drawnow
           
            % check for out of axis limits 
            % xsize = size(app.planes.refIm,2);
            % ysize = size(app.planes.refIm,1);

            xsize = app.planes.imSize(2);
            ysize = app.planes.imSize(1);
 
            cursorPointum(cursorPointum<=1) = 2;

            if cursorPointum(1) > xsize-1
                cursorPointum(1) = xsize-2;
            end

            if cursorPointum(2) > ysize-1
                cursorPointum(2) = ysize-2;
            end

            % auto detect z position
            if app.AutoZCheckBox.Value
                % get image data
                currentTimePoint = app.TimePointSlider.Value;
                zrange = 1:app.planes.nPlanes;
                zstack = getZProjection(app,app.planes.zstack, app.appData.activeCh, zrange,currentTimePoint,'zstack');
    
                % smooth zstack by gaussian
                zstack = imgaussfilt3(zstack,2);
    
                % select column of pixels with neigburhood +-1 pixel

                pixVect = zstack(cursorPointum(2)-1:cursorPointum(2)+1,cursorPointum(1)-1:cursorPointum(1)+1,:);
                % average over xy
                pixVect = squeeze(mean(pixVect,[1,2]));
    
                % detect max intensity in z
                [~,cursorPointum(3)] = max(pixVect);

            end
        
            % count selected points number
            numOfPts = app.TrackdendriteButton.UserData.nPoints;

           
            if numOfPts == 0 && evt.Button == 1
                    app.TrackdendriteButton.UserData.startPoint = cursorPointum;
                    delete(findobj(app.UIAxes,'Tag','startPoint'))
                    plot3(app.UIAxes,cursorPoint(1),cursorPoint(2),cursorPoint(3),'Tag','startPoint','Color','m','Marker','+','MarkerSize',10,'LineWidth',2)
                    drawnow
                    app.TrackdendriteButton.UserData.nPoints = app.TrackdendriteButton.UserData.nPoints+1;

            elseif numOfPts == 1 && evt.Button == 1
                    
                    app.TrackdendriteButton.UserData.endPoint = cursorPointum;
                    delete(findobj(app.UIAxes,'Tag','endPoint'))
                    plot3(app.UIAxes,cursorPoint(1),cursorPoint(2),cursorPoint(3),'Tag','endPoint','Color','g','Marker','+','MarkerSize',10,'LineWidth',2)
                    drawnow
                    app.TrackdendriteButton.UserData.nPoints = app.TrackdendriteButton.UserData.nPoints+1;

            end
            
    
            % if second point is added
            if app.TrackdendriteButton.UserData.nPoints >= 2

                set(app.InstructionsPanel,'Visible','off');
                
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

                        % code for determining parent id for the next time points
                        modelIdParent = app.timeline.currentIndex.model.(parentBranch)(currentTimePoint);
                        branch = 'shaft';
                        modelId = app.timeline.currentIndex.model.(branch)(currentTimePoint);
                        currentList = app.model.(parentBranch).List{modelIdParent};
                        currentId = app.appData.selectedObjectId;
                        groupId = currentList{num2str(currentId),'groupId'};
    
                        modelIdParentNext = app.timeline.currentIndex.model.(parentBranch)(currentTimePoint+1);
                        nextList = app.model.(parentBranch).List{modelIdParentNext};
                        nextRow = find(nextList{:,'groupId'} == groupId);
                        app.appData.selectedObjectId = str2double(nextList.Properties.RowNames{nextRow});
    
                        nextTimePoint = currentTimePoint + 1;
                        app.TimePointSlider.Value = nextTimePoint;
                        app.TimePointSliderValueChanged;
    
                        workingRowNum = app.appData.workingRowNum;
                        % disp('after workingRowNum')
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
        end