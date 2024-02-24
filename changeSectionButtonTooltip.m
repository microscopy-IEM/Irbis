function changeSectionButtonTooltip(button,value)
    tooltip = button.Tooltip;
    tooltipWords = strsplit(string(tooltip), ' ');
    if value
        newFirstWord = 'Collapse';
    else
        newFirstWord = 'Expand';
    end
    if ~isempty(tooltip)
        tooltipWords{1} = newFirstWord;
        newTooltip = strjoin(tooltipWords, ' ');
        set(button,'Tooltip',newTooltip);
    end                                
end