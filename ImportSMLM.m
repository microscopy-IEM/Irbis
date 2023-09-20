

function MMpack = ImportSMLM(MMpack,path)
    
    if nargin == 1
        path = [];
    end
    
    
    % select csv file from directory
    [coor_fileName,path] = uigetfile([path '*.csv'],'Select dStorm file with localizations');
    
    
    if isequal(coor_fileName,0)
       disp('User selected Cancel');
    else
       
        disp(['User selected ', fullfile(path,coor_fileName)]);
    
        % import coordinates acquired with astigmatism lens
        coor = readtable([path coor_fileName]);
        
        % set frame range for plotting
        range = 1:size(coor,1);
        
        % units conversion from nm to um
        % x = coor.x_nm_(range)./1000;
        % y = coor.y_nm_(range)./1000;
        % z = coor.z_nm_(range)./1000;
    
        x = coor.x_nm_(range);
        y = coor.y_nm_(range);
        z = coor.z_nm_(range);
        
        % x = u;
        % y = v;
        
        % asign the registered coordinates to the table
        % coor.x_nm_ = x.*1000;
        % coor.y_nm_ = y.*1000;
        % coor.z_nm_ = z;
        
        coor.x_nm_ = x;
        coor.y_nm_ = y;
        coor.z_nm_ = z;
    
        %% Remove negative values (some localizations can appear outside the reference image after registration)
    %     negative_x = x<=0;
    %     negative_y = y<=0;
    %     
    %     negative_xy = negative_x | negative_y;
    %     coor_cleaned = coor(~negative_xy,:);
        
        %% Add or replace localization in MMpack file
    
        answer = questdlg('Import localizations as:', ...
	    'Localizations import', ...
	    'Orig','Corrected','Cancel','Orig');
        % Handle response
    switch answer
        case 'Orig'
            MMpack.storm.origFileName = coor_fileName;
            MMpack.storm.origLocalizations = coor;
            % for now saving to both
            MMpack.storm.correctedLocalizations = coor;

        case 'Corrected'
            MMpack.storm.origFileName = coor_fileName;
            MMpack.storm.correctedLocalizations = coor;
             % for now saving to both
            MMpack.storm.origLocalizations = coor;

        case 'Cancel'
            MMpack.storm.correctedLocalizations = [];
            MMpack.storm.origLocalizations = [];
            
    end
 
    

    end
end