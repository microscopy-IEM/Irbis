close all;

clc;
f = figure
ax = gca
% f.Units = "points";
% f.Position = [200 100 1200 1200];



roi = drawellipse(ax,'Center',[0,0],'SemiAxes',[200,200],'InteractionsAllowed','reshape');
axis equal

ax.XLim = [-250 250];
ax.YLim = [-250 250];

disableDefaultInteractivity(ax)

addlistener(roi,'MovingROI',@allevents);
% addlistener(roi,'ROIMoved',@allevents);


function allevents(src,evt)
    evname = evt.EventName;
    switch(evname)
        case{'MovingROI'}
            evt
            % disp(['ROI moving previous position: ' mat2str(evt.PreviousPosition)]);
            % disp(['ROI moving current position: ' mat2str(evt.CurrentPosition)]);
        case{'ROIMoved'}
            disp(['ROI moved previous position: ' mat2str(evt.PreviousPosition)]);
            disp(['ROI moved current position: ' mat2str(evt.CurrentPosition)]);
    end
end