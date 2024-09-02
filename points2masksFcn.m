

function finalMap = points2masksFcn(peaks,greyMap,expectedPeakDiamPx,pixel_size,z_spacing)

conn = 6; % 3D case
peak2BcgRatioThres = 1;

% pixel_size = 0.0484;
% z_scaling = 0.115;
% 
% pixel_size = 0.03385;
% z_scaling = 0.2;

% thFun = @(mx,mn)((mx-mn)/2 + mn);      

% Local threshold function
thFun = @(mx,mn)((mx)/3 + mn);    

nDimensions = ndims(greyMap);

%% Pre-process by gaussian filtering

% smooth to suppress pixel-pixel variations
greyMap = imgaussfilt3(greyMap,0.5);

% binary operators
searchDiam = round(1.5*expectedPeakDiamPx);

% searchDiam = 10
searchDiam = 10

searchOffset = strel('sphere',searchDiam);
peakOffset = strel("sphere",1);

expectedVol = 4/3*pi*(expectedPeakDiamPx/2)^2;

minVol = round(4/3*pi*(expectedPeakDiamPx/2/2)^2);
maxVol = round(4/3*pi*(4*expectedPeakDiamPx/2)^2);

% minVol = round(expectedVol/5) % in pixels
% maxVol = round(expectedVol*100) % in pixels
   
sz = size(greyMap);

