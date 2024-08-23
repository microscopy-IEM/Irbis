function currentIndexStruct = makeCurrentIndexSameLength(currentIndexStruct, nTimePoints)
    % disp('in makeCurrentIndexSameLength function')
    % Call the recursive function to process each level
    currentIndexStruct = processStruct(currentIndexStruct, nTimePoints);
    % assignin('base',"currentIndexStruct",currentIndexStruct)
end

function structVar = processStruct(structVar, nTimePoints)
    % Get the field names of the current struct
    fields = fieldnames(structVar);
    
    % Loop through each field
    for i = 1:numel(fields)
        field = fields{i};
        
        % Check if the field is a struct
        if isstruct(structVar.(field))
            % Recursively process the sub-struct
            structVar.(field) = processStruct(structVar.(field), nTimePoints);
        else
            % Check if the field is a numeric array
            if isnumeric(structVar.(field))
                % Get the length of the array
                len = length(structVar.(field));
                
                % Pad with zeros if length is less than nTimePoints
                if len < nTimePoints
                    structVar.(field)((len+1):nTimePoints) = 0;
                end
            end
        end
    end
end

% function currentIndexStruct = makeCurrentIndexSameLength(currentIndexStruct,nTimePoints)
%     modalities = fieldnames(currentIndexStruct);
%     for i = 1:numel(modalities)
%         modality = modalities{i};
%         currentIndex = currentIndexStruct.(modality);
%         len = length(currentIndex)
%         if len < nTimePoints
%             currentIndex((len+1):nTimePoints) = 0;
%             currentIndexStruct.(modality) = currentIndex;
%         end
%     end
% end