function List = createEmptyListFcn(structType,varargin)
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

            varNames = ["groupId","Points","Mesh","name","prevTPid","nextTPid","parent","children","volume","surface","positionShift"];
            varTypes = ["double","cell","cell","string","double","double","cell","cell","double","double","cell"];
        
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