nPeaks = height(peaks);
    
    %% Detect if any peaks has maxima extended to more than one pixel
    % nExtendedMaxima = sum(peaks.VolumePix > 1);
    % nPeaks = size(peaks,1);
    % 
    % % replace extended maximas by only one by rounded centroid position
    % if nExtendedMaxima > 0
    % 
    %     BW = false(sz);
    % 
    %     for currentAreaInd = 1:nPeaks
    % 
    %         x = round(peaks.Centroid(currentAreaInd,1));
    %         y = round(peaks.Centroid(currentAreaInd,2));
    %         z = round(peaks.Centroid(currentAreaInd,3));
    %         BW(y,x,z) = 1;
    % 
    %     end
    % 
    %     LabeledBW = bwlabeln(BW);
    % 
    %     peaks = regionprops3(LabeledBW,greyMap,"Centroid","VoxelIdxList",'Volume',"MaxIntensity");
    % 
    %     nPeaks = size(peaks,1);
    % 
    % end
    
    
    %% Find near peaks that merge into connected area
    % totalOffset = imdilate(BW,searchOffset)
    % figure
    % imshow(totalOffset,[],'InitialMagnification',5000)
    
    
    % create empty map for storing detected peak areas
    peakAreas = false(sz);
    
    %% Single peak processing
    
    for currentAreaInd = 1:nPeaks
    
        % currentAreaInd

        % x = round(peaks.x(currentAreaInd));
        % y = round(peaks.y(currentAreaInd));
        % z = ceil(peaks.z(currentAreaInd));

       
        x = ceil(peaks.x(currentAreaInd)./pixel_size);
        y = ceil(peaks.y(currentAreaInd)./pixel_size);
        z = ceil(peaks.z(currentAreaInd)./z_spacing);
        
        % create binary maxima map - all pixels with maxima = 1, otherwise 0
        peakSearchArea = false(sz);
        peakDetectedArea = false(sz);
        peakSearchArea(y,x,z) = 1;
        % peakSearchArea(x,y,z) = 1
        
        % define close pixels next to local maxima to calculate "mean" peak maxima value
        peakAbs = imdilate(peakSearchArea,peakOffset);
        % define neiburhood of maxima to search for connected pixels
        peakSearchArea = imdilate(peakSearchArea,searchOffset);
        
        mn = min(greyMap(peakSearchArea));
        % mx = mean(greyMap(peakAbs));
        mx = max(greyMap(peakAbs));
        % th_max = max(greyMap(peakAbs)); % max threshold - in region can be present pixels with higher value from another lokal peak maxime 
    
        % calculate local threshold by selected function
        th_low = thFun(mx,mn);

        % calculate ratio between maxima and minima of the peak
        peak2BcgRatio = mx/mn;
        
        
        % detect connected pixels by defined threshold in maxima neiburhood
        % thIdx = greyMap(peakArea) > th_low & greyMap(peakArea) <= th_max;
        thIdx = greyMap(peakSearchArea) >= th_low;
    
        Vol = sum(thIdx);
    
        % keep only peaks with minimal volume
        % if Vol >= minVol && Vol <= maxVol && peak2BcgRatio >= peak2BcgRatioThres

        if peak2BcgRatio >= peak2BcgRatioThres
    
            peakDetectedArea(peakSearchArea) = thIdx;
              
            [~,nAreas]  = bwlabeln(peakDetectedArea);
            %% if there is more than one separetd area, keep only the one below current peak
            % typically when few pixels in the corner of search area have higer values
            % from leaking other peak
            
            if nAreas > 1
            
                singleRegProbs = regionprops3(peakDetectedArea,greyMap,"Centroid","VoxelIdxList",'Volume');
            
                for i = 1:nAreas
            
                    ind = sub2ind(sz,y,x,z);
            
                    voxels = singleRegProbs.VoxelIdxList{i};
            
                    if ismember(ind,voxels)
                        break
                    end
            
                end
            
                % delete areas not below current peak
                peakDetectedArea(:) = 0;
                % keep only one area
                peakDetectedArea(voxels) = 1;
                        
            end
                
            % add detected current peak area into peak map
            peakAreas = peakAreas | peakDetectedArea;
    
        end
    
    end
    
    %% Check each peak area if contains only one peak or if more peaks merged into one connected area
    
    CC = bwconncomp(peakAreas,conn);
    singleRegProbs = regionprops3(CC,greyMap,"Centroid","VoxelIdxList")
    
    nAreas = size(singleRegProbs,1);
    
    finalMap = false(sz);
    finalMap = bwlabeln(finalMap);
    
    % total number of areas
    N = 1;
    
    for currentAreaInd = 1:nAreas
    
    % get all voxels of current area
    voxels = singleRegProbs.VoxelIdxList{currentAreaInd};
    
    % get positions of all peaks
    % maximaIdx = cell2mat(peaks.VoxelIdxList);
    
    % determinet how many peaks fell into current area
    % nMaximaInRegion = sum(ismember(maximaIdx,voxels));

    nMaximaInRegion = 1;
        
    
        %% if connected peak area has n>1 regional maxima, cluster it to n areas   
    
        if nMaximaInRegion == 1
    
            % disp('oneMaxima')
            
            finalMap(voxels) = N;
            N = N+1;
    
        elseif nMaximaInRegion > 1
    
            % disp('twoMaxima')
          
            [x,y,z] = ind2sub(sz,voxels);
            P = [x,y,z];
                        
            regMap = zeros(sz);
           
            idx = spectralcluster(P,nMaximaInRegion,'Distance','euclidean');
            % [idx,V,DD] = spectralcluster(P,nMaximainRegion,'Distance','mahalanobis');
    
            % figure
            % for i = 1:nMaximaInRegion
            %     scatter3(x(idx==i),y(idx==i),z(idx==i))
            %     hold on
            % end
      
            idx = idx + N - 1;
            regMap(voxels) = idx;
    
            N = N+nMaximaInRegion;
    
            finalMap = finalMap + regMap;
    
            % Detect touching regions between multiple peaks
            regOverlaps = zeros(sz);
    
            for n = unique(idx)'
                    
                currentArea = finalMap;
                currentArea(finalMap ~= n) = 0;
                currentArea(currentArea>1) = 1;
    
                % enlarge current area by 1 pixel
                currentArea = imdilate(currentArea,peakOffset);
    
                % sum togehter - overlaping pixels will have value > 1
                regOverlaps = regOverlaps + currentArea;
    
            end
    
            % detect edge pixels
            edgeIdx = regOverlaps > 1;
            % delete edge points
            finalMap(edgeIdx) = 0;
    
        end
    
    end
    
    nObjects =  max(finalMap,[],'all'); 
    
    %% Result plot

    % size(finalMap)
    % finalMap
    % max(finalMap,[],3)
    % 
    % figure(1)
    % imshow(max(finalMap,3),[],'InitialMagnification',5000)
    
    % if nDimensions == 3
    %     viewer = viewer3d(BackgroundColor="white", ...
    %         GradientColor=[0.5 0.5 0.5],Lighting="on");
    % 
    %     finalFiltered = finalMap;
    %     finalFiltered(finalFiltered>0) = 1;
    %     finalFiltered = imgaussfilt3(finalFiltered,1);
    % 
    % vol = volshow(finalFiltered,'RenderingStyle','VolumeRendering','Colormap',[0 1 0],Parent=viewer);
    % 
    % else
    % 
    %     figure
    %     imshow(greyMap,[],'InitialMagnification',5000)
    %     hold on
    %     % CC = bwconncomp(finalMap);
    %     % L = labelmatrix(CC);
    %     RGB = label2rgb(finalMap,'cool');
    % 
    %     hold on
    %     im = imshow(RGB);
    %     im.AlphaData = 0.15;
    % 
    % 
    % end


end



