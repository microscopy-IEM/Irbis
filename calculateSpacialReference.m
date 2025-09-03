function spacialRef = calculateSpacialReference(imageSizePix, pixelSize)
    xsize_um = imageSizePix(2) * pixelSize; % x size in micrometers
    ysize_um = imageSizePix(1) * pixelSize; % y size in micrometers
    xWorldLimits = [0 xsize_um]; % x limits in micrometers
    yWorldLimits = [0 ysize_um]; % y limits in micrometers
    spacialRef = imref2d(imageSizePix, xWorldLimits, yWorldLimits);    % TO FIX: spatial instead of spacial
end