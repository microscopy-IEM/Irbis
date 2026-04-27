% structure definition 
function baseStructs = getBaseStruct(varargin)

    % varargins: 
    %     1: structTypes - which structures are being extracted from the base structure
    %     2: timeDependencyType
    %     3: nTimePoints

    irbisVersion = 1.17;    % Updated from 1.16 to 1.17 on 27.4.2026 - only relevant for model, changes how reconstruction parameters are kept
    % Updated from 1.15 to 1.16 on 15.3.2026 - only relevant for model
    % Updated from 1.14 to 1.15 on 21.6.2025

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
                planes.bitDepth = 16;                               % bit depth of the image data (8, 16, 32)
        
                planes.spacialRef = imref2d();
                
                % reference image default settings
                % UNUSED - removed for 1.15: planes.refImParam.plane = [];
                planes.refImParam.depth = [];
                planes.refImParam.channel = 1;                % channel used as reference image (synaptic marker, membrane marker...)
        
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
    
                % primaryObjectBranches = {'fullVolume','synapses'};
                derivedObjectBranches = {'shaft'};
    
                % generating shared properties for all branches:
                for branchNum=1:size(branches,2)
                    branch = branches{branchNum};

                        model.(branch).Color = availableColors{branchNum};
                        model.(branch).Transparency = 0.8;
                        model.(branch).Show = 0;
                        % 260427: PointCloud removed as we do not use it at all

                    % actual parameters will be obtained from IsourfaceGenerator or other relevant reconstruction method
                    % goal - make sure we keep all the changes in for example threshold, when a person changes it only for some time points
                    % adding properties specific for primary objects
                    % if ismember(branch,primaryObjectBranches)
                    %     model.(branch).reconstructionMethod = 'isosurface';   % default method for reconstruction - marching cubes
                        % decide whether reconstructionParameters should be a struct array or cell array
                        % struct array is sensitive on adding structures with different fields, but enables a person to see all values in one 'table' visually
                    %     model.(branch).reconstructionParameters = {};   % cellArray to store parameters relevant for the reconstruction method
                    % end

                    % all of this is specific to the reconstruction method - does not need to be in the default structure? 
                    % if ismember(branch,primaryObjectBranches)
                    %     model.(branch).threshold(1:nTimePoints) = 6000;
                    %     model.(branch).bleachCompensation = 0;
                    %     model.(branch).channel = 1;
                    %     % model.(branch).poissonDepthValue = 9;
                    %     % model.(branch).gaussFilterSigma = 0.5;
                    %     % model.(branch).fractionToKeep = 0.8;
                    %     % model.(branch).minVertexNum = 1;
                    %     model.(branch).scaleFactor = 0.75;
                    %     model.(branch).zScaleFactor = 0.5;
                    % end

                    % 260427: we are using currentIndex match order in the cell to timepoints, and therefore it does not make sense to generate the full cell here
                    model.(branch).List = {};
                    % for tp = 1:nTimePoints
                    %     model.(branch).List{tp} = createEmptyList(structType);
                    % end
    
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
                model.timeDrift = zeros(nTimePoints,3);
                model.timeDriftCorrected = 0;

                % List of columns that are affected by time drift correction
                model.driftCorrectedColumns = {'Mesh','Points','CentreLine','Contours','MiddlePoints','cuttingPlaneCentre'};
        
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
                varMeta = [
                    "areaId", "double", "", "";
                    "x",      "cell",   "", "";
                    "y",      "cell",   "", "";
                    "z",      "cell",   "", "";
                    "type",   "categorical", "", "";
                    "source", "categorical", "", ""
                ];
            else
                List = table();
                return
            end

        case 'views'
            varMeta = [
                "id",             "double", "", "";
                "rotation",       "cell",   "", "";
                "position",       "cell",   "", "";
                "checkBoxValues", "cell",   "", "";
                "selection",      "cell",   "", "";
                "name",           "string", "", ""
            ];

        case 'tracks'
            varMeta = [
                "id",        "double", "", "";
                "xyz",       "cell",   "", "";
                "frame_i",   "cell",   "", "";
                "color",     "cell",   "", "";
                "length",    "double", "", "";
                "nOfNaN",    "double", "", "";
                "maxGap",    "double", "", "";
                "meanDisp",  "double", "", "";
                "ovArea",    "double", "", "";
                "ovDist",    "double", "", "";
                "meanX",     "double", "", "";
                "meanY",     "double", "", "";
                "MSD5",      "double", "", "";
                "MSDr2",     "double", "", "";
                "zone",      "double", "", "";
                "type",      "string", "", "";
                "timePoint", "categorical", "", "";
                "excluded",  "logical", "", ""
            ];

        case 'points'
            varMeta = [
                "id",             "double",     "",     "";
                "frame",          "double",     "",     "";
                "x",              "double",     "um",   "";
                "y",              "double",     "um",   "";
                "z",              "double",     "um",   "";
                "uncertainty_xy", "double",     "um",   "";
                "uncertainty_z",  "double",     "um",   "";
                "height",         "double",     "um",   "";
                "maxIntensity",   "double",     "",     "";
                "inArea",         "logical",    "",     "";
                "timePoint",      "categorical", "",    "";
                "excluded",       "logical",    "",     ""
            ];

        case 'model'

            % TO OPTIMIZE - add volume, surface, ... right away? 

            % properties relevant to functionality within Irbis: color, excluded (filtering related), timePoint (propagates to ResultsViewer)
            % object features: volume, surface
            % time related: groupId
            % relatives: parent, children

            % deleting: prevTPid, nextTPid, Points, name (replacing with parentId - numerical instead of string)
            % renaming: cuttingPlaneCentre -> basePoint, cuttingPlaneNormal -> basePointNormal

            % Define variable metadata: {name, type, unit, description}
            varMeta = [
                "groupId",        "double",      "",      "Identifier for the same object across time points";
                "Mesh",           "cell",        "",      "Mesh data stored as a surfaceMesh object";
                "parentId",       "double",      "",      "Value used to identify objects coming from the same parent object (e.g. spines coming from the same fullVolume)";
                "parent",         "cell",        "",      "Information about parent objects, stored in dictionary";
                "children",       "cell",        "",      "Information about children objects, stored in dictionary";
                "volume",         "double",      "um^3",  "Enclosed 3D volume of the object mesh";
                "surface",        "double",      "um^2",  "Total surface area of the object mesh";
                "positionShift",  "cell",        "um",    "Individual shift in object position";
                "color",          "cell",        "",      "Individual object color, stored as RGB triplet";
                "excluded",       "logical",     "",      "Boolean value indicating whether the object is excluded by filters";
                "timePoint",      "categorical", "",      "";
            ];

            % Add derived features if needed
            if ismember('derived', specialTypes)
                varMeta = [varMeta;
                    "CentreLine",   "cell",   "um", "";
                    "RadiusVect",   "cell",   "um", "Radius vector";
                    "ZScale",       "cell",   "", "Deformation factor in Z direction applied when using constant shaft";
                    "Contours",     "cell",   "um", "";
                    "MiddlePoints", "cell",   "um", "List of middle points corresponding to each contour point";
                    "RadiusScale",  "double", "", ""
                ];
            end

            if ismember('spines', specialTypes)
                varMeta = [varMeta;
                    "basePoint",       "double", "um", "Base point position calculated as centroid of the base patch vertices, attached to its surface";
                    "basePointNormal", "double", "", "Normal vector of the base patch in the base point";
                    "basePatch",       "cell",   "", "List of stuctures, each containing the vertices and faces of the patch where the spine is cut from the shaft";
                ];
            end

            % varNames = ["groupId", "Mesh", "name", "nextTPid", "parent", "children", "volume", "surface", "positionShift", "color", "excluded", "timePoint"];
            % varTypes = ["double", "cell", "string", "double", "cell", "cell", "double", "double", "cell", "cell", "logical", "categorical"];
        
            % if ismember('derived',specialTypes)
            %     addedNames = ["CentreLine","RadiusVect","ZScale","Contours","MiddlePoints","RadiusScale"];
            %     addedTypes = ["cell","cell","cell","cell","cell","double"];
        
            %     varNames = [varNames,addedNames];
            %     varTypes = [varTypes,addedTypes];
            % end
        
            % if ismember('spines',specialTypes)
            %     addedNames = ["basePoint", "basePointNormal", "basePatch"];
            %     addedTypes = ["double", "double", "cell"];
        
            %     varNames = [varNames,addedNames];
            %     varTypes = [varTypes,addedTypes];
            % end
    end

    varNames = varMeta(:,1)';
    varTypes = varMeta(:,2)';
    sz = [nRows numel(varNames)];
    List = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    % Assign metadata
    List.Properties.VariableUnits = varMeta(:,3)';
    List.Properties.VariableDescriptions = varMeta(:,4)';

    % sz = [nRows numel(varNames)];
    % List = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
end
