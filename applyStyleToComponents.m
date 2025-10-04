function applyStyleToComponents(fig)
    sectionButtons = findobj(fig.Children,'Tag','sectionButton');
    set(sectionButtons,'BackgroundColor',[0.4980,0.7765,0.9098]);
    set(sectionButtons, 'FontColor', [0, 0, 0]);
    subsectionButtons = findobj(fig.Children,'Tag','subsectionButton');
    set(subsectionButtons,'BackgroundColor',[0.8745,0.9412,0.9765]);
    set(subsectionButtons, 'FontColor', [0, 0, 0]);

    % objectsWithFont = findobj(fig,'-property', 'FontSize');
    % set(objectsWithFont,'FontSize',11);

    % color setting of whole app GUI
    % colorh = findobj(app.LeftPanel, '-property', 'BackgroundColor');
    % set(colorh,'BackgroundColor',[0.05 .11 0.07])
    % set(colorh,'BackgroundColor',[0.38 .64 0.77])

    % colorh = findobj(app.LeftPanel, '-property', 'FontColor');
    % set(colorh,'FontColor',[0.39 1 0.64])
    % set(colorh,'FontColor',[0.04 0.28 0.49])    

end