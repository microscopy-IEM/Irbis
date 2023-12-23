% Function creates new empty MMpack with help of an input dialog
function newMMpack = newMMpackDialog()

    repeatDial = 1;

    while repeatDial
    
        dial = inputdlg('Name','New MMpack',[1 50],{'test'}); 

        waitfor(dial);
        if ~isempty(dial)
             
            if isempty(dial{1})
                f = warndlg('Name must be filled','Warning');
                waitfor(f);
            else
                repeatDial = 0;
            end


        end

    end

    newMMpack = createEmptyMMpack(dial);
        
end

function MMpack = createEmptyMMpack(dial)
    %% Create MMPack structure
        
    MMpack_version = '';
    
    name = [dial{1} '_MMpack.mat'];
    description = '';   % Description of the experiment ('Mobility_2Avs2Bvs3A')
    groupName = '';               % Name of the experimental condition ('2A_cre' or '3A_wt'...)
    roundN = 1;                      % Number of round
    cellN = 1;   
    
    
    %% Common information
    info = [];
    
    info.name = name;                                                      % file name 
    info.groupName = groupName;                                            % for xample: 'mutation XX'...
    info.description = description;                                        % general description of the experiment
    info.round = roundN;                                                   % numbe of experimental round
    info.cell = cellN;                                                     % number identifying cell
    info.spaceUnits = 'µm';                                             % space units um, nm common for all modalities
    info.timeUnits = 'sec';                                              % time units 'sec','min' common for all modalitioes
    info.MMpack_version = MMpack_version;                                  % version od MMpack 
    
    
    %% WF data (wide-field, confocal, SIM or other pixel-brightness based images)
    
    planes = [];
    % planes = [];
    
    %% SMLM data (single molecule localizations)
    
    points = [];
    % points = [];
    
    %% Tracks (data from single particle tracking input)
    
    tracks = [];
        
    %% Model

    model = [];
    % model.soma = [];
    % model.dendrites = [];
    % model.spines = [];
    % model.synapses = [];

    %% Timeline

    timeline = [];

    %% Archive
    
    archive = [];
    
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
    MMpack.timeline = timeline;
    MMpack.results = results;
    MMpack.archive = archive;
    
    disp(MMpack)

end