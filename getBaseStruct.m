% structure definition 
function baseStructs = getBaseStruct(varargin)

    % varargins: 
    %     1: structTypes - which structures are being extracted from the base structure
    %     2: timeDependencyType
    %     3: nTimePoints

    irbisVersion = 1.14;

    structTypes = {'info','timeline','tools','views','results','planes','tracks','points','model'};
    timeDependencyType = {'timeDependent','timeIndependent'};
    nTimePoints = 1;

    % special case - generating just table instead of structure
    if nargin > 0
        if isequal(varargin{1},'table')
            structType = varargin{2};
            nRows = varargin{3};
            branchTypes = {};
            if nargin > 3
                branchTypes = varargin{4};
            end
            baseStructs = createEmptyList(structType,nRows,branchTypes);
            return
        elseif isequal(varargin{1},'irbisVersion')
            baseStructs = irbisVersion;
            return
        end
    end

    if nargin > 0
        structTypes = varargin{1};
        if isequal(structTypes,'init')
            structTypes = {'info','timeline','tools','views','results'};
        elseif ~iscell(structTypes)
            structTypes = {structTypes};
        end
    end

    if nargin > 1
        timeDependencyType = varargin{2};
        if ~iscell(timeDependencyType)
            timeDependencyType = {timeDependencyType};
        end
        nTimePoints = varargin{3};
    end

    branches = {'fullVolume','shaft','dendrite','spines','synapses'};

    baseStructs = struct();
    for i = 1:length(structTypes)
        structType = structTypes{i};
        switch structType

            case 'info'

                % what to store into info
                    % Irbis version - creating new
                    % Matlab version - creating new
                    % date created - creating/storing? 
                    % Irbis name - storing
                    % something like processing notes? 
                        % any way how to store multiple versions? 
        
                info = struct();
        
                info.irbisVersion = irbisVersion;
                info.matlabVersion = version;
                info.groupName = '';
                info.round = 1;
                info.cell = 1;
                info.dish = 1;    % For Irbis ver 1.12
                info.description = '';
                info.experimentDate = NaT;  % For Irbis ver 1.12
                info.notes = '';
                info.spaceUnits = 'µm'; 
                info.timeUnits = 'sec';
                info.path = [pwd '\'];                      % rewritten during saving
                info.filename = '';                         % rewritten during saving
                info.createTimestamp = datetime();
                info.saveTimestamp = datetime();            % rewritten during saving
            
                baseStructs.info = info;
                % info

            case 'timeline'

                timeline = struct();
        
                timeline.nTimePoints = 0;   % changed to 0 because 1 was causing problems when there was only 1 tp - it did not update the other currentIndexes
                timeline.currentTimePoint = 1;
                timeline.currentIndex.planes = [];
                timeline.currentIndex.tracks = [];
                timeline.currentIndex.points = [];
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
                    timeline.currentIndex.model.(branch) = [];
                end
                timeline.currentIndex.tools.areas = [];
        
                baseStructs.timeline = timeline;
        
            case 'tools'

                tools = struct();
            
                tools.areas = [];
                tools.areas.List{1} = createEmptyList('tools',0,{'areas'});
            
                baseStructs.tools = tools;
        
            case 'views'

                views = struct();
               
                views.storedViewsList = createEmptyList('views');

                baseStructs.views = views;
        
            case 'results'

                results = struct();
                % not used for anything atm
            
                baseStructs.results = results;
        
            case 'planes'

                planes = struct();

                % TO OPTIMIZE - convert integers to uint8?
                planes.refOrigFileName = '';
                planes.zstack = [];                                      % raw image data (multiple tiff of zstack or single tiff per channel) - dimensions x*y*z*t*ch
                planes.pixel_size = [];                               % pixel size in defined units (micrometeres)
                planes.z_spacing = [];                                % step in Z-stack data
                planes.channelNames = {};                        % channel specification {'GFP','Homer','DIC'}
                planes.channelColors = {};
                planes.channelColormaps = {};                  % default colormap is gray for all channels
                planes.channel_ranges = {};                      % histogram ranges for plotting
                planes.imSize = [];                                 % single plane xy size in pixels 
                planes.nPlanes = [];
                planes.nChannels = [];
                planes.nTimePoints = [];
        
                planes.spacialRef = imref2d();
                
                % reference image default settings
                planes.refImParam.plane = [];
                planes.refImParam.depth = [];
                planes.refImParam.channel = [];                % channel used as reference image (synaptic marker, membrane marker...)
        
                % added during cropping
                planes.timeDrift = [];
                % add zstack_adjusted? 
        
                baseStructs.planes = planes;
        
            case 'tracks'

                tracks = struct();

                if ismember('timeDependent',timeDependencyType)
                    % disp('timeDependent in')

                    tracks.tracksOrigFileName = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.nTracks = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.nFrames = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.frameInterval = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);                         % frame interval in defined units (sec)
                    tracks.group = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.description = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.driftCorrection = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.timeRange = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                
                    % Define table
                    T = createEmptyList('tracks');
                
                    tracks.tracksList = arrayfun(@(x) T, 1:nTimePoints, 'UniformOutput', false);
                
                    tracks.filterTable = arrayfun(@(x) table(), 1:nTimePoints, 'UniformOutput', false);

                end

                % tracks time-independent
                if ismember('timeIndependent',timeDependencyType)
                    % disp('timeIndependent in')
                    tracks.storedFilters = FilteringStorage();
                    tracks.storedCategorizations = CategorizationStorage();
                    tracks.storedSummarizedTables = SummarizedTableStorageClass();
                    
                    tracks.timePointPresent = false;

                end
                
                baseStructs.tracks = tracks;

            case 'points'
        
                points = struct();

                points.pointsList = createEmptyList('points');
                points.fileName = '';
                points.registration = [];
                points.manualAlignment = [];

                points.storedSummarizedTables = SummarizedTableStorageClass();
            
                baseStructs.points = points;

            case 'model'

                model = struct();

                availableColors = {[0.88,0.06,0.88],[0.39,0.83,0.07],[0.06,1.00,1.00],[0.72,0.27,1.00],[0.92,0.20,0.20],[1.00,1.00,0.00]};
        
                % lets introduce branches here - later we can have different model with different brach names
                model.branches = branches;
                model.selectableBranches = {'fullVolume'};
    
                primaryObjectBranches = {'fullVolume','synapses'};
                derivedObjectBranches = {'shaft'};
    
                % generating shared properties for all branches:
                for branchNum=1:size(branches,2)
                    branch = branches{branchNum};

                        model.(branch).Color = availableColors{branchNum};
                        model.(branch).Transparency = 0.8;
                        model.(branch).Show = 0;
                        model.(branch).PointCloud = cell(nTimePoints,1); 

                    % adding properties specific for primary objects
                    if ismember(branch,primaryObjectBranches)
                        model.(branch).threshold(1:nTimePoints) = 6000;
                        model.(branch).bleachCompensation = 0;
                        model.(branch).channel = 1;
                        model.(branch).poissonDepthValue = 9;
                        model.(branch).gaussFilterSigma = 0.5;
                        model.(branch).fractionToKeep = 0.8;
                        model.(branch).minVertexNum = 1;
                        model.(branch).scaleFactor = 0.75;
                        model.(branch).zScaleFactor = 0.5;
                    end

                    for tp = 1:nTimePoints
                        model.(branch).List{tp} = createEmptyList(structType);
                    end
    
                    % generating unique properties for derived object - shaft:
                    if ismember(branch,derivedObjectBranches)

                        % for tp = 1:nTimePoints
                        %     model.(branch).List{tp}.CentreLine = cell(size(model.(branch).List{tp},1),1);
                        %     model.(branch).List{tp}.RadiusVect = cell(size(model.(branch).List{tp},1),1);
                        %     model.(branch).List{tp}.ZScale = cell(size(model.(branch).List{tp},1),1);
                        %     model.(branch).List{tp}.Contours = cell(size(model.(branch).List{tp},1),1);
                        %     model.(branch).List{tp}.MiddlePoints = cell(size(model.(branch).List{tp},1),1);
                        % end
                        model.(branch).methodApplied = 'Constant diameter';
                    end

                    model.(branch).storedFilters = FilteringStorage();
                    model.(branch).storedCategorizations = CategorizationStorage();
                    model.(branch).storedSummarizedTables = SummarizedTableStorageClass();
                end

                % General model features
                % timeDrift = repmat({[0 0 0]},1,nTimePoints);
                model.timeDrift = zeros(nTimePoints,3);
                model.timeDriftCorrected = 0;
        
                baseStructs.model = model;

            otherwise

                disp([structType ' is not defined'])
                baseStructs.(structType) = struct();
                break
        end

    end
