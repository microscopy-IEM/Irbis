close all

% hFig = figure('Toolbar','none','Menubar','none');

hFig = figure
% hIm = imshow('foggysf1.jpg');

im = imread('im1.tif');

% hIm = imshow('foggysf1.jpg');
hIm = imshow(im);
colormap jet
ax = gca
% 
% hSP = imscrollpanel(hFig,hIm);
% imoverview(hIm)
% % 
% % api = iptgetapi(hSP);
% % 
% api = iptgetapi(hSP);
% api.setMagnification(5);