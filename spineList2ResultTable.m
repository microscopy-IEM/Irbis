function resultTable = spineList2ResultTable(allTPsSpineLists,attributes)

nTimePoinst = size(allTPsSpineLists,2);
labels = {'id'};

% attributes = {'volume','surface','newAttribute'};
% attributes = {'volume','surface'};
nAttributes = size(attributes,2);

% check if the query attributes actually exsit in the spine list
attrNames = allTPsSpineLists{1}.Properties.VariableNames;
queryAttributes = ismember(attributes,attrNames);
existingAttributes = find(queryAttributes == 1);

if size(attributes,2) ~= size(existingAttributes,2)
    warndlg('Warning: some of the query attributes do not exist in the spine list!')
end

%% create empty table
resultTable = table;

for attr = 1:nAttributes
    for tp = 1:nTimePoinst
    
        Tlabel = [attributes{attr} num2str(tp)];
    
        pos = 1+(attr-1)*nTimePoinst+tp;
        labels{pos} = Tlabel;
    
    end
end

% create first empty row
resultTable(1,:) = num2cell(nan(size(labels)));
resultTable.Properties.VariableNames = labels;

%% Fill table with data

% detect all spine chain IDs existing in spine list
uniqueTemp = [];
for tp = 1:nTimePoinst
    uniqueTemp = [uniqueTemp; unique(allTPsSpineLists{tp}.id)];
end

% summary of IDs from all time points
uniqueIds = unique(uniqueTemp);
% remove 0 IDs
uniqueIds = uniqueIds(uniqueIds~=0);


    currentRow = 1; % poiner to actual row in table (is not spine chain id!)

    % cycle all spine chain IDs
    for chainId = uniqueIds'
    
        resultTable(currentRow,:) = [{chainId} num2cell(nan(1,nAttributes*nTimePoinst))];
        resultTable{currentRow,'id'} = chainId;
        
       % cycle all time poinsts
        for tp = 1:nTimePoinst
       
            
            currentSpineList = allTPsSpineLists{tp};
            currentSpine = currentSpineList(currentSpineList.id == chainId,:);
            
            for currentAttribute = existingAttributes

                if ~isempty(currentSpine)
                
                    currentValue = currentSpine{:,attributes{currentAttribute}};
            
                else

                    currentValue = nan;
                        
                end
                
                % assembe txt identifier
                txt = [attributes{currentAttribute} num2str(tp)];
 
                resultTable{currentRow,txt} = currentValue;

            end
   
        end
    
        % new row in result table
        currentRow = currentRow+1;
    
    end

end























