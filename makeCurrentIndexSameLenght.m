function currentIndexStruct = makeCurrentIndexSameLenght(currentIndexStruct,nTimePoints)
    modalities = fieldnames(currentIndexStruct);
    for i = 1:numel(modalities)
        modality = modalities{i};
        currentIndex = currentIndexStruct.(modality);
        len = length(currentIndex);
        if len < nTimePoints
            currentIndex(len+1:nTimePoints) = 0;
            currentIndexStruct.(modality) = currentIndex;
        end
    end
end