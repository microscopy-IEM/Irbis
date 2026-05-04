% Custom colormap similar to the ImageJ LUT "fire"

function cmap = fire(greyLevels)

    if nargin < 1
        greyLevels = 256;
    end

    % Define the normalized anchor points of the gradient (from 0 to 1)
    anchors = [0.0; 0.2; 0.4; 0.6; 0.8; 1.0];
    
    % Define the RGB values at those specific anchor points
    colors = [
        0.00, 0.00, 0.00;  % Black
        0.15, 0.00, 0.40;  % Dark Purple
        0.60, 0.00, 0.60;  % Magenta
        1.00, 0.40, 0.00;  % Orange
        1.00, 1.00, 0.00;  % Yellow
        1.00, 1.00, 1.00   % White
    ];

    % Create the query points for 'm' color levels
    xq = linspace(0, 1, greyLevels)';
    
    % Interpolate the colors linearly 
    cmap = interp1(anchors, colors, xq, 'linear');
    
    % Clamp the values between 0 and 1
    cmap = max(min(cmap, 1), 0);
end