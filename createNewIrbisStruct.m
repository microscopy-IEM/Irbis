function newIrbisStruct = createNewIrbisStruct()

    irbisVersion = 1.1;

    %% info
    info = struct;

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
    
    %% tools
    tools = struct();

    tools.areas = [];
    sz = [0 6];
    varTypes = ["double","cell","cell","cell","categorical","categorical"];
    varNames = ["areaId","x","y",'z',"type",'source'];
    AreasTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    tools.areas.list = AreasTable;

    %% views
    views = struct();

    sz = [0 6];
    varTypes = ["double","cell","cell","cell","cell","string"];
    varNames = ["id","rotation","position","checkBoxValues",'selection','name'];      
    views.storedViewsList = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

    %% results
    results = struct();
    % not used for anything atm

    % put together 
    newIrbisStruct.info = info;
    newIrbisStruct.tools = tools;
    newIrbisStruct.views = views;
    newIrbisStruct.results = results;

end