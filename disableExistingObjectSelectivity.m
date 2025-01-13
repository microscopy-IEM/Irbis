function disableExistingObjectSelectivity(ax)

    objectHandles = ax.Children;
    for componentN = 1:length(objectHandles)
        if isprop(objectHandles(componentN), 'PickableParts')
            set(objectHandles(componentN), 'PickableParts', 'none');
        end
    end

end