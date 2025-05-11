% ThrowawayColumnSelectionState.m
classdef ThrowawayColumnSelectionState < handle
    properties (Access = private)
        selections % dict of keys 'modality/branch' -> cell array of column names
            % I cannot set 'selection dictionary', it causes problems
    end

    methods
        function obj = ThrowawayColumnSelectionState()
            obj.selections = configureDictionary('char', 'cell');
        end

        function setSelection(obj, modality, branch, columns)
            key = obj.makeKey(modality, branch);
            obj.selections(key) = {columns};    % needs to be packed in one more cell to prevent problem with size
        end

        function columns = getSelection(obj, modality, branch)
            key = obj.makeKey(modality, branch);
            if isKey(obj.selections, key)
                columnsCell = obj.selections(key);
                columns = columnsCell{1}; % Extract the cell array from the dictionary
            else
                columns = {};
            end
        end

        function columns = getSelectionForModalityPath(obj, modalityPath)
            % Extract modality and branch from modalityPath
            if isequal(numel(modalityPath), 1)
                modality = modalityPath{1};
                branch = '';
            else
                modality = modalityPath{1};
                branch = modalityPath{2};
            end

            % Get the selection for the given modality and branch
            columns = obj.getSelection(modality, branch);
        end

        function selectionExists = hasSelection(obj, modality, branch)
            key = obj.makeKey(modality, branch);
            selectionExists = isKey(obj.selections, key);
        end

        % function structData = toStruct(obj)
        %     % Convert the dictionary to a nested struct
        %     keys = keys(obj.selections);
        %     structData = struct();
        %     for i = 1:numel(keys)
        %         key = keys{i};
        %         [modality, branch] = obj.splitKey(key);
        %         if ~isfield(structData, modality)
        %             structData.(modality) = struct();
        %         end
        %         structData.(modality).(matlab.lang.makeValidName(branch)) = struct( ...
        %             'modalityPath', key, ...
        %             'columnCellArray', obj.selections(key) ...
        %         );
        %     end
        % end

        % function fromStruct(obj, structData)
        %     % Load the nested struct into the dictionary
        %     modalities = fieldnames(structData);
        %     for i = 1:numel(modalities)
        %         modality = modalities{i};
        %         branches = fieldnames(structData.(modality));
        %         for j = 1:numel(branches)
        %             branch = branches{j};
        %             entry = structData.(modality).(branch);
        %             obj.selections(entry.modalityPath) = entry.columnCellArray;
        %         end
        %     end
        % end
    end

    methods (Access = private)
        function key = makeKey(~, modality, branch)
            if isempty(branch)
                key = modality;
            else
                key = [modality '/' branch];
            end
            key = string(key); % Ensure the key is a string
        end

        % function [modality, branch] = splitKey(~, key)
        %     % Split the key into modality and branch
        %     parts = strsplit(key, '/');
        %     modality = parts{1};
        %     if numel(parts) > 1
        %         branch = parts{2};
        %     else
        %         branch = '';
        %     end
        % end
    end
end