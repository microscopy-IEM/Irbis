function configureTemporalAxes(currentAxes)

    % hide axes decorations
    currentAxes.XAxis.Visible = 'off';
    currentAxes.YAxis.Visible = 'off';
    currentAxes.ZAxis.Visible = 'off';

    currentAxes.XLabel.Visible = 'off';
    currentAxes.YLabel.Visible = 'off';
    currentAxes.ZLabel.Visible = 'off';

    % background color
    currentAxes.Color = [0 0 0];

    % stable 3-D behaviour
    axis(currentAxes,'vis3d')
    % axis(currentAxes,'tight')

    daspect(currentAxes,[1 1 1])

    % camera setup
    % camtarget(currentAxes,[0 0 0])

    % lighting
    % lighting(currentAxes,'gouraud')


    % remove default interactions FIRST
    % disableDefaultInteractivity(currentAxes)

    % then install custom interactions
    currentAxes.Interactions = [
        rotateInteraction
        zoomInteraction
    ];
    enableDefaultInteractivity(currentAxes)

    currentAxes.Clipping = 'off';

    % hide toolbar
    % currentAxes.Toolbar.Visible = 'off';

end