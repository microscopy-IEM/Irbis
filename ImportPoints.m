% function imports localizations from csv files and returns it as MMpack
% compatible structure

function points = ImportPoints()
    
  
    % select csv file from directory
    [coor_fileName,path] = uigetfile('*.csv','Select file with localizations');

    origin = 'ThunderStorm';
    units = 'nm';
    
    fullFileName = fullfile(path,coor_fileName);
    
    if isequal(coor_fileName,0)
       disp('User selected Cancel');
       points = [];
       return;
    end
           
        disp(['User selected ', fullFileName]);
    

        coor = readtable(fullFileName,'VariableNamingRule','preserve');

        switch origin
            case 'ThunderStorm'
                % replace space and brackets with undrescoper if present in column headers
                coor.Properties.VariableNames = regexprep(coor.Properties.VariableNames, ' ', '');
                coor.Properties.VariableNames = regexprep(coor.Properties.VariableNames, '[', '');
                coor.Properties.VariableNames = regexprep(coor.Properties.VariableNames, ']', '');
                coor.Properties.VariableNames = regexprep(coor.Properties.VariableNames, 'nm', '');

                % ff = isfield(coor,'id')

                if isfield(coor,'id')
                    pointList = coor(:,["id","frame",'x','y','z','uncertainty_xy','uncertainty_z']);
                else
                    
                    pointList = coor(:,["frame",'x','y','z','uncertainty_xy','uncertainty_z']);

                end

            case 'name'
                
                % code for other localizations origin

        end               
      
        
        % if the units are nm, convert to micrometers
        if isequal(units,'nm')
        
            % units conversion from nm to um
            pointList.x = pointList.x./1000;
            pointList.y = pointList.y./1000;
            pointList.z = pointList.z./1000;

            pointList.uncertainty_xy = pointList.uncertainty_xy./1000;
            % pointList.uncertainty_z = pointList.uncertainty_z./1000;

        end
      
    %% Create points structure

    points.pointsList = pointList;
    points.fileName = coor_fileName;
    points.registration = [];

end