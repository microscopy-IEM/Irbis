clc; 
% clear all

%% Import planes
% f = uifigure;
% planes = importPlanes3(f);
% close(f)

zstack = planes.zstack;


nChannels = planes.nChannels;
nPlanes = planes.nPlanes;
nTimePoints = planes.nTimePoints;
xres = planes.imSize(1);
yres = planes.imSize(2);

channel_ranges = planes.channel_ranges;



%% user input for getZprojection

% manual change of channel ranges
channel_ranges{1} = [0 0.75];
channel_ranges{2} = [0 0.20];
% channel_ranges{3} = [0.4 0.5]

% Z range selection
% Z_Range = 1;
Z_Range = 12:24;
currentTimePoint = 1;

% user selected channels to be plotted
activeChannels = [1,2];

%% To IRBIS

% Zstack - keeps originala images as uint16
% zstack_adjusted - keeps adjusted images as uint8 used later for composition of RGB for plot
% RBGplane - single image of all channels blended into one RGB image for plot CData update


%% create colormaps for each channel 
% update everytime user changes channel color or selects a different colormap

channelColors = planes.channelColors;

% test change channel ch1 to magenta
channelColors{1} = [1 0 1];

%
for ch = activeChannels
    cmap{ch} = gray(2^16).*channelColors{ch};
end


%% Fast contrast adjustment of whole 5D image
% run this code for each histogram adjustmanet
disp('Zstack contrast adjustment time:')
tic 
zstack_adjusted = uint16.empty(xres,yres,nPlanes,nTimePoints,0);
for ch = activeChannels

    zstack_adjusted(:,:,:,:,ch) = imadjustn(zstack(:,:,:,:,ch),channel_ranges{ch});

end
toc

%% getZprojection

plotPlane = zstack_adjusted(:,:,Z_Range,currentTimePoint,activeChannels);
mode = 'max';
Zprojection = squeeze(getZProjection([],zstack_adjusted,activeChannels,Z_Range,currentTimePoint,mode));


%% Fast RGB blend
% saturation of colors is not a proble, imageJ does it the same way. User
% must adjust hostogram to avoid saturation in plotted image

disp('RGB blend time:')
tic

% create empty array
RBGplane = uint8.empty(xres,yres,3,0);

for ch_ind = 1:length(activeChannels)
    
    % RBGplane(:,:,:,ch) = ind2rgb8(zstack_adjusted(:,:,Z_Range,currentTimePoint,ch),cmap{ch});
    RBGplane(:,:,:,ch_ind) = ind2rgb8(Zprojection(:,:,ch_ind),cmap{activeChannels(ch_ind)});

end

rgbImage = sum(RBGplane,4,"native");
toc

%% test plot
figure(1)
imshow(rgbImage,"InitialMagnification",150)

%% Adjusted getZProjection function

function Zprojection = getZProjection(~,zstack,refCh,Z_Range,timePoint,mode)
        
            IM = zstack(:,:,Z_Range,timePoint,refCh);
          
            Zprojection = [];
            
                switch mode
                    case 'max'
                        Zprojection = max(IM,[],3,"omitmissing");
                    case 'mean'                   
                        Zprojection = mean(IM,3,"omitmissing");
                    case 'median'
                        Zprojection = median(IM,3,"omitmissing");
                    case 'zstack'
                        Zprojection = IM;
                end
        end


