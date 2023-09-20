% Function creates new empty MMpack with help of an input dialog
function newMMpack = newMMpackDialog()

    repeatDial = 1;

    while repeatDial
    
        dial = inputdlg({'Name','Group','Description','Round','Cell number','Space units','Time units'},...
                      'New MMpack', [1 50; 1 30; 1 30; 1 7; 1 7; 1 7; 1 7],{'test','test','test','2','1','µm','sec'}); 

        % dial = inputdlg({'Name','Group','Description','Round','Cell number','Space units','Time units'},...
        %               'New MMpack', [1 50; 1 30; 1 30; 1 7; 1 7; 1 7; 1 7],{'GF3A_Homer_mice2a2b_1518_QD605_01','noCre','mice2a2b','2','1','µm','sec'}); 
        waitfor(dial);
    
        if ~isempty(dial)
        
            if isnan(str2double(dial{4}))
                
                f = warndlg('Round must be numeric (1,2,3...)','Warning');
                waitfor(f);
        
            elseif isempty(dial{1})
        
                f = warndlg('Name must be filled','Warning');
                waitfor(f);
        
            elseif isempty(dial{2})
        
                f = warndlg('Group must be filled','Warning');
                waitfor(f);
        
            elseif isempty(dial{3})
        
                f = warndlg('Description must be filled','Warning');
                waitfor(f);

            elseif isempty(dial{5})
        
                f = warndlg('Cell number must be filled','Warning');
                waitfor(f);
            
            else
                repeatDial = 0;
            end
    
        else
            disp('User canceled')
            newMMpack = [];
            return
        end
    
    end
    
    newMMpack = createEmptyMMpack(dial);
        
end

function MMpack = createEmptyMMpack(dial)
    %% Create MMPack structure
        
    MMpack_version = '0.5';
    
    name = [dial{1} '_MMpack.mat'];
    description = dial{3};   % Description of the experiment ('Mobility_2Avs2Bvs3A')
    groupName = dial{2};               % Name of the experimental condition ('2A_cre' or '3A_wt'...)
    roundN = str2double(dial{4});                      % Number of round
    cellN = str2double(dial{5});   
    
    
    %% Common information
    info = [];
    
    info.name = name;                                                      % file name 
    info.groupName = groupName;                                            % for xample: 'mutation XX'...
    info.description = description;                                        % general description of the experiment
    info.round = roundN;                                                   % numbe of experimental round
    info.cell = cellN;                                                     % number identifying cell
    info.spaceUnits = dial{5};                                             % space units um, nm common for all modalities
    info.timeUnits = dial{6};                                              % time units 'sec','min' common for all modalitioes
    info.MMpack_version = MMpack_version;                                  % version od MMpack 
    
    
    %% WF data (wide-field, confocal, SIM or other pixel-brightness based images)
    
    wf = [];
    
    %% SMLM data (single molecule localizations)
    
    smlm = [];
    
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
    MMpack.wf = wf;
    MMpack.storm = smlm;
    MMpack.tracks = tracks;
    MMpack.model = model;
    MMpack.timeline = timeline;
    MMpack.results = results;
    MMpack.archive = archive;
    
    disp(MMpack)

end