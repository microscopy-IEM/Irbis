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

    %#DOC_PAGE; Title: Irbis file structure
    % Description:
    %   This page describes the main structure of an Irbis output file.
    %
    %   Detailed table column definitions are described on separate reference pages.

    branches = {'fullVolume','shaft','dendrite','spines','synapses'};

    baseStructs = struct();
    for i = 1:length(structTypes)
        structType = structTypes{i};
        switch structType

            %#DOC_SECTION info; Title: Info
            % Description: General metadata describing the Irbis file, version, dataset identity, units and save history.
            case 'info'
                info = struct();

                %#DOC_FIELD info.irbisVersion; Type: double; Unit:
                % Description: Irbis version used to create the file.
                info.irbisVersion = irbisVersion;

                %#DOC_FIELD info.matlabVersion; Type: char; Unit:
                % Description: MATLAB version used to create the file.
                info.matlabVersion = version;

                %#DOC_FIELD info.groupName; Type: char; Unit:
                % Description: 
                info.groupName = '';

                %#DOC_FIELD info.round; Type: double; Unit:
                % Description: 
                info.round = 1;

                %#DOC_FIELD info.cell; Type: double; Unit:
                % Description: 
                info.cell = 1;

                %#DOC_FIELD info.dish; Type: double; Unit:
                % Description: 
                info.dish = 1;    % For Irbis ver 1.12

                %#DOC_FIELD info.description; Type: char; Unit:
                % Description: 
                info.description = '';

                %#DOC_FIELD info.experimentDate; Type: datetime; Unit:
                % Description: 
                info.experimentDate = NaT;  % For Irbis ver 1.12

                %#DOC_FIELD info.notes; Type: char; Unit:
                % Description: 
                info.notes = '';

                %#DOC_FIELD info.spaceUnits; Type: char; Unit: 
                % Description: Units used for spatial measurements in the dataset.
                info.spaceUnits = 'µm'; 

                %#DOC_FIELD info.timeUnits; Type: char; Unit:
                % Description: Units used for temporal measurements in the dataset.
                info.timeUnits = 'sec';

                %#DOC_FIELD info.path; Type: char; Unit:
                % Description: Path to the working directory where file was saved (rewritten during saving).
                info.path = [pwd '\'];                      % rewritten during saving

                %#DOC_FIELD info.filename; Type: char; Unit:
                % Description: Filename of the saved Irbis file (rewritten during saving).
                info.filename = '';                         % rewritten during saving

                %#DOC_FIELD info.createTimestamp; Type: datetime; Unit:
                % Description: Timestamp when the structure was initially created.
                info.createTimestamp = datetime();

                %#DOC_FIELD info.saveTimestamp; Type: datetime; Unit:
                % Description: Timestamp when the structure was last saved (rewritten during saving).
                info.saveTimestamp = datetime();            % rewritten during saving
            
                baseStructs.info = info;


            %#DOC_SECTION timeline; Title: Timeline
            % Description: Structure for managing time points, current selections, and time-dependent indices.
            case 'timeline'

                timeline = struct();

                %#DOC_FIELD timeline.nTimePoints; Type: double; Unit:
                % Description: Number of time points present in the dataset.
                timeline.nTimePoints = 0;   % changed to 0 because 1 was causing problems when there was only 1 tp - it did not update the other currentIndexes

                %#DOC_FIELD timeline.currentTimePoint; Type: double; Unit:
                % Description: Currently selected time point index.
                timeline.currentTimePoint = 1;

                %#DOC_FIELD timeline.currentIndex.planes; Type: double / array; Unit:
                % Description: Index of the currently selected plane for each time point.
                timeline.currentIndex.planes = [];

                %#DOC_FIELD timeline.currentIndex.tracks; Type: double / array; Unit:
                % Description: Index of the currently selected track for each time point.
                timeline.currentIndex.tracks = [];

                %#DOC_FIELD timeline.currentIndex.points; Type: double / array; Unit:
                % Description: Index of the currently selected point for each time point.
                timeline.currentIndex.points = [];
                % model per-branch current index placeholders
                %#DOC_FIELD timeline.currentIndex.model; Type: struct; Unit:
                % Description: Per-branch indices of currently selected model objects for each time point.
                for branchNum = 1:numel(branches)
                    branch = branches{branchNum};
                    timeline.currentIndex.model.(branch) = [];
                end

                %#DOC_FIELD timeline.currentIndex.tools.areas; Type: double / array; Unit:
                % Description: Index(es) of the currently selected area tool entries.
                timeline.currentIndex.tools.areas = [];
        
                baseStructs.timeline = timeline;
        

            %#DOC_SECTION tools; Title: Tools
            % Description: Storage for user-defined tools and annotations, such as area selections.
            case 'tools'

                tools = struct();
            
                %#DOC_FIELD tools.areas; Type: struct; Unit:
                % Description: Storage for area-selection tool entries.
                tools.areas = [];

                %#DOC_FIELD tools.areas.List; Type: cell / table; Link: parameters/areas-table.md
                % Description: List/table of area tool entries.
                tools.areas.List{1} = createEmptyList('tools',0,{'areas'});
            
                baseStructs.tools = tools;
        
            %#DOC_SECTION views; Title: Views
            % Description: Storage for viewer configurations, camera positions, and related settings.
            case 'views'

                views = struct();
               
                %#DOC_FIELD views.storedViewsList; Type: table; Link: parameters/views-table.md
                % Description: Stored viewer configurations and camera positions.
                views.storedViewsList = createEmptyList('views');

                baseStructs.views = views;
        
            %#DOC_SECTION results; Title: Results
            % Description: Not used atm. 
            case 'results'

                results = struct();
                % not used for anything atm

                %#DOC_FIELD results; Type: struct; Unit:
                % Description: Placeholder for results and computed outputs.
            
                baseStructs.results = results;
        
                
            %#DOC_SECTION planes; Title: Planes
            % Description: Storage for structural image data, image stack parameters and spatial reference settings.
            case 'planes'

                planes = struct();

                % TO OPTIMIZE - convert integers to uint8?

                %#DOC_FIELD planes.refOrigFileName; Type: char; Unit:
                % Description: Original filename of the reference image.
                planes.refOrigFileName = '';

                %#DOC_FIELD planes.zstack; Type: array / numeric; Unit:
                % Description: Raw image data (z-stack), shape x*y*z*t*ch.
                planes.zstack = [];                                      % raw image data (multiple tiff of zstack or single tiff per channel) - dimensions x*y*z*t*ch

                %#DOC_FIELD planes.pixel_size; Type: double; Unit:
                % Description: Pixel size in spatial units.
                planes.pixel_size = [];                               % pixel size in defined units (micrometeres)

                %#DOC_FIELD planes.z_spacing; Type: double; Unit:
                % Description: Z-step spacing for z-stack images.
                planes.z_spacing = [];                                % step in Z-stack data

                %#DOC_FIELD planes.channelNames; Type: cell; Unit:
                % Description: Channel names list (e.g., {'GFP','Homer','DIC'}).
                planes.channelNames = {};                        % channel specification {'GFP','Homer','DIC'}

                %#DOC_FIELD planes.channelColors; Type: cell; Unit:
                % Description: Per-channel color specifications.
                planes.channelColors = {};

                %#DOC_FIELD planes.channelColormaps; Type: cell; Unit:
                % Description: Per-channel colormap settings.
                planes.channelColormaps = {};                  % default colormap is gray for all channels

                %#DOC_FIELD planes.channel_ranges; Type: cell; Unit:
                % Description: Per-channel histogram ranges for plotting.
                planes.channel_ranges = {};                      % histogram ranges for plotting

                %#DOC_FIELD planes.imSize; Type: double; Unit:
                % Description: Single-plane XY size in pixels.
                planes.imSize = [];                                 % single plane xy size in pixels 

                %#DOC_FIELD planes.nPlanes; Type: double; Unit:
                % Description: Number of Z planes in a stack.
                planes.nPlanes = [];

                %#DOC_FIELD planes.nChannels; Type: double; Unit:
                % Description: Number of channels in the dataset.
                planes.nChannels = [];

                %#DOC_FIELD planes.nTimePoints; Type: double; Unit:
                % Description: Number of time points in the image data.
                planes.nTimePoints = [];

                %#DOC_FIELD planes.bitDepth; Type: double; Unit:
                % Description: Bit depth of the image data (e.g., 8,16,32).
                planes.bitDepth = 16;                               % bit depth of the image data (8, 16, 32)

                %#DOC_FIELD planes.spacialRef; Type: imref2d; Unit:
                % Description: Spatial referencing object for 2D images.
                planes.spacialRef = imref2d();
                
                % reference image default settings
                % UNUSED - removed for 1.15: planes.refImParam.plane = [];

                %#DOC_FIELD planes.refImParam.depth; Type: double; Unit:
                % Description: Default reference image depth (z plane) used for registration.
                planes.refImParam.depth = [];

                %#DOC_FIELD planes.refImParam.channel; Type: double; Unit:
                % Description: Channel index used as reference image.
                planes.refImParam.channel = 1;                % channel used as reference image (synaptic marker, membrane marker...)

                % added during cropping
                %#DOC_FIELD planes.timeDrift; Type: numeric; Unit:
                % Description: Measured time drift applied to plane images (per time point).
                planes.timeDrift = [];
                % add zstack_adjusted? 

                baseStructs.planes = planes;
        
            %#DOC_SECTION tracks; Title: Tracks
            % Description: Storage for trajectories (loaded from the TrackMate files) and their parameters. 
            case 'tracks'

                tracks = struct();

                if ismember('timeDependent',timeDependencyType)
                    % disp('timeDependent in')

                    %#DOC_FIELD tracks.tracksOrigFileName; Type: cell; Unit:
                    % Description: Original filenames for track input per time point.
                    tracks.tracksOrigFileName = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.nTracks; Type: cell; Unit:
                    % Description: Number of tracks found per time point.
                    tracks.nTracks = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.nFrames; Type: cell; Unit:
                    % Description: Number of frames per time point.
                    tracks.nFrames = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.frameInterval; Type: cell; Unit:
                    % Description: Frame interval in temporal units (per time point).
                    tracks.frameInterval = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);                         % frame interval in defined units (sec)

                    %#DOC_FIELD tracks.group; Type: cell; Unit:
                    % Description: Group identifier for tracks per time point.
                    tracks.group = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.description; Type: cell; Unit:
                    % Description: Descriptive text for track sets per time point.
                    tracks.description = arrayfun(@(x) '', 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.driftCorrection; Type: cell; Unit:
                    % Description: Drift correction parameters applied to tracks per time point.
                    tracks.driftCorrection = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);

                    %#DOC_FIELD tracks.timeRange; Type: cell; Unit:
                    % Description: Time range information for tracks per time point.
                    tracks.timeRange = arrayfun(@(x) [], 1:nTimePoints, 'UniformOutput', false);
                
                    % Define table
                    T = createEmptyList('tracks');
                
                    %#DOC_FIELD tracks.tracksList; Type: cell; Link: parameters/tracks-table.md
                    % Description: Cell array of track tables, one per time point.
                    tracks.tracksList = arrayfun(@(x) T, 1:nTimePoints, 'UniformOutput', false);
                
                    %#DOC_FIELD tracks.filterTable; Type: cell; Unit:
                    % Description: (Deprecated) Filter tables per time point.
                    tracks.filterTable = arrayfun(@(x) table(), 1:nTimePoints, 'UniformOutput', false);     % TO FIX - remove, we do not use it anywhere

                end

                % tracks time-independent
                if ismember('timeIndependent',timeDependencyType)
                    % disp('timeIndependent in')
                    %#DOC_FIELD tracks.storedFilters; Type: FilteringStorage; Unit:
                    % Description: Storage object for filters applied to tracks.
                    tracks.storedFilters = FilteringStorage();

                    %#DOC_FIELD tracks.storedCategorizations; Type: CategorizationStorage; Unit:
                    % Description: Storage object for categorizations related to tracks.
                    tracks.storedCategorizations = CategorizationStorage();

                    %#DOC_FIELD tracks.storedSummarizedTables; Type: SummarizedTableStorageClass; Unit:
                    % Description: Storage for precomputed summarized tables for tracks.
                    tracks.storedSummarizedTables = SummarizedTableStorageClass();
                    
                    %#DOC_FIELD tracks.timePointPresent; Type: logical; Unit:
                    % Description: Flag indicating whether tracks include explicit time-point information.
                    tracks.timePointPresent = false;

                end
                
                baseStructs.tracks = tracks;


            %#DOC_SECTION points; Title: Points
            % Description: Storage for detected points and corresponding metadata.
            case 'points'
        
                points = struct();

                %#DOC_FIELD points.pointsList; Type: table; Link: parameters/points-table.md
                % Description: Table/list of detected or stored points.
                points.pointsList = createEmptyList('points');

                %#DOC_FIELD points.fileName; Type: char; Unit:
                % Description: Source filename for points data.
                points.fileName = '';

                %#DOC_FIELD points.registration; Type: struct; Unit:
                % Description: Registration parameters for points relative to images.
                points.registration = [];

                %#DOC_FIELD points.manualAlignment; Type: struct; Unit:
                % Description: Manual alignment adjustments applied to points.
                points.manualAlignment = [];

                %#DOC_FIELD points.storedSummarizedTables; Type: SummarizedTableStorageClass; Unit:
                % Description: Storage for summarized tables derived from points.
                points.storedSummarizedTables = SummarizedTableStorageClass();
            
                baseStructs.points = points;


            %#DOC_SECTION model; Title: Model
            % Description: Storage for branch-based model objects, object parameters, reconstruction settings and drift correction data.
            case 'model'

                model = struct();

                availableColors = {[0.88,0.06,0.88],[0.39,0.83,0.07],[0.06,1.00,1.00],[0.72,0.27,1.00],[0.92,0.20,0.20],[1.00,1.00,0.00]};
        
                %#DOC_FIELD model.branches; Type: cell; Unit:
                % Description: Names of model branches available in this dataset.
                model.branches = branches;

                %#DOC_FIELD model.selectableBranches; Type: cell; Unit:
                % Description: Subset of branches that are selectable in the UI.
                model.selectableBranches = {'fullVolume'};

                % primaryObjectBranches = {'fullVolume','synapses'};
                derivedObjectBranches = {'shaft'};

                % generating shared properties for all branches:
                for branchNum=1:size(branches,2)
                    branch = branches{branchNum};

                        %#DOC_FIELD model.(branch).Color; Type: double (1x3); Unit:
                        % Description: RGB color for objects in this branch.
                        model.(branch).Color = availableColors{branchNum};

                        %#DOC_FIELD model.(branch).Transparency; Type: double; Unit:
                        % Description: Transparency (alpha) for objects in this branch.
                        model.(branch).Transparency = 0.8;

                        %#DOC_FIELD model.(branch).Show; Type: logical / numeric; Unit:
                        % Description: Visibility flag for this branch in the viewer.
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
                    
                    %#DOC_FIELD model.(branch).List; Type: cell array of tables; Link: parameters/model-table.md
                    % Description: Cell array where each cell contains a table of objects for the time point defined by currentIndex in this branch. The table structure depends on the reconstruction method and branch type.
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

                        %#DOC_FIELD model.(branch).methodApplied; Type: char; Unit:
                        % Description: Reconstruction method applied to derived objects in this branch.
                        model.(branch).methodApplied = 'Constant diameter';
                    end

                    %#DOC_FIELD model.(branch).storedFilters; Type: FilteringStorage; Unit:
                    % Description: Stored filters for objects in this branch.
                    model.(branch).storedFilters = FilteringStorage();

                    %#DOC_FIELD model.(branch).storedCategorizations; Type: CategorizationStorage; Unit:
                    % Description: Stored categorizations for objects in this branch.
                    model.(branch).storedCategorizations = CategorizationStorage();

                    %#DOC_FIELD model.(branch).storedSummarizedTables; Type: SummarizedTableStorageClass; Unit:
                    % Description: Summarized tables storage for objects in this branch.
                    model.(branch).storedSummarizedTables = SummarizedTableStorageClass();
                end

                % General model features
                %#DOC_FIELD model.timeDrift; Type: double; Unit:
                % Description: Time-dependent drift vectors for the model (nTimePoints x 3).
                model.timeDrift = zeros(nTimePoints,3);

                %#DOC_FIELD model.timeDriftCorrected; Type: logical / numeric; Unit:
                % Description: Flag indicating if time drift correction has been applied.
                model.timeDriftCorrected = 0;

                %#DOC_FIELD model.driftCorrectedColumns; Type: cell; Unit:
                % Description: List of model property names that are corrected by drift compensation.
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
                "groupId",        "categorical", "",      "Identifier for the same object across time points";
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
                "edited",         "logical",     "",      "Boolean value indicating whether the object has been edited (semi)manually after creation"
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
