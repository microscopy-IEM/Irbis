function res = log10(values)
% custom version of log10 function
% treats negative values at imput as NaN, to prevent complex number at
% output of the function

    disp('doing custom log10')
    values(values < 0) = nan;

    res = log10(values);


end