end

function List = createEmptyList(structType,varargin)
    nRows = 0;
    specialTypes = {};
    if nargin == 2
        nRows = varargin{1};
    elseif nargin == 3
        nRows = varargin{1};
        specialTypes = varargin{2};
    end

    switch structType
        case 'tools'

            if ismember('areas',specialTypes)
                varNames = ["areaId","x","y",'z',"type",'source'];
                varTypes = ["double","cell","cell","cell","categorical","categorical"];
            end

        case 'views'

            varNames = ["id","rotation","position","checkBoxValues",'selection','name'];  
            varTypes = ["double","cell","cell","cell","cell","string"];

        case 'tracks'

            varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
            varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};

        case 'points'

            varNames = ["id","frame","x","y","z","uncertainty_xy","uncertainty_z","height","maxIntensity",'inArea'];
            varTypes = ["double","double","double","double","double","double","double","double","double",'logical'];

        case 'model'

            % TO OPTIMIZE - add volume, surface, ... right away? 

            varNames = ["groupId","Points","Mesh","name","prevTPid","nextTPid","parent","children","volume","surface","positionShift","color","excluded"];
            varTypes = ["double","cell","cell","string","double","double","cell","cell","double","double","cell","cell","logical"];
        
            if ismember('derived',specialTypes)
                addedNames = ["CentreLine","RadiusVect","ZScale","Contours","MiddlePoints","RadiusScale"];
                addedTypes = ["cell","cell","cell","cell","cell","double"];
        
                varNames = [varNames,addedNames];
                varTypes = [varTypes,addedTypes];
            end
        
            if ismember('spines',specialTypes)
                addedNames = ["cuttingPlaneCentre","cuttingPlaneNormal"];
                addedTypes = ["double","double"];
        
                varNames = [varNames,addedNames];
                varTypes = [varTypes,addedTypes];
            end

    end

    sz = [nRows numel(varNames)];
    List = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
end
