classdef processingPipeline < handle 
   
    properties
        name % name of the pipeline
        steps = [];    
    end

    methods
        
        function obj = processingPipeline(name)

            obj.name = name;            

        end

        function im = runPipeline(obj,im,varargin)
            
            if isempty(obj.steps)
                disp('No processing steps in the current pipeline')
                return
            end
            
            % Existence of a caller figure will determine the type of
            % progress bar to be used (waitbar or uiprogressdlg)
            if ~isempty(varargin)                                    
                callerFigure =  varargin{1};         
            else
                callerFigure = [];
            end

            % sz = size(im)
            % nTimePoints = sz(4)
            % nChannels = size(im)

            % create progress bar
            progressBar = obj.createProgressBar(callerFigure);

            nSteps = size(obj.steps,1);     
            
            for stepInd = 1:nSteps

                stepName = obj.steps(stepInd).type;
                obj.updateProgressBar((stepInd-1)/nSteps,stepName,callerFigure,progressBar)

                if obj.steps(stepInd).do    
                    
                    try
                        im = obj.steps(stepInd).fcn(im,obj.steps(stepInd).params); % this calls the processing function of the current step with 'params' and 'im' as input stored in the class object
                    catch ME
                        disp('Error Message:')
                        disp(ME.message)
                        disp(['Error at step ' stepName])
                        return
                    end

                    if obj.cancelRequestedCheck(callerFigure,progressBar) % interrupt in case of cancel button pressed
                        obj.closeProgressBar(progressBar)
                        disp(['Processing cancelled at step ' stepName])
                        return                                               
                    end
                end
            end

            obj.updateProgressBar(1,'Finished',callerFigure,progressBar)   
            obj.closeProgressBar(progressBar)
       
        end
  
        %% Pipeline building/editing functions
        function delStep(obj,id)
            
            nSteps = size(obj.steps,1);

            if id <= nSteps
                obj.steps(id) = [];            
            end

        end


        function addNewStep(obj,type)

            switch type
                case 'Median filter'
            
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myMedianFilter;
                    
                    newStep.params.neighborhood = 3;
                    newStep.paramsInfo.neighborhood.limits = [3,15];
                    newStep.paramsInfo.neighborhood.step = 2;
                    newStep.paramsInfo.neighborhood.label = 'Neig.';
                    newStep.paramsInfo.neighborhood.tooltip = 'Neighborhood';
            
                case 'Gaussian filter'
            
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myGaussFilter;
                    
                    newStep.params.sigma = 0.5;
                    newStep.paramsInfo.sigma.limits = [0.1,10];
                    newStep.paramsInfo.sigma.step = 0.1;
                    newStep.paramsInfo.sigma.label = 'Sigma';
                    newStep.paramsInfo.sigma.tooltip = 'Sigma value for the gaussian filter';
            
                case 'Bilateral filter'
        
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myBilatFilter;
                    
                    newStep.params.sigma = 5;
                    newStep.params.degreeOfSmoothing = 1;
                    newStep.paramsInfo.sigma.limits = [1 10];
                    newStep.paramsInfo.sigma.step = 1;
                    newStep.paramsInfo.sigma.label = 'Sigma';
                    newStep.paramsInfo.sigma.tooltip = 'Sigma value';

                    newStep.paramsInfo.degreeOfSmoothing.limits = [1 10];
                    newStep.paramsInfo.degreeOfSmoothing.step = 1;
                    newStep.paramsInfo.degreeOfSmoothing.label = 'DoS';
                    newStep.paramsInfo.degreeOfSmoothing.tooltip = 'Degree of smoothing';
        
                case 'Anisotropic diffusion'
        
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myAnisotropicDiffusion;
                    
                    newStep.params.numberOfIterations = 3;     
                    newStep.paramsInfo.numberOfIterations.limits = [1 10];
                    newStep.paramsInfo.numberOfIterations.step = 1;
                    newStep.paramsInfo.numberOfIterations.label = 'nIter';
                    newStep.paramsInfo.numberOfIterations.tooltip  = 'Number of iterations';
            
                case 'Non-local means'
            
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myNonLocalMeans;
                    
                    newStep.params.degreeOfSmoothing = 1;
                    newStep.paramsInfo.degreeOfSmoothing.limits = [1 10];
                    newStep.paramsInfo.degreeOfSmoothing.step = 1;
                    newStep.paramsInfo.degreeOfSmoothing.label = 'DoS';
                    newStep.paramsInfo.degreeOfSmoothing.tooltip = 'Degree of smoothing';
                  
                case 'Local brightening'

                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myLocalBrightening;                    
                    
                    newStep.params.strength = 0.5; % or 'Flat-field correction'
                    newStep.paramsInfo.strength.limits = [0 1];
                    newStep.paramsInfo.strength.step = 0.1;
                    newStep.paramsInfo.strength.label = 'Strength';
                    newStep.paramsInfo.strength.tooltip = 'Strength value';

                case 'Background subtraction'

                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myBackgroundSubtraction;
                    
                    newStep.params.kernel = 32; % or 'Flat-field correction'
                    newStep.paramsInfo.kernel.limits = [1 512];
                    newStep.paramsInfo.kernel.step = 1;
                    newStep.paramsInfo.kernel.label = 'Sigma';
                    newStep.paramsInfo.kernel.tooltip = 'Kernel size';

                case 'Flat-field correction'
                  
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myFlatFieldCorrection;
                    
                    newStep.params.kernel = 32; % or 'Flat-field correction'
                    newStep.paramsInfo.kernel.limits = [1 512];
                    newStep.paramsInfo.kernel.step = 1;
                    newStep.paramsInfo.kernel.label = 'Sigma';
                    newStep.paramsInfo.kernel.tooltip = 'Kernel size';
                                                  
                case 'Deconvolution'
                    
                    newStep.type = type;
                    newStep.do = true;
                    newStep.fcn = @obj.myDeconvolution;
                    
                    newStep.params.sigma = 1.5;
                    newStep.paramsInfo.sigma.limits = [0.1 10];
                    newStep.paramsInfo.sigma.step = 0.1;
                    newStep.paramsInfo.sigma.label = 'Sigma';
                    newStep.paramsInfo.sigma.tooltip = 'Sigma value';
                    
                    newStep.params.nIter = 10;
                    newStep.paramsInfo.nIter.limits = [1 50];
                    newStep.paramsInfo.nIter.step = 1;
                    newStep.paramsInfo.nIter.label = 'nIter.';
                    newStep.paramsInfo.nIter.tooltip = 'Number of iterations';

                    newStep.params.method = 'Lucy-Richardson'; 
                    newStep.paramsInfo.method.options = {'Blind','Lucy-Richardson'}; 
                    newStep.paramsInfo.method.label = 'Method';
                    newStep.paramsInfo.method.tooltip = 'Deconvolution method';

                % case 'BM4D'
                % 
                %     newStep.type = type;
                %     newStep.do = true;
                %     newStep.fcn = @obj.myBM4D;
                % 
                %     newStep.params.degreeOfSmoothing = 1;
                %     newStep.paramsInfo.degreeOfSmoothing.limits = [1 10];
                %     newStep.paramsInfo.degreeOfSmoothing.step = 1;
                %     newStep.paramsInfo.degreeOfSmoothing.label = 'DoS';
                %     newStep.paramsInfo.degreeOfSmoothing.tooltip = 'Degree of smoothing';                    

            end

            % obj.steps{end+1} = newStep; % adding the new step to the pipeline  

            if isempty(obj.steps)

                obj.steps = struct('type','','do',[],'fcn',[],'params',[],'paramsInfo',[]);
                obj.steps = newStep; % adding first step to the pipeline 

            else
                obj.steps(end+1,1) = newStep; % adding the new step to the pipeline     
            end

        end
       

    end

    methods(Static)

        %% Spatial filtering functions

        function im = myMedianFilter(im,params)
        
            neig = params.neighborhood;    
            im = medfilt3(im,[neig, neig, neig]);
            
            disp('Median filter done')
        
        end
                
        function im = myGaussFilter(im,params)
        
            sigma = params.sigma;        
            im = imgaussfilt3(im,[sigma, sigma, sigma]);
            
            disp('Gaussian done')
            
        end
        
        function im = myBilatFilter(im,params)
            
            degreeOfSmoothing = params.degreeOfSmoothing;
            sigma = params.sigma;

            % nSteps = size(im,3);

            for plane = 1:size(im,3)

                patchVar = std2(im(:,:,plane))^2;
                DoS = 2*patchVar;
                DoS = DoS*degreeOfSmoothing*0.2;

                im(:,:,plane) = imbilatfilt(im(:,:,plane),DoS,sigma);  

                % obj.updateProgressBar(round(plane/nSteps,2)*100,'Finished',callerFigure,progressBar)   


            end
            
            disp('Bilateral filtering done')
        
        end
        
        function im = myNonLocalMeans(im,params)
         
            degreeOfSmoothing = params.degreeOfSmoothing;
                 
            for plane = 1:size(im,3)
                patchVar = std2(im(:,:,plane));
                DoS = patchVar*degreeOfSmoothing*0.1;
                
                im(:,:,plane) = imnlmfilt(im(:,:,plane),'DegreeOfSmoothing',DoS);
            end
        
            disp('Non-local means filtering done')
        
        end
        
        function im = myAnisotropicDiffusion(im,params)
        
            numberOfIterations = params.numberOfIterations;
            im = imdiffusefilt(im,'NumberOfIterations',numberOfIterations);
            
            disp('Anisotropic diffusion filtered')
        
        end
        
        %% Background correction functions
        function im = myFlatFieldCorrection(im,params)
                   
            kernelSize = params.kernel;                        
                
            for plane = 1:size(im,3)
                im(:,:,plane) = imflatfield(im(:,:,plane),kernelSize);
            end
                 
            disp('Flat-field correction done')
        
        end

        function im = myBackgroundSubtraction(im,params)

            kernelSize = params.kernel;
            sigma = ceil(kernelSize/5);

            for plane = 1:size(im(:,:,:),3)
                 background = imopen(im(:,:,:),strel('disk',kernelSize));
                 background = imgaussfilt(background,sigma);                    
                 im(:,:,:) = imsubtract(im(:,:,:),background);
            end

            disp('Background subtraction done')

        end
        
        %% Contrast enhancement functions        
        function im = myLocalBrightening(im,params)
        
            strength = params.strength;
       
            for plane = 1:size(im,3)
                 im(:,:,plane) = imlocalbrighten(im(:,:,plane),strength);
            end
                      
        end
        
        %% Deconvolution functions
        function im = myDeconvolution(im,params)
        
            sigma = params.sigma;
            nIter = params.nIter;
            method = params.method;
            
            kernelW = round(sigma*3);
        
            if size(im,3) < 3 % 2D case
        
                PSF = fspecial('gaussian',kernelW,sigma);
        
            else % 3D case
            
                PSF = fspecial3('gaussian',5,sigma);
        
            end
                
            dampThres = cast(10,like=im);
            readoutNoise = cast(10,like=im);
        
            switch method
                case 'Blind'
                
                    [im,~] = deconvblind(im,PSF,nIter,dampThres,[],readoutNoise);
                                    
                case 'Lucy-Richardson'
                
                    im = deconvlucy(im,PSF,nIter,dampThres,[],readoutNoise);
            
            end
        
            disp('Deconvolution done')
        
        end

        %% External functions
      
        % function im = myBM4D(im,params)
        % 
        %     degreeOfSmoothing = params.degreeOfSmoothing;
        %     origRange = getrangefromclass(im); % bit depth
        %     origClass = class(im);
        %     origClassFc = str2func(origClass);
        % 
        %     % convert to double for the BM4D fcn
        %     im = im2double(im);
        % 
        %     patchVar = std2(im(:));
        %     DoS = patchVar*degreeOfSmoothing*0.25;
        %     hasLicense = license('test', 'wavelet_toolbox'); 
        % 
        %     if size(im,3) < 3 % 2D case
        %         % single plane
        %         disp('Run BM4D plane for single plane using BM3D')
        %         im = BM3D(im, DoS, 'lc');
        %         % im = BM3D(im, DoS);
        % 
        %     else % 3D case
        % 
        %         sz = size(im);
        %         if(max(sz) > 512)                                                               
        % 
        %             if hasLicense      
        % 
        %                 disp('Run BM4D in blocks')                     
        %                 bs = round(min(sz(1:2))/4);
        % 
        %                 bim = blockedImage(im,BlockSize=[bs bs sz(3)]);
        %                 clear im
        %                 % fc = @(bl)BM4D(bl.Data,DoS);
        %                 fc = @(bl)BM4D(bl.Data,DoS,'lc'); 
        % 
        %                 bim2 = apply(bim,fc,BorderSize=[5 5]);
        %                 % bim2 = apply(bim,fc,BorderSize=[5 5 5]);
        %                 im = gather(bim2);
        % 
        %             else
        % 
        %                 disp('Wavelet toolbox is missing')
        %                 disp('Run BM4D plane wise using BM3D')
        % 
        %                 for plane = 1:sz(3)
        %                     im(:,:,plane) =  BM3D(im(:,:,plane),DoS);
        %                 end
        %             end
        % 
        %         else
        % 
        %             if hasLicense   
        %                 disp('Run BM4D normally')
        %                 im = BM4D(im, DoS);
        %             else
        % 
        %                 disp('Wavelet toolbox is missing')
        %                 disp('Run BM4D plane wise using BM3D')
        % 
        %                 for plane = 1:sz(3)
        %                     im(:,:,plane) =  BM3D(im(:,:,plane),DoS);
        %                 end
        % 
        %             end
        % 
        %         end
        % 
        %     end
        % 
        %     % rescale back to original range and convert to original class
        %     im = im.*origRange(2);
        %     im = origClassFc(im);
        % 
        % end

        %% Progress bar functions
        function progressBar = createProgressBar(callerFigure)

            iconName = 'MightyDuckLogo.png';
            haveIcon = exist(iconName,"file");

            if haveIcon == 2
               icon = iconName;
            else
               icon = ''; 
            end

            if isempty(callerFigure)

                progressBar = waitbar(0,'0','Name','Processing image','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
                progressBar.Icon = icon;
                setappdata(progressBar,'canceling',0);

            else

                progressBar = uiprogressdlg(callerFigure,'Title','Processing','Message','Processing image','Cancelable','on');
                progressBar.Value = 0;

            end            

        end

        function updateProgressBar(perc,stepName,callerFigure,progressBar)

            if isempty(callerFigure)
                waitbar(perc,progressBar,stepName)
            else

                progressBar.Message = stepName;
                progressBar.Value = perc;

            end

            pause(0.1)

        end

        function cancelStatus = cancelRequestedCheck(callerFigure,progressBar)

            if isempty(callerFigure)

                cancelStatus = getappdata(progressBar,'canceling');

            else

                cancelStatus = progressBar.CancelRequested;
            end

        end

        function closeProgressBar(progressgBar)

            if ~isempty(progressgBar)
                close(progressgBar)
                delete(progressgBar)
                delete(findall(0, 'type', 'figure', 'tag', 'TMWWaitbar'));
            end

        end
    end
end