function applyStyleToComponents(fig)
    sectionButtons = findobj(fig.Children,'Tag','sectionButton');
    set(sectionButtons,'BackgroundColor',[0.4980,0.7765,0.9098]);
    subsectionButtons = findobj(fig.Children,'Tag','subsectionButton');
    set(subsectionButtons,'BackgroundColor',[0.8745,0.9412,0.9765]);
end