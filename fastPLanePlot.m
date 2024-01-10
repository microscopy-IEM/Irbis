% clc; 
clear all

% 
f = uifigure;
planes = importPlanes3(f);
close(f)
zstack = planes.zstack;
% 
zstack = uint16(zstack);
% 
% size(zstack)
% 
% zstackGPU = gpuArray(zstack);

cmapCh = 'gray';

% ranges = planes.channel_ranges;

ch1 = zstack(:,:,:,:,1);
ch2 = zstack(:,:,:,:,2);
% ch3 = zstack(:,:,:,:,3);

%% Fast contrast adjustment of whole 5D image
% tic 
im1 = imadjustn(ch1,[0 0.1]);
im2 = imadjustn(ch2,[0 0.1]);
% im3 = imadjustn(ch3,[0 0.1]);
% toc
% 
% cmap = gray(2^16);
% 
% tic
% rgbImage = cat(5, im1, im2, im3);
% toc
% imshow(squeeze(rgbImage(:,:,15,1,:)))
% 
% 
% tic
%  im1RGB = ind2rgb8(uint8(im1(:,:,15,1)),jet(2^16));
% toc
% 
% RGB2 = imadjust(im1RGB,[ranges{1}(1) ranges{2}(1) ranges{3}(1); ranges{1}(2) ranges{2}(2) ranges{3}(2)],[]);
% 
% % tic
% % for z = 1:size(im1,3)
% %     for tp = 1:size(im1,4)
% % 
% %         im1RGB = ind2rgb(im1(:,:,z,tp),jet(2^16));
% %     end
% % end
% % toc
% 
% filename = ['D:\OneDrive - Ústav experimentální medicíny AV ČR, v. v. i\Microscopy Team\Irbis project\Test data - planes' '\Spines_life_NB+ to ECS_ECS_SR_2 min_Multichannel tZ-Stack_0001_ID1_CI deconv.vsi - 001 SR561, SR488-1.tif']
% V = tiffreadVolume(filename);
% 

