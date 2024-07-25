% structure definition 
function baseStructs = getBaseStruct(varargin)

    if nargin > 0
        structTypes = varargin{1};
        if isequal(structTypes,'init')
            structTypes = {'info','timeline','tools','views','results'};
        elseif ~iscell(structTypes)
            structTypes = {structTypes};
        end
    else
        structTypes = {'info','timeline','tools','views','results','planes','tracks','points','model'};
    end

    if nargin > 1
        timeDependencyType = varargin{2};
        if ~iscell(timeDependencyType)
            timeDependencyType = {timeDependencyType};
        end
        nTimePoints = varargin{3};
    else
        timeDependencyType = {'timeDepedent','timeIndependent'};
        nTimePoints = 1;
    end

    irbisVersion = 1.1;

    baseStructs = struct();
    for i = 1:length(structTypes)
        structType = structTypes{i};
        switch structType

            case 'info'
        
                info = struct();
        
                info.irbisVersion = irbisVersion;
                info.matlabVersion = version;
                info.groupName = '';
                info.round = 1;
                info.cell = 1;
                info.description = '';
                info.notes = '';
                info.spaceUnits = 'µm'; 
                info.timeUnits = 'sec';
                info.path = [pwd '\'];                      % rewritten during saving
                info.filename = '';                         % rewritten during saving
                info.createTimestamp = datetime();
                info.saveTimestamp = datetime();            % rewritten during saving
            
                baseStructs.info = info;

            case 'timeline'

                timeline = struct();
        
                timeline.nTimePoints = 1;
                timeline.currentTimePoint = 1;
                timeline.currentIndex = struct();
        
                baseStructs.timeline = timeline;
        
            case 'tools'

                tools = struct();
            
                tools.areas = [];
                sz = [0 6];
                varTypes = ["double","cell","cell","cell","categorical","categorical"];
                varNames = ["areaId","x","y",'z',"type",'source'];
                AreasTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
                tools.areas.list = AreasTable;
            
                baseStructs.tools = tools;
        
            case 'views'

                views = struct();
            
                sz = [0 6];
                varTypes = ["double","cell","cell","cell","cell","string"];
                varNames = ["id","rotation","position","checkBoxValues",'selection','name'];      
                views.storedViewsList = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
            
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

                    tracks.tracksOrigFileName = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.nTracks = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.nFrames = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.frameInterval = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);                         % frame interval in defined units (sec)
                    tracks.group = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.description = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);
                    tracks.driftCorrection = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                    tracks.timeRange = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                
                    % Define table
                    varNames = {'id';'xyz';'frame_i';'color';'length';'nOfNaN';'maxGap';'meanDisp';'ovArea';'ovDist';'meanX';'meanY';'MSD5';'MSDr2';'zone';'type'};
                    varTypes = {'double','cell','cell','cell','double','double','double','double','double','double','double','double','double','double','double','string'};
                    sz = [0 numel(varNames)];
                    T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
                
                    tracks.tracksList = arrayfun(@(x) T, 1:nTimePoints, 'UniformOutput', false);
                
                    tracks.filterTable = arrayfun(@(x) table(), 1:nTimePoints, 'UniformOutput', false);

                end

                % tracks time-independent
                if ismember('timeIndependent',timeDependencyType)
                    tracks.storedFilters = FilteringStorage();
                    tracks.storedCategorizations = CategorizationStorage();
                    
                    tracks.timePointPresent = false;

                end
                
                baseStructs.tracks = tracks;

            case 'points'
        
                points = struct();
        
                points.pointsList = table();
                points.fileName = '';
                points.registration = [];
                points.manualAlignment = [];
            
                baseStructs.points = points;
            case 'model'
                nTimePoints = 1;
                model = struct();
        
                    % lets introduce branches here - later we can have different model with different brach names
                    branches = {'fullVolume','shaft','dendrite','spines','synapses'};
                    model.branches = branches;
                    model.selectableBranches = {'fullVolume'};
        
                    primaryObjectBranches = {'fullVolume','synapses'};
                    derivedObjectBranches = {'shaft'};
        
                    % generating shared properties for all branches:
                    for branchNum=1:size(branches,2)
                        branch = branches{branchNum};
                        model.(branch).Color = [];
                        model.(branch).Transparency = 0.8;
                        model.(branch).Show = 0;
                        model.(branch).PointCloud = cell(nTimePoints,1); 
                            
                        for currentTimePoint = 1:nTimePoints
                            model.(branch).List{currentTimePoint} = createEmptyList();
                        end
            
                        % adding properties specific for primary objects
                        if ismember(branch,primaryObjectBranches)
                            model.(branch).threshold(1:nTimePoints) = 6000;
                            model.(branch).bleachCompensation = 0;
                        end
        
                        % generating unique properties for derived object - shaft:
                        if ismember(branch,derivedObjectBranches)
                            for currentTimePoint = 1:nTimePoints
                                model.(branch).List{currentTimePoint}.CentreLine = cell(size(model.(branch).List{currentTimePoint},1),1);
                                model.(branch).List{currentTimePoint}.RadiusVect = cell(size(model.(branch).List{currentTimePoint},1),1);
                                model.(branch).List{currentTimePoint}.ZScale = cell(size(model.(branch).List{currentTimePoint},1),1);
                                model.(branch).List{currentTimePoint}.Contours = cell(size(model.(branch).List{currentTimePoint},1),1);
                                model.(branch).List{currentTimePoint}.MiddlePoints = cell(size(model.(branch).List{currentTimePoint},1),1);
                            end
                        end
        
                    end
            
                    % General model features
                    timeDrift = repmat({[0 0 0]},1,1);
                    model.timeDrift = timeDrift;
                    model.timeDriftCorrected = 0;
        
                baseStructs.model = model;

            otherwise

                disp([structType ' is not defined'])
                baseStructs.(structType) = struct();
                break
        end

    end
end

function List = createEmptyList()
    sz = [0 11];
    varTypes = ["double","cell","cell","string","double","double","cell","cell","double","double","cell"];
    varNames = ["groupId","Points","Mesh","name",'prevTPid','nextTPid','parent','children','volume','surface','positionShift'];
    List = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
end