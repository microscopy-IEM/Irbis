clc;

 load('dish3_2B_ATTO_03_MMpack_edited_res_table.mat')

 x = matFile.smlm.x;
 y = matFile.smlm.y;

roi = matFile.T.roiPolygon{1};

plot(roi)