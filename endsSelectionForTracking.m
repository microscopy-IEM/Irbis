        function endsSelectionForTracking(app,~,evt,timePoints)
            % function perform dendrite trackin after manual selection of two points


            branch = 'shaft';
            parentBranch = 'fullVolume';


            cursorPoint = evt.IntersectionPoint;

            % convert um to pixels
            cursorPointum(1:2) = round(cursorPoint(1:2)./app.planes.pixel_size);
            cursorPointum(3) = app.PlaneSpinner.Value;
           
            drawnow
           
            % check for out of axis limits 
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
                


            end
        end