close all;
clear all

info = imfinfo('stack.tif');
info(1)
stack = imread('stack.tif');

% green = imread('green.tif');
% red = imread('red.tif');
% blue = imread('blue.tif');
% 
% green = im2double(green);
% red = im2double(red);
% blue = im2double(blue);
% 

% 
% 
% 
% f = figure;
% 
% % h1 = imshow(green)
% 
% ax = gca;
% 
% g = [0 1 0];
% 
% cmap = gray.*g;
% 
% ax.Colormap = cmap;
% 
% 
% D = cat(3,red,green,blue);
% 
% h1 = imshow(D)
% 
% 
% green = imadjust(green,[0.1, 0.5]);
% blue = imadjust(blue,[0.2, 0.8]);
% 
% h1.CData(:,:,2) = green;
% h1.CData(:,:,3) = blue;
% 
% h1.CData(:,:,1) = nan(size(blue));


% im = im2double(im);
% 
% 
% % im = randn(200,1);
% 
% 
% 
% h = histogram([],'Normalization','probability')
% % ax = gca;
% % 
% % 
% % syn_x1 = ax.XLim(1);
% % syn_x2 = ax.XLim(2)/2;
% % 
% % histRoi = drawrectangle(ax, 'Position', [syn_x1,ax.YLim(1),syn_x2-syn_x1,ax.YLim(2)],'Color','r','Tag','Syn');
% % 
% % 
% % % ax.Children(2) = histogram(im)
% % 
% % 
% % % 
% % % ax
% % % 
% % % h = histogram(im)
% % % 
% % % bringToFront(histRoi)
% % 
% % pause(2)
% % 
% % im = randn(200,1);
% [N,edges] = histcounts(im,'Normalization','probability');
% 
% h.BinEdges = edges;
% h.BinCounts = N;
% % % h.Values = N;
% % 
% % 
% % % 
% % % figure
% % % stairs(N,edges)