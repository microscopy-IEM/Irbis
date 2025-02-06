classdef ResultsView < handle
    properties
        viewName = 'DefaultView'
        modality
        branch
        table1 = struct('type', 'Full', 'data', [], 'columnNames', [], 'rowNames', [])
        table2 = struct('type', [], 'data', [], 'columnNames', [], 'rowNames', [])
        plotType = 'histogram'
        categoricalAsLabels = false
        xLog = false
        yLog = false
    end

    methods
        function obj = ResultsView(viewName, modality, branch, table1, table2, plotType, categoricalAsLabels, xLog, yLog)
            obj.viewName = viewName;
            obj.modality = modality;
            obj.branch = branch;
            obj.table1 = table1;
            obj.table2 = table2;
            obj.plotType = plotType;
            obj.categoricalAsLabels = categoricalAsLabels;
            obj.xLog = xLog;
            obj.yLog = yLog;
        end


        function renameView(obj)
            prompt = {'Enter new view name:'};
            dlgtitle = 'Rename view';
            dims = [1 35];
            definput = {obj.viewName};
            answer = inputdlg(prompt, dlgtitle, dims, definput);
            if ~isempty(answer)
                obj.viewName = answer{1};
            end
        end


        function printView(obj)
            disp('View Name: ')
            disp(obj.viewName)
            disp('Table 1: ')
            disp(obj.table1)
            disp('Table 2: ')
            disp(obj.table2)
            disp('Plot Type: ')
            disp(obj.plotType)
            disp('Categorical As Labels: ')
            disp(obj.categoricalAsLabels)
            disp('X Log: ')
            disp(obj.xLog)
            disp('Y Log: ')
            disp(obj.yLog)
        end
    end

end