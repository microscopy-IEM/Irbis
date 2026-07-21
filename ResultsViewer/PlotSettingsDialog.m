classdef PlotSettingsDialog < handle
    % PlotSettingsDialog builds a compact, reusable panel for plot rendering options.
    %
    % The dialog is intentionally driven by small control specifications. That
    % keeps IrbisResultsViewer from knowing how individual settings are rendered,
    % and it lets future plot settings be added by extending getControlSpecs()
    % rather than duplicating layout and callback code.

    properties (Access = private)
        UIFigure
        PlotManagerHandle
        ControlHandles = struct()
    end

    methods (Static)
        function dialog = show(parentFigure, plotManagerHandle)
            % Keep app callbacks simple: PlotSettingsDialog.show(app.UIFigure, app.plotManagerHandle)
            % creates the window and stores the dialog object on the figure so it
            % remains alive even if the caller does not keep the return value.
            dialog = PlotSettingsDialog(parentFigure, plotManagerHandle);
        end
    end

    methods
        function obj = PlotSettingsDialog(parentFigure, plotManagerHandle)
            if nargin < 1
                parentFigure = [];
            end

            if nargin < 2 || isempty(plotManagerHandle)
                error('PlotSettingsDialog:MissingPlotManager', 'A PlotManager handle is required.');
            end

            obj.PlotManagerHandle = plotManagerHandle;
            obj.build(parentFigure);
        end

        function delete(obj)
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure)
                delete(obj.UIFigure);
            end
        end
    end

    methods (Access = private)
        function build(obj, parentFigure)
            settings = obj.PlotManagerHandle.getPlotSettings();
            controlSpecs = obj.getControlSpecs(settings);

            obj.UIFigure = uifigure( ...
                'Name', 'Plot Settings', ...
                'Position', obj.getDialogPosition(parentFigure, numel(controlSpecs)), ...
                'Resize', 'off');

            % Store the handle object on the figure. UI callbacks reference obj,
            % but this also makes the lifetime explicit and easy to inspect.
            obj.UIFigure.UserData = obj;

            mainGrid = uigridlayout(obj.UIFigure, [numel(controlSpecs), 2]);
            mainGrid.RowHeight = repmat({28}, 1, numel(controlSpecs));
            mainGrid.ColumnWidth = {105, '1x'};
            mainGrid.Padding = [12 12 12 12];
            mainGrid.RowSpacing = 8;
            mainGrid.ColumnSpacing = 10;

            for specId = 1:numel(controlSpecs)
                obj.addControl(mainGrid, controlSpecs{specId}, specId);
            end
        end

        function addControl(obj, parentGrid, spec, rowId)
            label = uilabel(parentGrid, 'Text', spec.label);
            label.Layout.Row = rowId;
            label.Layout.Column = 1;

            switch spec.type
                case "checkbox"
                    control = uicheckbox(parentGrid, ...
                        'Text', '', ...
                        'Value', logical(spec.value), ...
                        'ValueChangedFcn', @(src, ~) obj.applySetting(spec.name, src.Value));
                case "dropdown"
                    control = uidropdown(parentGrid, ...
                        'Items', cellstr(spec.items), ...
                        'Value', char(spec.value), ...
                        'ValueChangedFcn', @(src, ~) obj.applySetting(spec.name, src.Value));
                case "color"
                    control = uicolorpicker(parentGrid, ...
                        'Value', spec.value, ...
                        'ValueChangedFcn', @(src, ~) obj.applySetting(spec.name, src.Value));
                otherwise
                    error('PlotSettingsDialog:UnsupportedControlType', 'Unsupported control type: %s', spec.type);
            end

            control.Layout.Row = rowId;
            control.Layout.Column = 2;
            obj.ControlHandles.(char(spec.name)) = control;
        end

        function applySetting(obj, name, value)
            % The dialog deliberately sends only name/value pairs. PlotManager
            % decides how a setting affects current data, cached rendering, or
            % future formatting.
            obj.PlotManagerHandle.setPlotSetting(name, value);
        end
    end

    methods (Static, Access = private)
        function controlSpecs = getControlSpecs(settings)
            % Each spec uses the same fields so the builder can remain generic.
            % Add new plot controls here first; the layout and callback wiring
            % below will follow automatically for supported control types.
            controlSpecs = {
                struct( ...
                    'name', "useJitter", ...
                    'label', 'Jitter', ...
                    'type', "checkbox", ...
                    'items', strings(0, 1), ...
                    'value', settings.useJitter)
                struct( ...
                    'name', "lineErrorMetric", ...
                    'label', 'Error metric', ...
                    'type', "dropdown", ...
                    'items', ["sem", "std", "ci95", "none"], ...
                    'value', settings.lineErrorMetric)
                struct( ...
                    'name', "lineErrorStyle", ...
                    'label', 'Error style', ...
                    'type', "dropdown", ...
                    'items', ["shaded", "bars"], ...
                    'value', settings.lineErrorStyle)
                struct( ...
                    'name', "lineColor", ...
                    'label', 'Line color', ...
                    'type', "color", ...
                    'items', strings(0, 1), ...
                    'value', settings.lineColor)
                struct( ...
                    'name', "lineErrorColor", ...
                    'label', 'Error color', ...
                    'type', "color", ...
                    'items', strings(0, 1), ...
                    'value', settings.lineErrorColor)
            };
        end

        function position = getDialogPosition(parentFigure, controlNum)
            width = 290;
            height = 24 + controlNum * 36;

            if isempty(parentFigure) || ~isvalid(parentFigure)
                position = [100 100 width height];
                return
            end

            parentPosition = parentFigure.Position;
            x = parentPosition(1) + max(20, (parentPosition(3) - width) / 2);
            y = parentPosition(2) + max(20, (parentPosition(4) - height) / 2);
            position = [x y width height];
        end
    end
end
