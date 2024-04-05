% Function creates new empty MMpack with help of an input dialog
function newMMpack = newMMpackDialog(ver)

    repeatDial = 1;

    while repeatDial
    
        dial = inputdlg('Name','New Irbis file',[1 50],{'test'}); 

        waitfor(dial);
        if ~isempty(dial)
             
            if isempty(dial{1})
                f = warndlg('Name must be filled','Warning');
                waitfor(f);
            else
                repeatDial = 0;
            end
        else    
            break   % enable to exit using Cancel - returns empty {}

        end

    end

    if ~isempty(dial)   % does not continue if Cancel was pressed
        newMMpack = createEmptyMMpack(dial,ver);
    else 
        newMMpack = {}; % something needs to be returned
    end
        
end

function MMpack = createEmptyMMpack(dial,ver)
    %% Create MMPack structure
        
    irbis_version = ver;
    
    name = [dial{1} '.irbis'];
    description = '';   % Description of the experiment ('Mobility_2Avs2Bvs3A')
    groupName = '';     % Name of the experimental condition ('2A_cre' or '3A_wt'...)
    roundN = 1;         % Number of round
    cellN = 1;   
    
    
    %% Common information
    info = [];
    
    info.name = name;                                                      % file name 
    info.groupName = groupName;                                            % for xample: 'mutation XX'...
    info.description = description;                                        % general description of the experiment
    info.round = roundN;                                                   % numbe of experimental round
    info.cell = cellN;                                                     % number identifying cell
    info.spaceUnits = 'µm';                                                % space units um, nm common for all modalities
    info.timeUnits = 'sec';                                                % time units 'sec','min' common for all modalitioes
    info.irbis_version = irbis_version;                                    % version od MMpack 
    
    
    %% WF data (wide-field, confocal, SIM or other pixel-brightness based images)
    
    planes = [];
       
    %% SMLM data (single molecule localizations)
    
    points = [];
        
    %% Tracks (data from single particle tracking input)
    
    tracks = [];
        
    %% Model

    model = [];

    %% Timeline

    timeline = [];

    %% Archive
    
    archive = [];

    %% Tools
    tools = [];
    % To store:
    % Peaks
    % Areas
    % Zones
    % Masks
    % ROIs
    
    %% Results
    
    results = [];

    %% Modality registration
    
    % reference A
    % reference B
    % modalReg.storm2wf.tform = []; 
    
    %% Compose structured MMpack file
    
    MMpack.info = info;
    MMpack.planes = planes;
    MMpack.points = points;
    MMpack.tracks = tracks;
    MMpack.model = model;
    MMpack.tools = tools;
    MMpack.timeline = timeline;
    MMpack.results = results;
    MMpack.archive = archive;
    
    % disp(MMpack)

end